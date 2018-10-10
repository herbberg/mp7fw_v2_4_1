-- mp7_datapath
--
-- Wrapper for MGTs, buffers, TTC signals distribution
--
-- Dave Newbold, February 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.mp7_data_types.all;
use work.mp7_ttc_decl.all;
use work.mp7_readout_decl.all;
use work.ipbus_decode_mp7_datapath.all;
use work.drp_decl.all;
use work.top_decl.all;
use work.mp7_brd_decl.all;

entity mp7_datapath is
	port(
		clk: in std_logic; -- ipbus clock, rst, bus
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		board_id: in std_logic_vector(31 downto 0);
		clk40: in std_logic;
		clk_p: in std_logic; -- parallel data clock & rst
		rst_p: in std_logic;
		ttc_cmd: in ttc_cmd_t; -- TTC command (clk40 domain)
		ttc_l1a: in std_logic; -- TTC L1A (clk40 domain)
		lock: out std_logic; -- lock flag for distributed bunch counters
		ctrs_out: out ttc_stuff_array(N_REGION - 1 downto 0); -- TTC counters for local logic
		rst_out: out std_logic_vector(N_REGION - 1 downto 0); -- Resets for local logic;
		clken_out: out std_logic_vector(N_REGION - 1 downto 0); -- Clock enables for local logic;
		tmt_sync: in tmt_sync_t; -- TMT sync signals
		cap_bus: in daq_cap_bus; -- DAQ capture signals
		daq_bus_in: in daq_bus; -- DAQ bus in and out
		daq_bus_out: out daq_bus;
		payload_bc0: in std_logic;
		refclkp: in std_logic_vector(N_REFCLK - 1 downto 0); -- MGT refclks & IO
		refclkn: in std_logic_vector(N_REFCLK - 1 downto 0);
		clkmon: out std_logic_vector(2 downto 0);  -- clock frequency monitoring outputs
		d: in ldata(N_REGION * 4 - 1 downto 0); -- parallel data from payload
		q: out ldata(N_REGION * 4 - 1 downto 0) -- parallel data to payload
	);

end mp7_datapath;

architecture rtl of mp7_datapath is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ipbdc: ipbdc_bus_array(N_REGION downto 0);
	
	signal ctrl: ipb_reg_v(0 downto 0);
	
	signal rst_chain, lock_chain, l1a_chain: std_logic_vector(N_REGION downto 0);
	signal ttc_chain: ttc_cmd_array(N_REGION downto 0);
	signal tmt_chain: tmt_sync_array(N_REGION downto 0);
	signal cap_chain: daq_cap_bus_array(N_REGION downto 0);
	signal daq_chain: daq_bus_array(N_REGION downto 0);
	signal dbus_cross: daq_bus;
	
	signal refclk, refclk_buf, refclk_mon: std_logic_vector(N_REFCLK - 1 downto 0);
	signal rxclk_mon, txclk_mon, qplllock: std_logic_vector(31 downto 0); -- Match range of integer sel
	signal sel: integer range 0 to 31;
	signal qplllock_sel: std_logic;
	signal ctrs: ttc_stuff_array(N_REGION - 1 downto 0);
		
begin

-- ipbus address decode
		
	fabric: entity work.ipbus_fabric_sel
    generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_mp7_datapath(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

-- Control reg

	loc: entity work.ipbus_reg_v
		generic map(
			N_REG => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_CTRL),
			ipbus_out => ipbr(N_SLV_CTRL),
			q => ctrl,
			qmask => (0 => X"000000ff")
		);

-- Region info

	id: entity work.region_info
		port map(
			ipb_in => ipbw(N_SLV_REGION_INFO),
			ipb_out => ipbr(N_SLV_REGION_INFO),
			qsel => ctrl(0)(7 downto 3)
		);

-- Payload BC0 monitoring
	
	bc0_mon: entity work.align_mon
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_BC0_MON),
			ipb_out => ipbr(N_SLV_BC0_MON),
			clk_p => clk_p,
			rst_p => rst_p,
			bctr => ctrs(ALIGN_REGION).bctr,
			pctr => ctrs(ALIGN_REGION).pctr,
			sig => payload_bc0
		);

-- Regions
		
	fabric_q: entity work.ipbus_dc_fabric_sel
		generic map(
			SEL_WIDTH => 5
		)
		port map(
			clk => clk,
			rst => rst,
			sel => ctrl(0)(7 downto 3),
			ipb_in => ipbw(N_SLV_REGION),
			ipb_out => ipbr(N_SLV_REGION),
			ipbdc_out => ipbdc(0),
			ipbdc_in => ipbdc(N_REGION)
		);
	
