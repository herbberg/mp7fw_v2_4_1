library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library unisim;
use unisim.vcomponents.all;

use work.package_links.all;
use work.package_utilities.all;


entity gth_quad_wrapper_calotest is
generic
(
    -- Simulation attributes
    SIMULATION                      : integer   := 0;           -- Set to 1 for simulation
    SIM_GTRESET_SPEEDUP             : string    := "FALSE";     -- Set to "true" to speed up sim reset
    -- Configuration
    STABLE_CLOCK_PERIOD             : integer   := 32          -- Period of the stable clock driving this state-machine, unit is [ns] 
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
    txdata_in                          : in type_16b_data_array(3 downto 0);
    txcharisk_in                       : in type_16b_charisk_array(3 downto 0);
  
  -- Rx signals 
    rx_comma_det_out                   : out   std_logic_vector(3 downto 0);
    rxpolarity_in                      : in  std_logic_vector(3 downto 0);
    rxcdrlock_out                      : out  std_logic_vector(3 downto 0);
    rxdata_out                         : out type_32b_data_array(3 downto 0);
    rxcharisk_out                      : out type_32b_charisk_array(3 downto 0);
    rxchariscomma_out                  : out type_32b_chariscomma_array(3 downto 0);
    rxbyteisaligned_out                : out std_logic_vector(3 downto 0);
    rxpcommaalignen_in                : in std_logic_vector(3 downto 0);
    rxmcommaalignen_in                : in std_logic_vector(3 downto 0)
);



end gth_quad_wrapper_calotest;




architecture RTL of gth_quad_wrapper_calotest is

  function get_cdrlock_time(is_sim : in integer) return integer is
    variable lock_time: integer;
  begin
    if (is_sim = 1) then
      lock_time := 1000;
    else
      lock_time := 50000 / integer(3); --Typical CDR lock time is 50,000UI as per DS183
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

  -- Be very careful here.  It is easy to accidently force a LUT into the clk
  -- net so that the net can be slit into two parts for naming reasons.
  attribute keep: string;  
  --attribute keep of txusrclk : signal is "true";
  --attribute keep of txusrclk2 : signal is "true";
  attribute keep of rxusrclk : signal is "true";
  --attribute keep of rxusrclk2 : signal is "true";
  --attribute keep of txoutclk : signal is "true";
  --attribute keep of rxoutclk : signal is "true";

  signal cpllreset, cplllock : std_logic_vector(3 downto 0); 
  signal txresetdone, rxresetdone : std_logic_vector(3 downto 0); 
  signal gttxreset, gtrxreset : std_logic_vector(3 downto 0); 
  signal txuserrdy, rxuserrdy : std_logic_vector(3 downto 0); 
  signal rxdfeagchold, rxdfelfhold, rxlpmlfhold, rxlpmhfhold : std_logic_vector(3 downto 0); 
  signal rxcheck, rxbyteisaligned : std_logic_vector(3 downto 0); 
  signal rxdata : type_32b_data_array(3 downto 0);
  signal rxcharisk : type_32b_charisk_array(3 downto 0);
  signal tx_fsm_reset_done, rx_fsm_reset_done : std_logic_vector(3 downto 0);   

  signal rx_cdrlock_counter : integer range 0 to WAIT_TIME_CDRLOCK:= 0 ;
  signal rx_cdrlocked : std_logic;

  signal tied_to_gnd, tied_to_vcc : std_logic;

  type type_prbssel_array is array (natural range <>) of std_logic_vector(2 downto 0);
  signal prbssel: type_prbssel_array(3 downto 0);
  
  signal qplllock, qpllrefclklost, qpllresetrequestor, qplloutclk, qplloutrefclk, qpllreset : std_logic;
  signal qpllresetrequest : std_logic_vector(3 downto 0);   
  signal commonreset : std_logic;
  
  

