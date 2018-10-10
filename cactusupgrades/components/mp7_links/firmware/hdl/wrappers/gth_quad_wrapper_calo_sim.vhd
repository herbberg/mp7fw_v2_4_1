library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

use work.package_links.all;
use work.package_utilities.all;

entity gth_quad_wrapper_calo_sim is
generic
(
    -- Simulation attributes
    SIMULATION                      : integer   := 0;           -- Set to 1 for simulation
    SIM_GTRESET_SPEEDUP             : string    := "FALSE";     -- Set to "true" to speed up sim reset
    -- Configuration
    STABLE_CLOCK_PERIOD             : integer   := 32           -- Period of the stable clock driving this state-machine, unit is [ns] 
);
port
(
    -- Common signals
    soft_reset_in                      : in   std_logic;
    refclk0_in                        : in   std_logic;
    refclk1_in                        : in   std_logic;
    drpclk_in                          : in   std_logic;
    sysclk_in                          : in   std_logic;
    qplllock_out                       : out   std_logic;
    cplllock_out                       : out  std_logic_vector(3 downto 0);
  
    -- Common dynamic reconfiguration port
    common_drp_address_in   : in  std_logic_vector(7 downto 0);
    common_drp_data_in    : in  std_logic_vector(15 downto 0);
    common_drp_data_out   : out std_logic_vector(15 downto 0);
    common_drp_enable_in    : in  std_logic;
    common_drp_ready_out    : out std_logic;
    common_drp_write_in     : in  std_logic;
  
    -- Channel signals
    rxusrclk_out                       : out  std_logic_vector(3 downto 0);
    txusrclk_out                       : out  std_logic_vector(3 downto 0);
    rxusrrst_out                       : out  std_logic_vector(3 downto 0);
    txusrrst_out                       : out  std_logic_vector(3 downto 0);
  
  -- Serdes links
    rxn_in                             : in   std_logic_vector(3 downto 0);
    rxp_in                             : in   std_logic_vector(3 downto 0);
    txn_out                            : out  std_logic_vector(3 downto 0);
    txp_out                            : out  std_logic_vector(3 downto 0);
  
  -- Channel dynamic reconfiguration ports
    chan_drp_address_in  : in type_drp_addr_array(3 downto 0);
    chan_drp_data_in   : in type_drp_data_array(3 downto 0);
    chan_drp_data_out   : out type_drp_data_array(3 downto 0);
    chan_drp_enable_in  : in std_logic_vector(3 downto 0);
    chan_drp_ready_out  : out std_logic_vector(3 downto 0);
    chan_drp_write_in   : in std_logic_vector(3 downto 0);
  
  -- State machines that control MGT Tx / Rx initialisation
    tx_fsm_reset_in                    : in   std_logic_vector(3 downto 0);
    rx_fsm_reset_in                    : in   std_logic_vector(3 downto 0);
    tx_fsm_reset_done_out              : out   std_logic_vector(3 downto 0);
    rx_fsm_reset_done_out              : out   std_logic_vector(3 downto 0);
  
  -- Misc
    loopback_in                        : in type_loopback_array(3 downto 0);
    prbs_enable_in                     : in std_logic_vector(3 downto 0);
    prbs_error_out                     : out std_logic_vector(3 downto 0);

  -- Tx signals
    txoutclk_out                       : out  std_logic_vector(3 downto 0);
    txpolarity_in                      : in  std_logic_vector(3 downto 0);
    txdata_in                          : in type_32b_data_array(3 downto 0);
    txcharisk_in                       : in type_32b_charisk_array(3 downto 0);
  
  -- Rx signals 
    rx_comma_det_out                   : out   std_logic_vector(3 downto 0);
    rxpolarity_in                      : in  std_logic_vector(3 downto 0);
    rxcdrlock_out                      : out  std_logic_vector(3 downto 0);
    rxdata_out                         : out type_16b_data_array(3 downto 0);
    rxcharisk_out                      : out type_16b_charisk_array(3 downto 0);
    rxchariscomma_out                  : out type_16b_chariscomma_array(3 downto 0);
    rxbyteisaligned_out                : out std_logic_vector(3 downto 0);
    rxpcommaalignen_in                : in std_logic_vector(3 downto 0);
    rxmcommaalignen_in                : in std_logic_vector(3 downto 0)
);

end gth_quad_wrapper_calo_sim;


