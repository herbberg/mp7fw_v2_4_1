LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

LIBRARY unisim;
USE unisim.VComponents.ALL;

USE work.mp7_readout_decl.ALL;
USE work.mp7_ttc_decl.ALL;

USE work.top_decl.ALL;

ENTITY mp7_readout_mode_fifo IS
  PORT (
    clk : IN std_logic;
    rst : IN std_logic;
    l1a : IN std_logic;
    bank_sel : IN std_logic_vector(DAQ_BWIDTH DOWNTO 0);
    init_word : OUT std_logic_vector(31 DOWNTO 0);
    daq_word : OUT std_logic_vector(63 DOWNTO 0);
    actr : IN dr_address_array;
    capture_size : IN std_logic_vector(7 DOWNTO 0);
    bunch_ctr : IN bctr_t;
    evt_ctr : IN eoctr_t;
    orb_ctr : IN eoctr_t;
    fifo_ren : IN std_logic;
    fifo_empty : OUT std_logic;
    fifo_full : OUT std_logic
  );

END mp7_readout_mode_fifo;

ARCHITECTURE rtl OF mp7_readout_mode_fifo IS

    SIGNAL ctrs_fifo_d : std_logic_vector(63 DOWNTO 0);

    SIGNAL l1a_d, fifo_wen : std_logic;
    SIGNAL s_fifo_full, s_fifo_empty : std_logic_vector(1 DOWNTO 0);
    SIGNAL addr_fifo_empty, addr_fifo_full : std_logic_vector(DAQ_N_BANKS - 1 DOWNTO 0);
 
    TYPE addr_fifo_array IS ARRAY (DAQ_N_BANKS - 1 DOWNTO 0 ) OF std_logic_vector(63 DOWNTO 0);
    SIGNAL addr_fifo_q : addr_fifo_array;
     
    SIGNAL ctrs_fifo_q : std_logic_vector(63 DOWNTO 0);
     
    SIGNAL s_fill : std_logic_vector(63 DOWNTO (40 + DAQ_BWIDTH)) := (OTHERS => '0');
 
    SIGNAL b_sel : INTEGER := 0;
    
    SIGNAL s_lactr : unsigned(15 DOWNTO 0);
    SIGNAL lactr : std_logic_vector(7 DOWNTO 0);
BEGIN
        PROCESS (clk)
        BEGIN
            IF rising_edge(clk) THEN
                l1a_d <= l1a;
            END IF;
        END PROCESS;
    
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF unsigned(capture_size) > 0 THEN
                s_lactr <= (CLOCK_RATIO * unsigned(capture_size));
            ELSE
                s_lactr <= (OTHERS => '0');
            END IF;
                lactr <= std_logic_vector(s_lactr(7 DOWNTO 0));
        END IF;
    END PROCESS;
    
    b_sel <= 0 WHEN unsigned(bank_sel) < 1 OR rst = '1' ELSE to_integer(unsigned(bank_sel));
    
    fifo_full <= '0' WHEN s_fifo_full = "00" ELSE '1';
    fifo_empty <= '0' WHEN s_fifo_empty = "00" ELSE '1';
    
    fifo_wen <= l1a AND (NOT rst) AND (NOT l1a_d);
    
    init_word <= addr_fifo_q(b_sel)(42 DOWNTO 23) & X"0" & addr_fifo_q(b_sel)(7 DOWNTO 0);
    
    fifo_gen : FOR n IN 0 TO (DAQ_N_BANKS - 1) GENERATE
    
        CONSTANT bank_id : INTEGER := n;
        SIGNAL addr_fifo_d : std_logic_vector(63 DOWNTO 0);
    
        BEGIN
            addr_fifo_d <= s_fill & std_logic_vector(to_unsigned(bank_id, bank_sel'length)) & X"0" & "000"
                                & std_logic_vector(actr(n)) & X"000" & "000" & lactr;
    
            addr_fifo : FIFO36E1 -- halve the fifo - too big
            GENERIC MAP(
                DATA_WIDTH => 72, 
                FIFO_MODE => "FIFO36_72"
            )
            PORT MAP(
                di => addr_fifo_d, 
                dip => X"00", 
                do => addr_fifo_q(n), 
                empty => addr_fifo_empty(n), 
                full => addr_fifo_full(n), 
                injectdbiterr => '0', 
                injectsbiterr => '0', 
                rdclk => clk, 
                rden => fifo_ren, 
                regce => '1', 
                rst => rst, 
                rstreg => '0', 
                wrclk => clk, 
                wren => fifo_wen
          );

    END GENERATE;

    s_fifo_empty(0) <= or_reduce(addr_fifo_empty);
    s_fifo_full(0) <= or_reduce(addr_fifo_full);

    ctrs_fifo_d <= "0000" & evt_ctr(23 downto 0) & orb_ctr(23 downto 0) & bunch_ctr;

    ctrs_fifo : FIFO36E1
    GENERIC MAP(
      DATA_WIDTH => 72, 
      FIFO_MODE => "FIFO36_72"
    )
    PORT MAP(
        di => ctrs_fifo_d, 
        dip => X"00", 
        do => daq_word, 
        empty => s_fifo_empty(1), 
        full => s_fifo_full(1), 
        injectdbiterr => '0', 
        injectsbiterr => '0', 
        rdclk => clk, 
        rden => fifo_ren, 
        regce => '1', 
        rst => rst, 
        rstreg => '0', 
        wrclk => clk, 
        wren => fifo_wen
    );

  END rtl;