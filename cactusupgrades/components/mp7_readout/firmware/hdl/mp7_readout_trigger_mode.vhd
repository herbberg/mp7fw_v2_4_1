-- Contains all the settings needed for a particular trigger
-- Will process the MP7 DAQ header here
-- F. Ball - Feb 2015

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

library unisim;
use unisim.VComponents.all;

USE work.ipbus.ALL;
USE work.ipbus_reg_types.ALL;

USE work.mp7_ttc_decl.ALL;
USE work.mp7_data_types.ALL;
USE work.top_decl.ALL;
use work.mp7_top_decl.ALL;
USE work.mp7_readout_decl.ALL;

ENTITY mp7_readout_trigger_mode IS
    PORT (
        clk : IN std_logic;
        rst : IN std_logic;
        ipbus_in : IN ipb_wbus;
        ipbus_out : OUT ipb_rbus;
        ipbus_in_hist : IN ipb_wbus;
        ipbus_out_hist : OUT ipb_rbus;
        board_id: in std_logic_vector(15 downto 0);        
        clk_p : IN std_logic;
        rst_p : IN std_logic;
        resync : IN std_logic;
        bc0 : IN std_logic;
        ctrl : IN ipb_reg_v(1 DOWNTO 0);
        stat : OUT ipb_reg_v(1 DOWNTO 0);
        l1a : IN std_logic;
        l1a_flag : IN std_logic;
        ttc_clk : IN std_logic;
        daq_bus_in : IN daq_bus;
        daq_bus_out : OUT daq_bus;
        daq_ro : OUT std_logic;
        actr : IN dr_address_array;
        bunch_ctr : IN bctr_t;
        evt_ctr : IN eoctr_t;
        orb_ctr : IN eoctr_t;
        ec0 : IN std_logic;
        veto_in : IN std_logic;
        veto_out : OUT std_logic;
        cap_ctrl_sel : IN std_logic_vector(1 DOWNTO 0);
        cap_bus : OUT daq_cap_bus;
        fifo_full : OUT std_logic;
        fifo_empty : OUT std_logic;
        next_evt : IN eoctr_t;
        last : OUT std_logic
    );
END mp7_readout_trigger_mode;

