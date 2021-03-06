library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

use work.package_links.all;
use work.package_utilities.all;


entity gth_quad_wrapper_8b10bx16b_xi_5g is
generic
(
    -- Simulation attributes
    SIMULATION                      : integer   := 0;           -- Set to 1 for simulation
    SIM_GTRESET_SPEEDUP             : string    := "FALSE";     -- Set to "true" to speed up sim reset
    -- Configuration
    STABLE_CLOCK_PERIOD             : integer   := 32;          -- Period of the stable clock driving this state-machine, unit is [ns] 
    LINE_RATE                       : real		  := 5.0;        -- gb/s
    REFERENCE_CLOCK_RATE            : real      := 125.0;         -- mhz
    PRBS_MODE                       : string    := "PRBS-7";
    PLL                             : string;
    -- Placement information
    X_LOC                           : integer 	:= 0;
    Y_LOC                           : integer 	:= 0
);
port
(
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



end gth_quad_wrapper_8b10bx16b_xi_5g;




architecture RTL of gth_quad_wrapper_8b10bx16b_xi_5g is

  function get_cdrlock_time(is_sim : in integer) return integer is
    variable lock_time: integer;
  begin
    if (is_sim = 1) then
      lock_time := 1000;
    else
      lock_time := 50000 / integer(5); --Typical CDR lock time is 50,000UI as per DS183
    end if;
    return lock_time;
  end function;

  constant DLY : time := 1 ns;
  constant RX_CDRLOCK_TIME : integer := get_cdrlock_time(SIMULATION);       -- 200us
  constant WAIT_TIME_CDRLOCK : integer := RX_CDRLOCK_TIME / STABLE_CLOCK_PERIOD;      -- 200 us time-out
  constant DONT_RESET_ON_DATA_ERROR : std_logic := '0';

  signal    txoutclk, rxoutclk : std_logic_vector(3 downto 0); 
  signal    txusrclk, rxusrclk : std_logic_vector(3 downto 0); 
  signal    txusrclk2, rxusrclk2 : std_logic_vector(3 downto 0); 

  attribute keep: string;  
  attribute keep of txusrclk : signal is "true";
  attribute keep of txusrclk2 : signal is "true";
  attribute keep of rxusrclk : signal is "true";
  attribute keep of rxusrclk2 : signal is "true";
	attribute keep of txoutclk : signal is "true";
  attribute keep of rxoutclk : signal is "true";

  signal cpllreset, cpllrefclklost, cplllock : std_logic_vector(3 downto 0); 
  signal txresetdone, rxresetdone : std_logic_vector(3 downto 0); 
  signal gttxreset, gtrxreset : std_logic_vector(3 downto 0); 
  signal txuserrdy, rxuserrdy : std_logic_vector(3 downto 0); 
  signal rxdfeagchold, rxdfelfhold, rxlpmlfhold, rxlpmhfhold : std_logic_vector(3 downto 0); 
  signal rxcheck, rxbyteisaligned : std_logic_vector(3 downto 0); 
  signal rxdata : type_16b_data_array(3 downto 0);
  signal rxcharisk : type_16b_charisk_array(3 downto 0);
  signal tx_fsm_reset_done, rx_fsm_reset_done : std_logic_vector(3 downto 0);   
  signal recclk_stable : std_logic_vector(3 downto 0); 

  signal rx_cdrlock_counter : integer range 0 to WAIT_TIME_CDRLOCK:= 0 ;
  signal rx_cdrlocked : std_logic;

  signal tied_to_gnd, tied_to_vcc : std_logic;

  type type_prbssel_array is array (natural range <>) of std_logic_vector(2 downto 0);
  signal prbssel: type_prbssel_array(3 downto 0);
 
  

begin

    

    tied_to_gnd <= '0';
    tied_to_vcc <= '1';

    ----------------------------------------------------------------------------
    -- Clocking
    ----------------------------------------------------------------------------

    usrclk_source : entity work.usrclk_source
    port map
    (
      refclk_in                   =>      refclk_in,  
      txusrclk_out                =>      txusrclk,
      txusrclk2_out               =>      txusrclk2,
      txoutclk_in                 =>      txoutclk,
      rxusrclk_out                =>      rxusrclk,
      rxusrclk2_out               =>      rxusrclk2,
      rxoutclk_in                 =>      rxoutclk
    );

    ----------------------------------------------------------------------------
    -- Transceiver
    ----------------------------------------------------------------------------

    xilinx_gth_16b_5g_cpll_i : entity work.xilinx_gth_16b_5g_cpll
    generic map
    (
        EXAMPLE_SIMULATION              =>      SIMULATION,
        WRAPPER_SIM_GTRESET_SPEEDUP     =>      SIM_GTRESET_SPEEDUP
    )
    port map
    (
        ----------------------------------------------------------------------------
        -- GT0
        ----------------------------------------------------------------------------
        --------------------------------- CPLL Ports -------------------------------
        GT0_CPLLFBCLKLOST_OUT           =>      open,
        GT0_CPLLLOCK_OUT                =>      cplllock(0),
        GT0_CPLLLOCKDETCLK_IN           =>      sysclk_in,
        GT0_CPLLREFCLKLOST_OUT          =>      cpllrefclklost(0),
        GT0_CPLLRESET_IN                =>      cpllreset(0),
        -------------------------- Channel - Clocking Ports ------------------------
        GT0_GTREFCLK0_IN                =>      refclk_in,
        ---------------------------- Channel - DRP Ports  --------------------------
        GT0_DRPADDR_IN                  =>      chan_drp_address_in(0),
        GT0_DRPCLK_IN                   =>      drpclk_in,
        GT0_DRPDI_IN                    =>      chan_drp_data_in(0),
        GT0_DRPDO_OUT                   =>      chan_drp_data_out(0),
        GT0_DRPEN_IN                    =>      chan_drp_enable_in(0),
        GT0_DRPRDY_OUT                  =>      chan_drp_ready_out(0),
        GT0_DRPWE_IN                    =>      chan_drp_write_in(0),
        ------------------------------- Loopback Ports -----------------------------
        GT0_LOOPBACK_IN                 =>      loopback_in(0),
        --------------------- RX Initialization and Reset Ports --------------------
        GT0_RXUSERRDY_IN                =>      rxuserrdy(0),
        -------------------------- RX Margin Analysis Ports ------------------------
        GT0_EYESCANDATAERROR_OUT        =>      open,
        ------------------------- Receive Ports - CDR Ports ------------------------
        GT0_RXCDRLOCK_OUT               =>      rxcdrlock_out(0),
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        GT0_RXUSRCLK_IN                 =>      rxusrclk(0),
        GT0_RXUSRCLK2_IN                =>      rxusrclk2(0),
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        GT0_RXDATA_OUT                  =>      rxdata(0),
        ------------------- Receive Ports - Pattern Checker Ports ------------------
        GT0_RXPRBSERR_OUT               =>      prbs_error_out(0),
        GT0_RXPRBSSEL_IN                =>      prbssel(0),
        ------------------- Receive Ports - Pattern Checker ports ------------------
        GT0_RXPRBSCNTRESET_IN           =>      tied_to_gnd,
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        GT0_RXDISPERR_OUT               =>      open,
        GT0_RXNOTINTABLE_OUT            =>      open,
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        GT0_GTHRXN_IN                   =>      rxn_in(0),
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        GT0_RXBYTEISALIGNED_OUT         =>      rxbyteisaligned(0),
        GT0_RXCOMMADET_OUT              =>      rx_comma_det_out(0),
        GT0_RXMCOMMAALIGNEN_IN          =>      rxmcommaalignen_in(0),
        GT0_RXPCOMMAALIGNEN_IN          =>      rxpcommaalignen_in(0),
        -------------------- Receive Ports - RX Equailizer Ports -------------------
        GT0_RXLPMHFHOLD_IN              =>      rxlpmhfhold(0),
        GT0_RXLPMLFHOLD_IN              =>      rxlpmlfhold(0),
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        GT0_RXOUTCLK_OUT                =>      rxoutclk(0),
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        GT0_GTRXRESET_IN                =>      gtrxreset(0),
        GT0_RXPOLARITY_IN               =>      rxpolarity_in(0),
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        GT0_RXCHARISCOMMA_OUT           =>      rxchariscomma_out(0),
        GT0_RXCHARISK_OUT               =>      rxcharisk(0),
        ------------------------ Receive Ports -RX AFE Ports -----------------------
        GT0_GTHRXP_IN                   =>      rxp_in(0),
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        GT0_RXRESETDONE_OUT             =>      rxresetdone(0),
        --------------------- TX Initialization and Reset Ports --------------------
        GT0_GTTXRESET_IN                =>      gttxreset(0),
        GT0_TXUSERRDY_IN                =>      txuserrdy(0),
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        GT0_TXUSRCLK_IN                 =>      txusrclk(0),
        GT0_TXUSRCLK2_IN                =>      txusrclk2(0),
        ------------------ Transmit Ports - TX Data Path interface -----------------
        GT0_TXDATA_IN                   =>      txdata_in(0),
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GT0_GTHTXN_OUT                  =>      txn_out(0),
        GT0_GTHTXP_OUT                  =>      txp_out(0),
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        GT0_TXOUTCLK_OUT                =>      txoutclk(0),
        GT0_TXOUTCLKFABRIC_OUT          =>      open,
        GT0_TXOUTCLKPCS_OUT             =>      open,
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        GT0_TXRESETDONE_OUT             =>      txresetdone(0),
        ----------------- Transmit Ports - TX Polarity Control Ports ---------------
        GT0_TXPOLARITY_IN               =>      txpolarity_in(0),
        ------------------ Transmit Ports - pattern Generator Ports ----------------
        GT0_TXPRBSSEL_IN                =>      prbssel(0),
        ----------- Transmit Transmit Ports - 8b10b Encoder Control Ports ----------
        GT0_TXCHARISK_IN                =>      txcharisk_in(0),


        ----------------------------------------------------------------------------
        -- GT1
        ----------------------------------------------------------------------------
        --------------------------------- CPLL Ports -------------------------------
        GT1_CPLLFBCLKLOST_OUT           =>      open,
        GT1_CPLLLOCK_OUT                =>      cplllock(1),
        GT1_CPLLLOCKDETCLK_IN           =>      sysclk_in,
        GT1_CPLLREFCLKLOST_OUT          =>      cpllrefclklost(1),
        GT1_CPLLRESET_IN                =>      cpllreset(1),
        -------------------------- Channel - Clocking Ports ------------------------
        GT1_GTREFCLK0_IN                =>      refclk_in,
        ---------------------------- Channel - DRP Ports  --------------------------
        GT1_DRPADDR_IN                  =>      chan_drp_address_in(1),
        GT1_DRPCLK_IN                   =>      drpclk_in,
        GT1_DRPDI_IN                    =>      chan_drp_data_in(1),
        GT1_DRPDO_OUT                   =>      chan_drp_data_out(1),
        GT1_DRPEN_IN                    =>      chan_drp_enable_in(1),
        GT1_DRPRDY_OUT                  =>      chan_drp_ready_out(1),
        GT1_DRPWE_IN                    =>      chan_drp_write_in(1),
        ------------------------------- Loopback Ports -----------------------------
        GT1_LOOPBACK_IN                 =>      loopback_in(1),        
        --------------------- RX Initialization and Reset Ports --------------------
        GT1_RXUSERRDY_IN                =>      rxuserrdy(1),
        -------------------------- RX Margin Analysis Ports ------------------------
        GT1_EYESCANDATAERROR_OUT        =>      open,
        ------------------------- Receive Ports - CDR Ports ------------------------
        GT1_RXCDRLOCK_OUT               =>      rxcdrlock_out(1),
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        GT1_RXUSRCLK_IN                 =>      rxusrclk(1),
        GT1_RXUSRCLK2_IN                =>      rxusrclk2(1),
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        GT1_RXDATA_OUT                  =>      rxdata(1),
        ------------------- Receive Ports - Pattern Checker Ports ------------------
        GT1_RXPRBSERR_OUT               =>      prbs_error_out(1),
        GT1_RXPRBSSEL_IN                =>      prbssel(1),
        ------------------- Receive Ports - Pattern Checker ports ------------------
        GT1_RXPRBSCNTRESET_IN           =>      tied_to_gnd,
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        GT1_RXDISPERR_OUT               =>      open,
        GT1_RXNOTINTABLE_OUT            =>      open,
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        GT1_GTHRXN_IN                   =>      rxn_in(1),
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        GT1_RXBYTEISALIGNED_OUT         =>      rxbyteisaligned(1),
        GT1_RXCOMMADET_OUT              =>      rx_comma_det_out(1),
        GT1_RXMCOMMAALIGNEN_IN          =>      rxmcommaalignen_in(1),
        GT1_RXPCOMMAALIGNEN_IN          =>      rxpcommaalignen_in(1),
        -------------------- Receive Ports - RX Equailizer Ports -------------------
        GT1_RXLPMHFHOLD_IN              =>      rxlpmhfhold(1),
        GT1_RXLPMLFHOLD_IN              =>      rxlpmlfhold(1),
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        GT1_RXOUTCLK_OUT                =>      rxoutclk(1),
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        GT1_GTRXRESET_IN                =>      gtrxreset(1),
        GT1_RXPOLARITY_IN               =>      rxpolarity_in(1),
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        GT1_RXCHARISCOMMA_OUT           =>      rxchariscomma_out(1),
        GT1_RXCHARISK_OUT               =>      rxcharisk(1),
        ------------------------ Receive Ports -RX AFE Ports -----------------------
        GT1_GTHRXP_IN                   =>      rxp_in(1),
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        GT1_RXRESETDONE_OUT             =>      rxresetdone(1),
        --------------------- TX Initialization and Reset Ports --------------------
        GT1_GTTXRESET_IN                =>      gttxreset(1),
        GT1_TXUSERRDY_IN                =>      txuserrdy(1),
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        GT1_TXUSRCLK_IN                 =>      txusrclk(1),
        GT1_TXUSRCLK2_IN                =>      txusrclk2(1),
        ------------------ Transmit Ports - TX Data Path interface -----------------
        GT1_TXDATA_IN                   =>      txdata_in(1),
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GT1_GTHTXN_OUT                  =>      txn_out(1),
        GT1_GTHTXP_OUT                  =>      txp_out(1),
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        GT1_TXOUTCLK_OUT                =>      txoutclk(1),
        GT1_TXOUTCLKFABRIC_OUT          =>      open,
        GT1_TXOUTCLKPCS_OUT             =>      open,
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        GT1_TXRESETDONE_OUT             =>      txresetdone(1),
        ----------------- Transmit Ports - TX Polarity Control Ports ---------------
        GT1_TXPOLARITY_IN               =>      txpolarity_in(1),
        ------------------ Transmit Ports - pattern Generator Ports ----------------
        GT1_TXPRBSSEL_IN                =>      prbssel(1),
        ----------- Transmit Transmit Ports - 8b10b Encoder Control Ports ----------
        GT1_TXCHARISK_IN                =>      txcharisk_in(1),


        ----------------------------------------------------------------------------
        -- GT2
        ----------------------------------------------------------------------------  
        --------------------------------- CPLL Ports -------------------------------
        GT2_CPLLFBCLKLOST_OUT           =>      open,
        GT2_CPLLLOCK_OUT                =>      cplllock(2),
        GT2_CPLLLOCKDETCLK_IN           =>      sysclk_in,
        GT2_CPLLREFCLKLOST_OUT          =>      cpllrefclklost(2),
        GT2_CPLLRESET_IN                =>      cpllreset(2),
        -------------------------- Channel - Clocking Ports ------------------------
        GT2_GTREFCLK0_IN                =>      refclk_in,
        ---------------------------- Channel - DRP Ports  --------------------------
        GT2_DRPADDR_IN                  =>      chan_drp_address_in(2),
        GT2_DRPCLK_IN                   =>      drpclk_in,
        GT2_DRPDI_IN                    =>      chan_drp_data_in(2),
        GT2_DRPDO_OUT                   =>      chan_drp_data_out(2),
        GT2_DRPEN_IN                    =>      chan_drp_enable_in(2),
        GT2_DRPRDY_OUT                  =>      chan_drp_ready_out(2),
        GT2_DRPWE_IN                    =>      chan_drp_write_in(2),
        ------------------------------- Loopback Ports -----------------------------
        GT2_LOOPBACK_IN                 =>      loopback_in(2),
        --------------------- RX Initialization and Reset Ports --------------------
        GT2_RXUSERRDY_IN                =>      rxuserrdy(2),
        -------------------------- RX Margin Analysis Ports ------------------------
        GT2_EYESCANDATAERROR_OUT        =>      open,
        ------------------------- Receive Ports - CDR Ports ------------------------
        GT2_RXCDRLOCK_OUT               =>      rxcdrlock_out(2),
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        GT2_RXUSRCLK_IN                 =>      rxusrclk(2),
        GT2_RXUSRCLK2_IN                =>      rxusrclk2(2),
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        GT2_RXDATA_OUT                  =>      rxdata(2),
        ------------------- Receive Ports - Pattern Checker Ports ------------------
        GT2_RXPRBSERR_OUT               =>      prbs_error_out(2),
        GT2_RXPRBSSEL_IN                =>      prbssel(2),
        ------------------- Receive Ports - Pattern Checker ports ------------------
        GT2_RXPRBSCNTRESET_IN           =>      tied_to_gnd,
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        GT2_RXDISPERR_OUT               =>      open,
        GT2_RXNOTINTABLE_OUT            =>      open,
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        GT2_GTHRXN_IN                   =>      rxn_in(2),
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        GT2_RXBYTEISALIGNED_OUT         =>      rxbyteisaligned(2),
        GT2_RXCOMMADET_OUT              =>      rx_comma_det_out(2),
        GT2_RXMCOMMAALIGNEN_IN          =>      rxmcommaalignen_in(2),
        GT2_RXPCOMMAALIGNEN_IN          =>      rxpcommaalignen_in(2),
        -------------------- Receive Ports - RX Equailizer Ports -------------------
        GT2_RXLPMHFHOLD_IN              =>      rxlpmhfhold(2),
        GT2_RXLPMLFHOLD_IN              =>      rxlpmlfhold(2),
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        GT2_RXOUTCLK_OUT                =>      rxoutclk(2),
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        GT2_GTRXRESET_IN                =>      gtrxreset(2),
        GT2_RXPOLARITY_IN               =>      rxpolarity_in(2),
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        GT2_RXCHARISCOMMA_OUT           =>      rxchariscomma_out(2),
        GT2_RXCHARISK_OUT               =>      rxcharisk(2),
        ------------------------ Receive Ports -RX AFE Ports -----------------------
        GT2_GTHRXP_IN                   =>      rxp_in(2),
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        GT2_RXRESETDONE_OUT             =>      rxresetdone(2),
        --------------------- TX Initialization and Reset Ports --------------------
        GT2_GTTXRESET_IN                =>      gttxreset(2),
        GT2_TXUSERRDY_IN                =>      txuserrdy(2),
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        GT2_TXUSRCLK_IN                 =>      txusrclk(2),
        GT2_TXUSRCLK2_IN                =>      txusrclk2(2),
        ------------------ Transmit Ports - TX Data Path interface -----------------
        GT2_TXDATA_IN                   =>      txdata_in(2),
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GT2_GTHTXN_OUT                  =>      txn_out(2),
        GT2_GTHTXP_OUT                  =>      txp_out(2),
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        GT2_TXOUTCLK_OUT                =>      txoutclk(2),
        GT2_TXOUTCLKFABRIC_OUT          =>      open,
        GT2_TXOUTCLKPCS_OUT             =>      open,
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        GT2_TXRESETDONE_OUT             =>      txresetdone(2),
        ----------------- Transmit Ports - TX Polarity Control Ports ---------------
        GT2_TXPOLARITY_IN               =>      txpolarity_in(2),
        ------------------ Transmit Ports - pattern Generator Ports ----------------
        GT2_TXPRBSSEL_IN                =>      prbssel(2),
        ----------- Transmit Transmit Ports - 8b10b Encoder Control Ports ----------
        GT2_TXCHARISK_IN                =>      txcharisk_in(2),

  
        ----------------------------------------------------------------------------
        -- GT3
        ----------------------------------------------------------------------------
        --------------------------------- CPLL Ports -------------------------------
        GT3_CPLLFBCLKLOST_OUT           =>      open,
        GT3_CPLLLOCK_OUT                =>      cplllock(3),
        GT3_CPLLLOCKDETCLK_IN           =>      sysclk_in,
        GT3_CPLLREFCLKLOST_OUT          =>      cpllrefclklost(3),
        GT3_CPLLRESET_IN                =>      cpllreset(3),
        -------------------------- Channel - Clocking Ports ------------------------
        GT3_GTREFCLK0_IN                =>      refclk_in,
        ---------------------------- Channel - DRP Ports  --------------------------
        GT3_DRPADDR_IN                  =>      chan_drp_address_in(3),
        GT3_DRPCLK_IN                   =>      drpclk_in,
        GT3_DRPDI_IN                    =>      chan_drp_data_in(3),
        GT3_DRPDO_OUT                   =>      chan_drp_data_out(3),
        GT3_DRPEN_IN                    =>      chan_drp_enable_in(3),
        GT3_DRPRDY_OUT                  =>      chan_drp_ready_out(3),
        GT3_DRPWE_IN                    =>      chan_drp_write_in(3),
        ------------------------------- Loopback Ports -----------------------------
        GT3_LOOPBACK_IN                 =>      loopback_in(3),
        --------------------- RX Initialization and Reset Ports --------------------
        GT3_RXUSERRDY_IN                =>      rxuserrdy(3),
        -------------------------- RX Margin Analysis Ports ------------------------
        GT3_EYESCANDATAERROR_OUT        =>      open,
        ------------------------- Receive Ports - CDR Ports ------------------------
        GT3_RXCDRLOCK_OUT               =>      rxcdrlock_out(3),
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        GT3_RXUSRCLK_IN                 =>      rxusrclk(3),
        GT3_RXUSRCLK2_IN                =>      rxusrclk2(3),
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        GT3_RXDATA_OUT                  =>      rxdata(3),
        ------------------- Receive Ports - Pattern Checker Ports ------------------
        GT3_RXPRBSERR_OUT               =>      prbs_error_out(3),
        GT3_RXPRBSSEL_IN                =>      prbssel(3),
        ------------------- Receive Ports - Pattern Checker ports ------------------
        GT3_RXPRBSCNTRESET_IN           =>      tied_to_gnd,
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        GT3_RXDISPERR_OUT               =>      open,
        GT3_RXNOTINTABLE_OUT            =>      open,
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        GT3_GTHRXN_IN                   =>      rxn_in(3),
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        GT3_RXBYTEISALIGNED_OUT         =>      rxbyteisaligned(3),
        GT3_RXCOMMADET_OUT              =>      rx_comma_det_out(3),
        GT3_RXMCOMMAALIGNEN_IN          =>      rxmcommaalignen_in(3),
        GT3_RXPCOMMAALIGNEN_IN          =>      rxpcommaalignen_in(3),
        -------------------- Receive Ports - RX Equailizer Ports -------------------
        GT3_RXLPMHFHOLD_IN              =>      rxlpmhfhold(3),
        GT3_RXLPMLFHOLD_IN              =>      rxlpmlfhold(3),
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        GT3_RXOUTCLK_OUT                =>      rxoutclk(3),
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        GT3_GTRXRESET_IN                =>      gtrxreset(3),
        GT3_RXPOLARITY_IN               =>      rxpolarity_in(3),
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        GT3_RXCHARISCOMMA_OUT           =>      rxchariscomma_out(3),
        GT3_RXCHARISK_OUT               =>      rxcharisk(3),
        ------------------------ Receive Ports -RX AFE Ports -----------------------
        GT3_GTHRXP_IN                   =>      rxp_in(3),
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        GT3_RXRESETDONE_OUT             =>      rxresetdone(3),
        --------------------- TX Initialization and Reset Ports --------------------
        GT3_GTTXRESET_IN                =>      gttxreset(3),
        GT3_TXUSERRDY_IN                =>      txuserrdy(3),
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        GT3_TXUSRCLK_IN                 =>      txusrclk(3),
        GT3_TXUSRCLK2_IN                =>      txusrclk2(3),
        ------------------ Transmit Ports - TX Data Path interface -----------------
        GT3_TXDATA_IN                   =>      txdata_in(3),
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GT3_GTHTXN_OUT                  =>      txn_out(3),
        GT3_GTHTXP_OUT                  =>      txp_out(3),
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        GT3_TXOUTCLK_OUT                =>      txoutclk(3),
        GT3_TXOUTCLKFABRIC_OUT          =>      open,
        GT3_TXOUTCLKPCS_OUT             =>      open,
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        GT3_TXRESETDONE_OUT             =>      txresetdone(3),
        ----------------- Transmit Ports - TX Polarity Control Ports ---------------
        GT3_TXPOLARITY_IN               =>      txpolarity_in(3),
        ------------------ Transmit Ports - pattern Generator Ports ----------------
        GT3_TXPRBSSEL_IN                =>      prbssel(3),
        ----------- Transmit Transmit Ports - 8b10b Encoder Control Ports ----------
        GT3_TXCHARISK_IN                =>      txcharisk_in(3),


        ----------------------------------------------------------------------------
        -- GT COMMON - Try & disable it
        ----------------------------------------------------------------------------
        ---------------------- Common Block  - Ref Clock Ports ---------------------
        GT0_GTREFCLK0_COMMON_IN         =>      refclk_in,
        ------------------------- Common Block - QPLL Ports ------------------------
        GT0_QPLLLOCK_OUT                =>      open,
        GT0_QPLLLOCKDETCLK_IN           =>      tied_to_gnd,
        GT0_QPLLREFCLKLOST_OUT          =>      open,
        GT0_QPLLRESET_IN                =>      tied_to_gnd

    );

  ----------------------------------------------------------------------------
  -- Loop over Rx & Tx startyup state machines for all channels
  ----------------------------------------------------------------------------

  rxbyteisaligned_out <= rxbyteisaligned;
  rxcharisk_out <= rxcharisk;
  rxdata_out <= rxdata;
  txoutclk_out <= txoutclk;     
  txusrclk_out <= txusrclk;      
  rxusrclk_out <= rxusrclk;      
  tx_fsm_reset_done_out <= tx_fsm_reset_done;
  rx_fsm_reset_done_out <= rx_fsm_reset_done;

  chan: for j in 0 to 3 generate
  
    recclk_stable(j) <= rx_cdrlocked;
    txusrrst_out(j) <= (not tx_fsm_reset_done(j)) or soft_reset_in;      
    rxusrrst_out(j) <= (not rx_fsm_reset_done(j)) or soft_reset_in;  
    
      
    -- Use PRBS-7 only : "001"
    prbssel(j) <= "001" when prbs_enable_in(j) = '1' else "000";

    txresetfsm_i:  entity work.xilinx_gth_16b_5g_cpll_TX_STARTUP_FSM 
      generic map(
        GT_TYPE                  => "GTH", --GTX or GTH or GTP
        STABLE_CLOCK_PERIOD      => STABLE_CLOCK_PERIOD,           -- Period of the stable clock driving this state-machine, unit is [ns]
        RETRY_COUNTER_BITWIDTH   => 8, 
        TX_QPLL_USED             => FALSE ,                       -- the TX and RX Reset FSMs must
        RX_QPLL_USED             => FALSE,                        -- share these two generic values
        PHASE_ALIGNMENT_MANUAL   => FALSE                         -- Decision if a manual phase-alignment is necessary or the automatic 
                                                                         -- is enough. For single-lane applications the automatic alignment is sufficient              
      )     
      port map ( 
        STABLE_CLOCK                    =>      sysclk_in,
        TXUSERCLK                       =>      txusrclk(0),
        SOFT_RESET                      =>      soft_reset_in,
        QPLLREFCLKLOST                  =>      tied_to_gnd,
        CPLLREFCLKLOST                  =>      cpllrefclklost(j),
        QPLLLOCK                        =>      tied_to_vcc,
        CPLLLOCK                        =>      cplllock(j),
        TXRESETDONE                     =>      txresetdone(j),
        MMCM_LOCK                       =>      tied_to_vcc,
        GTTXRESET                       =>      gttxreset(j),
        MMCM_RESET                      =>      open,
        QPLL_RESET                      =>      open,
        CPLL_RESET                      =>      cpllreset(j),
        TX_FSM_RESET_DONE               =>      tx_fsm_reset_done(j),
        TXUSERRDY                       =>      txuserrdy(j),
        RUN_PHALIGNMENT                 =>      open,
        RESET_PHALIGNMENT               =>      open,
        PHALIGNMENT_DONE                =>      tied_to_vcc,
        RETRY_COUNTER                   =>      open
      );
       
    rxresetfsm_i:  entity work.xilinx_gth_16b_5g_cpll_RX_STARTUP_FSM 
      generic map(
        EXAMPLE_SIMULATION       => SIMULATION,
        GT_TYPE                  => "GTH", --GTX or GTH or GTP
        EQ_MODE                  => "LPM",                 --Rx Equalization Mode - Set to DFE or LPM
        STABLE_CLOCK_PERIOD      => STABLE_CLOCK_PERIOD,           --Period of the stable clock driving this state-machine, unit is [ns]
        RETRY_COUNTER_BITWIDTH   => 8, 
        TX_QPLL_USED             => FALSE ,                       -- the TX and RX Reset FSMs must
        RX_QPLL_USED             => FALSE,                        -- share these two generic values
        PHASE_ALIGNMENT_MANUAL   =>  FALSE                        -- Decision if a manual phase-alignment is necessary or the automatic 
                                                                 -- is enough. For single-lane applications the automatic alignment is sufficient              
      )     
      port map ( 
        STABLE_CLOCK                    =>      sysclk_in,
        RXUSERCLK                       =>      rxusrclk(j),
        SOFT_RESET                      =>      soft_reset_in,
        DONT_RESET_ON_DATA_ERROR        =>      DONT_RESET_ON_DATA_ERROR,
        QPLLREFCLKLOST                  =>      tied_to_gnd,
        CPLLREFCLKLOST                  =>      cpllrefclklost(j),
        QPLLLOCK                        =>      tied_to_vcc,
        CPLLLOCK                        =>      cplllock(j),
        RXRESETDONE                     =>      rxresetdone(j),
        MMCM_LOCK                       =>      tied_to_vcc,
        RECCLK_STABLE                   =>      recclk_stable(j),
        RECCLK_MONITOR_RESTART          =>      tied_to_gnd,
        DATA_VALID                      =>      rxcheck(j),
        TXUSERRDY                       =>      tied_to_vcc,
        GTRXRESET                       =>      gtrxreset(j),
        MMCM_RESET                      =>      open,
        QPLL_RESET                      =>      open,
        CPLL_RESET                      =>      open,
        RX_FSM_RESET_DONE               =>      rx_fsm_reset_done(j),
        RXUSERRDY                       =>      rxuserrdy(j),
        RUN_PHALIGNMENT                 =>      open,
        RESET_PHALIGNMENT               =>      open,
        PHALIGNMENT_DONE                =>      tied_to_vcc,
        RXDFEAGCHOLD                    =>      rxdfeagchold(j),
        RXDFELFHOLD                     =>      rxdfelfhold(j),
        RXLPMLFHOLD                     =>      rxlpmlfhold(j),
        RXLPMHFHOLD                     =>      rxlpmhfhold(j),
        RETRY_COUNTER                   =>      open
      );
      
      
    check: entity work.data_check_8b10b
      port map (
        rx_usr_clk_in => rxusrclk(j),
        rx_byte_is_aligned_in => rxbyteisaligned(j),
        rx_data_in => rxdata(j),
        rx_char_is_k_in => rxcharisk(j),
        data_check_out => rxcheck(j));
        
  end generate;
  

  ----------------------------------------------------------------------------
  -- COMMON
  ----------------------------------------------------------------------------
  
  qplllock_out <= tied_to_gnd;
  cplllock_out <= cplllock;

  cdrlock_timeout:process(sysclk_in)
  begin
    if rising_edge(sysclk_in) then
        if(gtrxreset(0) = '1') then
          rx_cdrlocked       <= '0';
          rx_cdrlock_counter <=  0                        after DLY;
        elsif (rx_cdrlock_counter = WAIT_TIME_CDRLOCK) then
          rx_cdrlocked       <= '1';
          rx_cdrlock_counter <= rx_cdrlock_counter        after DLY;
        else
          rx_cdrlock_counter <= rx_cdrlock_counter + 1    after DLY;
        end if;
    end if;
  end process;


end RTL;
