-- mp7_readout
--
-- All the stuff to read out data from the MP7 via ipbus or AMC13
--
-- Dave Newbold, March 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_mp7_readout.all;

use work.top_decl.all;
use work.mp7_readout_decl.all;
use work.mp7_ttc_decl.all;

entity mp7_readout is
	port(
		clk: in std_logic; -- ipbus clock, rst, bus
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		board_id: in std_logic_vector(31 downto 0);
		ttc_clk: in std_logic;
		ttc_rst: in std_logic;
		ttc_cmd: in ttc_cmd_t;
		l1a: in std_logic;
		l1a_flag: in std_logic;
		l1a_throttle: out std_logic;
		bunch_ctr: in bctr_t;
		evt_ctr: out eoctr_t;
		orb_ctr: in eoctr_t;
		clk_p: in std_logic; -- data clock, rst
		rst_p: in std_logic;
		cap_bus: out daq_cap_bus; -- data capture strobes
		daq_bus_out: out daq_bus; -- DAQ daisy-chain bus
		daq_bus_in: in daq_bus;
		amc13_refclk: in std_logic;
		trig_err: in std_logic := '0'
	);

end mp7_readout;

architecture rtl of mp7_readout is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal ctrl, stat: ipb_reg_v(1 downto 0);
	signal tts_ctrl, tts_stat: ipb_reg_v(0 downto 0);
	signal resync_cmd, ec0_cmd, resync_pend, resync_pend_amc13, ec0_pend, resync, ec0, resync_pend_d, resync_empty: std_logic;
	signal evt_ctr_i: unsigned(eoctr_t'range);
	signal evt_ctr_u: eoctr_t;
	signal src_err, warn, src_warn, f_src_err, rob_err, rob_warn, rob_empty, rst_link, rc_warn, rc_err, dr_full: std_logic;
	signal fake_l1a, real_l1a, token_throttle, rob_last, f_rob_last, r_rob_last: std_logic;
	signal f_done, r_done, ro_done, rob_done, zs_done_out: std_logic; --JRF Feb 2016 added zs_done_out
	signal fake_dbus_in, fake_dbus_out, dbus_out, dbus_in, dbus_zs_in, dbus_zs_out, real_dbus_in: daq_bus;
	signal cap_b : daq_cap_bus;
	signal bunch_ctr_i: bctr_t;
	signal amc13_d: std_logic_vector(63 downto 0);
	signal amc13_valid, amc13_hdr, amc13_trl, amc13_warn, amc13_rdy, amc13_rdy_m: std_logic;
	signal evt_cnt: std_logic_vector(31 downto 0);
	signal hist_state, tts_state: std_logic_vector(15 downto 0);
	signal tts, tts_i: std_logic_vector(3 downto 0);
	signal debug: std_logic_vector(27 downto 0);
	signal uptime_ctr, busy_ctr, ready_ctr, warn_ctr, oos_ctr: std_logic_vector(63 downto 0);
	signal bx_offset: signed(11 downto 0);
	signal bunch_ctr_s, bunch_ctr_wrap: unsigned(12 downto 0);
	signal done : std_logic;
	signal bc0_cmd, bcntres : std_logic;
	signal amc_bc0_offset : std_logic_vector(4 downto 0);
	type state_type is (ST_IDLE, ST_HDR);
	signal event_state : state_type;
	signal evt_ctrl: ipb_reg_v(-1 downto 0);
	signal evt_stat: ipb_reg_v(0 downto 0);
	signal dbus_evt_ctr, evt_err_ctr : unsigned(23 downto 0);
	signal hdr_st_d : std_logic;

begin

-- ipbus address decode

	fabric: entity work.ipbus_fabric_sel
		generic map(
			NSLV => N_SLAVES,
			SEL_WIDTH => IPBUS_SEL_WIDTH
		)
		port map(
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			sel => ipbus_sel_mp7_readout(ipb_in.ipb_addr),
			ipb_to_slaves => ipbw,
			ipb_from_slaves => ipbr
		);
		
-- CSR

	csr: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 2,
			N_STAT => 2
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
		
	stat(0)(0) <= src_err;
	stat(0)(1) <= rob_err;
	stat(0)(2) <= amc13_warn;
	stat(0)(3) <= amc13_rdy;
	stat(0)(31 downto 4) <= debug;
	stat(1) <= evt_cnt; -- CDC, unrelated clocks 
	
	evt_err: entity work.ipbus_ctrlreg_v
        generic map(
            N_CTRL => 0,
            N_STAT => 1
        )
        port map(
            clk => clk,
            reset => rst,
            ipbus_in => ipbw(N_SLV_EVT_CHECK),
            ipbus_out => ipbr(N_SLV_EVT_CHECK),
            d => evt_stat,
            q => evt_ctrl
        );
    evt_stat(0)(23 downto 0) <= std_logic_vector(evt_err_ctr);

-- Resync & EC0

	resync_cmd <= '1' when ttc_cmd = TTC_BCMD_RESYNC else '0';
	ec0_cmd <= '1' when ttc_cmd = TTC_BCMD_EC0 else '0';

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			ro_done <= r_done and f_done and rob_done; -- pipelining
			resync_pend <= (resync_pend or resync_cmd) and not (resync or ttc_rst);
			resync_pend_amc13 <= (resync_pend_amc13 or resync_cmd) and not (l1a or ttc_rst);
			ec0_pend <= (ec0_pend or ec0_cmd) and not (ec0 or ttc_rst);
		end if;
	end process;
	
	process(ttc_clk)
	begin
	   if rising_edge(ttc_clk) then
	       resync_pend_d <= resync_pend;
	       resync_empty <= resync_pend_d and not resync_pend;
	   end if;
    end process;

	resync <= (resync_pend and ro_done) or rst_p;
	ec0 <= ec0_pend and not resync_pend;
	
-- Event counter

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			if ec0 = '1' or ttc_rst = '1' then
				evt_ctr_i <= to_unsigned(1, evt_ctr_i'length); -- CMS rules; first event is 1, not zero
			elsif l1a = '1' then
				evt_ctr_i <= evt_ctr_i + 1;
			end if;
		end if;
	end process;
	
	evt_ctr_u <= eoctr_t(evt_ctr_i);
	evt_ctr <= evt_ctr_u;
	
-- Event counter counter (yeah, it's a thing)

    process(clk_p)
    begin
        if rising_edge(clk_p) then
            
            if rst_p = '1' then
                event_state <= ST_IDLE;
                hdr_st_d <= '0';
            else
                hdr_st_d <= real_dbus_in.data.start;
                
                case event_state is
                when ST_IDLE =>
                    if real_dbus_in.data.start = '1' and hdr_st_d = '0' then -- needs to be second header word, 24 bits
                        event_state <= ST_HDR;
                    end if;
                when ST_HDR =>
                    event_state <= ST_IDLE;
                end case;
            end if;
        end if;
    end process;
    
    process(clk_p)
    begin
        if rising_edge(clk_p) then
            if rst_p = '1' or ec0 = '1' then
                evt_err_ctr <= (others => '0');
                dbus_evt_ctr <=(others => '0');
            else     
                if real_dbus_in.data.start = '1' and hdr_st_d = '0' then
                    dbus_evt_ctr <= dbus_evt_ctr + 1;            
                elsif event_state = ST_HDR then                                  
                    if dbus_evt_ctr(23 downto 0) /= unsigned(real_dbus_in.data.data(23 downto 0)) then
                        evt_err_ctr <= evt_err_ctr + 1; 
                        dbus_evt_ctr <= unsigned(real_dbus_in.data.data(23 downto 0));-- now take value of dbus evt ctr so not to keep tripping error
                    end if;
                    
                end if;
            end if;
        end if;
    end process;
                
	
-- Token throttle and fake bus driver switch

	daq_bus_out <= dbus_out when ctrl(0)(0) = '0' else DAQ_BUS_NULL;
	rob_last <= r_rob_last when ctrl(0)(0) = '0' else f_rob_last;
	cap_bus <= cap_b when ctrl(0)(0) = '0' else (others => '0');

-- Pipelining
	
	process(clk_p) -- pipelining
	begin
		if rising_edge(clk_p) then
			dbus_in <= dbus_zs_out;
			if ctrl(0)(0) = '0' then
				dbus_zs_in <= daq_bus_in;
				real_dbus_in <= dbus_zs_out;
			else
				dbus_zs_in <= fake_dbus_out;
				fake_dbus_in <= dbus_zs_out;
			end if;
		end if;
	end process;
	
	token_throttle <= warn and ctrl(1)(16);
	
-- Bunch counter offset

	bunch_ctr_s <= unsigned('0' & bunch_ctr) + unsigned('0' & ctrl(0)(15 downto 4));
	bunch_ctr_wrap <= bunch_ctr_s - LHC_BUNCH_COUNT;

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			if bunch_ctr_s >= LHC_BUNCH_COUNT then
				bunch_ctr_i <= std_logic_vector(bunch_ctr_wrap(11 downto 0));
			else
				bunch_ctr_i <= std_logic_vector(bunch_ctr_s(11 downto 0));
			end if;
		end if;
	end process;
	
-- Fake event source

	real_l1a <= l1a and not ctrl(0)(0);	
	fake_l1a <= l1a and ctrl(0)(0); -- CDC, unrelated clocks
	
	src: entity work.fake_event_src
		generic map(
			USER_DATA => X"DEAD1001"
		)
		port map(
			board_id => board_id(15 downto 0),
			evt_size => ctrl(0)(27 downto 16),
			ttc_clk => ttc_clk,
			resync => resync,
			l1a => fake_l1a,
			l1a_flag => l1a_flag,
			bunch_ctr => bunch_ctr_i,
			evt_ctr => evt_ctr_u,
			orb_ctr => orb_ctr,
			clk_p => clk_p,
			rst_p => rst_p,
			throttle => token_throttle,
			daq_bus_out => fake_dbus_out,
			daq_bus_in => fake_dbus_in,
			err => f_src_err,
			rob_last => f_rob_last,
			done => f_done
		);

-- Readout control
                
	real_l1a <= l1a and not ctrl(0)(0); -- CDC, unrelated clocks

	readout_ctrl: entity work.mp7_readout_control
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_READOUT_CONTROL),
			ipb_out => ipbr(N_SLV_READOUT_CONTROL),
			board_id => board_id(15 downto 0),
			resync => resync,
			clk_p => clk_p,
			rst_p => rst_p,
			l1a => real_l1a,
			l1a_flag => l1a_flag,
			throttle => token_throttle,
			ttc_clk => ttc_clk,
			ttc_cmd => ttc_cmd,
			bunch_ctr => bunch_ctr_i,
			evt_ctr => evt_ctr_u,
			orb_ctr => orb_ctr,
			err => rc_err,
			warn => rc_warn,
			dr_full => dr_full,
			cap_bus => cap_b,
			daq_bus_out => dbus_out,
			daq_bus_in => real_dbus_in,
			rob_last => r_rob_last,
			done => r_done
		);
    
-- Zero suppression

	zero_supp: entity work.mp7_readout_zero_suppression
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_READOUT_ZS),
			ipb_out => ipbr(N_SLV_READOUT_ZS),
			clk_p => clk_p,
			rst_p => rst_p,
			daq_bus_in => dbus_zs_in,
			daq_bus_out => dbus_zs_out,		
			done_in => rob_last, --JRF added this for the ZS Block, this signal created in readout signifies the end of the event
			done_out => zs_done_out --JRF added this for the ZS Block, this signal is the hijacked version of rob_last created by ZS block
		);
		