ARCHITECTURE rtl OF mp7_readout_trigger_mode IS
    
    TYPE bank_array IS ARRAY (natural range <>) OF std_logic_vector(DAQ_N_BANKS - 1 DOWNTO 0);
    SIGNAL cap : bank_array(DAQ_N_CAP_CTRLS - 1 DOWNTO 0);
    FUNCTION or_array_reduce(ale : bank_array) RETURN std_logic_vector IS --since or_reduce expects a st_logic_vector and not an array
    VARIABLE ret : std_logic_vector(DAQ_N_BANKS - 1 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        FOR i IN ale'RANGE LOOP
            ret := ret OR ale(i);
        END LOOP; RETURN ret;
    END FUNCTION or_array_reduce;
    SIGNAL rst_i : std_logic;
    SIGNAL rst_ctr : unsigned(2 DOWNTO 0);
    TYPE cyc_state_type IS (ST_IDLE, ST_PIPE, ST_NEXT,ST_CYC);
    SIGNAL cyc_state : cyc_state_type;
    SIGNAL ipbw : ipb_wbus_array(DAQ_N_CAP_CTRLS - 1 DOWNTO 0);
    SIGNAL ipbr : ipb_rbus_array(DAQ_N_CAP_CTRLS - 1 DOWNTO 0);
    SIGNAL stat_reg, ctrl_reg : ipb_reg_v(1 DOWNTO 0);
    SIGNAL dbus_hdr, dbus_tmt, dbus_data, dbus_in, dbus_out : daq_bus;
    SIGNAL event_type : std_logic_vector(15 DOWNTO 0);
    SIGNAL ro_tok : std_logic_vector(DAQ_N_CAP_CTRLS DOWNTO 0);  
    SIGNAL s_l1a, s_l1a_d : std_logic; 
    SIGNAL cap_fifo_full, cap_fifo_empty : std_logic_vector(DAQ_N_CAP_CTRLS -1 DOWNTO 0);
    SIGNAL ctrs_fifo_full, ctrs_fifo_empty, fifo_ren, fifo_wen : std_logic;
    SIGNAL trigger_event : std_logic_vector(7 DOWNTO 0);
    TYPE state_type IS (ST_IDLE, ST_TOK_DEL, ST_HDR, ST_DATA, ST_TMT);
    SIGNAL state : state_type;
    SIGNAL ctrs_fifo_q, ctrs_fifo_d : std_logic_vector(63 downto 0);
    SIGNAL hdr_ctr : unsigned(DAQ_N_HDR_WORDS -1 DOWNTO 0);
    SIGNAL hdr_word : std_logic_vector(31 DOWNTO 0);
    SIGNAL mode_evt_proc : unsigned(evt_ctr'length -1 DOWNTO 0);
    SIGNAL event_size, s_event_size : std_logic_vector(19 DOWNTO 0);
    SIGNAL readme, token_del, token_d_in, token_en : std_logic;
    SIGNAL token_delay : std_logic_vector(6 DOWNTO 0);
    SIGNAL evt_rec, token_rec : unsigned(9 DOWNTO 0);
    
    TYPE cap_array IS ARRAY (natural range <>) OF std_logic_vector(31 DOWNTO 0);
    SIGNAL i_wo : cap_array(DAQ_N_CAP_CTRLS DOWNTO 0);
    SIGNAL init_word : std_logic_vector(31 DOWNTO 0);
    SIGNAL i_we : std_logic_vector(DAQ_N_CAP_CTRLS DOWNTO 0);
    SIGNAL init_word_we, s_last : std_logic;
    
    SIGNAL ipbw_hist : ipb_wbus_array(DAQ_N_CAP_CTRLS - 1 DOWNTO 0);
    SIGNAL ipbr_hist : ipb_rbus_array(DAQ_N_CAP_CTRLS - 1 DOWNTO 0);
    
    SIGNAL ro_tok_d1, ro_tok_d2 : std_logic;
    SIGNAL rst_p_d1, rst_p_d0 : std_logic;

    -- Problems meeting timing in "trig_processor" in Vivado 15.2 
    -- Adding extra reg not viable without possibly chnaging DAQ 
    -- functionality and requiring additional testing.
    -- Use "max_fanout" instead.
    
    ATTRIBUTE max_fanout : integer;
    ATTRIBUTE max_fanout of rst_p_d0 : signal is 8;
    ATTRIBUTE max_fanout of rst_p_d1 : signal is 1;
    
BEGIN

    stat(0) <= x"0000000" & "00" & ctrs_fifo_empty & ctrs_fifo_full; -- temp_cnt
    stat(1) <= std_logic_vector(mode_evt_proc);   

    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
        	rst_p_d0 <= rst_p;
        	rst_p_d1 <= rst_p_d0;

            IF rst_p_d1 = '0' THEN
                event_size <= ctrl(0)(19 DOWNTO 0);
                event_type <= ctrl(1)(15 DOWNTO 0);
                trigger_event <= ctrl(0)(27 DOWNTO 20);
            ELSE 
                event_size <= (OTHERS => '0');
                event_type <= (OTHERS => '0');
                trigger_event <= (OTHERS => '0');  
            END IF;
            token_delay <= std_logic_vector(to_unsigned(70, token_delay'length)); --ctrl(0)(30 DOWNTO 24) WHEN rst_p_d1 = '0' ELSE (OTHERS => '0');
            
        END IF;
    END PROCESS;

    daq_ro <= '1' WHEN (cyc_state = ST_CYC) ELSE '0'; --or ro_state = ST_READ ELSE '0'; --- !!!!

    cap_ctrl_fabric: entity work.ipbus_fabric_sel
        generic map(
            NSLV => DAQ_N_CAP_CTRLS,
            SEL_WIDTH => 2
        )
        port map(
            ipb_in => ipbus_in,
            ipb_out => ipbus_out,
            sel => cap_ctrl_sel,
            ipb_to_slaves => ipbw,
            ipb_from_slaves => ipbr
        );
        
    hist_fabric: entity work.ipbus_fabric_sel
        generic map(
            NSLV => DAQ_N_CAP_CTRLS,
            SEL_WIDTH => 2
        )
        port map(
            ipb_in => ipbus_in_hist,
            ipb_out => ipbus_out_hist,
            sel => cap_ctrl_sel,
            ipb_to_slaves => ipbw_hist,
            ipb_from_slaves => ipbr_hist
        );

    PROCESS(ttc_clk)
    BEGIN
        IF rising_edge(ttc_clk) THEN
            IF resync = '1' THEN
                rst_ctr <= "000";
            ELSIF rst_i = '1' THEN
                rst_ctr <= rst_ctr + 1;
            END IF;
        END IF;
    END PROCESS;
    
    --rst_i <= '1' WHEN rst_ctr /= "111" ELSE '0';

    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_ctr /= "111" THEN
                rst_i <= '1';
            ELSE
                rst_i <= '0';
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                readme <= '0';
            ELSIF ctrs_fifo_full = '0' and ctrs_fifo_empty = '0' THEN
                readme <= '1';
            ELSE
                readme <= '0';
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                mode_evt_proc <= (OTHERS => '0');
            ELSE
                IF dbus_in.token = '1' and (s_last = '1' or state = ST_TMT) THEN -- s last and TMT????
                    mode_evt_proc <= mode_evt_proc + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' OR cyc_state /= ST_CYC THEN
                dbus_in <= DAQ_BUS_NULL;
                daq_bus_out <= daq_bus_in;
            ELSE
                dbus_in <= daq_bus_in;
                daq_bus_out <= dbus_out;
            END IF;
        END IF;
    END PROCESS;    
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            ro_tok_d2 <= ro_tok_d1;
            IF state = ST_DATA THEN
                ro_tok_d1 <= '1';
            ELSE
                ro_tok_d1 <= '0';
            END IF;           
        END IF;
    END PROCESS;
    
    ro_tok(0) <= ro_tok_d1 and not ro_tok_d2;
            
    
    WITH state SELECT dbus_out <= 
        dbus_hdr WHEN ST_HDR,
        dbus_data WHEN ST_DATA,
        dbus_tmt WHEN ST_TMT,
        DAQ_BUS_NULL WHEN OTHERS;
    
    
    PROCESS(clk_p)
    BEGIN    
        IF rising_edge(clk_p) THEN            
            IF rst_i = '1' THEN
                dbus_tmt <= DAQ_BUS_NULL;
            ELSIF state = ST_HDR AND (hdr_ctr = to_unsigned(DAQ_N_HDR_WORDS - 1, hdr_ctr'length)) THEN
                dbus_tmt.token <= '1';
            ELSE
                dbus_tmt <= DAQ_BUS_NULL;
            END IF;
        END IF;
    END PROCESS;
                
        
    i_wo(0) <= (OTHERS => '0');
    i_we(0) <= '0';
    init_word <= i_wo(DAQ_N_CAP_CTRLS);
    init_word_we <= i_we(DAQ_N_CAP_CTRLS);
           
    cap_gen : FOR i IN  0 TO (DAQ_N_CAP_CTRLS-1) GENERATE
    
        SIGNAL v_l1a : std_logic;

        SIGNAL ctrl_reg, stat_reg : ipb_reg_v(0 DOWNTO 0);
        SIGNAL trigger_mode_hist : std_logic_vector(6 downto 0);

    BEGIN
        trigger_mode_hist(0) <= '1' WHEN cyc_state = ST_IDLE ELSE '0';
        trigger_mode_hist(1) <= '1' WHEN cyc_state = ST_CYC ELSE '0';
        trigger_mode_hist(2) <= '1' WHEN state = ST_IDLE ELSE '0';
        trigger_mode_hist(3) <= '1' WHEN state = ST_TOK_DEL ELSE '0';
        trigger_mode_hist(4) <= '1' WHEN state = ST_HDR ELSE '0';
        trigger_mode_hist(5) <= '1' WHEN state = ST_DATA ELSE '0';
        trigger_mode_hist(6) <= ctrs_fifo_full;      
    
        ctrl : ENTITY work.ipbus_ctrlreg_v
        GENERIC MAP(
            N_CTRL => 1, 
            N_STAT => 1
            )
        PORT MAP(
            clk => clk, 
            reset => rst, 
            ipbus_in => ipbw(i), 
            ipbus_out => ipbr(i), 
            d => stat_reg, 
            q => ctrl_reg
        );
    
        cap_ctrl : ENTITY work.mp7_capture_control
        PORT MAP(
            clk => clk,
            rst => rst,
            ipbus_in => ipbw_hist(i),
            ipbus_out => ipbr_hist(i),
            trigger_mode_hist => trigger_mode_hist,
            bunch_ctr => bunch_ctr,
            evt_ctr => evt_ctr, 
            orb_ctr => orb_ctr, 
            clk_p => clk_p,            
            rst_p => rst_p_d1,
            resync => resync,
            bc0 => bc0,
            ttc_clk => ttc_clk,
            ro_tok_in => ro_tok(i), -- daisy chained readout token
            ro_tok_out => ro_tok(i + 1),
            ctrl => ctrl_reg,
            stat => stat_reg,
            l1a => v_l1a,
            actr => actr,
            capture => cap(i),
            fifo_full => cap_fifo_full(i),
            fifo_empty => cap_fifo_empty(i),
            init_word_in => i_wo(i), -- snakes around
            init_word_out => i_wo(i + 1),
            init_word_we_in => i_we(i), -- write enable block
            init_word_we_out => i_we(i + 1)
    );
    
    v_l1a <= s_l1a AND l1a_flag;
           
    END GENERATE;
    
    daq_ctrl : ENTITY work.mp7_daq_control
    PORT MAP(
        clk_p => clk_p, 
        rst_p => rst_p_d1,
        resync => resync,
        init => ro_tok(DAQ_N_CAP_CTRLS), 
        init_we => init_word_we, 
        init_word => init_word, 
        daq_bus_out => dbus_data,
        daq_bus_in => dbus_in,
        last => s_last
    ); 
    
    last <= '1' WHEN s_last = '1' OR state = ST_TMT ELSE '0';
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN    
            cap_bus <= or_array_reduce(cap);
        END IF;
    END PROCESS;
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            fifo_full <= or_reduce(cap_fifo_full) or ctrs_fifo_full;
            fifo_empty <= or_reduce(cap_fifo_empty) or ctrs_fifo_empty;
        END IF;
    END PROCESS;
    
    trig_processor : ENTITY work.mp7_readout_trigger_counter
    PORT MAP(
        clk => ttc_clk,
        rst => rst_i,
        ec0 => ec0,
        evt_ctr => evt_ctr,
        l1a_in => l1a,
        l1a_out => s_l1a,
        veto_in => veto_in,
        veto_out => veto_out,
        trigger_event => trigger_event
    );
    
    token_delay_ctrl : ENTITY work.bitshift_delay
    GENERIC MAP(
        MAX_DELAY => 127,
        DELAY_WIDTH => 7
        )
    PORT MAP(
        rst => rst_i, 
        clk => clk_p, 
        delay => token_delay, 
        d => token_d_in,
        q => token_del 
    );
    
    token_d_in <= s_l1a AND NOT s_l1a_d WHEN rising_edge(clk_p);
    
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            s_l1a_d <= s_l1a;
        END IF;
    END PROCESS;
    
    -- cap ctrl state machine for readout 
    
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                state <= ST_IDLE;
            ELSE
                CASE state IS
                    WHEN ST_IDLE => 
                        IF cyc_state = ST_CYC THEN
                            IF token_en = '1' THEN
                                state <= ST_HDR;
                            ELSE
                                state <= ST_TOK_DEL;
                            END IF;
                        END IF;
                    WHEN ST_TOK_DEL =>
                        IF token_en = '1' THEN
                            state <= ST_HDR;
                        END IF;
                    WHEN ST_HDR =>
                        IF hdr_ctr = to_unsigned(DAQ_N_HDR_WORDS - 1, hdr_ctr'length) THEN
                            IF ctrs_fifo_q(60) = '1' THEN
                                state <= ST_DATA;
                            ELSE                     
                                state <= ST_TMT;
                            END IF;
                        END IF;
                    WHEN ST_DATA =>
                        IF s_last = '1' AND dbus_in.token = '1' THEN
                            state <= ST_IDLE;
                        END IF;
                    WHEN ST_TMT =>
                        IF dbus_in.token = '1' THEN
                            state <= ST_IDLE;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                token_rec <= (OTHERS => '0');
            ELSE
                IF token_d_in = '1' AND token_del = '0' THEN 
                    token_rec <= token_rec + 1;
                ELSIF token_d_in = '0' AND token_del = '1' THEN
                    token_rec <= token_rec - 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                token_en <= '0';
            ELSE
                IF token_rec = 0 or unsigned(token_delay) = 0 THEN
                    token_en <= '1';
                ELSIF token_rec < evt_rec THEN
                    token_en <= '1';
                ELSE
                    token_en <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                evt_rec <= (others => '0');
            ELSE
                IF token_d_in = '1' AND ro_tok(DAQ_N_CAP_CTRLS) = '0'  THEN
                    evt_rec <= evt_rec + 1;
                ELSIF token_d_in = '0' AND ro_tok(DAQ_N_CAP_CTRLS) = '1' THEN
                    evt_rec <= evt_rec - 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF state = ST_HDR THEN
                hdr_ctr <= hdr_ctr + 1;
            ELSE
                hdr_ctr <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS;
    
    dbus_hdr.data.data <= hdr_word;
    dbus_hdr.data.strobe <= '1';
    dbus_hdr.data.start <= '1';
    dbus_hdr.data.valid <= '1';
    dbus_hdr.init <= '0';
    dbus_hdr.token <= '0';
    
	WITH hdr_ctr(2 DOWNTO 0) SELECT hdr_word <= -- header words for readout
        ctrs_fifo_q(11 DOWNTO 0) & s_event_size WHEN "000", 
        X"00" & ctrs_fifo_q(59 DOWNTO 36) WHEN "001", 
        ctrs_fifo_q(27 DOWNTO 12) & board_id WHEN "010", 
        X"0000" & event_type WHEN "011",
        X"00" & FW_REV WHEN "100",
        ALGO_REV WHEN "101",
        (OTHERS => '0') WHEN OTHERS;
        
    s_event_size <= event_size when ctrs_fifo_q(60) = '1' else std_logic_vector(to_unsigned(DAQ_N_HDR_WORDS - 2, event_size'length)); -- TMT event or not?
        
    ctrs_fifo_d <= "000" & l1a_flag & evt_ctr(23 downto 0) & orb_ctr(23 downto 0) & bunch_ctr;
    
    -- fifo for readout counters, contains info for readout header
    
    ctrs_fifo : FIFO36E1
    GENERIC MAP(
      DATA_WIDTH => 72, 
      FIFO_MODE => "FIFO36_72"
    )
    PORT MAP(
        di => ctrs_fifo_d, 
        dip => X"00", 
        do => ctrs_fifo_q, 
        empty => ctrs_fifo_empty, 
        full => ctrs_fifo_full, 
        injectdbiterr => '0', 
        injectsbiterr => '0', 
        rdclk => clk_p, 
        rden => fifo_ren, 
        regce => '1', 
        rst => rst_i, 
        rstreg => '0', 
        wrclk => ttc_clk, 
        wren => fifo_wen
    );
    
    -- state machine to check order of processed events
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                cyc_state <= ST_IDLE;
            ELSE
                CASE cyc_state IS
                WHEN ST_IDLE =>
                    IF readme = '1' THEN
                        cyc_state <= ST_PIPE;
                    END IF;
                WHEN ST_PIPE => -- wait for fifo_ren to drop
                    IF next_evt(23 DOWNTO 0) /= ctrs_fifo_q(59 DOWNTO 36) THEN
                        cyc_state <= ST_NEXT;
                    ELSE
                        cyc_state <= ST_CYC;
                    END IF;                       
                WHEN ST_NEXT =>
                    IF next_evt(23 DOWNTO 0) = ctrs_fifo_q(59 DOWNTO 36) THEN
                        cyc_state <= ST_CYC;
                    END IF;
                WHEN ST_CYC =>
                    IF (s_last = '1' OR state = ST_TMT) AND dbus_in.token = '1' THEN
                        cyc_state <= ST_IDLE;
                    END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
    
    fifo_wen <= s_l1a AND (NOT rst_i);  
    fifo_ren <= '1' WHEN readme = '1' AND (cyc_state = ST_IDLE) AND (rst_i = '0') ELSE '0';   
    
 
    
END rtl;
