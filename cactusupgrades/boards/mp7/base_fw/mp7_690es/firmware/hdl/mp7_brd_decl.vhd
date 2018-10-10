-- mp7_brd_decl
--
-- Defines constants for the whole device
--
-- Dave Newbold, June 2014

library IEEE;
use IEEE.STD_LOGIC_1164.all;

package mp7_brd_decl is

	constant BOARD_REV: std_logic_vector(7 downto 0) := X"10";
	constant N_REGION: integer := 18;
	constant ALIGN_REGION: integer := 4;
	constant CROSS_REGION: integer := 8;
	constant N_REFCLK: integer := 9;

end mp7_brd_decl;
