-- mod_adder_dsp
--
-- Wrapper for DSP, bringing out only required signals for implementation
-- of accumulator with modulus 2^32 - 1
--
-- Dave Newbold, August 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library unisim;
use unisim.VComponents.all;

entity mod_adder_dsp is
	port(
		clk: in std_logic;
		rst: in std_logic;
		clken: in std_logic;
		d: in std_logic_vector(47 downto 0); -- direct data input
		cascin: in std_logic_vector(47 downto 0); -- cascade data input from another DSP
		cascout: out std_logic_vector(47 downto 0); -- cascade data output to another DSP
		q: out std_logic_vector(47 downto 0); -- direct data output
		match: out std_logic; -- X"FFFFFFFF" detected at output
		c: in std_logic; -- carry input
		z: in std_logic -- force-zero input
	);
	
end mod_adder_dsp;

architecture rtl of mod_adder_dsp is

	signal opmode: std_logic_vector(6 downto 0);

begin

	dsp: DSP48E1
		generic map(
			ALUMODEREG => 0,
			CARRYINREG => 0,
			CARRYINSELREG => 0,
			CREG => 0,
			INMODEREG => 0,
			MASK => X"FFFF00000000",
			OPMODEREG => 0,
			PATTERN => X"0000FFFFFFFF",
			USE_MULT => "NONE",
			USE_PATTERN_DETECT => "PATDET"
		)
		port map(
			A => (others => '1'),
			ACIN => (others => '0'),
			ALUMODE => "0000",
			B => (others => '1'),
			BCIN => (others => '0'),
			C => d,
			CARRYCASCIN => '0',
			CARRYIN => c,
			CARRYINSEL => "000",
			CEAD => '0',
			CEALUMODE => '0',
			CEA1 => '0',
			CEA2 => '0',
			CEB1 => '0',
			CEB2 => '0',
			CEC => '0',
			CECARRYIN => '0',
			CECTRL => '0',
			CED => '0',
			CEINMODE => '0',
			CEM => '0',
			CEP => clken,
			CLK => clk,
			D => (others => '0'),
			INMODE => "00000",
			MULTSIGNIN => '0',
			OPMODE => opmode,
			P => q,
			PATTERNDETECT => match,
			PCIN => cascin,
			PCOUT => cascout,
			RSTA => '0',
			RSTALLCARRYIN => '0',
			RSTALUMODE => '0',
			RSTB => '0',
			RSTC => '0',
			RSTCTRL => '0',
			RSTD => '0',
			RSTINMODE => '0',
			RSTM => '0',
			RSTP => rst
		);
		
	opmode(1 downto 0) <= "10";
	opmode(3 downto 2) <= "00" when z = '1' else "11";
	opmode(6 downto 4) <= "001";

end rtl;

