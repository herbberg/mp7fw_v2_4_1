-- Creates N registers with separate read/write values

-- F. Ball April 2015

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.mp7_readout_decl.all;

entity mp7_readout_control_reg is
    generic(
        N_REG: natural := 1
        );
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipbus_in: in ipb_wbus;
		ipbus_out: out ipb_rbus;
		d: in ipb_reg_v(N_REG - 1 downto 0);
		q: out ipb_reg_v(N_REG - 1 downto 0);
		qmask: in ipb_reg_v(N_REG -1 downto 0) := (others => (others => '1'))	
	);
	
end mp7_readout_control_reg;

architecture rtl of mp7_readout_control_reg is

    constant ADDR_WIDTH: integer := calc_width(N_REG);
    
	signal cw_cyc: std_logic;
	signal reg : ipb_reg_v(N_REG-1 downto 0);
	
    signal sel: integer range 0 to 2 ** ADDR_WIDTH - 1 := 0;

begin

    sel <= to_integer(unsigned(ipbus_in.ipb_addr(ADDR_WIDTH - 1 downto 0))) when ADDR_WIDTH > 0 else 0;

	ipbus_out.ipb_ack <= ipbus_in.ipb_strobe;
	ipbus_out.ipb_err <= '0';
	
    cw_cyc <= ipbus_in.ipb_strobe and ipbus_in.ipb_write;
    
	q <= reg;
	
	process(clk)
	begin
	   if rising_edge(clk) then
	       if rst = '1' then
	           reg <= (others => (others => '0'));
	        elsif cw_cyc = '1' and sel < N_REG then
	           reg(sel) <= ipbus_in.ipb_wdata and qmask(sel);
	        end if;
	    end if;
	end process;
	
	ipbus_out.ipb_rdata <= d(sel) when sel < N_REG;

end rtl;    