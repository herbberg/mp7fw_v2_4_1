library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_misc.all;



entity serdes_tx_8b10b is
generic
(
    BYTE_WIDTH : integer;           
    CLK_PARALLEL_PERIOD: real);
port
(
    -- Serdes links
    txn_out: out  std_logic;
    txp_out: out  std_logic;
    
    -- Parallel Interface
    clk_in: in   std_logic;
    rst_in: in   std_logic;
    data_in: in std_logic_vector(8*BYTE_WIDTH-1 downto 0);
    charisk_in: in std_logic_vector(BYTE_WIDTH-1 downto 0)
);

end serdes_tx_8b10b;


architecture RTL of serdes_tx_8b10b is

	signal clk_serdes, toggle_par: std_logic := '0';
	signal enc, enc_reg: std_logic_vector((10*BYTE_WIDTH-1) downto 0);
  signal jdebug: natural;

	constant CLK_SERDES_HALFPERIOD: time := (CLK_PARALLEL_PERIOD / (real(BYTE_WIDTH) * 20.0)) * 1.0 ns;
	
begin

	--clk_serdes <= '1' when rising_edge(clk_in) else (not clk_serdes) after CLK_SERDES_HALFPERIOD;
	
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
	
		encoder: entity work.enc_8b10b 
		port map (
			RESET => rst_in,
			SBYTECLK => clk_in,
			KI => charisk_in(i),
			AI => data_in(8*i+0),
			BI => data_in(8*i+1),
			CI => data_in(8*i+2),
			DI => data_in(8*i+3),
			EI => data_in(8*i+4),
			FI => data_in(8*i+5),
			GI => data_in(8*i+6),
			HI => data_in(8*i+7),
			AO => enc(10*i+0),
			BO => enc(10*i+1),
			CO => enc(10*i+2),
			DO => enc(10*i+3),
			EO => enc(10*i+4),
			IO => enc(10*i+5),
			FO => enc(10*i+6),
			GO => enc(10*i+7),
			HO => enc(10*i+8),
			JO => enc(10*i+9)
		);
			
		end generate;

	toggle: process(clk_in)
	begin
		if rising_edge(clk_in) then
			toggle_par <= not toggle_par;
			enc_reg <= enc;   -- Must reg enc on rising edge (encoder output not registered)
		end if;
	end process;

	-- Be careful.  Don't want to hit some kind delta issue.
	serdes_tx: process(clk_serdes)
		variable j: natural;
		variable toggle_ser: std_logic_vector(1 downto 0);
	begin
		if rising_edge(clk_serdes) then
			toggle_ser := toggle_ser(0) & toggle_par;
			if (toggle_ser(0) xor toggle_ser(1)) = '1'  then 
				j := 0;
			-- Following if statement protects simulator against missing parallel clk
			elsif j < (BYTE_WIDTH * 10 - 1) then
				j := j+1;
			end if;
			jdebug <= j;
			txn_out <= not enc_reg(j);
			txp_out <= enc_reg(j);
		end if;
	end process;
	


end RTL;
