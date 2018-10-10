


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.package_links.all;
use work.package_types.all;
use work.package_utilities.all;
use work.package_calo.ecal_tx;
use work.package_calo.hcal_tx;

entity ext_align_gth_calotest_spartan is
generic
(
  SIM_GTRESET_SPEEDUP: string := "TRUE";  -- Simulation setting for GT secureip model
  SIMULATION: integer := 0;               -- Set to 1 for simulation
  LOCAL_LHC_CLK_MULTIPLE: integer := 4;   -- Number of TTC clks per LHC clk
  LOCAL_LHC_BUNCH_COUNT: integer;         -- Number of bx per orbit
  KIND: integer;
  X_LOC: integer;
  Y_LOC: integer
  );
port
(
  -- TTC based clock
  ttc_clk_in : in std_logic;
  ttc_rst_in : in std_logic;
  -- Common signals
  refclk0_in : in std_logic;  -- 125mhz via dedicated distribution network
  refclk1_in : in std_logic;  -- 125mhz via dedicated distribution network
  drpclk_in : in std_logic;  -- 50mhz
  sysclk_in : in std_logic;  -- 100mhz
  -- Common dynamic reconfiguration port
  common_drp_address_in : in  std_logic_vector(7 downto 0);
  common_drp_data_in : in  std_logic_vector(15 downto 0);
  common_drp_data_out : out std_logic_vector(15 downto 0);
  common_drp_enable_in : in  std_logic;
  common_drp_ready_out : out std_logic;
  common_drp_write_in : in  std_logic;
  -- High Speed Serdes
  rxn_in : in std_logic_vector(3 downto 0);
  rxp_in : in std_logic_vector(3 downto 0);
  txn_out : out std_logic_vector(3 downto 0);
  txp_out : out std_logic_vector(3 downto 0);
  -- Channel dynamic reconfiguration port
  chan_drp_address_in  : in type_drp_addr_array(3 downto 0);
  chan_drp_data_in : in type_drp_data_array(3 downto 0);
  chan_drp_data_out : out type_drp_data_array(3 downto 0);
  chan_drp_enable_in : in std_logic_vector(3 downto 0);
  chan_drp_ready_out : out std_logic_vector(3 downto 0);
  chan_drp_write_in  : in std_logic_vector(3 downto 0);
  -- Parallel interface data
  txen_in : in std_logic_vector(3 downto 0);
  txdata_in : in type_32b_data_array(3 downto 0);
  txdatavalid_in : in std_logic_vector(3 downto 0);
  rxen_out : out std_logic_vector(3 downto 0);
  rxdata_out : out type_32b_data_array(3 downto 0);
  rxdatavalid_out : out std_logic_vector(3 downto 0);
  -- External Rx buffer control
  buf_master_in: in  std_logic_vector(3 downto 0);
  buf_rst_in: in  std_logic_vector(3 downto 0);
  buf_ptr_inc_in: in  std_logic_vector(3 downto 0);
  buf_ptr_dec_in: in  std_logic_vector(3 downto 0);
  -- Synchronisation signals
  align_marker_out : out std_logic_vector(3 downto 0);
  -- Channel Registers
  chan_ro_regs_out : out type_chan_ro_reg_array(3 downto 0);
  chan_rw_regs_in : in type_chan_rw_reg_array(3 downto 0);
  -- Common Registers
  common_ro_regs_out : out type_common_ro_reg;
  common_rw_regs_in : in type_common_rw_reg;
  qplllock: out std_logic;
  -- Monitoring clocks
  txclk_mon: out std_logic;
  rxclk_mon: out std_logic_vector(3 downto 0)
  );
end ext_align_gth_calotest_spartan;



