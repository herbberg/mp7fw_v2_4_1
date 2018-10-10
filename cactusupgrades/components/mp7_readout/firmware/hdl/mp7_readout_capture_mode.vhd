-- Processes L1As and captures data ready for daq readout
-- F. Ball - Feb 2015

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

USE work.ipbus_reg_types.ALL;

USE work.mp7_ttc_decl.ALL;
USE work.mp7_data_types.ALL;
USE work.top_decl.ALL;
USE work.mp7_readout_decl.ALL;

ENTITY mp7_readout_capture_mode IS
    GENERIC (
        BOARD_ID : std_logic_vector(15 DOWNTO 0)
    );
    PORT (
        clk_p : IN std_logic;
        rst_p : IN std_logic;
        rst_i : IN std_logic;
        ctrl : IN ipb_reg_v(1 DOWNTO 0);
        stat : OUT ipb_reg_v(1 DOWNTO 0);
        l1a : IN std_logic;
        ttc_clk : IN std_logic;
        daq_bus_in : IN daq_bus;
        daq_bus_out : OUT daq_bus;
        actr : IN dr_address_array;
        bunch_ctr : IN bctr_t;
        evt_ctr : IN eoctr_t;
        orb_ctr : IN eoctr_t;
        ec0 : IN std_logic;
        mode_ready : OUT std_logic; -- data read to be read out
        mode_enabled : OUT std_logic; -- to veto other modes
        mode_veto : IN std_logic; -- veto this mode
        daq_sel : IN std_logic; -- select this trigger mode to readout
        daq_busy : OUT std_logic; -- daq_ctrl ready to get data
        bank_enable : OUT std_logic_vector(DAQ_N_BANKS - 1 DOWNTO 0);
        fifo_full : OUT std_logic;
        fifo_empty : OUT std_logic
    );
END mp7_readout_capture_mode;

