-- region_info
--
-- Allows software to determine configuration of regions
--
-- loc 0: information for region pointed to by qsel
--
-- Dave Newbold, April 2015

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.top_decl.all;
use work.mp7_top_decl.all;
use work.mp7_brd_decl.all;

entity region_info is
	port(
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		qsel: in std_logic_vector(4 downto 0)
	);

end region_info;

architecture rtl of region_info is

	type region_data_array is array(31 downto 0) of std_logic_vector(31 downto 0);
	signal region_data: region_data_array;

begin

	ipb_out.ipb_ack <= ipb_in.ipb_strobe;
	ipb_out.ipb_err <= '0';		
	ipb_out.ipb_rdata <= region_data(to_integer(unsigned(qsel)));

	gen: for i in N_REGION - 1 downto 0 generate
	begin
		region_data(i) <= X"0" &
			std_logic_vector(to_unsigned(mgt_kind_t'pos(REGION_CONF(i).mgt_o_kind), 4)) &
			std_logic_vector(to_unsigned(chk_kind_t'pos(REGION_CONF(i).chk_o_kind), 4)) &
			std_logic_vector(to_unsigned(buf_kind_t'pos(REGION_CONF(i).buf_o_kind), 4)) &
			std_logic_vector(to_unsigned(fmt_kind_t'pos(REGION_CONF(i).fmt_kind), 4)) &
			std_logic_vector(to_unsigned(buf_kind_t'pos(REGION_CONF(i).buf_i_kind), 4)) &
			std_logic_vector(to_unsigned(chk_kind_t'pos(REGION_CONF(i).chk_i_kind), 4)) &
			std_logic_vector(to_unsigned(mgt_kind_t'pos(REGION_CONF(i).mgt_i_kind), 4));
	end generate;
	
	region_data(31 downto N_REGION) <= (others => (others => '0'));
		
end rtl;