architecture behave of ext_align_gth_calotest_spartan is

  -- Interface to tranceiver
  constant TX_BYTE_WIDTH: natural := 2;
  constant TX_DATA_WIDTH: natural := 8*TX_BYTE_WIDTH;
  constant RX_BYTE_WIDTH: natural := 4;
  constant RX_DATA_WIDTH: natural := 8*RX_BYTE_WIDTH;
  
  -- Pre Tx processing
  constant TX_BYTE_WIDTH_HCAL: natural := 4;
  constant TX_DATA_WIDTH_HCAL: natural := 8*TX_BYTE_WIDTH_HCAL;
  
  -- When crossing clock domains we wish for the data and datavalid signals
  -- to jump at the same time.  Hence merge data nad datavalid into a single 
  -- word called "info" when jumping across the domains.
  type info_16b is array (natural range <>) of std_logic_vector(16 downto 0);
  type info_32b is array (natural range <>) of std_logic_vector(32 downto 0);

  -- At ttc clk both ECAL = 16b & HCAL = 32b
  signal txinfo_ecal_at_ttc_clk: info_16b(1 downto 0);
  signal txinfo_hcal_at_ttc_clk: info_32b(3 downto 2);
  
  -- At link clk bothe ECAL & HCAL 16b
  signal txinfo_at_link_clk: info_16b(3 downto 0);
  
  -- Data path operating @ link speed - 250MHz (K codes not yet inserted)
  signal txdata_at_link_clk: type_16b_data_array(3 downto 0);
  signal txpad_at_link_clk : std_logic_vector(3 downto 0);

  -- Clocks driving MGT fabric interface
  signal txusrclk, rxusrclk : std_logic_vector(3 downto 0);
  signal txusrrst, rxusrrst : std_logic_vector(3 downto 0);
 
  -- Final data for transmission 
  signal txdata : type_16b_data_array(3 downto 0);
  signal txcharisk : type_16b_charisk_array(3 downto 0);

  signal rxdata : type_32b_data_array(3 downto 0);
  signal rxcharisk : type_32b_charisk_array(3 downto 0);
    
  signal loopback : type_loopback_array(3 downto 0);
  signal txpolarity, rxpolarity : std_logic_vector(3 downto 0);
  
  signal cplllock_i : std_logic_vector(3 downto 0);

  signal rxchariscomma : type_32b_chariscomma_array(3 downto 0);
  signal rxpcommaalignen : std_logic_vector(3 downto 0) := "1111";
  signal rxmcommaalignen : std_logic_vector(3 downto 0) := "1111";
  signal rxbyteisaligned : std_logic_vector(3 downto 0);
  
  signal rxdata_int :  type_32b_data_array(3 downto 0);
  signal rxdatavalid_int :  std_logic_vector(3 downto 0);
  
  signal rxen, txen :  std_logic_vector(3 downto 0);

  signal rxcdrlock :  std_logic_vector(3 downto 0);
  signal txoutclk : std_logic_vector(3 downto 0);
  signal txdatavalid, rxdatavalid :  std_logic_vector(3 downto 0);
  signal rx_comma_det : std_logic_vector(3 downto 0);  

  signal tx_fsm_reset, rx_fsm_reset, tx_fsm_reset_done, rx_fsm_reset_done: std_logic_vector(3 downto 0);
  signal orbit_tag_enable, align_disable, buf_inc, buf_dec: std_logic_vector(3 downto 0);

  signal rx_crc_checked_cnt, rx_crc_error_cnt: type_vector_of_stdlogicvec_x8(3 downto 0);
  signal reset_crc_counters: std_logic_vector(3 downto 0);
  signal rx_trailer, tx_trailer : type_vector_of_stdlogicvec_x32(3 downto 0);

  signal data_start : std_logic_vector(3 downto 0);
  
  signal divclk, divclkout: std_logic_vector(4 downto 0);
  signal soft_reset, soft_reset_sysclk, qplllock_i : std_logic;
  signal data_en_drv: std_logic;

  signal quad_x_loc : std_logic;
  signal quad_y_loc : std_logic_vector(3 downto 0);

  type offset_array is array(0 to 3) of integer;
  constant RAM18B_X_MULT: integer := 14; -- These values for xc7v690 part
  constant RAM18B_X_OFFSET: offset_array := (0, 0, 0, 0);
  constant RAM18B_Y_MULT: integer := 20;
  constant RAM18B_Y_OFFSET: offset_array := (1, 6, 13, 18);


