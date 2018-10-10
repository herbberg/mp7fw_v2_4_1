-- crc_tx
--
-- Trial implementation of crc tx block
--
-- Dave Newbold, April 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.mp7_data_types.all;

entity crc_tx is
	port(
		clk: in std_logic;
		d: in lword;
		q: out lword
	);
	
end crc_tx;

architecture rtl of crc_tx is

	signal data_v_d: std_logic_vector(2 downto 0);
	signal crc_rst, crc_valid: std_logic;
	signal crc: std_logic_vector(31 downto 0);
	
begin

	data_v_d(0) <= d.valid;

	process(clk)
	begin
		if rising_edge(clk) then
			data_v_d(2 downto 1) <= data_v_d(1 downto 0);
		end if;
	end process;
	
	crc_rst <= '1' when data_v_d(1 downto 0) = "00" else '0';
	crc_valid <= '1' when data_v_d = "100" else '0';
	
	crc32: entity work.new_crc32
		port map(
			clk => clk,
			rst => crc_rst,
			clken => d.valid,
			d => d.data,
			crc => crc
		);
		
	q.data <= crc when crc_valid = '1' else d.data;
	q.valid <= crc_valid or d.valid;

end rtl;

