-- Readout Control
-- L1a -> Procsessing in N Trigger Modes -> Capture Signals -> Process capture on daq_bus for readout
-- F. Ball, March 2014

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

LIBRARY unisim;
USE unisim.VComponents.ALL;

USE work.top_decl.ALL;

USE work.ipbus.ALL;
USE work.ipbus_reg_types.ALL;
USE work.ipbus_decode_mp7_readout_control.ALL;

USE work.mp7_readout_decl.ALL;
USE work.mp7_data_types.ALL;
USE work.mp7_ttc_decl.ALL;

ENTITY mp7_readout_control IS
    PORT (
        clk : IN std_logic;
        rst : IN std_logic;
        ipb_in : IN ipb_wbus;
        ipb_out : OUT ipb_rbus;
        board_id: in std_logic_vector(15 downto 0);
        resync : IN std_logic;
        clk_p : IN std_logic;
        rst_p : IN std_logic;
        l1a : IN std_logic;
        l1a_flag: IN std_logic;
        throttle : IN std_logic;
        ttc_clk : IN std_logic;
        ttc_cmd : IN ttc_cmd_t;
        bunch_ctr : IN bctr_t;
        evt_ctr : IN eoctr_t;
        orb_ctr : IN eoctr_t;
        err : OUT std_logic;
        dr_full : OUT std_logic;
        warn : OUT std_logic;
        cap_bus : OUT daq_cap_bus;
        daq_bus_out : OUT daq_bus;
        daq_bus_in : IN daq_bus;
        rob_last : OUT std_logic;
        done : OUT std_logic
    );

END mp7_readout_control;