-- Readout buffer

	rob: entity work.ro_buffer
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_BUFFER),
			ipb_out => ipbr(N_SLV_BUFFER),
			hwm => ctrl(1)(7 downto 0),
			lwm => ctrl(1)(15 downto 8),
			clk_p => clk_p,
			rst_p => rst_p,
			resync => resync,
			auto_empty => ctrl(0)(2),
			ro_rate => ctrl(0)(31 downto 28),
			daq_bus_in => dbus_in,
			amc13_en => ctrl(0)(1),
			amc13_data => amc13_d,
			amc13_valid => amc13_valid,
			amc13_hdr => amc13_hdr,
			amc13_trl => amc13_trl,
			amc13_warn => amc13_warn,
			amc13_rdy => amc13_rdy,
			err => rob_err,
			warn => rob_warn,
			empty => rob_empty,
			done => rob_done,
			evt_cnt => evt_cnt,
			rob_last => zs_done_out-- JRF repalced this with zs_done_out from the zs block, rob_last
		);

-- TTS control register

	tts_csr: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_TTS_CSR),
			ipb_out => ipbr(N_SLV_TTS_CSR),
			slv_clk => ttc_clk,
			d => tts_stat,
			q => tts_ctrl,
			qmask(0) => X"0000003f"
		);
		
