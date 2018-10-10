--
-- Definition library for MP7 QDR SRAM test components
--
library ieee;
use ieee.std_logic_1164.all;

package test_definitions is

  component cyqdr2_b4
    port (
      TCK, TMS, TDI : in std_logic;
      TDO : out std_logic;
      D : in std_logic_vector(17 downto 0);
      Q : out std_logic_vector(17 downto 0);
      A : in std_logic_vector(19 downto 0);
      K, Kb : in std_logic;
      RPSb, WPSb : in std_logic;
      BWS0b, BWS1b : in std_logic;
      CQ, CQb : inout std_logic;
      ZQ, DOFF, ODT : in std_logic;
      QVLD : out std_logic
      );
  end component;

    component mig_7series_v1_8_traffic_gen_top
    generic (
      TCQ                      : integer;
      SIMULATION               : string;
      FAMILY                   : string;
      MEM_TYPE                 : string;
      TST_MEM_INSTR_MODE       : string;
      --BL_WIDTH                 : integer;
      nCK_PER_CLK              : integer;
      NUM_DQ_PINS              : integer;
      MEM_BURST_LEN            : integer;
      MEM_COL_WIDTH            : integer;
      DATA_WIDTH               : integer;
      ADDR_WIDTH               : integer;
      DATA_MODE                : std_logic_vector(3 downto 0);
      BEGIN_ADDRESS            : std_logic_vector(31 downto 0);
      END_ADDRESS              : std_logic_vector(31 downto 0);
      PRBS_EADDR_MASK_POS      : std_logic_vector(31 downto 0);
      EYE_TEST                 : string;
      CMD_WDT                  : std_logic_vector(31 downto 0);
      WR_WDT                   : std_logic_vector(31 downto 0);
      RD_WDT                   : std_logic_vector(31 downto 0);
      PORT_MODE                : string;
      DATA_PATTERN             : string;
      CMD_PATTERN              : string
      );
    port (
      clk                    : in   std_logic;
      rst                    : in   std_logic;
      tg_only_rst            : in   std_logic;
      manual_clear_error     : in   std_logic;
      memc_init_done         : in   std_logic;
      memc_cmd_full          : in   std_logic;
      memc_cmd_en            : out  std_logic;
      memc_cmd_instr         : out  std_logic_vector(2 downto 0);
      memc_cmd_bl            : out  std_logic_vector(5 downto 0);
      memc_cmd_addr          : out  std_logic_vector(31 downto 0);
      memc_wr_en             : out  std_logic;
      memc_wr_end            : out  std_logic;
      memc_wr_mask           : out  std_logic_vector(DATA_WIDTH/8-1 downto 0);
      memc_wr_data           : out  std_logic_vector(DATA_WIDTH-1 downto 0);
      memc_wr_full           : in   std_logic;
      memc_rd_en             : out  std_logic;
      memc_rd_data           : in   std_logic_vector(DATA_WIDTH-1 downto 0);
      memc_rd_empty          : in   std_logic;
      qdr_wr_cmd_o           : out  std_logic;
      qdr_rd_cmd_o           : out  std_logic;
      vio_pause_traffic      : in   std_logic;
      vio_modify_enable      : in   std_logic;
      vio_data_mode_value    : in   std_logic_vector(3 downto 0);
      vio_addr_mode_value    : in   std_logic_vector(2 downto 0);
      vio_instr_mode_value   : in   std_logic_vector(3 downto 0);
      vio_bl_mode_value      : in   std_logic_vector(1 downto 0);
      vio_fixed_bl_value     : in   std_logic_vector(9 downto 0);
      vio_fixed_instr_value  : in   std_logic_vector(2 downto 0);
      vio_data_mask_gen      : in   std_logic;
      fixed_addr_i           : in   std_logic_vector(31 downto 0);
      fixed_data_i           : in   std_logic_vector(31 downto 0);
      simple_data0           : in   std_logic_vector(31 downto 0);
      simple_data1           : in   std_logic_vector(31 downto 0);
      simple_data2           : in   std_logic_vector(31 downto 0);
      simple_data3           : in   std_logic_vector(31 downto 0);
      simple_data4           : in   std_logic_vector(31 downto 0);
      simple_data5           : in   std_logic_vector(31 downto 0);
      simple_data6           : in   std_logic_vector(31 downto 0);
      simple_data7           : in   std_logic_vector(31 downto 0);
      wdt_en_i               : in   std_logic;
      bram_cmd_i             : in   std_logic_vector(38 downto 0);
      bram_valid_i           : in   std_logic;
      bram_rdy_o             : out  std_logic;
      cmp_data               : out  std_logic_vector(DATA_WIDTH-1 downto 0);
      cmp_data_valid         : out  std_logic;
      cmp_error              : out  std_logic;
      wr_data_counts         : out   std_logic_vector(47 downto 0);
      rd_data_counts         : out   std_logic_vector(47 downto 0);
      dq_error_bytelane_cmp  : out  std_logic_vector((NUM_DQ_PINS/8)-1 downto 0);
      error                  : out  std_logic;
      error_status           : out  std_logic_vector((64+(2*DATA_WIDTH-1)) downto 0);
      cumlative_dq_lane_error : out  std_logic_vector((NUM_DQ_PINS/8)-1 downto 0);
      cmd_wdt_err_o          : out std_logic; 
      wr_wdt_err_o           : out std_logic; 
      rd_wdt_err_o           : out std_logic; 
      mem_pattern_init_done  : out  std_logic
      );
  end component mig_7series_v1_8_traffic_gen_top;

end test_definitions;
