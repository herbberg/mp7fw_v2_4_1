-- Handles each captures and readouts per bank
-- F. Ball - Feb 2015

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

library unisim;
use unisim.VComponents.all;

USE work.ipbus_reg_types.ALL;

USE work.mp7_ttc_decl.ALL;
USE work.mp7_data_types.ALL;
USE work.top_decl.ALL;
USE work.mp7_readout_decl.ALL;


use work.ipbus.all;

ENTITY mp7_capture_control IS
    PORT (
        clk : IN std_logic;
        rst : IN std_logic;
        ipbus_in : IN ipb_wbus;
        ipbus_out : OUT ipb_rbus;
        trigger_mode_hist : IN std_logic_vector(6 downto 0);
        bunch_ctr : IN bctr_t;
        evt_ctr : IN eoctr_t;
        orb_ctr : IN eoctr_t;
        clk_p : IN std_logic;
        rst_p : IN std_logic;
        resync : IN std_logic;
        bc0 : IN std_logic;
        ttc_clk : IN std_logic;
        ro_tok_in : IN std_logic;
        ro_tok_out : OUT std_logic;
        ctrl : IN ipb_reg_v(0 DOWNTO 0);
        stat : OUT ipb_reg_v(0 DOWNTO 0);
        l1a : IN std_logic;
        capture : OUT daq_cap_bus := (OTHERS => '0');
        actr : IN dr_address_array;
        fifo_full : OUT std_logic;
        fifo_empty : OUT std_logic;
        init_word_in : IN std_logic_vector(31 DOWNTO 0);
        init_word_out : OUT std_logic_vector(31 DOWNTO 0);
        init_word_we_in : IN std_logic;
        init_word_we_out : OUT std_logic
    );
END mp7_capture_control;

