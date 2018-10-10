-- fletcher64
--
-- DSP-based implementation of Fletcher's checksum for 32b data
--
-- NB!
--  - Pipelining means that cksumb word will emerge one cycle later than cksuma
--  - The very last modulus operation is omitted to save latency, so this is not
--    strictly the 'book algorithm', and will give outputs including 0xffffffff; 0xffffffff.
--    However, it should still have all the required properties of the checksum.
--
-- Dave Newbold, August 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fletcher64 is
	port(
		clk: in std_logic;
		rst: in std_logic;
		clken: in std_logic;
		d: in std_logic_vector(31 downto 0);
		cksuma: out std_logic_vector(31 downto 0);
		cksumb: out std_logic_vector(31 downto 0)		
	);
	
end fletcher64;

architecture rtl of fletcher64 is

	signal clken_d, match_a, match_b: std_logic;
	signal casc, qa, qb: std_logic_vector(47 downto 0);

begin

	dspa: entity work.mod_adder_dsp
		port map(
			clk => clk,
			rst => rst,
			clken => clken,
			d(47 downto 32) => (others => '0'),
			d(31 downto 0) => d,
			cascin => (others => '0'),
			cascout => casc,
			q => qa,
			match => match_a,
			c => match_a,
			z => '0'
		);

	process(clk)
	begin
		if rising_edge(clk) then
			clken_d <= clken;
		end if;
	end process;
		
	dspb: entity work.mod_adder_dsp
		port map(
			clk => clk,
			rst => rst,
			clken => clken_d,
			d => (others => '0'),
			cascin => casc,
			q => qb,
			match => match_b,
			c => match_b,
			z => match_a
		);
		
	cksuma <= qa(31 downto 0);
	cksumb <= qb(31 downto 0);

end rtl;

