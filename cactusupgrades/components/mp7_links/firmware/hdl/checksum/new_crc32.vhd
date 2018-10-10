-- new_crc32
--
-- Trial implementation of crc32
--
-- Dave Newbold, April 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.pck_crc32_d32.all;

entity new_crc32 is
	port(
		clk: in std_logic;
		rst: in std_logic;
		clken: in std_logic;
		d: in std_logic_vector(31 downto 0);
		crc: out std_logic_vector(31 downto 0)
	);
	
end new_crc32;

architecture rtl of new_crc32 is

	signal crc_i: std_logic_vector(31 downto 0);

begin

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				crc_i <= (others => '1');
			elsif clken = '1' then
				crc_i <= nextCRC32_D32(d, crc_i);
			end if;
		end if;
	end process;
	
	crc <= crc_i;

end rtl;