begin

  
  
  tied_to_gnd <= '0';
  tied_to_vcc <= '1';
  
  ----------------------------------------------------------------------------
  -- Clocking
  ----------------------------------------------------------------------------
  
  -- Drive txusrclk_out(x) from txoutclk_in(0) (i.e. 250MHz)
  -- Drive rxusrclk_out(x) from rxoutclk_in(x) (i.e. 240MHz for 4.8g link, 320MHz for 6.4g link)
  
  usrclk_source : entity work.usrclk_source_calo
  port map
  (
    refclk_in                   =>  '0',  -- Not used.  Should be removed
    txusrclk_out                =>  txusrclk,
    txusrclk2_out               =>  txusrclk2, 
    txoutclk_in                 =>  txoutclk,
    rxusrclk_out                =>  rxusrclk,
    rxusrclk2_out               =>  rxusrclk2,
    rxoutclk_in                 =>  rxoutclk
  );
  
  ----------------------------------------------------------------------------
  -- 4.8Gb/s Transceiver
  ----------------------------------------------------------------------------
  
  -- These ports are available for use with chipscope
  -- When chipscope = 0 they are disabled. 
  cpllreset <= (others => '0');
  gttxreset <= (others => '0'); 
  gtrxreset <= (others => '0');
  txuserrdy <= (others => '0'); 
  rxuserrdy <= (others => '0');
  
  gt_4g8: for i in 0 to 1 generate
  begin
    
    rxcdrlock_out(i) <= '1';
  
    chan_gth_calotest_4g8_i : entity work.chan_gth_calotest_4g8
    port map
    (
    
        SYSCLK_IN                       =>      sysclk_in,
        SOFT_RESET_IN                   =>      soft_reset_in,
        DONT_RESET_ON_DATA_ERROR_IN     =>      DONT_RESET_ON_DATA_ERROR,
        ----------------------------------------------------------------------------
        -- GT0
        ----------------------------------------------------------------------------
        GT0_TX_FSM_RESET_DONE_OUT       =>      tx_fsm_reset_done(i),
        GT0_RX_FSM_RESET_DONE_OUT       =>      rx_fsm_reset_done(i),
        GT0_DATA_VALID_IN               =>      rxcheck(i),
        --------------------------------- CPLL Ports -------------------------------
        GT0_CPLLFBCLKLOST_OUT           =>      open,
        GT0_CPLLLOCK_OUT                =>      cplllock(i),
        GT0_CPLLLOCKDETCLK_IN           =>      sysclk_in,
        GT0_CPLLRESET_IN                =>      cpllreset(i),
        -------------------------- Channel - Clocking Ports ------------------------
        GT0_GTREFCLK0_IN                =>      refclk1_in,
        ---------------------------- Channel - DRP Ports  --------------------------
        GT0_DRPADDR_IN                  =>      chan_drp_address_in(i),
        GT0_DRPCLK_IN                   =>      drpclk_in,
        GT0_DRPDI_IN                    =>      chan_drp_data_in(i),
        GT0_DRPDO_OUT                   =>      chan_drp_data_out(i),
        GT0_DRPEN_IN                    =>      chan_drp_enable_in(i),
        GT0_DRPRDY_OUT                  =>      chan_drp_ready_out(i),
        GT0_DRPWE_IN                    =>      chan_drp_write_in(i),
        ------------------------------- Loopback Ports -----------------------------
        GT0_LOOPBACK_IN                 =>      loopback_in(i),
        --------------------- RX Initialization and Reset Ports --------------------
        GT0_EYESCANRESET_IN             =>      '0',
        GT0_RXUSERRDY_IN                =>      rxuserrdy(i),
        -------------------------- RX Margin Analysis Ports ------------------------
        GT0_EYESCANDATAERROR_OUT        =>      open,
        GT0_EYESCANTRIGGER_IN           =>      '0',
        ------------------- Receive Ports - Digital Monitor Ports ------------------
        GT0_DMONITOROUT_OUT             =>      open,
        ------------------------- Receive Ports - CDR Ports ------------------------
        --GT0_RXCDRLOCK_OUT               =>      rxcdrlock_out(i),
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        GT0_RXUSRCLK_IN                 =>      rxusrclk(i),
        GT0_RXUSRCLK2_IN                =>      rxusrclk2(i),
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        GT0_RXDATA_OUT                  =>      rxdata(i),
        ------------------- Receive Ports - Pattern Checker Ports ------------------
        GT0_RXPRBSERR_OUT               =>      prbs_error_out(i),
        GT0_RXPRBSSEL_IN                =>      prbssel(i),
        ------------------- Receive Ports - Pattern Checker ports ------------------
        GT0_RXPRBSCNTRESET_IN           =>      tied_to_gnd,
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        GT0_RXDISPERR_OUT               =>      open,
        GT0_RXNOTINTABLE_OUT            =>      open,
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        GT0_GTHRXN_IN                   =>      rxn_in(i),
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        GT0_RXBYTEISALIGNED_OUT         =>      rxbyteisaligned(i),
        GT0_RXCOMMADET_OUT              =>      rx_comma_det_out(i),
        GT0_RXMCOMMAALIGNEN_IN          =>      rxmcommaalignen_in(i),
        GT0_RXPCOMMAALIGNEN_IN          =>      rxpcommaalignen_in(i),
        --------------------- Receive Ports - RX Equalizer Ports -------------------
        GT0_RXMONITOROUT_OUT            =>      open,
        GT0_RXMONITORSEL_IN             =>      "00",
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        GT0_RXOUTCLK_OUT                =>      rxoutclk(i),
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        GT0_GTRXRESET_IN                =>      gtrxreset(i),
        GT0_RXPOLARITY_IN               =>      rxpolarity_in(i),
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        GT0_RXCHARISCOMMA_OUT           =>      rxchariscomma_out(i),
        GT0_RXCHARISK_OUT               =>      rxcharisk(i),
        ------------------------ Receive Ports -RX AFE Ports -----------------------
        GT0_GTHRXP_IN                   =>      rxp_in(i),
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        GT0_RXRESETDONE_OUT             =>      rxresetdone(i),
        --------------------- TX Initialization and Reset Ports --------------------
        GT0_GTTXRESET_IN                =>      gttxreset(i),
        GT0_TXUSERRDY_IN                =>      txuserrdy(i),
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        GT0_TXUSRCLK_IN                 =>      txusrclk(i),
        GT0_TXUSRCLK2_IN                =>      txusrclk2(i),
        ------------------ Transmit Ports - TX Data Path interface -----------------
        GT0_TXDATA_IN                   =>      txdata_in(i),
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GT0_GTHTXN_OUT                  =>      txn_out(i),
        GT0_GTHTXP_OUT                  =>      txp_out(i),
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        GT0_TXOUTCLK_OUT                =>      txoutclk(i),
        GT0_TXOUTCLKFABRIC_OUT          =>      open,
        GT0_TXOUTCLKPCS_OUT             =>      open,
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        GT0_TXRESETDONE_OUT             =>      txresetdone(i),
        ----------------- Transmit Ports - TX Polarity Control Ports ---------------
        GT0_TXPOLARITY_IN               =>      txpolarity_in(i),
        ------------------ Transmit Ports - pattern Generator Ports ----------------
        GT0_TXPRBSSEL_IN                =>      prbssel(i),
        ----------- Transmit Transmit Ports - 8b10b Encoder Control Ports ----------
        GT0_TXCHARISK_IN                =>      txcharisk_in(i),
        ------------------------- Common Block - QPLL Ports ------------------------
        GT0_QPLLLOCK_IN                  =>       qplllock,
        GT0_QPLLREFCLKLOST_IN            =>       qpllrefclklost,
        GT0_QPLLRESET_OUT                =>       qpllresetrequest(i),
        GT0_QPLLOUTCLK_IN                =>       qplloutclk,
        GT0_QPLLOUTREFCLK_IN             =>       qplloutrefclk 
      );
      
  end generate;


 gt_6g4: for i in 2 to 3 generate
  begin
    
    rxcdrlock_out(i) <= '1';
  
    chan_gth_calotest_6g4_i : entity work.chan_gth_calotest_6g4
    port map
    (
    
        SYSCLK_IN                       =>      sysclk_in,
        SOFT_RESET_IN                   =>      soft_reset_in,
        DONT_RESET_ON_DATA_ERROR_IN     =>      DONT_RESET_ON_DATA_ERROR,
        ----------------------------------------------------------------------------
        -- GT0
        ----------------------------------------------------------------------------
        GT0_TX_FSM_RESET_DONE_OUT       =>      tx_fsm_reset_done(i),
        GT0_RX_FSM_RESET_DONE_OUT       =>      rx_fsm_reset_done(i),
        GT0_DATA_VALID_IN               =>      rxcheck(i),
        --------------------------------- CPLL Ports -------------------------------
        GT0_CPLLFBCLKLOST_OUT           =>      open,
        GT0_CPLLLOCK_OUT                =>      cplllock(i),
        GT0_CPLLLOCKDETCLK_IN           =>      sysclk_in,
        GT0_CPLLRESET_IN                =>      cpllreset(i),
        -------------------------- Channel - Clocking Ports ------------------------
        GT0_GTREFCLK0_IN                =>      refclk1_in,
        ---------------------------- Channel - DRP Ports  --------------------------
        GT0_DRPADDR_IN                  =>      chan_drp_address_in(i),
        GT0_DRPCLK_IN                   =>      drpclk_in,
        GT0_DRPDI_IN                    =>      chan_drp_data_in(i),
        GT0_DRPDO_OUT                   =>      chan_drp_data_out(i),
        GT0_DRPEN_IN                    =>      chan_drp_enable_in(i),
        GT0_DRPRDY_OUT                  =>      chan_drp_ready_out(i),
        GT0_DRPWE_IN                    =>      chan_drp_write_in(i),
        ------------------------------- Loopback Ports -----------------------------
        GT0_LOOPBACK_IN                 =>      loopback_in(i),
        --------------------- RX Initialization and Reset Ports --------------------
        GT0_EYESCANRESET_IN             =>      '0',
        GT0_RXUSERRDY_IN                =>      rxuserrdy(i),
        -------------------------- RX Margin Analysis Ports ------------------------
        GT0_EYESCANDATAERROR_OUT        =>      open,
        GT0_EYESCANTRIGGER_IN           =>      '0',
        ------------------- Receive Ports - Digital Monitor Ports ------------------
        GT0_DMONITOROUT_OUT             =>      open,
        ------------------------- Receive Ports - CDR Ports ------------------------
        --GT0_RXCDRLOCK_OUT               =>      rxcdrlock_out(i),
        ------------------ Receive Ports - FPGA RX Interface Ports -----------------
        GT0_RXUSRCLK_IN                 =>      rxusrclk(i),
        GT0_RXUSRCLK2_IN                =>      rxusrclk2(i),
        ------------------ Receive Ports - FPGA RX interface Ports -----------------
        GT0_RXDATA_OUT                  =>      rxdata(i),
        ------------------- Receive Ports - Pattern Checker Ports ------------------
        GT0_RXPRBSERR_OUT               =>      prbs_error_out(i),
        GT0_RXPRBSSEL_IN                =>      prbssel(i),
        ------------------- Receive Ports - Pattern Checker ports ------------------
        GT0_RXPRBSCNTRESET_IN           =>      tied_to_gnd,
        ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
        GT0_RXDISPERR_OUT               =>      open,
        GT0_RXNOTINTABLE_OUT            =>      open,
        ------------------------ Receive Ports - RX AFE Ports ----------------------
        GT0_GTHRXN_IN                   =>      rxn_in(i),
        -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
        GT0_RXBYTEISALIGNED_OUT         =>      rxbyteisaligned(i),
        GT0_RXCOMMADET_OUT              =>      rx_comma_det_out(i),
        GT0_RXMCOMMAALIGNEN_IN          =>      rxmcommaalignen_in(i),
        GT0_RXPCOMMAALIGNEN_IN          =>      rxpcommaalignen_in(i),
        --------------------- Receive Ports - RX Equalizer Ports -------------------
        GT0_RXMONITOROUT_OUT            =>      open,
        GT0_RXMONITORSEL_IN             =>      "00",
        --------------- Receive Ports - RX Fabric Output Control Ports -------------
        GT0_RXOUTCLK_OUT                =>      rxoutclk(i),
        ------------- Receive Ports - RX Initialization and Reset Ports ------------
        GT0_GTRXRESET_IN                =>      gtrxreset(i),
        GT0_RXPOLARITY_IN               =>      rxpolarity_in(i),
        ------------------- Receive Ports - RX8B/10B Decoder Ports -----------------
        GT0_RXCHARISCOMMA_OUT           =>      rxchariscomma_out(i),
        GT0_RXCHARISK_OUT               =>      rxcharisk(i),
        ------------------------ Receive Ports -RX AFE Ports -----------------------
        GT0_GTHRXP_IN                   =>      rxp_in(i),
        -------------- Receive Ports -RX Initialization and Reset Ports ------------
        GT0_RXRESETDONE_OUT             =>      rxresetdone(i),
        --------------------- TX Initialization and Reset Ports --------------------
        GT0_GTTXRESET_IN                =>      gttxreset(i),
        GT0_TXUSERRDY_IN                =>      txuserrdy(i),
        ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
        GT0_TXUSRCLK_IN                 =>      txusrclk(i),
        GT0_TXUSRCLK2_IN                =>      txusrclk2(i),
        ------------------ Transmit Ports - TX Data Path interface -----------------
        GT0_TXDATA_IN                   =>      txdata_in(i),
        ---------------- Transmit Ports - TX Driver and OOB signaling --------------
        GT0_GTHTXN_OUT                  =>      txn_out(i),
        GT0_GTHTXP_OUT                  =>      txp_out(i),
        ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
        GT0_TXOUTCLK_OUT                =>      txoutclk(i),
        GT0_TXOUTCLKFABRIC_OUT          =>      open,
        GT0_TXOUTCLKPCS_OUT             =>      open,
        ------------- Transmit Ports - TX Initialization and Reset Ports -----------
        GT0_TXRESETDONE_OUT             =>      txresetdone(i),
        ----------------- Transmit Ports - TX Polarity Control Ports ---------------
        GT0_TXPOLARITY_IN               =>      txpolarity_in(i),
        ------------------ Transmit Ports - pattern Generator Ports ----------------
        GT0_TXPRBSSEL_IN                =>      prbssel(i),
        ----------- Transmit Transmit Ports - 8b10b Encoder Control Ports ----------
        GT0_TXCHARISK_IN                =>      txcharisk_in(i),
        ------------------------- Common Block - QPLL Ports ------------------------
        GT0_QPLLLOCK_IN                  =>       qplllock,
        GT0_QPLLREFCLKLOST_IN            =>       qpllrefclklost,
        GT0_QPLLRESET_OUT                =>       qpllresetrequest(i),
        GT0_QPLLOUTCLK_IN                =>       qplloutclk,
        GT0_QPLLOUTREFCLK_IN             =>       qplloutrefclk 
      );
      
  end generate;

  qpllresetrequestor <= or_reduce(qpllresetrequest);
   
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
  
    txusrrst_out(j) <= (not tx_fsm_reset_done(j)) or soft_reset_in;      
    rxusrrst_out(j) <= (not rx_fsm_reset_done(j)) or soft_reset_in;  
    
    -- Use PRBS-7 only : "001"
    prbssel(j) <= "001" when prbs_enable_in(j) = '1' else "000";
      
    check: entity work.data_check_8b10b
      generic map (
        BYTE_WIDTH => 4)
      port map (
        rx_usr_clk_in => rxusrclk(j),
        rx_byte_is_aligned_in => rxbyteisaligned(j),
        rx_data_in => rxdata(j),
        rx_char_is_k_in => rxcharisk(j),
        data_check_out => rxcheck(j));
        
  end generate;
  
  cplllock_out <= cplllock;

  ----------------------------------------------------------------------------
  -- COMMON
  ----------------------------------------------------------------------------
  
  qplllock_out <= qplllock;
  qpllreset <= commonreset or qpllresetrequestor;

  common : entity work.gth_common
  port map
   (
    GTREFCLK0_IN => refclk0_in,
    QPLLLOCK_OUT => qplllock,
    QPLLLOCKDETCLK_IN => sysclk_in,
    QPLLOUTCLK_OUT => qplloutclk,
    QPLLOUTREFCLK_OUT => qplloutrefclk,
    QPLLREFCLKLOST_OUT => qpllrefclklost,    
    QPLLRESET_IN => qpllreset
  );
  
  common_reset : entity work.gth_common_reset
   generic map 
   (
      STABLE_CLOCK_PERIOD =>STABLE_CLOCK_PERIOD        -- Period of the stable clock driving this state-machine, unit is [ns]
   )
   port map
   (    
      STABLE_CLOCK => sysclk_in,              --Stable Clock, either a stable clock from the PCB
      SOFT_RESET => soft_reset_in,            --User Reset, can be pulled any time
      COMMON_RESET => commonreset             --Reset QPLL
   );



end RTL;