begin                       

  ---------------------------------------------------------------------------
  -- Strobe generation if required
  ---------------------------------------------------------------------------

  data_en_drv_inst: entity work.data_enable_driver
  generic map (
    DATA_ENABLE_PER_BX => "110110")   
  port map (
    clk => ttc_clk_in,
    rst => ttc_rst_in,
    enable => data_en_drv
  );
  

  -- rx 10g
  rxen(1 downto 0) <= (others => '1');
  -- rx 10g
  rxen(3 downto 2) <= (others => '1');
  
  rxen_out <= rxen;
  
  -- txen <= txen_in;

  -- Hack - tx 4g8
  txen(1 downto 0) <= (others => '1');
  -- Hack - tx 6g4
  txen(3 downto 2) <= (others => data_en_drv);

  ---------------------------------------------------------------------------
  -- Clock monitoring
  ---------------------------------------------------------------------------

  divclk <= txusrclk(0) & rxusrclk;
  
  div_ref: entity work.freq_ctr_div
    generic map(
      N_CLK => 5
    )
    port map(
      clk => divclk,
      clkdiv => divclkout
    );
    
  txclk_mon <= divclkout(4);
  rxclk_mon <= divclkout(3 downto 0);

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  ---- Tx ECAL
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------    
    
  tx_4g8_gen: for i in 0 to 1 generate 
        
  ---------------------------------------------------------------------------
  -- Tx Stage (1): Add CRC 
  ---------------------------------------------------------------------------
  
    ecal_tx_inst: ecal_tx
    port map(
      rst_in => ttc_rst_in,
      clk_in => ttc_clk_in,
      data_in => txdata_in(i)(TX_DATA_WIDTH-1 downto 0), 
      data_valid_in => txdatavalid_in(i),
      data_start_in => '0',
      data_out => txinfo_ecal_at_ttc_clk(i)(TX_DATA_WIDTH-1 downto 0),
      data_valid_out => txinfo_ecal_at_ttc_clk(i)(TX_DATA_WIDTH));

    ---------------------------------------------------------------------------
    -- Tx Stage (2): Bridge data from local domain to link clock
    ---------------------------------------------------------------------------

    tx_clk_bridge: cdc_txdata_circular_buf
    --tx_clk_bridge: cdc_txdata_fifo
    generic map(
      data_length       => TX_DATA_WIDTH+1)
    port map( 
      upstream_clk      =>     ttc_clk_in,
      upstream_rst      =>     ttc_rst_in,
      upstream_en       =>     txen(i),
      downstream_clk    =>     txusrclk(i),
      downstream_rst    =>     txusrrst(i),
      data_in           =>     txinfo_ecal_at_ttc_clk(i),
      data_out          =>     txinfo_at_link_clk(i),
      pad_out           =>     txpad_at_link_clk(i));
     
  ---------------------------------------------------------------------------
  -- Tx Stage (3): Insert K codes
  ---------------------------------------------------------------------------

    -- TX part of transmitter fails to reset correctly when we send both
    -- bytes as k-codes during reset.  Change coode so that alignment 
    -- comma is always sent during reset and that upper k-code is removed.
    
    -- Xilinx doc U476 (v1.10)  states K28.7 should only be used for 
    -- charaterisation & testing
    -- Wikipedia explains why -http://en.wikipedia.org/wiki/8b/10b_encoding
    -- K28.7 plus other kcodes leads to ambiguities.
    
    txdata(i) <= x"F7F7" when txpad_at_link_clk(i) = '1' 
      else txinfo_at_link_clk(i)(15 downto 0) when txinfo_at_link_clk(i)(TX_DATA_WIDTH) = '1'
      else x"3CBC";
      
    txcharisk(i) <= "11" when txpad_at_link_clk(i) = '1' 
      else "00" when txinfo_at_link_clk(i)(TX_DATA_WIDTH) = '1' 
      else "11";

  end generate tx_4g8_gen;

  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  ---- Tx HCAL
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------    
    
  tx_6g4_gen: for i in 2 to 3 generate 
    
    txinfo_hcal_at_ttc_clk(i) <= txdatavalid_in(i) & txdata_in(i);
    
    tx_clk_bridge: cdc_txdata_fifo_asymmetric
    port map( 
      upstream_clk      =>     ttc_clk_in,
      upstream_rst      =>     ttc_rst_in,
      upstream_en       =>     txen(i),
      downstream_clk    =>     txusrclk(i),
      downstream_rst    =>     txusrrst(i),
      data_in           =>     txinfo_hcal_at_ttc_clk(i),
      data_out          =>     txinfo_at_link_clk(i),
      pad_out           =>     txpad_at_link_clk(i));
     
    hcal_tx_inst: hcal_tx
    port map(
      rst_in => txusrrst(i),
      clk_in => txusrclk(i),
      pad_in => txpad_at_link_clk(i),
      data_in => txinfo_at_link_clk(i)(15 downto 0),
      data_valid_in => txinfo_at_link_clk(i)(16),
      data_start_in => '0',
      data_out => txdata(i),
      charisk_out => txcharisk(i));   
    
  end generate tx_6g4_gen;


  ---------------------------------------------------------------------------
  -- GTX
  ---------------------------------------------------------------------------

  -- Make sure soft reset is in stable clock domain
  sync_pulse_inst: async_pulse_sync
    port map(
        async_pulse_in => soft_reset,
        sync_clk_in => sysclk_in,
        sync_pulse_out => soft_reset_sysclk,
        sync_pulse_sgl_clk_out => open);

  quad_wrapper_inst: entity work.gth_quad_wrapper_calotest
  --quad_wrapper_inst: entity work.gth_quad_wrapper_calotest_sim
  generic map(
    -- Simulation attributes  
    SIMULATION => SIMULATION,
    SIM_GTRESET_SPEEDUP => SIM_GTRESET_SPEEDUP,
    STABLE_CLOCK_PERIOD => 32  -- ns  
  )
  port map
  ( 
    -- Common signals
    soft_reset_in => soft_reset_sysclk,       -- Clock domain = STABLE_CLOCK
    refclk0_in => refclk0_in,
    refclk1_in => refclk1_in,
    
    drpclk_in => drpclk_in,
    sysclk_in => sysclk_in,
    qplllock_out => qplllock_i,
    cplllock_out => cplllock_i,

    -- Common dynamic reconfiguration port
    common_drp_address_in => common_drp_address_in,
    common_drp_data_in => common_drp_data_in,
    common_drp_data_out => common_drp_data_out,
    common_drp_enable_in => common_drp_enable_in, 
    common_drp_ready_out => common_drp_ready_out,
    common_drp_write_in => common_drp_write_in,

    -- Fabric interface clocks
    rxusrclk_out => rxusrclk,
    txusrclk_out => txusrclk,
    rxusrrst_out => rxusrrst,
    txusrrst_out => txusrrst,

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
    tx_fsm_reset_in => tx_fsm_reset, 
    rx_fsm_reset_in => rx_fsm_reset,
    tx_fsm_reset_done_out => tx_fsm_reset_done,
    rx_fsm_reset_done_out => rx_fsm_reset_done,

    -- Misc
    loopback_in => loopback,
    prbs_enable_in => "0000",

    -- Tx signals
    txoutclk_out => txoutclk,
    txpolarity_in => txpolarity,
    txdata_in => txdata,
    txcharisk_in => txcharisk,

    -- Rx signals
    rx_comma_det_out => rx_comma_det,
    rxpolarity_in => rxpolarity,
    rxcdrlock_out => rxcdrlock,
    rxdata_out => rxdata,
    rxcharisk_out => rxcharisk,
    rxchariscomma_out => rxchariscomma,
    rxbyteisaligned_out => rxbyteisaligned,
    rxpcommaalignen_in => rxpcommaalignen,      -- Clock domain = RXUSRCLK2
    rxmcommaalignen_in => rxmcommaalignen);     -- Clock domain = RXUSRCLK2


  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  ---- Tx Calo-L1
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------    

  rx_gen: for i in 0 to 3 generate 
  
  -----------------------------------------------------------------------------
  ---- Rx Stage (1): CDC
  -----------------------------------------------------------------------------

  buf_inc(i) <= buf_ptr_inc_in(i) and not align_disable(i);
  buf_dec(i) <= buf_ptr_dec_in(i) and not align_disable(i);
  
  rxdata_simple_cdc_buf_inst: rxdata_simple_cdc_buf
    generic map(
      SIMULATION => SIMULATION,
      BYTE_WIDTH => RX_BYTE_WIDTH,
      X_LOC => RAM18B_X_MULT * X_LOC + RAM18B_X_OFFSET(i),
      Y_LOC => RAM18B_Y_MULT * Y_LOC + RAM18B_Y_OFFSET(i)
    )
    port map(
      -- All the following in link clk domain
      link_rst_in => rxusrrst(i),
      link_clk_in => rxusrclk(i),
      rxdata_in => rxdata(i),
      rxcharisk_in => rxcharisk(i),
      rx_comma_det_in => rx_comma_det(i),
      -- All in sys clk domain
      rx_fsm_reset_done_in => rx_fsm_reset_done(i),
      -- Want to keep it all in the local clk domain
      local_rst_in => ttc_rst_in,
      local_clk_in => ttc_clk_in,
      local_clken_in => rxen(i),      
      buf_master_in => buf_master_in(i),
      buf_rst_in => buf_rst_in(i),
      buf_ptr_inc_in => buf_inc(i),
      buf_ptr_dec_in => buf_dec(i),
      rxdata_out => rxdata_int(i),
      rxdatavalid_out => rxdatavalid_int(i)
    );
    
  ---------------------------------------------------------------------------
  -- Rx Stage (2): CRC
  ---------------------------------------------------------------------------

  rx_crc: links_crc_rx
  generic map (
      CRC_METHOD => "OUTPUT_LOGIC",
      POLYNOMIAL => "00000100110000010001110110110111",
      INIT_VALUE => "11111111111111111111111111111111",
      TRAILER_EN => FALSE,
      DATA_WIDTH => RX_DATA_WIDTH,
      SYNC_RESET => 1)   
     port map (
        reset                 => ttc_rst_in, 
        clk                   => ttc_clk_in,
        clken_in              => rxen(i), 
        data_in               => rxdata_int(i),
        data_valid_in         => rxdatavalid_int(i),
        data_out              => rxdata_out(i)(RX_DATA_WIDTH-1 downto 0),
        data_valid_out        => rxdatavalid_out(i),
        data_start_out        => data_start(i),
        reset_counters_in     => reset_crc_counters(i),
        crc_checked_cnt_out   => rx_crc_checked_cnt(i),
        crc_error_cnt_out     => rx_crc_error_cnt(i),
        trailer_out           => rx_trailer(i)(RX_DATA_WIDTH-1 downto 0),
        status_out            => open);    

