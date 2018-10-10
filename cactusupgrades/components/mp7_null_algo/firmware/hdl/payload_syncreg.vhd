-- payload_syncreg
--
-- A special address decoder / clock domain crossing block for payloads that internally
-- decode their 31b address space.
--
-- This block can be instantiated within the algo top level to interface to ipbus
--
-- Dave Newbold, September 2015

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.ipbus_reg_types.all;

entity payload_syncreg is
	port(
		clk: in std_logic; -- ipbus signals
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		payload_clk: in std_logic;
		payload_addr: out std_logic_vector(30 downto 0);
		payload_wdata: out std_logic_vector(31 downto 0);
		payload_stb: out std_logic;
		payload_rdata: in std_logic_vector(31 downto 0)
	)
		
end payload_syncreg;

architecture rtl of payload_syncreg is

	signal reg_ipb_in: ipb_wbus;

begin

	reg_ipb_in.ipb_addr <= (31 downto 1 => '0', 0 => not ipb_in.ipb_write);
	reg_ipb_in.ipb_wdata <= ipb_in.ipb_wdata;
	reg_ipb_in.ipb_strobe <= ipb_in.ipb_strobe and ipb_in.ipb_addr(31);
	reg_ipb_in.ipb_write <= ipb_in.ipb_write;
	
	reg: entity work.ipbus_syncreg_v
		port map(
			clk => clk,
			rst => rst,
			ipb_in => reg_ipb_in,
			ipb_out => ipb_out,
			slv_clk => payload_clk,
			d(0) => payload_rdata,
			q(0) => payload_wdata,
			stb(0) => payload_stb
		);

	process(payload_clk)
	begin
		if rising_edge(payload_clk) then
			if reg_ipb_in.ipb_strobe = '1' then	
				payload_addr <= ipb_in.ipb_addr(30 downto 0);
			end if;
		end if;
	end process;

end rtl;
