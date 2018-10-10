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

entity gth_quad_wrapper_8b10bx16b is
	generic(
		-- Simulation attributes
		SIMULATION                      : integer   := 0;           -- Set to 1 for simulation
		SIM_GTRESET_SPEEDUP             : string    := "FALSE";     -- Set to "true" to speed up sim reset
		-- Configuration
		STABLE_CLOCK_PERIOD             : integer   := 32;          -- Period of the stable clock driving this state-machine, unit is [ns] 
		LINE_RATE                       : real		:= 5.0;        -- gb/s
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

end gth_quad_wrapper_8b10bx16b;

architecture behavioural of gth_quad_wrapper_8b10bx16b is

	constant CLKP_HALFPERIOD: time := integer(20.0 / LINE_RATE) * 1 ns;
	constant LATENCY: integer := 30;
	signal clkp: std_logic := '0';

begin

	clkp <= not clkp after CLKP_HALFPERIOD;
	
	qplllock_out <= '1';
	cplllock_out <= (others => '1');
	common_drp_data_out <= (others => '0');
	common_drp_ready_out <= '0';
	prbs_error_out <= (others => '0');

	
	rxusrclk_out <= (others => clkp);
	txusrclk_out <= (others => clkp);
	rxusrrst_out <= rx_fsm_reset_in;
	txusrrst_out <= tx_fsm_reset_in;
	
	txn_out <= (others => '1');
	txp_out <= (others => '0');
	
	chan_drp_data_out <= (others => (others => '0'));
	chan_drp_ready_out <= (others => '0');

	tx_fsm_reset_done_out <= not tx_fsm_reset_in;
	rx_fsm_reset_done_out <= not rx_fsm_reset_in;
	
	txoutclk_out <= (others => clkp);

	gen: for i in 3 downto 0 generate
	
		type ddel_t is array(LATENCY downto 0) of std_logic_vector(15 downto 0);
		signal ddel: ddel_t;
		type kdel_t is array(LATENCY downto 0) of std_logic_vector(1 downto 0);
		signal kdel: kdel_t; 
		
	begin

		ddel(0) <= txdata_in(i) when loopback_in(i) = "010" else (others => '0');
		kdel(0) <= txcharisk_in(i) when loopback_in(i) = "010" else "00"	;
	
		process(clkp)
		begin
			if rising_edge(clkp) then
				ddel(LATENCY downto 1) <= ddel(LATENCY - 1 downto 0);
				kdel(LATENCY downto 1) <= kdel(LATENCY - 1 downto 0);
			end if;
		end process;

		rxdata_out(i) <= ddel(LATENCY);
		rxcharisk_out(i) <= kdel(LATENCY);
		rx_comma_det_out(i) <= '1' when ddel(LATENCY) = X"50BC" and kdel(LATENCY) = "01" else '0';
		
	end generate;			

	rxcdrlock_out <= (others => '1');
	rxchariscomma_out <= (others => (others => '0'));
	rxbyteisaligned_out <= (others => '1');

end behavioural;
