-- ipbus_dpram
--
-- Generic 36b wide dual-port memory with ported ipbus access on one side
-- Only the bottom 18b of the data port are meaningful
-- Note that this takes up *twice* the internal address space indicated by ADDR_WIDTH
--
-- Should lead to an inferred block RAM in Xilinx parts with modern tools
--
-- Dave Newbold, October 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ipbus.all;

entity ipbus_ported_dpram36 is
	generic(
		ADDR_WIDTH: positive
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		rclk: in std_logic;
		we: in std_logic := '0';
		d: in std_logic_vector(35 downto 0);
		q: out std_logic_vector(35 downto 0);
		addr: in std_logic_vector(ADDR_WIDTH - 1 downto 0)
	);
	
end ipbus_ported_dpram36;

architecture rtl of ipbus_ported_dpram36 is

	type ram_array is array(2 ** ADDR_WIDTH - 1 downto 0) of std_logic_vector(17 downto 0);
	shared variable ram_l, ram_h: ram_array;
	signal sel, rsel: integer range 0 to 2 ** ADDR_WIDTH - 1 := 0;
	signal wcyc, wcyc_d, dsel, rcyc: std_logic;
	signal ptr: unsigned(ADDR_WIDTH downto 0);
	signal data: std_logic_vector(35 downto 0);
	signal data_o: std_logic_vector(31 downto 0);
	signal wea_l, wea_h: std_logic;

begin

	wcyc <= ipb_in.ipb_strobe and ipb_in.ipb_write;
	rcyc <= ipb_in.ipb_strobe and not ipb_in.ipb_write;

	process(clk)
	begin
		if falling_edge(clk) then
			if rst = '1' then
				ptr <= (others => '0');				
			elsif ipb_in.ipb_addr(0) = '0' and wcyc = '1' then
				ptr <= unsigned(ipb_in.ipb_wdata(ADDR_WIDTH downto 0));
			elsif ipb_in.ipb_addr(0) = '1' and rcyc = '1' then
				ptr <= ptr + 1;
			elsif (wcyc_d = '1') then
				ptr <= ptr + 1;
			end if;
		end if;
	end process;
	
	sel <= to_integer(ptr(ADDR_WIDTH downto 1));
	wea_l <= wcyc and ipb_in.ipb_addr(0) and not ptr(0);
	wea_h <= wcyc and ipb_in.ipb_addr(0) and ptr(0);
	
	process(clk)
	begin
		if rising_edge(clk) then

			data <= ram_h(sel) & ram_l(sel);
			dsel <= ptr(0);
				
			if wea_l = '1' then
				ram_l(sel) := ipb_in.ipb_wdata(17 downto 0);
			end if;
			if wea_h = '1' then
				ram_h(sel) := ipb_in.ipb_wdata(17 downto 0);
			end if;
			
			wcyc_d <= wcyc and ipb_in.ipb_addr(0);
		
		end if;
	end process;
	
	data_o(17 downto 0) <= data(17 downto 0) when dsel = '0' else data(35 downto 18);
	data_o(31 downto 18) <= (others => '0');
	
	ipb_out.ipb_ack <= ipb_in.ipb_strobe;
	ipb_out.ipb_err <= '0';
	ipb_out.ipb_rdata <= std_logic_vector(to_unsigned(0, 32 - ADDR_WIDTH - 1)) & std_logic_vector(ptr)
		when ipb_in.ipb_addr(0)='0' else data_o;
	
	rsel <= to_integer(unsigned(addr));
	
	process(rclk)
	begin
		if rising_edge(rclk) then
			q <= ram_h(rsel) & ram_l(rsel); -- Order of statements is important to infer read-first RAM!
			if we = '1' then
				ram_l(rsel) := d(17 downto 0);
				ram_h(rsel) := d(35 downto 18);
			end if;
		end if;
	end process;

end rtl;
