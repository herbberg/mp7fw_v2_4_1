-- mp7_readout formatter

-- This module was originally developed in an attempt to reduce the data-bandwidth in stage 1
-- Now it remains as an example of daq formatter.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

use work.top_decl.all;
use work.mp7_readout_decl.all;

entity mp7_readout_formatter is
	port(
	    clk: in std_logic;
	    rst: in std_logic;
	    ipb_in: in ipb_wbus;
	    ipb_out: out ipb_rbus;
		clk_p: in std_logic; 
		rst_p: in std_logic;
		daq_bus_in: in daq_bus;
		daq_bus_out: out daq_bus;
		last: in std_logic
	);

end mp7_readout_formatter;

architecture rtl of mp7_readout_formatter is

	signal dbus: daq_bus;
	type state_type is (ST_IDLE, ST_HDR, ST_DATA);
	signal state: state_type;
	signal ctr, ro_mask_ctr: unsigned(15 downto 0);
	signal strobe: std_logic;
	signal ro_mask: std_logic_vector(CLOCK_RATIO downto 0) ; -- channel header + payload
    signal ctrl: ipb_reg_v(0 downto 0);
    signal stat: ipb_reg_v(-1 downto 0);
    signal en: std_logic;
     
begin


    csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 0
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			d => stat,
			q => ctrl
		);
    
    process(clk_p)
    begin
        if rising_edge(clk_p) then
            if rst_p = '1' then
                state <= ST_IDLE;
            else
                case state is
                when ST_IDLE =>
                    if daq_bus_in.data.strobe = '1' and daq_bus_in.data.start = '1' then
                        state <= ST_HDR;
                    end if;
                when ST_HDR =>
                    if daq_bus_in.data.strobe = '1' and ctr = to_unsigned(DAQ_N_HDR_WORDS - 1, 16) then
                        state <= ST_DATA;
                    end if;
                when ST_DATA =>
                    if daq_bus_in.token = '1' and last = '1' then
                        state <= ST_IDLE;
                    end if;
                end case;
            end if;
        end if;
    end process;
    
    process(clk_p)
    begin
        if rising_edge(clk_p) then
            if rst_p = '1' or state = ST_IDLE then
                ctr <= (others => '0');
            else
                if daq_bus_in.data.strobe = '1' and state = ST_HDR then
                    ctr <= ctr + 1;
                end if;
            end if;
        end if;
    end process;
    
    process(clk_p)
    begin
        if rising_edge(clk_p) then
            if rst_p = '1' then
                ro_mask <= (others => '0');
            elsif daq_bus_in.init = '1' then
                ro_mask <= daq_bus_in.data.data(CLOCK_RATIO + 21 downto 22) & '0';
            end if;
        end if;
    end process;
    
    process(clk_p)
    begin
       if rising_edge(clk_p) then
           if (rst_p = '1') or (state = ST_IDLE) or (ro_mask_ctr = (CLOCK_RATIO)) then -- clock ratio -1
               ro_mask_ctr <= (others => '0');
           elsif state = ST_DATA and daq_bus_in.data.strobe = '1' then
               ro_mask_ctr <= ro_mask_ctr + 1;
           end if;
       end if;
    end process;
                        
    strobe <= not ro_mask(to_integer(ro_mask_ctr)) when en = '1' else '1'; -- masks words being read out
      
    process(clk_p)
    begin
        if rising_edge(clk_p) then
            dbus.data.data <= daq_bus_in.data.data;
            dbus.data.valid <= daq_bus_in.data.valid;
            dbus.data.start <= daq_bus_in.data.start;
            dbus.init <= daq_bus_in.init;
            dbus.token <= daq_bus_in.token;
            dbus.data.strobe <= daq_bus_in.data.strobe and strobe;--strobe and daq_bus_in.data.strobe;
            daq_bus_out <= dbus;
        end if;
    end process;
    
    en <= ctrl(0)(0);

end rtl;