-- TTS control

	tts <= tts_ctrl(0)(3 downto 0) when tts_ctrl(0)(5) = '1' else tts_i;
	tts_stat(0)(3 downto 0) <= tts;
	tts_stat(0)(31 downto 4) <= (others => '0');
	
	src_err <= f_src_err or rc_err;
	src_warn <= rc_warn;
	warn <= rob_warn;
	
	tts_sm: entity work.tts_sm
		port map(
			clk => ttc_clk,
			rst => ttc_rst,
			tts => tts_i,
			resync => resync,
			resync_pend => resync_pend,
			rdy => tts_ctrl(0)(4),
			src_warn => src_warn,
			src_err => src_err,
			rob_warn => warn,
			rob_err => rob_err,
			amc13_rdy => '1', -- causes an unpleasant feedback loop with AMC13 if connected
			trig_err => trig_err, -- connect this later
			throttle => l1a_throttle,
			uptime_ctr => uptime_ctr,
			busy_ctr => busy_ctr,
			ready_ctr => ready_ctr,
			warn_ctr => warn_ctr,
			oos_ctr => oos_ctr
		);
		
-- AMC13 interface

    bc0_cmd <= '1' when ttc_cmd = TTC_BCMD_BC0 else '0';

    bc0_delay : entity work.bitshift_delay
    generic map (
        MAX_DELAY => 31,
        DELAY_WIDTH => 5
        )
    port map (
        rst => ttc_rst,
        clk => ttc_clk,
        delay => amc_bc0_offset, --24
        d => bc0_cmd,
        q => bcntres
    );
    
    amc_bc0_offset <= std_logic_vector(to_unsigned(LHC_BUNCH_COUNT - TTC_BC0_BX - 1, 5));

	rst_link <= rst or ctrl(0)(3);

	amc13: entity work.amc13_link
		port map(
			clk => clk,
			rst => rst_link,
--			ttcclk => '0',--ttc_clk, fb  disable for now
--			bcntres => '0',--bcntres, fb disable for now
			gt_refclk => amc13_refclk,
			clk_p => clk_p,
			data => amc13_d,
			valid => amc13_valid,
			hdr => amc13_hdr,
			trl => amc13_trl,
			warn => amc13_warn,
			ready => amc13_rdy,
			clk_tts => ttc_clk,
			tts => tts,
			debug => debug,
			resync_empty => resync_empty
		);
		