-- Refclks

	clkgen: for i in N_REFCLK - 1 downto 0 generate
	
		ibuf: IBUFDS_GTE2
			port map(
				i => refclkp(i),
				ib => refclkn(i),
				o => refclk(i),
				ceb => '0'
			);
			
		bufh_refclk: bufh
			port map(
				i => refclk(i),
				o => refclk_buf(i)
			);
		
	end generate;
	
	refclk_div: entity work.freq_ctr_div
		generic map(
			N_CLK => N_REFCLK
		)
		port map(
			clk => refclk_buf,
			clkdiv => refclk_mon
		);
		
-- Clock monitoring

	sel <= to_integer(unsigned(ctrl(0)(7 downto 3)));
	
	qplllock(31 downto N_REGION) <= (others => '0');
	txclk_mon(31 downto N_REGION) <= (others => '0');
	rxclk_mon(31 downto N_REGION) <= (others => '0');

	clkmon(0) <= refclk_mon(REGION_CONF(sel).refclk);
	clkmon(1) <= txclk_mon(sel);
	clkmon(2) <= rxclk_mon(sel);
	qplllock_sel <= qplllock(sel);

-- Inter-region chained signals

	process(clk_p)
	begin
		if rising_edge(clk_p) then
			rst_chain(0) <= rst_p;
			ttc_chain(0) <= ttc_cmd;
			l1a_chain(0) <= ttc_l1a;
			tmt_chain(0) <= tmt_sync;
			cap_chain(0) <= cap_bus;
		end if;
	end process;
	
	process(clk40)
	begin
		if rising_edge(clk40) then
			lock <= lock_chain(N_REGION);
		end if;
	end process;
	
	lock_chain(0) <= '1';	
	daq_chain(0) <= daq_bus_in;

	process(clk_p)
	begin
		if rising_edge(clk_p) then
			daq_bus_out <= daq_chain(N_REGION);
		end if;
	end process;
		
-- Regions

	rgen: for i in 0 to N_REGION - 1 generate
	
		constant ih: integer := 4 * i + 3;
		constant il: integer := 4 * i;
		signal dbus_out: daq_bus;
		signal ipbw_loc: ipb_wbus;
		signal ipbr_loc: ipb_rbus;
	
	begin

		dc: entity work.ipbus_dc_node
			generic map(
				I_SLV => i,
				SEL_WIDTH => 5,
				PIPELINE => (i = CROSS_REGION or i = N_REGION - 1)
			)
			port map(
				clk => clk,
				rst => rst,
				ipb_out => ipbw_loc,
				ipb_in => ipbr_loc,
				ipbdc_in => ipbdc(i),
				ipbdc_out => ipbdc(i + 1)
			);
					
    clken_out(i) <= '1';
  
		region: entity work.mp7_region
			generic map(
				INDEX => i
			)
			port map(
				clk => clk,
				rst => rst,
				ipb_in => ipbw_loc,
				ipb_out => ipbr_loc,
				board_id => board_id,
				csel => ctrl(0)(2 downto 0),
				clk_p => clk_p,
				rst_in => rst_chain(i),
				rst_out => rst_chain(i + 1),
				ttc_cmd_in => ttc_chain(i),
				ttc_cmd_out => ttc_chain(i + 1),
				ttc_l1a_in => l1a_chain(i),
				ttc_l1a_out => l1a_chain(i + 1),				
				tmt_sync_in => tmt_chain(i),
				tmt_sync_out => tmt_chain(i + 1),
				cap_bus_in => cap_chain(i),
				cap_bus_out => cap_chain(i + 1),
				daq_bus_in => daq_chain(i),
				daq_bus_out => daq_chain(i + 1),
				lock_in => lock_chain(i),
				lock_out => lock_chain(i + 1),
				ctrs_out => ctrs(i),
				rst_loc_out => rst_out(i),
				--clken_out => clken_out(i),
				d => d(ih downto il),
				q => q(ih downto il),
				refclk => refclk(REGION_CONF(i).refclk),
			  refclk_alt => refclk(REGION_CONF(i).refclk_alt),
				qplllock => qplllock(i),
				txclk_mon => txclk_mon(i),
				rxclk_mon => rxclk_mon(i)
			);
			
	end generate;
	
	ctrs_out <= ctrs;

end rtl;
