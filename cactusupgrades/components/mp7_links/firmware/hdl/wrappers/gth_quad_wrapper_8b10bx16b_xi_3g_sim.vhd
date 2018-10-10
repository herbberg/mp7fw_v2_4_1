-- simulation version of gth_quad_wrapper
--
-- This is just a loopback with delay to allow test of protocol blocks
--
-- Dave Newbold, Auguest 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

use work.package_links.all;

entity gth_quad_wrapper_8b10bx16b_xi_3g is
	generic(
		-- Simulation attributes
		SIMULATION                      : integer   := 0;           -- Set to 1 for simulation
		SIM_GTRESET_SPEEDUP             : string    := "FALSE";     -- Set to "true" to speed up sim reset
		-- Configuration
		STABLE_CLOCK_PERIOD             : integer   := 32;          -- Period of the stable clock driving this state-machine, unit is [ns] 
		LINE_RATE                       : real      := 3.0;        -- gb/s
		REFERENCE_CLOCK_RATE            : real      := 125.0;         -- mhz
		PRBS_MODE                       : string    := "PRBS-7";
		PLL: string;
		-- Placement information
		X_LOC                           : integer 	:= 0;
		Y_LOC                           : integer 	:= 0
	);
	port(
		-- Common signals
		soft_reset_in                      : in   std_logic;
		refclk_in                          : in   std_logic;
		drpclk_in                          : in   std_logic;
		sysclk_in                          : in   std_logic;
		qplllock_out                       : out   std_logic;
		cplllock_out                       : out  std_logic_vector(3 downto 0);
		
		-- Common dynamic reconfiguration port
		common_drp_address_in  	: in  std_logic_vector(7 downto 0);
		common_drp_data_in  		: in  std_logic_vector(15 downto 0);
		common_drp_data_out 		: out std_logic_vector(15 downto 0);
		common_drp_enable_in   	: in  std_logic;
		common_drp_ready_out    : out std_logic;
		common_drp_write_in    	: in  std_logic;
		
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
		chan_drp_address_in		: in type_drp_addr_array(3 downto 0);
		chan_drp_data_in			: in type_drp_data_array(3 downto 0);
		chan_drp_data_out			: out type_drp_data_array(3 downto 0);
		chan_drp_enable_in		: in std_logic_vector(3 downto 0);
		chan_drp_ready_out		: out std_logic_vector(3 downto 0);
		chan_drp_write_in			: in std_logic_vector(3 downto 0);
		
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
		txdata_in                          : in type_16b_data_array(3 downto 0);
		txcharisk_in                       : in type_16b_charisk_array(3 downto 0);
		
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

end gth_quad_wrapper_8b10bx16b_xi_3g;

architecture behavioural of gth_quad_wrapper_8b10bx16b_xi_3g is

begin

	sim_quad : entity work.gth_quad_wrapper_8b10bx16b
	generic map(
		-- Simulation attributes
		SIMULATION => SIMULATION,
		SIM_GTRESET_SPEEDUP => SIM_GTRESET_SPEEDUP,
		-- Configuration
		STABLE_CLOCK_PERIOD => STABLE_CLOCK_PERIOD,
		LINE_RATE => LINE_RATE,
		REFERENCE_CLOCK_RATE => REFERENCE_CLOCK_RATE,
		PRBS_MODE => PRBS_MODE,
		PLL => PLL,
		-- Placement information
		X_LOC => X_LOC,
		Y_LOC => Y_LOC
	)
	port map(
		-- Common signals
		soft_reset_in => soft_reset_in,
		refclk_in => refclk_in,
		drpclk_in => drpclk_in,
		sysclk_in => sysclk_in,
		qplllock_out => qplllock_out,
		cplllock_out => cplllock_out,
		-- Common dynamic reconfiguration port
		common_drp_address_in => common_drp_address_in,
		common_drp_data_in => common_drp_data_in,
		common_drp_data_out => common_drp_data_out,
		common_drp_enable_in => common_drp_enable_in,
		common_drp_ready_out => common_drp_ready_out,
		common_drp_write_in => common_drp_write_in,
		-- Channel signals
		rxusrclk_out => rxusrclk_out,
		txusrclk_out => txusrclk_out,
		rxusrrst_out => rxusrrst_out,
		txusrrst_out => txusrrst_out,
		-- Serdes links
		rxn_in => rxn_in,
		rxp_in => rxp_in,
		txn_out => txn_out,
		txp_out => txp_out,
		-- Channel dynamic reconfiguration ports
		chan_drp_address_in => chan_drp_address_in,
		chan_drp_data_in => chan_drp_data_in,
		chan_drp_data_out => chan_drp_data_out,
		chan_drp_enable_in => chan_drp_enable_in,
		chan_drp_ready_out => chan_drp_ready_out,
		chan_drp_write_in => chan_drp_write_in,
		-- State machines that control MGT Tx / Rx initialisation
		tx_fsm_reset_in => tx_fsm_reset_in,
		rx_fsm_reset_in => rx_fsm_reset_in,
		tx_fsm_reset_done_out => tx_fsm_reset_done_out,
		rx_fsm_reset_done_out => rx_fsm_reset_done_out,
		-- Misc
		loopback_in => loopback_in,
		prbs_enable_in => prbs_enable_in,
		prbs_error_out => prbs_error_out,
		-- Tx signals
		txoutclk_out => txoutclk_out,
		txpolarity_in => txpolarity_in,
		txdata_in => txdata_in,
		txcharisk_in => txcharisk_in,
		-- Rx signals 
		rx_comma_det_out => rx_comma_det_out,
		rxpolarity_in => rxpolarity_in,
		rxcdrlock_out => rxcdrlock_out,
		rxdata_out => rxdata_out,
		rxcharisk_out => rxcharisk_out,
		rxchariscomma_out => rxchariscomma_out,
		rxbyteisaligned_out => rxbyteisaligned_out,
		rxpcommaalignen_in => rxpcommaalignen_in,
		rxmcommaalignen_in => rxmcommaalignen_in
	);

end behavioural;