ARCHITECTURE rtl OF mp7_readout_control IS

    TYPE bank_array IS ARRAY (natural range <>) OF std_logic_vector(DAQ_N_BANKS - 1 DOWNTO 0);
    TYPE state_type IS (ST_IDLE, ST_DAQ);
    FUNCTION or_array_reduce(ale : bank_array) RETURN std_logic_vector IS -- since or_reduce expects a st_logic_vector and not an array
    VARIABLE ret : std_logic_vector(DAQ_N_BANKS - 1 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        FOR i IN ale'RANGE LOOP
            ret := ret OR ale(i);
        END LOOP; RETURN ret;
    END FUNCTION or_array_reduce;    
	SIGNAL ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	SIGNAL ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	SIGNAL ctrl : ipb_reg_v(1 DOWNTO 0);
	SIGNAL stat : ipb_reg_v(0 DOWNTO 0);
    SIGNAL rst_i : std_logic;
    SIGNAL rst_ctr : unsigned(3 DOWNTO 0);
    SIGNAL dr_hwm, dr_lwm : std_logic_vector(DR_ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL dr_warn : std_logic;
    SIGNAL mode_sel, cap_ctrl_sel: std_logic_vector(1 DOWNTO 0) := (OTHERS => '0');  
    SIGNAL bank_ctrl_sel : std_logic_vector(DAQ_BWIDTH-1 DOWNTO 0) := (OTHERS => '0');  
    SIGNAL capture_bus : bank_array(DAQ_TRIGGER_MODES - 1 DOWNTO 0);
    SIGNAL bank_enable, s_dr_warn, s_dr_full : std_logic_vector(DAQ_N_BANKS - 1 DOWNTO 0);       
    SIGNAL ipbus_in, ipb_w, hist_ipbw : ipb_wbus_array(DAQ_TRIGGER_MODES - 1 DOWNTO 0);
    SIGNAL ipbus_out, ipb_r, hist_ipbr : ipb_rbus_array(DAQ_TRIGGER_MODES - 1 DOWNTO 0);
    SIGNAL bank_ipbw : ipb_wbus_array(DAQ_N_BANKS - 1 DOWNTO 0);
    SIGNAL bank_ipbr : ipb_rbus_array(DAQ_N_BANKS - 1 DOWNTO 0);        
    SIGNAL ec0, bc0, dbus_en : std_logic;
    SIGNAL actr : dr_address_array(DAQ_N_BANKS - 1 DOWNTO 0);   
    SIGNAL dbus_state : state_type;
    SIGNAL veto_in : std_logic_vector(DAQ_TRIGGER_MODES DOWNTO 0);    
    SIGNAL fifo_full, fifo_empty, last, veto_out, daq_ro : std_logic_vector(DAQ_TRIGGER_MODES - 1 DOWNTO 0);
    SIGNAL dbus_mode : daq_bus_array(DAQ_TRIGGER_MODES DOWNTO 0);
    SIGNAL s_rc_cap_ff, s_rc_mode_ff : std_logic_vector(1 downto 0);
    SIGNAL daq_ro_d : std_logic;
    SIGNAL next_evt : eoctr_t;
    SIGNAL warn_int, err_int, dr_full_int : std_logic;

BEGIN

    done <= or_reduce(fifo_empty);

    PROCESS (clk_p) -- even though no FIFO, ro_tok needs to be in sync with readout_ctrl_mode
    BEGIN
        IF rising_edge(clk_p) THEN
            IF resync = '1' THEN
                rst_ctr <= "0000";
            ELSIF rst_i = '1' THEN
                rst_ctr <= rst_ctr + 1;
            END IF;
        END IF;
    END PROCESS;
    
    rst_i <= '1' WHEN rst_ctr /= "1111" ELSE '0';
    
    err_int <= or_reduce(fifo_full) OR or_reduce(s_dr_full) WHEN ctrl(1)(20) = '1' ELSE or_reduce(fifo_full);
    warn_int <= dr_warn WHEN ctrl(1)(20) = '1' ELSE '0';
    
    --- csr

	fabric: entity work.ipbus_fabric_sel
		generic map(
			NSLV => N_SLAVES,
			SEL_WIDTH => IPBUS_SEL_WIDTH
		)
		port map(
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			sel => ipbus_sel_mp7_readout_control(ipb_in.ipb_addr),
			ipb_to_slaves => ipbw,
			ipb_from_slaves => ipbr
		);
		
    rc_csr: entity work.ipbus_ctrlreg_v
        generic map(
            N_CTRL => 2,
            N_STAT => 1
        )
        port map(
            clk => clk,
            reset => rst,
            ipbus_in => ipbw(N_SLV_CSR),
            ipbus_out => ipbr(N_SLV_CSR),
            d => stat,
            q => ctrl
        );
        
    stat(0)(0) <= or_reduce(fifo_full);
    stat(0)(1) <= or_reduce(fifo_empty);
    stat(0)(2) <= dr_warn;
    stat(0)(3) <= or_reduce(s_dr_full);
    stat(0)(7 DOWNTO 4) <= std_logic_vector(to_unsigned(DAQ_TRIGGER_MODES, 4));
    stat(0)(11 DOWNTO 8) <= std_logic_vector(to_unsigned(DAQ_N_CAP_CTRLS, 4));
    stat(0)(15 DOWNTO 12) <= std_logic_vector(to_unsigned(DAQ_N_BANKS, 4));
    stat(0)(31 DOWNTO 16) <= (OTHERS => '0');    
    
    mode_sel <= ctrl(0)(1 DOWNTO 0);
    cap_ctrl_sel <= ctrl(0)(5 DOWNTO 4);
    bank_ctrl_sel <= ctrl(0)(DAQ_BWIDTH + 7 DOWNTO 8);
    
    dr_hwm <= ctrl(1)(8 DOWNTO 0);
    dr_lwm <= ctrl(1)(16 DOWNTO 8);   
 
    ec0 <= '1' WHEN ttc_cmd = TTC_BCMD_EC0 ELSE '0';
    bc0 <= '1' WHEN ttc_cmd = TTC_BCMD_BC0 ELSE '0';
    
    -- sel select for the trigger modes         
    
    mode_fabric: entity work.ipbus_fabric_sel
        generic map(
            NSLV => DAQ_TRIGGER_MODES,
            SEL_WIDTH => 2
        )
        port map(
            ipb_in => ipbw(N_SLV_MODE_CSR),
            ipb_out => ipbr(N_SLV_MODE_CSR),
            sel => mode_sel,
            ipb_to_slaves => ipb_w,
            ipb_from_slaves => ipb_r
        ); 
        
    -- sel select for the capture modes           
            
    cap_ctrl_fabric: entity work.ipbus_fabric_sel
        generic map(
            NSLV => DAQ_TRIGGER_MODES,
            SEL_WIDTH => 2
        )
        port map(
            ipb_in => ipbw(N_SLV_CAP_CSR),
            ipb_out => ipbr(N_SLV_CAP_CSR),
            sel => mode_sel,
            ipb_to_slaves => ipbus_in,
            ipb_from_slaves => ipbus_out
        );
    
    -- sel for bank ctrls
        
    bank_fabric: entity work.ipbus_fabric_sel
        generic map(
            NSLV => DAQ_N_BANKS,
            SEL_WIDTH => DAQ_BWIDTH
        )
        port map(
            ipb_in => ipbw(N_SLV_BANK_CSR),
            ipb_out => ipbr(N_SLV_BANK_CSR),
            sel => bank_ctrl_sel,
            ipb_to_slaves => bank_ipbw,
            ipb_from_slaves => bank_ipbr
        );
        
    hist_fabric: entity work.ipbus_fabric_sel
        generic map(
            NSLV => DAQ_TRIGGER_MODES,
            SEL_WIDTH => 2
        )
        port map(
            ipb_in => ipbw(N_SLV_HIST),
            ipb_out => ipbr(N_SLV_HIST),
            sel => mode_sel,
            ipb_to_slaves => hist_ipbw,
            ipb_from_slaves => hist_ipbr
        ); 
               
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            veto_in(0) <= '0'; 
            IF rst_i = '1' OR or_reduce(daq_ro) = '0' THEN
                daq_bus_out <= DAQ_BUS_NULL;
                dbus_mode(0) <= DAQ_BUS_NULL;
             ELSE
                daq_bus_out <= dbus_mode(DAQ_TRIGGER_MODES);                    
                dbus_mode(0) <= daq_bus_in; 
            END IF;
        END IF;
    END PROCESS;
    
    -- generates i trigger modes
     
    mode_gen : FOR i IN 0 TO (DAQ_TRIGGER_MODES - 1) GENERATE
     
        SIGNAL dbus_in, dbus_out : daq_bus;
        SIGNAL ctrl_reg, stat_reg : ipb_reg_v(1 DOWNTO 0);
     
        BEGIN
        
            ctrl : ENTITY work.ipbus_ctrlreg_v
                GENERIC MAP(
                    N_CTRL => 2, 
                    N_STAT => 2
                    )
                PORT MAP(
                    clk => clk, 
                    reset => rst, 
                    ipbus_in => ipb_w(i), 
                    ipbus_out => ipb_r(i), 
                    d => stat_reg, 
                    q => ctrl_reg
                );
        
            trigger_mode : ENTITY work.mp7_readout_trigger_mode
                PORT MAP(
                    clk => clk,
                    rst => rst,
                    ipbus_in => ipbus_in(i),
                    ipbus_out => ipbus_out(i),
                    ipbus_in_hist => hist_ipbw(i),
                    ipbus_out_hist => hist_ipbr(i),
                    board_id => board_id, -- used in header
                    clk_p => clk_p, 
                    rst_p => rst_p,
                    resync => resync,
                    bc0 => bc0, 
                    ctrl => ctrl_reg,
                    stat => stat_reg,
                    l1a => l1a,
                    l1a_flag => l1a_flag, 
                    ttc_clk => ttc_clk, 
                    daq_bus_in => dbus_mode(i), -- daisy chained daq_bus through trigger modes
                    daq_bus_out => dbus_mode(i + 1),
                    daq_ro => daq_ro(i), -- goes high if trigger mode is reading out
                    bunch_ctr => bunch_ctr,
                    evt_ctr => evt_ctr, 
                    orb_ctr => orb_ctr, 
                    ec0 => ec0, 
                    veto_in => veto_in(i), 
                    veto_out => veto_out(i), -- stops other trigger modes from reading out
                    cap_ctrl_sel => cap_ctrl_sel, -- selects capture mode to r/w to
                    actr => actr, -- current address pointer
                    cap_bus => capture_bus(i), -- bank capture mask
                    fifo_full => fifo_full(i), 
                    fifo_empty => fifo_empty(i),
                    next_evt => next_evt,
                    last => last(i) -- if the last capture mode is reading out, goes high
                );               
                
            veto_in(i + 1) <= veto_in(i) OR veto_out(i); -- vetos all the trigger_modes down the chain
     
    END GENERATE;
    
    rob_last <= or_reduce(last) when rising_edge(clk_p);     
    
    -- keeps track of the order of events
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            daq_ro_d <= or_reduce(daq_ro);
            IF rst_i = '1' THEN
                next_evt <= X"00000001";
            ELSIF or_reduce(daq_ro) = '0' AND daq_ro_d = '1' THEN
                next_evt <= std_logic_vector(unsigned(next_evt) + 1);
            END IF;
        END IF;
    END PROCESS;
     
    -- keeps track of derand address pointer, needs to be on daq_bus clk for keeping track of derand overflow
     
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                cap_bus <= (OTHERS => '0');
            ELSE
                cap_bus <= or_array_reduce(capture_bus);
            END IF;
        END IF;
    END PROCESS;
    
    -- keeps track of the derand r/w pointers                                                           
    
    bank_addr_gen : FOR i IN DAQ_N_BANKS - 1 DOWNTO 0 GENERATE
    
        SIGNAL token, init_sel : std_logic;
        SIGNAL raddr, s_dctr : std_logic_vector(DR_ADDR_WIDTH-1 DOWNTO 0);
        SIGNAL words_per_bx : std_logic_vector(3 DOWNTO 0);
        SIGNAL ctrl_reg, stat_reg : ipb_reg_v(0 DOWNTO 0);
        SIGNAL bank_enable : std_logic;
        SIGNAL dr_occupancy, max_occ : std_logic_vector(DR_ADDR_WIDTH - 1 DOWNTO 0);
        
    BEGIN
    
        ctrl : ENTITY work.ipbus_ctrlreg_v
            GENERIC MAP(
                N_CTRL => 1, 
                N_STAT => 1
                )
            PORT MAP(
                clk => clk, 
                reset => rst, 
                ipbus_in => bank_ipbw(i), 
                ipbus_out => bank_ipbr(i), 
                d => stat_reg, 
                q => ctrl_reg
            );
            
        bank_enable <= or_array_reduce(capture_bus)(i);
        
        stat_reg(0)(DR_ADDR_WIDTH - 1 DOWNTO 0) <= dr_occupancy;
        stat_reg(0)(DR_ADDR_WIDTH + 11 DOWNTO 12) <= max_occ;
    
        PROCESS(ttc_clk)
        BEGIN
            IF rising_edge(ttc_clk) THEN
                IF rst_i = '1' THEN
                    actr(i) <= (OTHERS => '0');
                ELSE
                    IF bank_enable = '1' THEN
                        actr(i) <= std_logic_vector(unsigned(actr(i)) + unsigned(words_per_bx));
                    END IF;
                END IF;
            END IF;
        END PROCESS;
        
        words_per_bx <= ctrl_reg(0)(3 DOWNTO 0);                          
    
        ram_flags : ENTITY work.ram_address_flags
            GENERIC MAP (
                RAM_DEPTH => 512,
                ADDR_WIDTH => DR_ADDR_WIDTH
            )
            PORT MAP (
                clk => clk_p,
                rst_i => rst_i,
                actr => actr(i),
                dctr => s_dctr,
                raddr => raddr,
                init_sel => init_sel,
                ren => token,
                hwm => dr_hwm,
                lwm => dr_lwm,
                warn => s_dr_warn(i),
                full => s_dr_full(i),
                occupancy => dr_occupancy,
                max_occ => max_occ
            );
            
        token <= '1' WHEN dbus_mode(DAQ_TRIGGER_MODES).token = '1' ELSE '0';          
        init_sel <= '1' WHEN dbus_mode(DAQ_TRIGGER_MODES).init = '1' AND
                      (DAQ_BWIDTH = 0 or unsigned(dbus_mode(DAQ_TRIGGER_MODES).data.data(DAQ_BWIDTH + 28 DOWNTO 28)) = i) ELSE '0';
        raddr <= dbus_mode(DAQ_TRIGGER_MODES).data.data(20 DOWNTO 12);
        s_dctr <= "0" & dbus_mode(DAQ_TRIGGER_MODES).data.data(7 DOWNTO 0);
                       
        
    END GENERATE;
     
    dr_warn <= or_reduce(s_dr_warn) WHEN rising_edge(clk_p);
    dr_full_int <= or_reduce(s_dr_full) WHEN rising_edge(clk_p);
    
    -- Improve timing
    regs: process(clk_p)
    begin
        if rising_edge(clk_p) then
            dr_full <= dr_full_int;
            warn <= warn_int;
            err <= err_int;
        end if;
    end process;    
  
      
                                
END rtl;