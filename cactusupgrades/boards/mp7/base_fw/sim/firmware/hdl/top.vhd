-- Top-level design for MP7 base firmware
--
-- Dave Newbold, July 2012

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.ipbus_trans_decl.all;
use work.mp7_data_types.all;
use work.mp7_readout_decl.all;
use work.mp7_ttc_decl.all;
use work.mp7_brd_decl.all;

entity top is

-- No ports here

end top;

architecture rtl of top is

	signal clk_ipb, rst_ipb, clk40ish, clk40, rst40, eth_refclk: std_logic;
	signal clk40_rst, clk40_sel, clk40_lock, clk40_stop, nuke, soft_rst: std_logic;
	signal clk_p, rst_p: std_logic;
	signal clks_aux, rsts_aux: std_logic_vector(2 downto 0);

	signal ipb_in_ctrl, ipb_in_ttc, ipb_in_datapath, ipb_in_readout, ipb_in_payload, ipb_in_formatter: ipb_wbus;
	signal ipb_out_ctrl, ipb_out_ttc, ipb_out_datapath, ipb_out_readout, ipb_out_payload, ipb_out_formatter: ipb_rbus;

	signal payload_d, payload_q: ldata(N_REGION * 4	- 1 downto 0);
	signal qsel: std_logic_vector(7 downto 0);
	signal board_id: std_logic_vector(31 downto 0);
	signal ttc_l1a, ttc_l1a_dist, dist_lock, payload_bc0, ttc_l1a_throttle, ttc_l1a_flag: std_logic;
	signal ttc_cmd, ttc_cmd_dist: ttc_cmd_t;
	signal bunch_ctr: bctr_t;
	signal evt_ctr, orb_ctr: eoctr_t;
	signal tmt_sync: tmt_sync_t;

	signal clkmon: std_logic_vector(2 downto 0);

	signal cap_bus: daq_cap_bus;
	signal daq_bus_top, daq_bus_bot: daq_bus;
	signal ctrs: ttc_stuff_array(N_REGION - 1 downto 0);
	signal rst_loc, clken_loc: std_logic_vector(N_REGION - 1 downto 0);

begin

-- Clocks and control IO

	infra: entity work.mp7_infra_sim
		generic map(
			MAC_ADDR => X"000A3501EDF2",
			IP_ADDR => X"c0a8c902"
		)
		port map(
			clk_ipb => clk_ipb,
			rst_ipb => rst_ipb,
			nuke => nuke,
			soft_rst => soft_rst,			
			ipb_in_ctrl => ipb_out_ctrl,
			ipb_out_ctrl => ipb_in_ctrl,
			ipb_in_ttc => ipb_out_ttc,
			ipb_out_ttc => ipb_in_ttc,
			ipb_in_datapath => ipb_out_datapath,
			ipb_out_datapath => ipb_in_datapath,
			ipb_in_readout => ipb_out_readout,
			ipb_out_readout => ipb_in_readout,
			ipb_in_payload => ipb_out_payload,
			ipb_out_payload => ipb_in_payload
		);

-- Control registers
		
	ctrl: entity work.mp7_ctrl
		port map(
			clk => clk_ipb,
			rst => rst_ipb,
			ipb_in => ipb_in_ctrl,
			ipb_out => ipb_out_ctrl,
			nuke => nuke,
			soft_rst => soft_rst,
			board_id => board_id,
			clk40_rst => clk40_rst,
			clk40_sel => clk40_sel,
			clk40_lock => clk40_lock,
			clk40_stop => clk40_stop
		);	

-- TTC signal handling		
	
	ttc: entity work.mp7_ttc_sim
		port map(
			clk => clk_ipb,
			rst => rst_ipb,
			mmcm_rst => clk40_rst,
			sel => clk40_sel,
			lock => clk40_lock,
			stop => clk40_stop,
			ipb_in => ipb_in_ttc,
			ipb_out => ipb_out_ttc,
			clk40 => clk40,
			rst40 => rst40,
			clk_p => clk_p,
			rst_p => rst_p,
			clks_aux => clks_aux,
			rsts_aux => rsts_aux,
			ttc_cmd => ttc_cmd,
			ttc_cmd_dist => ttc_cmd_dist,
			ttc_l1a => ttc_l1a,
			ttc_l1a_flag => ttc_l1a_flag,
			ttc_l1a_dist => ttc_l1a_dist,
			l1a_throttle => ttc_l1a_throttle,
			dist_lock => dist_lock,
			bunch_ctr => bunch_ctr,
			evt_ctr => evt_ctr,
			orb_ctr => orb_ctr,
			tmt_sync => tmt_sync,
			monclk => clkmon
		);

-- MGTs, buffers and TTC fanout
		
	datapath: entity work.mp7_datapath
		port map(
			clk => clk_ipb,
			rst => rst_ipb,
			ipb_in => ipb_in_datapath,
			ipb_out => ipb_out_datapath,
			board_id => board_id,
			clk40 => clk40,
			clk_p => clk_p,
			rst_p => rst_p,
			ttc_cmd => ttc_cmd_dist,
			ttc_l1a => ttc_l1a_dist,
			lock => dist_lock,
			ctrs_out => ctrs,
			rst_out => rst_loc,
			clken_out => clken_loc,
			tmt_sync => tmt_sync,
			cap_bus => cap_bus,
			daq_bus_in => daq_bus_top,
			daq_bus_out => daq_bus_bot,
			payload_bc0 => payload_bc0,
			refclkp => (others => '0'),
			refclkn => (others => '0'),
			clkmon => clkmon,
			q => payload_d,
			d => payload_q
		);

-- Readout
		
	readout: entity work.mp7_readout
		port map(
			clk => clk_ipb,
			rst => rst_ipb,
			ipb_in => ipb_in_readout,
			ipb_out => ipb_out_readout,
			board_id => board_id,
			ttc_clk => clk40,
			ttc_rst => rst40,
			ttc_cmd => ttc_cmd,
			l1a => ttc_l1a,
			l1a_flag => ttc_l1a_flag,
			l1a_throttle => ttc_l1a_throttle,
			bunch_ctr => bunch_ctr,
			evt_ctr => evt_ctr,
			orb_ctr => orb_ctr,
			clk_p => clk_p,
			rst_p => rst_p,
			cap_bus => cap_bus,
			daq_bus_out => daq_bus_top,
			daq_bus_in => daq_bus_bot,
			amc13_refclk => '0'			
		);

-- Payload
		
	payload: entity work.mp7_payload
		port map(
			clk => clk_ipb,
			rst => rst_ipb,
			ipb_in => ipb_in_payload,
			ipb_out => ipb_out_payload,
			clk_payload => clks_aux,
			rst_payload => rsts_aux,
			clk_p => clk_p,
			rst_loc => rst_loc,
			clken_loc => clken_loc,
			ctrs => ctrs,
			bc0 => payload_bc0,
			d => payload_d,
			q => payload_q,
			gpio => open,
			gpio_en => open
		);
		
end rtl;
