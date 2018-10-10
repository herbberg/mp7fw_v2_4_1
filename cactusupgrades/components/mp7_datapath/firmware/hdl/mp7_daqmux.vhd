-- mp7_daqmux
--
-- Handles insertion of derandomiser data onto daq bus
--
-- Dave Newbold, March 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.mp7_data_types.all;
use work.mp7_readout_decl.all;
use work.top_decl.ALL;

entity mp7_daqmux is
	generic(
		ADDR_WIDTH: integer;
		INDEX: integer
	);
	port(
		clk_p: in std_logic; -- parallel data clock & reset
		rst_p: in std_logic;
		resync: in std_logic;
		bank: in std_logic_vector(DAQ_BWIDTH downto 0); -- DAQ bank
		daq_bus_in: in daq_bus; -- daq readout bus
		daq_bus_out: out daq_bus;
		addr: out std_logic_vector(ADDR_WIDTH - 1 downto 0);
		data: in lword
	);

end mp7_daqmux;

architecture rtl of mp7_daqmux is

	type state_type is (ST_IDLE, ST_HDR, ST_DATA, ST_SKIP);
	signal state: state_type;
	signal rsti, last, init_sel: std_logic;
	signal idata: lword;
	signal dctr: unsigned(7 downto 0);
	signal actr: unsigned(ADDR_WIDTH - 1 downto 0);
	signal cap_id: std_logic_vector(3 downto 0);

begin

	rsti <= rst_p or resync;

	process(clk_p)
	begin
		if rising_edge(clk_p) then
		
			if rsti = '1'then
				state <= ST_IDLE;
			else
				case state is

				when ST_IDLE =>  -- Starting state
					if daq_bus_in.token = '1' then
						if last = '0' then
							state <= ST_HDR;
						else
							state <= ST_SKIP;
						end if;
					end if;
		       
				when ST_HDR => -- Send header
					state <= ST_DATA;

				when ST_DATA => -- Send data
					if last = '1' then
						state <= ST_IDLE;
					end if;
					
				when ST_SKIP =>
				    state <= ST_IDLE;
				
				end case;
			end if;
		end if;
	end process;

	init_sel <= '1' when daq_bus_in.init = '1' and (DAQ_BWIDTH = 0 or daq_bus_in.data.data(DAQ_BWIDTH + 28 downto 28) = bank) else '0';
	
	process(clk_p)
	begin
		if rising_edge(clk_p) then
			if rsti = '1' then
				dctr <= X"00";
				cap_id <= (others => '0');
			elsif init_sel = '1' then
				dctr <= unsigned(daq_bus_in.data.data(7 downto 0));
				actr <= unsigned(daq_bus_in.data.data(ADDR_WIDTH + 11 downto 12));
				cap_id <= daq_bus_in.data.data(25 downto 22);
			elsif daq_bus_in.token = '1' and last = '0' then 
			    actr <= actr + 1; 
			elsif state /= ST_IDLE and dctr /= X"00" then -- DCTR must never reach below 0 or nasty things will happen to the 'last' signal
				actr <= actr + 1;
				dctr <= dctr - 1;
			end if;
		end if;
	end process;
	
	last <= '1' when dctr = X"00" else '0'; 		
	addr <= std_logic_vector(actr);

	with state select daq_bus_out.data <=
		(data.data, data.valid, '0', '1') when ST_DATA,
		(std_logic_vector(to_unsigned(INDEX, 8)) & std_logic_vector(dctr) & X"0" & cap_id & X"00" , '0', '1', '1') when ST_HDR,
		LWORD_NULL when others; 
	
	daq_bus_out.token <= '1' when (last = '1' and state = ST_DATA) or state = ST_SKIP else '0';
	daq_bus_out.init <= '0';
		
end rtl;
