LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

LIBRARY unisim;
USE unisim.VComponents.ALL;

USE work.mp7_readout_decl.ALL;

USE work.mp7_ttc_decl.ALL;
USE work.top_decl.ALL;

ENTITY mp7_daq_control IS
	PORT (
		clk_p : IN std_logic;
		rst_p : IN std_logic;
		resync : IN std_logic;
		init : IN std_logic;
		init_we : IN std_logic;
		init_word : IN std_logic_vector(31 DOWNTO 0);
		daq_bus_out : OUT daq_bus;
		daq_bus_in : IN daq_bus;
		last : OUT std_logic
	);
END mp7_daq_control;

ARCHITECTURE rtl OF mp7_daq_control IS
    
    SIGNAL rst_i : std_logic;
    SIGNAL rst_ctr : unsigned(2 DOWNTO 0);
    SIGNAL daq_rst, s_last, cycle : std_logic;
	TYPE state_stype IS (ST_IDLE, ST_PIPE, ST_READ_FIFO, ST_BANK_MUX, ST_INIT, ST_TOKEN, ST_DATA);
	SIGNAL state : state_stype;
	SIGNAL fifo_full, fifo_empty, fifo_ren : std_logic;
	SIGNAL init_word_q : std_logic_vector(31 DOWNTO 0);
	SIGNAL bank_sel : std_logic_vector(DAQ_N_BANKS - 1 DOWNTO 0);
	SIGNAL sel : integer RANGE 0 TO DAQ_N_BANKS-1 ;
	SIGNAL cnt : unsigned(3 DOWNTO 0);
	
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
    
    daq_rst <= rst_i when rising_edge(clk_p);
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF daq_rst = '1' THEN
                cnt <= (OTHERS => '0');
            ELSE
                IF init_we = '1' AND fifo_ren = '0' THEN
                    cnt <= cnt + 1;
                ELSIF init_we = '0' AND fifo_ren = '1' THEN
                    cnt <= cnt - 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
	PROCESS (clk_p)
	BEGIN
		IF rising_edge(clk_p) THEN
			IF daq_rst = '1' THEN
				state <= ST_IDLE;
			ELSE
				CASE state IS
					WHEN ST_IDLE => 
				        IF init = '1' THEN
				            state <= ST_PIPE; -- whilst any FIFOs are being read
				        ELSIF cycle = '1' THEN
				            state <= ST_INIT;
				        END IF;
				    WHEN ST_PIPE =>
				        state <= ST_READ_FIFO;
				              
				    WHEN ST_READ_FIFO => -- pipelining	-- no idea why this is needed for a FIFO18 over a FIFO36			    
				        state <= ST_BANK_MUX;
				        
				    WHEN ST_BANK_MUX =>
                        IF bank_sel(sel) = '0' THEN -- is this bank already being sent down?
                            state <= ST_INIT;
                        ELSE
                            state <= ST_TOKEN;
                        END IF;
				    
				    WHEN ST_INIT =>
				        IF cnt = 0 THEN
				            state <= ST_TOKEN;
				        ELSE
				            state <= ST_PIPE;
				        END IF;
                        
				    WHEN ST_TOKEN =>
				            state <= ST_DATA;
					WHEN ST_DATA => 
						IF daq_bus_in.token = '1' THEN -- once token comes back
				            state <= ST_IDLE;
						END IF;
				END CASE;
			END IF;
		END IF;
	END PROCESS;
	
	PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF daq_rst = '1' OR state = ST_DATA THEN
                bank_sel <= (OTHERS => '0');
            ELSIF state = ST_IDLE AND cycle = '1' THEN -- catch previously rejected init word
                bank_sel(sel) <= '1';
            ELSIF state = ST_BANK_MUX THEN
                bank_sel(sel) <= '1'; 
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS(clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF daq_rst = '1' OR state = ST_IDLE THEN
                cycle <= '0';
            ELSIF state = ST_BANK_MUX THEN
                IF bank_sel(sel) = '1' THEN
                    cycle <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
--    fifo : FIFO36E1
--    GENERIC MAP(
--      DATA_WIDTH => 36
----      FIFO_MODE => "FIFO36_72"
--    )
--    PORT MAP(
--        di => init_word, 
--        dip => X"00", 
--        do => init_word_q, 
--        empty => fifo_empty, 
--        full => fifo_full, 
--        injectdbiterr => '0', 
--        injectsbiterr => '0', 
--        rdclk => clk_p, 
--        rden => fifo_ren, 
--        regce => '1', 
--        rst => rst_i, 
--        rstreg => '0', 
--        wrclk => clk_p, 
--        wren => init_we
--    );

    --TODO, understand why below FIFO needs so many pipes and above one doesn't
	
    daq_fifo : FIFO18E1 -- is a proper FIFO overkill?  -- TO DO - this FIFO isn't fast enough?
    GENERIC MAP(
        DATA_WIDTH => 36,
        FIFO_MODE => "FIFO18_36"
    )
    PORT MAP(
        di => init_word, 
        dip => X"0", 
        do => init_word_q, 
        empty => fifo_empty, 
        full => fifo_full,
        rdclk => clk_p, 
        rden => fifo_ren, 
        regce => '1', 
        rst => daq_rst, 
        rstreg => '0', 
        wrclk => clk_p, 
        wren => init_we
    );
    
    sel <= to_integer(unsigned(init_word_q(31 DOWNTO 28)));                 
    
    fifo_ren <= '1' WHEN (state = ST_READ_FIFO) ELSE '0';
            
    s_last <= '1' WHEN state = ST_DATA AND cycle = '0' ELSE '0';
    last <= s_last;
 
	daq_bus_out.data.valid <= '1' WHEN state = ST_DATA ELSE '0'; -- AMC13 doesn't care - debugging purposes only
	daq_bus_out.data.strobe <= '0';
	daq_bus_out.data.data <= init_word_q WHEN state = ST_INIT ELSE (OTHERS => '0');
 
	daq_bus_out.init <= '1' WHEN state = ST_INIT ELSE '0';
	daq_bus_out.token <= '1' WHEN state = ST_TOKEN ELSE '0';
	
	daq_bus_out.data.start <= '0';
	
END rtl;