-- History buffer

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
            hist_state <= "0000" & (amc13_trl and amc13_valid) & amc13_warn & amc13_rdy & rob_err & rob_warn & ro_done &
                        resync_cmd & ec0_cmd & resync_pend & ec0_pend & resync & ec0;
		end if;
	end process;	
	
	hist: entity work.state_history
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_HIST),
			ipb_out => ipbr(N_SLV_HIST),
			ttc_clk => ttc_clk,
			ttc_rst => ttc_rst,
			ttc_bx => bunch_ctr,
			ttc_orb => orb_ctr,
			ttc_evt => evt_ctr_u,
			state => hist_state
		);
		
-- TTS history buffer

	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			tts_state <= X"000" & tts;
		end if;
	end process;

	tts_hist: entity work.state_history
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_TTS_HIST),
			ipb_out => ipbr(N_SLV_TTS_HIST),
			ttc_clk => ttc_clk,
			ttc_rst => ttc_rst,
			ttc_bx => bunch_ctr,
			ttc_orb => orb_ctr,
			ttc_evt => evt_ctr_u,
			state => tts_state
		);
		
-- TTS counters

	ipbr(N_SLV_TTS_CTRS).ipb_ack <= ipbw(N_SLV_TTS_CTRS).ipb_strobe;
	ipbr(N_SLV_TTS_CTRS).ipb_err <= '0';
	
	with ipbw(N_SLV_TTS_CTRS).ipb_addr(3 downto 0) select ipbr(N_SLV_TTS_CTRS).ipb_rdata <=
		uptime_ctr(31 downto 0) when "0000",
		uptime_ctr(63 downto 32) when "0001",
		busy_ctr(31 downto 0) when "0010",
		busy_ctr(63 downto 32) when "0011",
		ready_ctr(31 downto 0) when "0100",
		ready_ctr(63 downto 32) when "0101",
		warn_ctr(31 downto 0) when "0110",
		warn_ctr(63 downto 32) when "0111",
		oos_ctr(31 downto 0) when "1000",
		oos_ctr(63 downto 32) when "1001",
		(others => '0') when others;

end rtl;