ARCHITECTURE rtl OF mp7_readout_capture_mode IS

    SIGNAL user_data : std_logic_vector(31 DOWNTO 0);

    SIGNAL s_fifo_full, s_fifo_empty, fifo_ren : std_logic;

    TYPE state_type IS (ST_IDLE, ST_ENABLE);
    SIGNAL trig_state : state_type;
    SIGNAL cap_state : state_type;

    TYPE readout_state_type IS (ST_IDLE, ST_ENABLE, ST_INIT, ST_DAQ, ST_END);
    SIGNAL read_state : readout_state_type;

    SIGNAL bank_sel : std_logic_vector(DAQ_BWIDTH DOWNTO 0);
    SIGNAL ptr : unsigned(DAQ_BWIDTH DOWNTO 0);

    SIGNAL bank_capture_mask : std_logic_vector(DAQ_N_BANKS - 1 DOWNTO 0);

    SIGNAL capture_size : std_logic_vector(7 DOWNTO 0);

    SIGNAL s_l1a, s_l1a_d, trig_mode_en, trig_always : std_logic;
    SIGNAL l1a_delay : std_logic_vector(3 DOWNTO 0);

    SIGNAL token_delay : std_logic_vector(15 DOWNTO 0);
    SIGNAL token_en, s_token_en : std_logic;
    SIGNAL number_token_en, stored_events : unsigned(15 DOWNTO 0);

    SIGNAL trigger_event : std_logic_vector(11 DOWNTO 0);
    SIGNAL trig_ctr : unsigned(evt_ctr'RANGE);
    SIGNAL dctr : unsigned(DR_ADDR_WIDTH - 1 DOWNTO 0);

    SIGNAL s_mode_ready : std_logic;

    SIGNAL init : std_logic;
    SIGNAL event_size : std_logic_vector(19 DOWNTO 0);
    SIGNAL init_word : std_logic_vector(31 DOWNTO 0);
    SIGNAL daq_word : std_logic_vector(63 DOWNTO 0);

    SIGNAL dbus_in, dbus_out : daq_bus;

    SIGNAL daq_sel_d : std_logic;
    SIGNAL s_evt_ctr : eoctr_t;

    SIGNAL l1a_in : std_logic;
    SIGNAL token_en_in : std_logic;

    SIGNAL mode_evt_ctr : unsigned(evt_ctr'RANGE);
    SIGNAL mode_evt_proc : unsigned(evt_ctr'RANGE);
BEGIN
    daq_bus_out <= dbus_out WHEN daq_sel = '1' ELSE daq_bus_in;
    dbus_in <= daq_bus_in WHEN daq_sel = '1' ELSE DAQ_BUS_NULL;
 
    daq_ctrl : ENTITY work.mp7_daq_control
        GENERIC MAP(
            BOARD_ID => BOARD_ID
        )
    PORT MAP(
        clk_p => clk_p, 
        rst => rst_i, 
        init => init, 
        init_word => init_word, 
        daq_word => daq_word, 
        daq_bus_out => dbus_out, 
        daq_bus_in => dbus_in, 
        token_en => token_en, 
        event_size => event_size, 
        user_data => user_data
    );
 
--user_data <= ctrl(1); -- capture_size
 
    l1a_delay_ctrl : ENTITY work.mp7_readout_l1a_delay
    PORT MAP(
        clk_p => clk_p, 
        rst => rst_i, 
        ttc_clk => ttc_clk, 
        l1a_delay => l1a_delay, 
        token_delay => token_delay, 
        l1a_in => l1a_in, 
        l1a_out => s_l1a, 
        evt_ctr_in => evt_ctr, 
        evt_ctr_out => s_evt_ctr, 
        token_en_in => token_en_in, 
        token_en_out => s_token_en
    );
 
    token_en_in <= s_l1a AND (NOT s_l1a_d);
    l1a_in <= l1a WHEN trig_state = ST_ENABLE AND mode_veto = '0' ELSE '0';
 
    PROCESS (ttc_clk)
    BEGIN
        IF rising_edge(ttc_clk) THEN
            IF rst_i = '1' OR ec0 = '1' THEN
                mode_evt_ctr <= to_unsigned(1, mode_evt_ctr'length);
            ELSIF l1a_in = '1' THEN
                mode_evt_ctr <= mode_evt_ctr + 1;
            END IF;
        END IF;
    END PROCESS;
 
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            s_l1a_d <= s_l1a;
        END IF;
    END PROCESS;
 
    fifo : ENTITY work.mp7_readout_mode_fifo
    PORT MAP(
        clk => clk_p, 
        rst => rst_i, 
        l1a => s_l1a, 
        bank_sel => bank_sel, 
        init_word => init_word, 
        daq_word => daq_word, 
        actr => actr, 
        capture_size => capture_size, 
        bunch_ctr => bunch_ctr, 
        evt_ctr => s_evt_ctr, 
        orb_ctr => orb_ctr, 
        fifo_ren => fifo_ren, 
        fifo_empty => s_fifo_empty, 
        fifo_full => s_fifo_full
    );
 
    fifo_full <= s_fifo_full;
    fifo_empty <= s_fifo_empty;
 
    fifo_ren <= '1' WHEN daq_sel = '1' AND daq_sel_d = '0' AND s_mode_ready = '1' AND rst_i = '0' ELSE '0';
 
--trigger processor
 
    PROCESS (ttc_clk)
    BEGIN
        IF rising_edge(ttc_clk) THEN
            IF unsigned(trigger_event) = 0 THEN
                trig_mode_en <= '0';
            ELSE
                trig_mode_en <= '1';
            END IF;
            IF unsigned(trigger_event) = 1 THEN
                trig_always <= '1';
            END IF;
        END IF;
    END PROCESS;
 
    PROCESS (ttc_clk)
    BEGIN
        IF rising_edge(ttc_clk) THEN
            IF rst_i = '1' OR trig_ctr = (unsigned(trigger_event)) OR (ec0 = '1') OR unsigned(evt_ctr) = 1 THEN
                trig_ctr <= (OTHERS => '0');
            ELSIF l1a = '1' THEN
                trig_ctr <= trig_ctr + 1;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (ttc_clk)
    BEGIN
        IF rising_edge(ttc_clk) THEN
            IF rst_i = '1' THEN
                trig_state <= ST_IDLE;
            ELSIF trig_mode_en <= '0' THEN
                trig_state <= ST_IDLE;
            ELSIF trig_always = '1' THEN -- trigger mode always on
                trig_state <= ST_ENABLE; 
            ELSE
                CASE trig_state IS
                    WHEN ST_IDLE => 
                        IF trig_ctr = (unsigned(trigger_event) - 2) THEN 
                            trig_state <= ST_ENABLE; 
                        ELSIF unsigned(evt_ctr) = 1 AND l1a = '0' THEN
                            trig_state <= ST_ENABLE; 
                        END IF;
                    WHEN ST_ENABLE => 
                        IF l1a = '1' THEN
                            trig_state <= ST_IDLE;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
 
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                number_token_en <= (OTHERS => '0'); 
            ELSIF s_token_en = '1' AND s_l1a = '1' AND s_l1a_d = '0' THEN
                number_token_en <= number_token_en;
            ELSIF s_token_en = '1' THEN
                number_token_en <= number_token_en - 1;
            ELSIF s_l1a = '1' AND s_l1a_d = '0' THEN
                number_token_en <= number_token_en + 1;
            END IF;
        END IF;
    END PROCESS;
     
    token_en <= '1' WHEN ((number_token_en < stored_events) OR unsigned(token_delay) = 0 OR number_token_en = 0) AND rst_i = '0' ELSE '0';
     
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                stored_events <= (OTHERS => '0');
            ELSE
                IF s_l1a = '1' AND s_l1a_d = '0' AND ptr = 0 AND read_state = ST_ENABLE THEN
                    stored_events <= stored_events;
                ELSIF s_l1a = '1' AND s_l1a_d = '0' THEN
                    stored_events <= stored_events + 1;
                ELSIF ptr = 0 AND read_state = ST_ENABLE THEN
                    stored_events <= stored_events - 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
     
    mode_enabled <= '1' WHEN trig_state = ST_ENABLE AND rst_i = '0' ELSE '0';
    s_mode_ready <= '1' WHEN s_fifo_empty = '0' AND s_fifo_full = '0' AND rst_i = '0' ELSE '0';
    mode_ready <= s_mode_ready;
     
    --capture processor
     
    PROCESS (ttc_clk)
    BEGIN
        IF rising_edge(ttc_clk) THEN
            IF rst_i = '1' THEN
                cap_state <= ST_IDLE;
                bank_enable <= (OTHERS => '0');
                dctr <= (OTHERS => '0');
            ELSE
                CASE cap_state IS
                    WHEN ST_IDLE => 
                        bank_enable <= (OTHERS => '0');
                        dctr <= (OTHERS => '0');
                        IF s_l1a = '1' THEN
                            dctr <= dctr + 1;
                            cap_state <= ST_ENABLE;
                        END IF;
                    WHEN ST_ENABLE => 
                        bank_enable <= bank_capture_mask;
                        IF s_l1a = '1' THEN
                            dctr <= (OTHERS => '0');
                        ELSIF dctr = unsigned(capture_size) THEN
                            cap_state <= ST_IDLE;
                        ELSE
                            dctr <= dctr + 1;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
     
    -- bank select state machine
     
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                daq_sel_d <= '0';
            ELSE
                daq_sel_d <= daq_sel;
            END IF;
        END IF;
    END PROCESS;
     
    daq_busy <= '0' WHEN read_state = ST_IDLE ELSE '1';
     
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' OR read_state = ST_IDLE THEN
                ptr <= (OTHERS => '0');
            ELSE
                IF read_state = ST_ENABLE AND ptr < DAQ_N_BANKS THEN
                    ptr <= ptr + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
     
    -- will read out banks back to back
     
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                read_state <= ST_IDLE;
            ELSE
                CASE read_state IS
                    WHEN ST_IDLE => 
                        IF daq_sel = '1' AND daq_sel_d = '0' THEN
                            read_state <= ST_ENABLE;
                        END IF;
                    WHEN ST_ENABLE => 
                        IF ptr = DAQ_N_BANKS THEN
                            read_state <= ST_IDLE;
                        ELSIF bank_capture_mask(to_integer(ptr)) = '1' THEN
                            init <= '1';
                            read_state <= ST_INIT;
                            bank_sel <= std_logic_vector(ptr);
                        END IF;
                    WHEN ST_INIT => 
                        init <= '0';
                        read_state <= ST_DAQ;
                    WHEN ST_DAQ => 
                        IF daq_bus_in.token = '1' THEN
                            read_state <= ST_END;
                        END IF;
                    WHEN ST_END => 
                        IF daq_bus_in.data.strobe = '0' THEN -- stops weird things happening the the chain if you flick off too early
                            IF ptr = DAQ_N_BANKS THEN
                                read_state <= ST_IDLE;
                            ELSE
                                read_state <= ST_ENABLE;
                            END IF; 
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
     
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' OR ec0 = '1' THEN
                mode_evt_proc <= (OTHERS => '0');
            ELSIF daq_sel = '1' AND daq_sel_d = '0' THEN
                mode_evt_proc <= mode_evt_proc + 1;
            END IF;
        END IF;
    END PROCESS;
     
    l1a_delay <= ctrl(0)(3 DOWNTO 0) WHEN rst_p = '0' ELSE (OTHERS => '0');
    capture_size <= ctrl(0)(11 DOWNTO 4) WHEN rst_p = '0' ELSE (OTHERS => '0');
    bank_capture_mask <= ctrl(0)(DAQ_N_BANKS + 11 DOWNTO 12) WHEN rst_p = '0' ELSE (OTHERS => '0');
    token_delay <= ctrl(0)(31 DOWNTO 16) WHEN rst_p = '0' ELSE (OTHERS => '0');
     
    event_size <= ctrl(1)(19 DOWNTO 0) WHEN rst_p = '0' ELSE (OTHERS => '0');
    trigger_event <= ctrl(1)(31 DOWNTO 20) WHEN rst_p = '0' ELSE (OTHERS => '0');
     
    stat(0)(mode_evt_ctr'LENGTH - 1 DOWNTO 0) <= std_logic_vector(mode_evt_ctr);
    stat(1)(mode_evt_proc'LENGTH - 1 DOWNTO 0) <= std_logic_vector(mode_evt_proc); 
    
END rtl;