--  pad_ext_interface: if RX_DATA_WIDTH /= 32 generate
--    rxdata_out(i)(31 downto RX_DATA_WIDTH) <= (others => '0');
--    rx_trailer(i)(31 downto RX_DATA_WIDTH) <= (others => '0');    
--  end generate;

		-- Alignment marker must ocvcur at fixed frequency for alignment mechanism.  
		-- Simplest is one per orbit.  Not time critical.  Large fan in later so register.
		align_marker_proc: process(ttc_clk_in) 
		begin
			if rising_edge(ttc_clk_in) then
				align_marker_out(i) <= (data_start(i) and (rxdata_int(i)(12) or (not orbit_tag_enable(i))) and rxen(i)) or align_disable(i);
			end if;
		end process;
    
  end generate rx_gen;

  -----------------------------------------------------------------------------
  ---- CHANNEL Register Access:
  -----------------------------------------------------------------------------

  quad_x_loc <= '0' when X_LOC = 0 else '1';
  quad_y_loc <= std_logic_vector(to_unsigned(Y_LOC, 4));

  -- Loop over all channels
  reg_gen: for i in 0 to 3 generate 
  
   ----------------------------------------------------------------------------- 
   -- ReadOnly Regs. All TTC domain
   -----------------------------------------------------------------------------
   
   chan_ro_regs_out(i)(0) <= rx_trailer(i);
   chan_ro_regs_out(i)(1) <= txusrrst(i) & 
                             rxusrrst(i) &
                             tx_fsm_reset_done(i) & 
                             rx_fsm_reset_done(i) &
                             rxcdrlock(i) & 
                             cplllock_i(i) & 
                             "00" &
                             x"00" & rx_crc_error_cnt(i) & rx_crc_checked_cnt(i);
      
   -----------------------------------------------------------------------------
   -- ReadWrite Regs. All TTC domain except for polarity & loopback regs: 
   -----------------------------------------------------------------------------
   
   -- loopback is async input
   loopback(i) <= chan_rw_regs_in(i)(0)(2 downto 0);
   -- crc reset is in TTC domain
   reset_crc_counters(i) <= chan_rw_regs_in(i)(0)(3);
   -- txpolarity is in the txusrclk2 domain
   txpolarity(i) <= chan_rw_regs_in(i)(0)(4) when rising_edge(txusrclk(i));
   -- rxpolarity is in the rxusrclk2 domain
   rxpolarity(i) <= chan_rw_regs_in(i)(0)(5) when rising_edge(rxusrclk(i));
   -- JJ's code handles clock domain crossing
   -- JJ's code also seprates out QPLL, which has a FSM that will automatically try to lock
   tx_fsm_reset(i) <= chan_rw_regs_in(i)(0)(6);
   rx_fsm_reset(i) <= chan_rw_regs_in(i)(0)(7);
   orbit_tag_enable(i)  <= chan_rw_regs_in(i)(0)(8);
   align_disable(i) <= chan_rw_regs_in(i)(0)(9);

  end generate;


  -----------------------------------------------------------------------------
  ---- COMMON Register Access:
  -----------------------------------------------------------------------------
  
  -- COMMON: ReadOnly Regs.
  -- WARNING: Clock domain may not be observed
  common_ro_regs_out(0)(0) <= qplllock_i;
  common_ro_regs_out(0)(4 downto 1) <= std_logic_vector(to_unsigned(KIND,4));
  common_ro_regs_out(0)(31 downto 5) <= (others => '0');

  -- COMMON: ReadWrite Regs.
  -- WARNING: Clock domain may not be observed
  soft_reset <= common_rw_regs_in(0)(0);
  
  qplllock <= qplllock_i;
  
end behave;