architecture RTL of gth_quad_wrapper_calo_sim is

	signal usrclk_4g8, usrclk_6g4, usrclk_10g: std_logic := '0';

	signal rxusrclk, txusrclk: std_logic_vector(3 downto 0) := (others => '1');
	signal rxusrrst, txusrrst: std_logic_vector(3 downto 0) := (others => '1');

  procedure usrrst_ctrl (
    signal fsm_reset : in std_logic;
    signal usrclk : in std_logic;
    signal usrrst : out std_logic) is 
  begin
    wait until usrclk'event and usrclk='1';
    if fsm_reset = '1' then
      usrrst <= '1';
    else
    wait for 1 us;  -- bug fix required
      for i in 0 to 10 loop
      -- Allow reset to propagte
        wait until usrclk'event and usrclk='1';
      end loop;
      usrrst <= '0';
    end if;
  end usrrst_ctrl;

begin



	-- Might have to improve this later to make clks uniform across simulation
	usrclk_6g4 <= not usrclk_6g4 after (25.0 / 16.0) * 1 ns; -- 320MHz Sync
	usrclk_4g8 <= not usrclk_4g8 after (25.0 / 12.0) * 1 ns; -- 240MHz Sync
	usrclk_10g <= not usrclk_10g after (4.0 / 2.0) * 1 ns; -- 250MHz Async
	
	txusrclk <= (others => usrclk_10g);	
	--txusrrst <= tx_fsm_reset_in;
	
	rxusrclk(1 downto 0) <= (others => usrclk_4g8);
	rxusrclk(3 downto 2) <= (others => usrclk_6g4);
	--rxusrrst <= rx_fsm_reset_in;
	
	gen: for i in 3 downto 0 generate
		
		usrrst_ctrl(tx_fsm_reset_in(i), txusrclk(i), txusrrst(i));
		usrrst_ctrl(rx_fsm_reset_in(i), rxusrclk(i), rxusrrst(i));

		tx_10g: entity work.serdes_tx_8b10b
		generic map (
				BYTE_WIDTH => 4,
				CLK_PARALLEL_PERIOD => 4.0)
		port map (
				-- Serdes links
				txn_out => txn_out(i),
				txp_out => txp_out(i),
				-- Parallel Interface
				clk_in => txusrclk(i),
				rst_in => txusrrst(i),
				data_in => txdata_in(i),
				charisk_in => txcharisk_in(i)
		);

		rx_4g8_gen : if i < 2 generate
			rx_4g8: entity work.serdes_rx_8b10b
			generic map (
					BYTE_WIDTH => 2,
					CLK_PARALLEL_PERIOD => (25.0 / 6.0))
			port map (
					-- Serdes links
					rxn_in => rxn_in(i),
					rxp_in => rxp_in(i),
					-- Parallel Interface
					clk_in => rxusrclk(i),
					rst_in => rxusrrst(i),
					data_out => rxdata_out(i),
					charisk_out => rxcharisk_out(i)
			);
		end generate;
		
		rx_6g4_gen : if i >= 2 generate
			rx_6g4: entity work.serdes_rx_8b10b
			generic map (
					BYTE_WIDTH => 2,
					CLK_PARALLEL_PERIOD => (25.0 / 8.0))
			port map (
					-- Serdes links
					rxn_in => rxn_in(i),
					rxp_in => rxp_in(i),
					-- Parallel Interface
					clk_in => rxusrclk(i),
					rst_in => rxusrrst(i),
					data_out => rxdata_out(i),
					charisk_out => rxcharisk_out(i)
			);
		end generate;
		
		
		rx_comma_det_out(i) <= '0';
		
	end generate;			

	qplllock_out <= '1';
	cplllock_out <= (others => '1');
	common_drp_data_out <= (others => '0');
	common_drp_ready_out <= '0';
	prbs_error_out <= (others => '0');

	chan_drp_data_out <= (others => (others => '0'));
	chan_drp_ready_out <= (others => '0');

	txusrrst_out <= txusrrst;
	rxusrrst_out <= rxusrrst;

	txusrclk_out <= txusrclk;
	rxusrclk_out <= rxusrclk;

	tx_fsm_reset_done_out <= not txusrrst;
	rx_fsm_reset_done_out <= not rxusrrst;

	rxcdrlock_out <= (others => '1');
	rxchariscomma_out <= (others => (others => '0'));
	rxbyteisaligned_out <= (others => '1');
	
	txoutclk_out <= (others => usrclk_10g);



end RTL;
