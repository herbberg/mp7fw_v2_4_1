-- amc13_link
--
-- Wrapper for backplane link to amc13 for virtex7 GTH devices
--
-- Dave Newbold, April 2015

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.VComponents.all;

entity amc13_link is
	port(
		clk: in std_logic; -- ipb clock (also used as sysclk for reset SMs, etc)
		rst: in std_logic; -- ipb reset
		gt_refclk: in std_logic; -- GTH refclk
		clk_p: in std_logic; -- data clock
		data: in std_logic_vector(63 downto 0); -- data to transmit
		valid: in std_logic; -- data valid flag
		hdr: in std_logic; -- header flag
		trl: in std_logic; -- trailer flag
		warn: out std_logic; -- buffer warning signal
		ready: out std_logic; -- ready signal
		clk_tts: in std_logic; -- TTS clock (40MHz)
		tts: in std_logic_vector(3 downto 0); -- TTS status
		debug: out std_logic_vector(27 downto 0);
		resync_empty: in std_logic
	);

end amc13_link;

architecture rtl of amc13_link is

	signal usrclk, txoutclk, cplllock, rx_reset_done, tx_reset_done, data_valid: std_logic;
	signal rxnotintable, rxchariscomma, rxcharisk, txcharisk: std_logic_vector(1 downto 0);
	signal rxdata, txdata: std_logic_vector(15 downto 0);
	signal rxrstdbg, txrstdbg, data_valid_d: std_logic;
	signal errctr: unsigned(15 downto 0);

begin

-- Debug

	debug(0) <= rx_reset_done;
	debug(1) <= tx_reset_done;
	debug(2) <= data_valid;
	debug(3) <= rxrstdbg;
	debug(4) <= cplllock;
	debug(5) <= txrstdbg;
	debug(6) <= '0';
	debug(7) <= '0';
	debug(23 downto 8) <= std_logic_vector(errctr);
	debug(27 downto 24) <= "1010";

-- AMC13 interface

	amc13: entity work.DAQ_Link_7S
		port map(
			reset => rst,
			use_trigger_port => false,
			usrclk => usrclk,
			cplllock => cplllock,
			rxresetdone => rx_reset_done,
			txfsmresetdone => tx_reset_done,
			rxnotintable => rxnotintable,
			rxchariscomma => rxchariscomma,
			rxcharisk => rxcharisk,
			rxdata => rxdata,
			txcharisk => txcharisk,
			txdata => txdata,
			ttcclk => '0',
			bcntres => '0',
			trig => X"00",
			ttsclk => clk_tts,
			tts => tts,
			resyncandempty => resync_empty,
			eventdataclk => clk_p,
			eventdata_valid => valid,
			eventdata_header => hdr,
			eventdata_trailer => trl,
			eventdata => data,
			almostfull => warn,
			ready => ready,
			sysclk => clk,
			l1a_data_we => open,
			l1a_data => open
		);
		
-- GTH wrapper
	
	gth: entity work.amc13_link_gth
		port map(
			SYSCLK_IN => clk, -- Nominal 31.25MHz ipbus clock
			SOFT_RESET_TX_IN => rst,
			SOFT_RESET_RX_IN => rst,			
			DONT_RESET_ON_DATA_ERROR_IN => '0',
			GT0_TX_FSM_RESET_DONE_OUT => tx_reset_done,
			GT0_RX_FSM_RESET_DONE_OUT => rxrstdbg,
			GT0_DATA_VALID_IN => data_valid,
			gt0_cpllfbclklost_out => open,
			gt0_cplllock_out => cplllock,
			gt0_cplllockdetclk_in => clk,
			gt0_cpllreset_in => '0', -- driven by wrapper reset SM
			gt0_gtrefclk0_in => '0',
			gt0_gtrefclk1_in => gt_refclk,
			gt0_drpclk_in => clk,
			gt0_eyescanreset_in => '0',
			gt0_rxuserrdy_in => '0',  -- driven by wrapper reset SM
			gt0_eyescandataerror_out => open,
			gt0_eyescantrigger_in => '0',
			gt0_rxclkcorcnt_out => open,
			gt0_dmonitorout_out => open,
			gt0_rxusrclk_in => usrclk,
			gt0_rxusrclk2_in => usrclk,
			gt0_rxdata_out => rxdata,
			gt0_rxdisperr_out => open,
			gt0_rxnotintable_out => rxnotintable,
			gt0_gthrxn_in => '1', -- don't need to connect transceiver ports externally
			gt0_rxmonitorout_out => open,
			gt0_rxmonitorsel_in => "00",
			gt0_gtrxreset_in => '0',  -- driven by wrapper reset SM
			gt0_rxchariscomma_out => rxchariscomma,
			gt0_rxcharisk_out => rxcharisk,
			gt0_gthrxp_in => '0', -- don't need to connect transceiver ports externally
			gt0_rxresetdone_out => rx_reset_done, -- rx reset status monitored via reset SM
			gt0_gttxreset_in => '0',  -- driven by wrapper reset SM
			gt0_txuserrdy_in => '0',  -- driven by wrapper reset SM
			gt0_txusrclk_in => usrclk,
			gt0_txusrclk2_in => usrclk,
			gt0_txdata_in => txdata,
			gt0_gthtxn_out => open, -- don't need to connect transceiver ports externally
			gt0_gthtxp_out => open, -- don't need to connect transceiver ports externally
			gt0_txoutclk_out => txoutclk,
			gt0_txoutclkfabric_out => open,
			gt0_txoutclkpcs_out => open,
			gt0_txresetdone_out => txrstdbg, -- tx reset status monitored via reset SM
			gt0_txcharisk_in => txcharisk,
			GT0_QPLLOUTCLK_IN => '0',
			GT0_QPLLOUTREFCLK_IN => '0'
		);
		
-- Clock buffer

	buf: BUFH
		port map(
			i => txoutclk,
			o => usrclk
		);
		
-- Data monitor

	process(usrclk)
	begin
		if rising_edge(usrclk) then
			if rx_reset_done = '0' or tx_reset_done = '0' or or_reduce(rxnotintable) = '1' or cplllock = '0' then
				data_valid <= '0';
			elsif rxcharisk = "11" and rxdata = X"3cbc" then
				data_valid <= '1';
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				errctr <= (others => '0');
			elsif data_valid <= '0' and data_valid_d <= '1' and errctr /= X"ffff" then
				errctr <= errctr + 1;
			end if;
			data_valid_d <= data_valid;
		end if;
	end process;

end rtl;
