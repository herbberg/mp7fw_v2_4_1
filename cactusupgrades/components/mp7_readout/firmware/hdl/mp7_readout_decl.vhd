-- mp7_readout_decl
--
-- Defines the constants and array subtypes for readout subsystem
--
-- Dave Newbold, September 2013

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.top_decl.all;
use work.mp7_data_types.all;
use work.ipbus_reg_types.all;
use ieee.numeric_std.all;

package mp7_readout_decl is

	constant DAQ_BWIDTH: integer := calc_width(DAQ_N_BANKS);

	constant DAQ_N_HDR_WORDS: integer := 6; -- Number of (32b) header words on bus
	
	constant DAQ_TM_WIDTH: integer := calc_width(DAQ_TRIGGER_MODES);
	
	type daq_bus is
		record
			init: std_logic;
			token: std_logic;
			data: lword;
		end record;
		
	constant DAQ_BUS_NULL: daq_bus := ('0', '0', LWORD_NULL);
	type daq_bus_array is array(natural range <>) of daq_bus;

	subtype daq_cap_bus is std_logic_vector(DAQ_N_BANKS - 1 downto 0);
	type daq_cap_bus_array is array(natural range <>) of daq_cap_bus;
	
	subtype dr_address is std_logic_vector(DR_ADDR_WIDTH-1 downto 0);
	type dr_address_array is array(natural range <>) of dr_address;
	
end mp7_readout_decl;

