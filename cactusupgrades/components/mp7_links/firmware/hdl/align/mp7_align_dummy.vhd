-- mp7_mgt
--
-- Wrapper for MGT quads - this version for equal width interfaces only
-- Equal number of input and output channels for now
--
-- Dave Newbold, July 2013

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.top_decl.all;

entity mp7_align is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_p: in std_logic;
		qsel: in std_logic_vector(4 downto 0);
		bctr: in std_logic_vector(11 downto 0);
		pctr: in std_logic_vector(2 downto 0);
		align_master: out std_logic_vector(4 * N_REGION - 1 downto 0);
		align_rst: out std_logic;
		align_ptr_inc: out std_logic_vector(4 * N_REGION - 1 downto 0);
		align_ptr_dec: out std_logic_vector(4 * N_REGION - 1 downto 0);
		align_marker: in std_logic_vector(4 * N_REGION - 1 downto 0);
		qplllock: in std_logic
	);

end mp7_align;

architecture rtl of mp7_align is
	
begin

	ipb_out <= IPB_RBUS_NULL;
	align_master <= (others => '0');
	align_rst <= '0';
	align_ptr_inc <= (others => '0');
	align_ptr_dec <= (others => '0');

end rtl;

