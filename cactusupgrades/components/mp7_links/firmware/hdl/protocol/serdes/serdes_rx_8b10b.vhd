library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_misc.all;



entity serdes_rx_8b10b is
generic
(
    BYTE_WIDTH : integer;           
    CLK_PARALLEL_PERIOD: real);
port
(
    -- Serdes links
    rxn_in: in  std_logic;
    rxp_in: in  std_logic;
    
    -- Parallel Interface
    clk_in: in   std_logic;
    rst_in: in   std_logic;
    data_out: out std_logic_vector(8*BYTE_WIDTH-1 downto 0);
    charisk_out: out std_logic_vector(BYTE_WIDTH-1 downto 0)
);

end serdes_rx_8b10b;


architecture RTL of serdes_rx_8b10b is

	signal clk_serdes, toggle_par: std_logic := '0';
	signal enc, serdes_shreg: std_logic_vector((10*BYTE_WIDTH-1) downto 0);
  signal jdebug: natural;
		
  signal data: std_logic_vector(8*BYTE_WIDTH-1 downto 0);
  signal charisk: std_logic_vector(BYTE_WIDTH-1 downto 0);
		
	constant CLK_SERDES_HALFPERIOD: time := (CLK_PARALLEL_PERIOD / (real(BYTE_WIDTH) * 20.0)) * 1.0 ns;
	
begin
	
	-- Try to lock serdes clk to parallel clk.
  clk_serdes_proc: process
  begin
    wait until clk_in'event and clk_in='1';
    clk_serdes <= '1';
    wait for CLK_SERDES_HALFPERIOD;
    for i in 1 to BYTE_WIDTH * 20 - 1 loop
      clk_serdes <= not clk_serdes;
      wait for CLK_SERDES_HALFPERIOD;
    end loop;
  end process;
	
	gen: for i in BYTE_WIDTH-1 downto 0 generate
	
	 -- Regs input data on falling edge
		decoder: entity work.dec_8b10b 
		port map (
			RESET => rst_in,
			RBYTECLK => clk_in,
			AI => enc(10*i+0),
			BI => enc(10*i+1),
			CI => enc(10*i+2),
			DI => enc(10*i+3),
			EI => enc(10*i+4),
			II => enc(10*i+5),
			FI => enc(10*i+6),
			GI => enc(10*i+7),
			HI => enc(10*i+8),
			JI => enc(10*i+9),
			AO => data(8*i+0),
			BO => data(8*i+1),
			CO => data(8*i+2),
			DO => data(8*i+3),
			EO => data(8*i+4),
			FO => data(8*i+5),
			GO => data(8*i+6),
			HO => data(8*i+7),
			KO => charisk(i)
		);
			
		end generate;


	-- Be careful.  Don't want to hit some kind delta issue.
	serdes_rx: process(clk_serdes)
		variable j: natural;
	begin
		if rising_edge(clk_serdes) then
			if (serdes_shreg(9 downto 0) = "0101111100") or (serdes_shreg(9 downto 0) = "1010000011") then
        -- Found comma
        j := 0;
			elsif j < (BYTE_WIDTH * 10 - 1) then
        j := j+1;
      else
        j := 0;
      end if;
      -- Reg shift reg 
      if  j = 0 then
        enc <= serdes_shreg;
      end if;
		  serdes_shreg <= rxp_in & serdes_shreg(BYTE_WIDTH * 10 - 1 downto 1);
		  jdebug <= j;
		end if;
	end process;
	
	-- Reclock data on rising edge
  output_rx: process(clk_in)
  begin
    if rising_edge(clk_in) then
      data_out <= data after 1 ps;
      charisk_out <= charisk after 1 ps;
    end if;
  end process;
  


end RTL;