ARCHITECTURE rtl OF mp7_capture_control IS
    
    SIGNAL rst_i : std_logic;
    SIGNAL rst_ctr : unsigned(2 DOWNTO 0);
    TYPE ro_state_type IS (ST_IDLE, ST_INIT, ST_SEND, ST_PASS, ST_PREP);
    SIGNAL ro_state : ro_state_type;
    TYPE cap_state_type IS (ST_IDLE, ST_CAP);
    SIGNAL cap_state : cap_state_type;    
    SIGNAL bank_id : std_logic_vector(DAQ_BWIDTH-1 DOWNTO 0);
    SIGNAL s_fifo_full, s_fifo_empty, init, fifo_wen, fifo_ren, capture_mode_en, rtok : std_logic;          
    SIGNAL init_word, actr_d, actr_q : std_logic_vector(31 DOWNTO 0);
    SIGNAL s_l1a, s_l1a_d, s_l1a_p, s_l1a_reg : std_logic;  
    SIGNAL capture_size, capture_delay, cap_id : std_logic_vector(3 DOWNTO 0);
    SIGNAL dctr : unsigned(capture_size'length - 1 DOWNTO 0);
    SIGNAL readout_length : std_logic_vector(7 DOWNTO 0);
    SIGNAL bank_sel : integer := 0;   
    -- History buffer signals
    SIGNAL hist_state: std_logic_vector(15 downto 0);
    SIGNAL hist_strobe : std_logic; 
    SIGNAL cap_mode_hist : std_logic_vector(4 DOWNTO 0);
    SIGNAL cyc_ctr : unsigned(2 downto 0);
    SIGNAL cyc : std_logic_vector(2 downto 0);
    
    SIGNAL s_bunch_ctr : bctr_t;
    SIGNAL s_evt_ctr : eoctr_t;
    SIGNAL s_orb_ctr : eoctr_t; 
    SIGNAL s_hist_state : std_logic_vector(15 downto 0);
    SIGNAL s_cyc : std_logic_vector(2 downto 0);  
        
BEGIN          

    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF resync = '1' THEN
                rst_ctr <= "000";
            ELSIF rst_i = '1' THEN
                rst_ctr <= rst_ctr + 1;
            END IF;
        END IF;
    END PROCESS;
    
    rst_i <= '1' WHEN rst_ctr /= "111" ELSE '0';
    
--    init_word_out <= init_word WHEN ro_state = ST_SEND ELSE init_word_in;
--    init_word_we_out <= '1' WHEN ro_state = ST_SEND ELSE init_word_we_in;
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF ro_state = ST_SEND THEN
                init_word_out <= init_word;
                init_word_we_out <= '1';
            ELSE
                init_word_out <= init_word_in;
                init_word_we_out <= init_word_we_in;
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            rtok <= ro_tok_in;
        END IF;
    END PROCESS;  
            
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                ro_tok_out <= '0';
            ELSE
                IF ro_state = ST_INIT THEN
                    ro_tok_out <= '1';
                ELSIF ro_state = ST_PASS THEN
                    ro_tok_out <= rtok;
                ELSE
                    ro_tok_out <= '0';
                END IF;
            END IF;
        END IF;
    END PROCESS;   
    
    init <= fifo_ren ;    
    
    -- state machine for readout init word
                               
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst_i = '1' THEN
                ro_state <= ST_IDLE;
            ELSE
                CASE ro_state IS
                
                    WHEN ST_IDLE =>
                        IF capture_mode_en = '0' THEN
                            ro_state <= ST_PASS;
                        ELSIF rtok = '1' THEN
                            ro_state <= ST_PREP;
                        END IF;
                        
                    WHEN ST_PREP => -- pipeling to allow init to be readout of of FIFO (Do I need now?)
                        ro_state <= ST_INIT;
                        
                    WHEN ST_INIT =>
                        ro_state <= ST_SEND; -- drop down the init word
                        
                    WHEN ST_SEND =>
                        ro_state <= ST_IDLE;
                        
                    WHEN ST_PASS =>
                        IF capture_mode_en = '1' THEN
                            ro_state <= ST_IDLE;
                        END IF;                  
                END CASE;
            END IF;
        END IF;
    END PROCESS;                    
    
    -- shift l1a with resepct to the other captures
    
    l1a_delay_ctrl : ENTITY work.bitshift_delay
    GENERIC MAP(
        MAX_DELAY => 15,
        DELAY_WIDTH => 4
        )
    PORT MAP(
        rst => rst_i, 
        clk => ttc_clk, 
        delay => capture_delay, 
        d => l1a,
        q => s_l1a 
    );                 
    
     s_l1a_p <= s_l1a_reg AND NOT s_l1a_d;    
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            s_l1a_d <= s_l1a_reg;
        END IF;
    END PROCESS;
    
    PROCESS(ttc_clk)
    BEGIN
        IF rising_edge(ttc_clk) THEN
            s_l1a_reg <= s_l1a ;
        END IF;
    END PROCESS; 
    
    -- state machine for captures
    
    bank_sel <= to_integer(unsigned(bank_id)) WHEN rising_edge(clk_p);
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF cap_state = ST_CAP THEN
                capture(bank_sel) <= '1';
            ELSE
                capture <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS;
         
    PROCESS (ttc_clk)
    BEGIN
       IF rising_edge(ttc_clk) THEN
           IF rst_i = '1' THEN
               cap_state <= ST_IDLE;
               dctr <= (OTHERS => '0');
           ELSE
               CASE cap_state IS
                   WHEN ST_IDLE => 
                       dctr <= (OTHERS => '0');
                       IF s_l1a = '1' and capture_mode_en = '1' THEN
                           dctr <= dctr + 1;
                           cap_state <= ST_CAP;
                       END IF;
                   WHEN ST_CAP => 
                       IF s_l1a = '1' THEN
                           dctr <= (OTHERS => '0'); -- reset counter for overlapping captures
                       ELSIF dctr = unsigned(capture_size) THEN
                           cap_state <= ST_IDLE;
                       ELSE
                           dctr <= dctr + 1;
                       END IF;
               END CASE;
           END IF;
       END IF;
    END PROCESS;

    fifo_ren <= '1' WHEN ro_state = ST_INIT ELSE '0';

    fifo_wen <= s_l1a_p AND (NOT rst_i) AND capture_mode_en;
    
    -- FIFO for derand address a bank
    
    -- FIFO for derand address of each bank
      
    actr_d <= X"00000" & "000" & actr(bank_sel);

    addr_fifo : FIFO18E1
    GENERIC MAP(
        DATA_WIDTH => 18
    )
    PORT MAP(
        di => actr_d, 
        dip => X"0", 
        do => actr_q, 
        empty => s_fifo_empty, 
        full => s_fifo_full,
        rdclk => clk_p, 
        rden => fifo_ren, 
        regce => '1', 
        rst => rst_i, 
        rstreg => '0', 
        wrclk => clk_p, 
        wren => fifo_wen
    );
    
    fifo_full <= s_fifo_full;
    fifo_empty <= s_fifo_empty;   
    
    init_word(31 DOWNTO 28) <= "00" & bank_id;
    init_word(27 DOWNTO 26) <= "00";
    init_word(25 DOWNTO 22) <= cap_id;
    init_word(21) <= '0';
    init_word(DR_ADDR_WIDTH + 11 DOWNTO 12) <= actr_q(DR_ADDR_WIDTH-1 DOWNTO 0);
    init_word(11 DOWNTO 8) <= X"0";
    init_word(7 DOWNTO 0) <= readout_length;    
    
    bank_id <= ctrl(0)(DAQ_BWIDTH - 1 DOWNTO 0) WHEN rst_i = '0' ELSE (OTHERS => '0');
    capture_mode_en <= ctrl(0)(3) WHEN rst_i = '0' ELSE '0';
    capture_delay <= ctrl(0)(7 DOWNTO 4) WHEN rst_i = '0' ELSE (OTHERS => '0');
    capture_size <= ctrl(0)(11 DOWNTO 8) WHEN rst_i = '0' ELSE (OTHERS => '0');
    cap_id <= ctrl(0)(15  DOWNTO 12);
    readout_length <= ctrl(0)(23 DOWNTO 16);
   
    stat(0) <= X"0000000" & "00" & s_fifo_empty & s_fifo_full;
    
    
    
    
    
     -----------------------HIST BUFFER----------------------------
        
        cap_mode_hist(0) <= '1' WHEN ro_state = ST_IDLE ELSE '0';
        cap_mode_hist(1) <= '1' WHEN ro_state = ST_INIT ELSE '0';
        cap_mode_hist(2) <= '0';--'1' WHEN ro_state = ST_READ ELSE '0';
        cap_mode_hist(3) <= '1' WHEN ro_state = ST_PREP ELSE '0';
        cap_mode_hist(4) <= '1' WHEN cap_state = ST_CAP ELSE '0';
        
        process(clk_p)
        begin
            if rising_edge(clk_p) then
                hist_state <= "0000" & trigger_mode_hist & cap_mode_hist;
                s_hist_state <= hist_state;
            end if;
        end process;
        
        process(ttc_clk)
        begin
            if rising_edge(ttc_clk) then
                s_bunch_ctr <= bunch_ctr;
                s_orb_ctr <= orb_ctr;
                s_evt_ctr <= evt_ctr;
                s_cyc <= cyc;
            end if;
        end process;
        
        process(clk_p)
            constant max : integer := 5;
        begin
            if rising_edge(clk_p) then
                if rst_i = '1' or cyc_ctr = max then
                    cyc_ctr <= (others => '0');
                elsif bc0 = '1' then
                    cyc_ctr <= "001";          
                else
                    cyc_ctr <= cyc_ctr + 1;
                end if;
            end if;
        end process;
        
        cyc <= std_logic_vector(cyc_ctr);    
        
        hist: entity work.state_history
            port map(
                clk => clk,
                rst => rst,
                ipb_in => ipbus_in,
                ipb_out => ipbus_out,
                ttc_clk => clk_p,
                ttc_rst => rst_p,
                ttc_bx => s_bunch_ctr,
                ttc_orb => s_orb_ctr,
                ttc_evt => s_evt_ctr,
                ttc_cyc => s_cyc,
                state => s_hist_state
            );
            
     
END rtl;