--
-- Definition library for MP7 QDR SRAM interface
--
library ieee;
use ieee.std_logic_1164.all;

package core_definitions is

  component mig_7series_v1_8_clk_nobuf
    port (
      sys_clk : in std_logic;
      mmcm_clk : out std_logic
      );
  end component;

  component mig_7series_v1_8_clk_ibuf
    generic (
      DIFF_TERM_SYSCLK : string := "TRUE"
      );
    port (
      sys_clk_p : in std_logic;
      sys_clk_n : in std_logic;
      mmcm_clk : out std_logic
      );
  end component;

  component mig_7series_v1_8_infrastructure
    generic (
      SIMULATION : string := "FALSE";    -- Should be TRUE during design simulations and
                                         -- FALSE during implementations
      TCQ : natural := 100;      -- clk->out delay (sim only)
      CLKIN_PERIOD : natural := 3000;     -- Memory clock period
      nCK_PER_CLK : natural := 2;                -- Fabric clk period:Memory clk period
      SYSCLK_TYPE : string := "DIFFERENTIAL";
                                        -- input clock type
                                        -- "DIFFERENTIAL";"SINGLE_ENDED"
      CLKFBOUT_MULT : natural := 4;        -- write PLL VCO multiplier
      DIVCLK_DIVIDE : natural := 1;        -- write PLL VCO divisor
      CLKOUT0_PHASE : real := 45.0;       -- VCO output divisor for clkout0
      CLKOUT0_DIVIDE : natural := 16;      -- VCO output divisor for clkout0
      CLKOUT1_DIVIDE : natural := 4;       -- VCO output divisor for clkout1
      CLKOUT2_DIVIDE : natural := 64;      -- VCO output divisor for clkout2
      CLKOUT3_DIVIDE : natural := 16;      -- VCO output divisor for clkout3
      CLKOUT4_DIVIDE : natural := 4;    -- VCO output divisor for clkout4
      RST_ACT_LOW : natural := 1
      );
    port (
      -- Clock inputs
      mmcm_clk : in std_logic;           -- System clock diff input

      -- System reset input
      sys_rst : in std_logic;            -- core reset from user application

      -- PLLE2/IDELAYCTRL Lock status
      iodelay_ctrl_rdy : in std_logic;   -- IDELAYCTRL lock status

      -- Clock outputs
      iodelay_clk : out std_logic;      -- unbuffered iodelay 200 MHz reference
      clk : out std_logic;    -- fabric clock freq ; either  half rate or quarter rate and is
                              -- determined by  PLL parameters settings.
      mem_refclk : out std_logic;         -- equal to  memory clock
      freq_refclk : out std_logic;        -- freq above 400 MHz:  set freq_refclk = mem_refclk
                                          -- freq below 400 MHz:  set freq_refclk = 2* mem_refclk or 4* mem_refclk;
                                          -- to hard PHY for phaser
      sync_pulse : out std_logic;         -- exactly 1/16 of mem_refclk and the sync pulse is exactly 1 memref_clk wide

      pll_locked : out std_logic;         -- locked output from PLLE2_ADV

      -- Reset outputs
      rstdiv0 : out std_logic;             -- Reset CLK and CLKDIV logic (incl I/O);

      rst_phaser_ref : out std_logic;
      ref_dll_lock : in std_logic
      );
  end component;

  component mig_7series_v1_8_iodelay_ctrl is
    generic(
      TCQ              : integer;
      IODELAY_GRP      : string;
      RST_ACT_LOW      : integer
      );
    port (
      clk_ref_i        : in  std_logic;
      sys_rst          : in  std_logic;
      clk_ref          : out std_logic;
      iodelay_ctrl_rdy : out std_logic
   );
  end component mig_7series_v1_8_iodelay_ctrl;

  component mig_7series_v1_8_qdr_phy_byte_lane_map
    generic (
      TCQ : natural := 100;
      nCK_PER_CLK : natural := 2;         -- qdr2+ used in the 2:1 mode
      NUM_DEVICES : natural := 2;         --Memory Devices
      ADDR_WIDTH  : natural := 19;        --Adress Width
      DATA_WIDTH  : natural := 72;        --Data Width
      BW_WIDTH    : natural := 8;         --Byte Write Width
      MEMORY_TYPE : string := "UNIDIR";   -- "UNIDIR" or "BIDIR"
      MEM_RD_LATENCY : real := 2.0;
      Q_BITS : natural := 7;         --clog2(DATA_WIDTH - 1)
      --parameter N_LANES         = 4;
      --parameter N_CTL_LANES     = 2;
      -- five fields; one per possible I/O bank; 4 bits in each field; 
      -- 1 per lane data=1/ctl=0
      DATA_CTL_B0 : std_logic_vector(3 downto 0) := x"c";
      DATA_CTL_B1 : std_logic_vector(3 downto 0) := x"f";
      DATA_CTL_B2 : std_logic_vector(3 downto 0) := x"f";
      DATA_CTL_B3 : std_logic_vector(3 downto 0) := x"f";
      DATA_CTL_B4 : std_logic_vector(3 downto 0) := x"f";
      -- defines the byte lanes in I/O banks being used in the interface
      -- 1- Used; 0- Unused
      BYTE_LANES_B0 : std_logic_vector(3 downto 0) := "1111";
      BYTE_LANES_B1 : std_logic_vector(3 downto 0) := "0000";
      BYTE_LANES_B2 : std_logic_vector(3 downto 0) := "0000";
      BYTE_LANES_B3 : std_logic_vector(3 downto 0) := "0000";
      BYTE_LANES_B4 : std_logic_vector(3 downto 0) := "0000";
      HIGHEST_LANE : natural := 12;
      HIGHEST_BANK : natural := 3;
      -- [7:4] - bank no. ; [3:0] - byte lane no. 
      K_MAP : std_logic_vector(47 downto 0) := x"00_00_00_00_00_11";
      CQ_MAP : std_logic_vector(47 downto 0) := x"00_00_00_00_00_01";
   
      -- Mapping for address and control signals
      -- The parameter contains the byte_lane and bit position information for 
      -- a control signal. 
      -- Each add/ctl bit will have 12 bits the assignments are
      -- [3:0] - Bit position within a byte lane . 
      -- [7:4] - Byte lane position within a bank. [5:4] have the byte lane position. 
      -- [7:6] tied to 0 
      -- [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero 
   
      RD_MAP : std_logic_vector(11 downto 0) := x"218";
      WR_MAP : std_logic_vector(11 downto 0) := x"219";
  
      -- supports 22 bits of address bits 
      ADD_MAP : std_logic_vector(263 downto 0) := x"217_216_21B_21A_215_214_213_212_211_210_209_208_207_206_20B_20A_205_204_203_202_201_200";
   
      -- One parameter per data byte - 9bits per byte = 9*12
      D0_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 0 
      D1_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 1
      D2_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 2
      D3_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 3
      D4_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 4
      D5_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 5
      D6_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 6
      D7_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 7
   
      -- byte writes for bytes 0 to 7 - 8*12
      BW_MAP : std_logic_vector(95 downto 0) := x"007_006_005_004_003_002_001_000";
   
      --One parameter per data byte - 9bits per byte = 9*12
      Q0_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 0 
      Q1_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 1
      Q2_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 2
      Q3_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 3
      Q4_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 4
      Q5_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 5
      Q6_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000"; --byte 6
      Q7_MAP : std_logic_vector(107 downto 0) := x"008_007_006_005_004_003_002_001_000" --byte 7
      );
    port (   
      clk : in std_logic;
      rst : in std_logic;
      phy_init_data_sel : in std_logic;
      --  input                                  ck_addr_ctl_delay_done;
      byte_sel_cnt : in std_logic_vector(5 downto 0);
      phy_din : in std_logic_vector(HIGHEST_LANE*80-1 downto 0);
      phy_dout : out std_logic_vector(HIGHEST_LANE*80-1 downto 0);
      ddr_clk : in std_logic_vector(HIGHEST_BANK*8-1 downto 0);
      cq_clk : out std_logic_vector(HIGHEST_BANK*4-1 downto 0);
      cqn_clk : out std_logic_vector(HIGHEST_BANK*4-1 downto 0);

      iob_addr  : in std_logic_vector(nCK_PER_CLK*2*ADDR_WIDTH-1 downto 0);
      iob_rd_n  : in std_logic_vector(nCK_PER_CLK*2-1 downto 0);
      iob_wr_n  : in std_logic_vector(nCK_PER_CLK*2-1 downto 0);
      iob_wdata : in std_logic_vector(nCK_PER_CLK*2*DATA_WIDTH-1 downto 0);
      iob_bw    : in std_logic_vector(nCK_PER_CLK*2*BW_WIDTH-1 downto 0);

      --  output reg [5:0]                              calib_sel;          -- need clarifications--
      --  output reg [HIGHEST_BANK-1:0]                 calib_zero_inputs;  -- need clarifications

      dlyval_dq : in std_logic_vector(5*DATA_WIDTH-1 downto 0);
      idelay_cnt_out : in std_logic_vector(HIGHEST_BANK*240-1 downto 0);
      dbg_inc_q_all, dbc_dec_q_all, dbg_inc_q, dbg_dec_q : in std_logic;
      dbg_sel_q : in std_logic_vector(Q_BITS-1 downto 0);

      dbg_q_tapcnt : out std_logic_vector(5*DATA_WIDTH-1 downto 0);
      idelay_cnt_in : out std_logic_vector(HIGHEST_BANK*240-1 downto 0);
      idelay_ce : out std_logic_vector((HIGHEST_LANE*12)-1 downto 0);
      idelay_inc : out std_logic_vector((HIGHEST_LANE*12)-1 downto 0);

      rd_data_map : out std_logic_vector(nCK_PER_CLK*2*DATA_WIDTH-1 downto 0);
      qdr_k_p : out std_logic_vector(NUM_DEVICES-1 downto 0);
      qdr_k_n : out std_logic_vector(NUM_DEVICES-1 downto 0);
      qdr_sa : out std_logic_vector(ADDR_WIDTH-1 downto 0);
      qdr_w_n, qdr_r_n : out std_logic;
      qdr_bw_n : out std_logic_vector(BW_WIDTH-1 downto 0);

      qdr_cq_p, qdr_cq_n : in std_logic_vector(DATA_WIDTH-1 downto 0);
      qdr_d : in std_logic_vector(DATA_WIDTH-1 downto 0);
      o : in std_logic_vector((HIGHEST_LANE*12)-1 downto 0);   -- input coming from mc_phy to drive out qdr output signals
      i : out std_logic_vector((HIGHEST_LANE*12)-1 downto 0)   -- read data coming from memory provided out to hard phy
      );  
  end component;


  component mig_7series_v1_8_qdr_phy_top is
    generic (
      SIMULATION          : string  :=  "FALSE";
      CPT_CLK_CQ_ONLY     : string  :=  "TRUE";
      ADDR_WIDTH          : integer :=  19;            
      DATA_WIDTH          : integer :=  72;            
      BW_WIDTH            : integer :=  8;             
      BURST_LEN           : integer :=  4;             
      CLK_PERIOD          : integer :=  2500;          
      nCK_PER_CLK         : integer :=  2;
      REFCLK_FREQ         : real    := 200.0;
      NUM_DEVICES         : integer :=  2;             
      N_DATA_LANES        : integer :=  4;
      FIXED_LATENCY_MODE  : integer :=  0;             
      PHY_LATENCY         : integer :=  0;             
      MEM_RD_LATENCY      : real    := 2.0;            
      CLK_STABLE          : integer :=  2048;          
      IODELAY_GRP         : string  :=  "IODELAY_MIG"; 
      MEM_TYPE            : string  :=  "QDR2PLUS";    
      RST_ACT_LOW         : integer := 1;             
      SIM_BYPASS_INIT_CAL : string  :=  "OFF";      
      IBUF_LPWR_MODE      : string  :=  "OFF";         
      IODELAY_HP_MODE     : string  :=  "ON";          
      CQ_BITS             : integer :=  1;             
      Q_BITS              : integer :=  7;             
      DEVICE_TAPS         : integer :=  32;            
      TAP_BITS            : integer :=  5;             
      MASTER_PHY_CTL      : integer :=  0;             
      PLL_LOC             : integer :=  2;
      INTER_BANK_SKEW     : integer :=  0;
      DATA_CTL_B0         : std_logic_vector(3 downto 0) := X"f";
      DATA_CTL_B1         : std_logic_vector(3 downto 0) := X"f";
      DATA_CTL_B2         : std_logic_vector(3 downto 0) := X"c";
      DATA_CTL_B3         : std_logic_vector(3 downto 0) := X"f";
      DATA_CTL_B4         : std_logic_vector(3 downto 0) := X"f";
      CPT_CLK_SEL_B0      : std_logic_vector(31 downto 0) := X"12121111";
      CPT_CLK_SEL_B1      : std_logic_vector(31 downto 0) := X"12121111";  
      CPT_CLK_SEL_B2      : std_logic_vector(31 downto 0) := X"12121111";
      BYTE_LANES_B0       : std_logic_vector(3 downto 0) := "1111";
      BYTE_LANES_B1       : std_logic_vector(3 downto 0) := "1111";
      BYTE_LANES_B2       : std_logic_vector(3 downto 0) := "0011";
      BYTE_LANES_B3       : std_logic_vector(3 downto 0) := "0000";
      BYTE_LANES_B4       : std_logic_vector(3 downto 0) := "0000";
      BYTE_GROUP_TYPE_B0  : std_logic_vector(3 downto 0) := "1111";
      BYTE_GROUP_TYPE_B1  : std_logic_vector(3 downto 0) := "0000";
      BYTE_GROUP_TYPE_B2  : std_logic_vector(3 downto 0) := "0000";  
      BYTE_GROUP_TYPE_B3  : std_logic_vector(3 downto 0) := "0000"; 
      BYTE_GROUP_TYPE_B4  : std_logic_vector(3 downto 0) := "0000"; 
      K_MAP               : std_logic_vector(47 downto 0) := X"000000000011";
      CQ_MAP              : std_logic_vector(47 downto 0) := X"000000000001";
      RD_MAP              : std_logic_vector(11 downto 0) := X"218";
      WR_MAP              : std_logic_vector(11 downto 0) := X"219";
      ADD_MAP             : std_logic_vector(263 downto 0) := X"21721621B21A21521421321221121020920820720620B20A205204203202201200";
      ADDR_CTL_MAP        : std_logic_vector(23 downto 0) := X"002120";  
      D0_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      D1_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      D2_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      D3_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      D4_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      D5_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      D6_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      D7_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      BW_MAP              : std_logic_vector(83 downto 0) := X"006005004003002001000";
      Q0_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      Q1_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      Q2_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      Q3_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      Q4_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      Q5_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      Q6_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      Q7_MAP              : std_logic_vector(107 downto 0) := X"008007006005004003002001000";
      BIT_LANES_B0        : std_logic_vector(47 downto 0) := X"1ff3fd1ff1ff";            
      BIT_LANES_B1        : std_logic_vector(47 downto 0) := X"000000000000"; 
      BIT_LANES_B2        : std_logic_vector(47 downto 0) := X"000000000000";
      BIT_LANES_B3        : std_logic_vector(47 downto 0) := X"000000000000"; 
      BIT_LANES_B4        : std_logic_vector(47 downto 0) := X"000000000000";
      DEBUG_PORT          : string  :=  "ON"; 
      TCQ                 : integer :=  100  
    );
    port (
      clk                      : in  std_logic;            
      rst_wr_clk               : in  std_logic;     
      --clk_ref                  : in  std_logic;        
      clk_mem                  : in  std_logic;        
      freq_refclk              : in  std_logic;
      pll_lock                 : in  std_logic;
      sync_pulse               : in  std_logic;
      ref_dll_lock             : out std_logic;
      rst_phaser_ref           : in  std_logic;
      rst_clk                  : out std_logic;          
      sys_rst                  : in  std_logic;          
      wr_cmd0                  : in  std_logic;          
      wr_cmd1                  : in  std_logic;          
      wr_addr0                 : in  std_logic_vector(ADDR_WIDTH-1 downto 0);         
      wr_addr1                 : in  std_logic_vector(ADDR_WIDTH-1 downto 0);         
      rd_cmd0                  : in  std_logic;          
      rd_cmd1                  : in  std_logic;          
      rd_addr0                 : in  std_logic_vector(ADDR_WIDTH-1 downto 0);         
      rd_addr1                 : in  std_logic_vector(ADDR_WIDTH-1 downto 0);         
      wr_data0                 : in  std_logic_vector(DATA_WIDTH*2-1 downto 0);         
      wr_data1                 : in  std_logic_vector(DATA_WIDTH*2-1 downto 0);         
      wr_bw_n0                 : in  std_logic_vector(BW_WIDTH*2-1 downto 0);         
      wr_bw_n1                 : in  std_logic_vector(BW_WIDTH*2-1 downto 0);        
      init_calib_complete      : out std_logic;         
      rd_valid0                : out std_logic;        
      rd_valid1                : out std_logic;        
      rd_data0                 : out std_logic_vector(DATA_WIDTH*2-1 downto 0);         
      rd_data1                 : out std_logic_vector(DATA_WIDTH*2-1 downto 0);         
      qdr_dll_off_n            : out std_logic;    
      qdr_k_p                  : out std_logic_vector(NUM_DEVICES-1 downto 0);          
      qdr_k_n                  : out std_logic_vector(NUM_DEVICES-1 downto 0);          
      qdr_sa                   : out std_logic_vector(ADDR_WIDTH-1 downto 0);           
      qdr_w_n                  : out std_logic;          
      qdr_r_n                  : out std_logic;          
      qdr_bw_n                 : out std_logic_vector(BW_WIDTH-1 downto 0);         
      qdr_d                    : out std_logic_vector(DATA_WIDTH-1 downto 0);            
      qdr_q                    : in  std_logic_vector(DATA_WIDTH-1 downto 0);            
      --qdr_qvld                 : in  std_logic_vector(NUM_DEVICES-1 downto 0);         
      qdr_cq_p                 : in  std_logic_vector(NUM_DEVICES-1 downto 0);         
      qdr_cq_n                 : in  std_logic_vector(NUM_DEVICES-1 downto 0);         
      dbg_phy_status           : out std_logic_vector(7 downto 0);          
      dbg_SM_No_Pause          : in std_logic;          
      dbg_SM_en                : in std_logic;          
      dbg_po_counter_read_val  : out std_logic_vector(8 downto 0);
      dbg_pi_counter_read_val  : out std_logic_vector(5 downto 0);
      dbg_phy_init_wr_only     : in  std_logic;
      dbg_phy_init_rd_only     : in  std_logic;
      dbg_byte_sel             : in  std_logic_vector(CQ_BITS-1 downto 0);
      dbg_bit_sel              : in  std_logic_vector(Q_BITS-1 downto 0);
      dbg_pi_f_inc             : in  std_logic;
      dbg_pi_f_dec             : in  std_logic;
      dbg_po_f_inc             : in  std_logic;
      dbg_po_f_dec             : in  std_logic;
      dbg_idel_up_all          : in  std_logic;
      dbg_idel_down_all        : in  std_logic;
      dbg_idel_up              : in  std_logic;
      dbg_idel_down            : in  std_logic;
      dbg_idel_tap_cnt         : out std_logic_vector(TAP_BITS*DATA_WIDTH-1 downto 0);
      dbg_idel_tap_cnt_sel     : out std_logic_vector(TAP_BITS-1 downto 0);
      dbg_select_rdata         : out std_logic_vector(2 downto 0);
      dbg_align_rd0_r          : out std_logic_vector(8 downto 0);
      dbg_align_rd1_r          : out std_logic_vector(8 downto 0);
      dbg_align_fd0_r          : out std_logic_vector(8 downto 0);
      dbg_align_fd1_r          : out std_logic_vector(8 downto 0);
      dbg_align_rd0            : out std_logic_vector(DATA_WIDTH-1 downto 0);
      dbg_align_rd1            : out std_logic_vector(DATA_WIDTH-1 downto 0);
      dbg_align_fd0            : out std_logic_vector(DATA_WIDTH-1 downto 0);
      dbg_align_fd1            : out std_logic_vector(DATA_WIDTH-1 downto 0);
      dbg_byte_sel_cnt         : out std_logic_vector(2 downto 0);
      dbg_phy_wr_cmd_n         : out std_logic_vector(1 downto 0);       
      dbg_phy_addr             : out std_logic_vector(ADDR_WIDTH*4-1 downto 0);          
      dbg_phy_rd_cmd_n         : out std_logic_vector(1 downto 0);       
      dbg_phy_wr_data          : out std_logic_vector(DATA_WIDTH*4-1 downto 0);        
      dbg_wr_init              : out std_logic_vector(255 downto 0);           
      dbg_mc_phy               : out std_logic_vector(255 downto 0);           
      dbg_rd_stage1_cal        : out std_logic_vector(255 downto 0);      
      dbg_stage2_cal           : out std_logic_vector(127 downto 0);         
      dbg_valid_lat            : out std_logic_vector(4 downto 0);          
      dbg_inc_latency          : out std_logic_vector(N_DATA_LANES-1 downto 0);        
      dbg_error_max_latency    : out std_logic_vector(N_DATA_LANES-1 downto 0);  
      dbg_error_adj_latency    : out std_logic  
    );
  end component mig_7series_v1_8_qdr_phy_top;
  
component qdr_sram
  generic
  (

  C0_MEM_TYPE              : string := "QDR2PLUS";
                                    -- # of CK/CK# outputs to memory.
  C0_DATA_WIDTH            : integer := 18;
                                    -- # of DQ (data)
  C0_BW_WIDTH              : integer := 2;
                                    -- # of byte writes (data_width/9)
  C0_ADDR_WIDTH            : integer := 20;
                                    -- Address Width
  C0_NUM_DEVICES           : integer := 1;
                                    -- # of memory components connected
  C0_MEM_RD_LATENCY        : real := 2.5;
                                    -- Value of Memory part read latency
  C0_CPT_CLK_CQ_ONLY       : string := "FALSE";
                                    -- whether CQ and its inverse are used for the data capture
  C0_INTER_BANK_SKEW       : integer := 0;
                                    -- Clock skew between two adjacent banks
  C0_PHY_CONTROL_MASTER_BANK : integer := 1;
                                    -- The bank index where master PHY_CONTROL resides,
                                    -- equal to the PLL residing bank

  --***************************************************************************
  -- The following parameters are mode register settings
  --***************************************************************************
  C0_BURST_LEN             : integer := 4;
                                    -- Burst Length of the design (4 or 2).
  C0_FIXED_LATENCY_MODE    : integer := 0;
                                    -- Enable Fixed Latency
  C0_PHY_LATENCY           : integer := 0;
                                    -- Value for Fixed Latency Mode
                                    -- Expected Latency
  
  --***************************************************************************
  -- The following parameters are multiplier and divisor factors for MMCM.
  -- Based on the selected design frequency these parameters vary.
  --***************************************************************************
  C0_CLKIN_PERIOD          : integer := 2500;
                          -- Input Clock Period
  C0_CLKFBOUT_MULT         : integer := 9;
                          -- write PLL VCO multiplier
  C0_DIVCLK_DIVIDE         : integer := 4;
                          -- write PLL VCO divisor
  C0_CLKOUT0_DIVIDE        : integer := 2;
                          -- VCO output divisor for PLL output clock (CLKOUT0)
  C0_CLKOUT1_DIVIDE        : integer := 2;
                          -- VCO output divisor for PLL output clock (CLKOUT1)
  C0_CLKOUT2_DIVIDE        : integer := 32;
                          -- VCO output divisor for PLL output clock (CLKOUT2)
  C0_CLKOUT3_DIVIDE        : integer := 4;
                          -- VCO output divisor for PLL output clock (CLKOUT3)
  C0_CLKOUT4_DIVIDE        : integer := 4;
                          -- VCO output divisor for PLL output clock (CLKOUT3)

  --***************************************************************************
  -- Simulation parameters
  --***************************************************************************
  C0_SIM_BYPASS_INIT_CAL   : string := "OFF";
                                    -- # = "OFF" -  Complete memory init &
                                    --              calibration sequence
                                    -- # = "SKIP" - Skip memory init &
                                    --              calibration sequence
                                    -- # = "FAST" - Skip memory init & use
                                    --              abbreviated calib sequence
  C0_SIMULATION            : string := "FALSE";
                                    -- Should be TRUE during design simulations and
                                    -- FALSE during implementations

  --***************************************************************************
  -- The following parameters varies based on the pin out entered in MIG GUI.
  -- Do not change any of these parameters directly by editing the RTL.
  -- Any changes required should be done through GUI and the design regenerated.
  --***************************************************************************
  C0_BYTE_LANES_B0         : std_logic_vector(3 downto 0) := "1100";
                                    -- Byte lanes used in an IO column.
  C0_BYTE_LANES_B1         : std_logic_vector(3 downto 0) := "1111";
                                    -- Byte lanes used in an IO column.
  C0_BYTE_LANES_B2         : std_logic_vector(3 downto 0) := "0000";
                                    -- Byte lanes used in an IO column.
  C0_BYTE_LANES_B3         : std_logic_vector(3 downto 0) := "0000";
                                    -- Byte lanes used in an IO column.
  C0_BYTE_LANES_B4         : std_logic_vector(3 downto 0) := "0000";
                                    -- Byte lanes used in an IO column.
  C0_DATA_CTL_B0           : std_logic_vector(3 downto 0) := "1100";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane
  C0_DATA_CTL_B1           : std_logic_vector(3 downto 0) := "1100";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane
  C0_DATA_CTL_B2           : std_logic_vector(3 downto 0) := "0000";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane
  C0_DATA_CTL_B3           : std_logic_vector(3 downto 0) := "0000";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane
  C0_DATA_CTL_B4           : std_logic_vector(3 downto 0) := "0000";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane

  -- this parameter specifies the location of the capture clock with respect
  -- to read data.
  -- Each byte refers to the information needed for data capture in the corresponding byte lane
  -- Lower order nibble - is either 4'h1 or 4'h2. This refers to the capture clock in T1 or T2 byte lane
  -- Higher order nibble - 4'h0 refers to clock present in the bank below the read data,
  --                       4'h1 refers to clock present in the same bank as the read data,
  --                       4'h2 refers to clock present in the bank above the read data.
  C0_CPT_CLK_SEL_B0       : std_logic_vector(31 downto 0) := X"11_11_00_00";
  C0_CPT_CLK_SEL_B1       : std_logic_vector(31 downto 0) := X"00_00_00_00";
  C0_CPT_CLK_SEL_B2       : std_logic_vector(31 downto 0) := X"00_00_00_00";

  C0_PHY_0_BITLANES       : std_logic_vector(47 downto 0) := X"DFC_FF1_000_000";
                                    -- The bits used inside the Bank0 out of 48 pins.
  C0_PHY_1_BITLANES       : std_logic_vector(47 downto 0) := X"3FE_FFE_FFF_CFF";
                                    -- The bits used inside the Bank1 out of 48 pins.
  C0_PHY_2_BITLANES       : std_logic_vector(47 downto 0) := X"000_000_000_000";
                                    -- The bits used inside the Bank2 out of 48 pins.
  C0_PHY_3_BITLANES       : std_logic_vector(47 downto 0) := X"000_000_000_000";
                                    -- The bits used inside the Bank3 out of 48 pins.
  C0_PHY_4_BITLANES       : std_logic_vector(47 downto 0) := X"000_000_000_000";
                                    -- The bits used inside the Bank4 out of 48 pins.

  -- Differentiates the INPUT and OUTPUT bytelates (1-input, 0-output)
  C0_BYTE_GROUP_TYPE_B0   : std_logic_vector(3 downto 0) := "1100";
  C0_BYTE_GROUP_TYPE_B1   : std_logic_vector(3 downto 0) := "0000";
  C0_BYTE_GROUP_TYPE_B2   : std_logic_vector(3 downto 0) := "0000";
  C0_BYTE_GROUP_TYPE_B3   : std_logic_vector(3 downto 0) := "0000";
  C0_BYTE_GROUP_TYPE_B4   : std_logic_vector(3 downto 0) := "0000";

  -- mapping for K/K# clocks. This parameter needs to have an 8-bit value per component
  -- since the phy drives a K/K# clock pair to each memory it interfaces to. A 3 component
  -- interface is supported for now. This parameter needs to be used in conjunction with
  -- NUM_DEVICES parameter which provides information on the number. of components being
  -- interfaced to.
  -- the 8 bit for each component is defined as follows:
  -- [7:4] - bank number ; [3:0] - byte lane number
  C0_K_MAP : std_logic_vector(47 downto 0) := X"00_00_00_00_00_13";

  -- mapping for CQ/CQ# clocks. This parameter needs to have an 4-bit value per component
  -- since the phy drives a CQ/CQ# clock pair to each memory it interfaces to. A 3 component
  -- interface is supported for now. This parameter needs to be used in conjunction with
  -- NUM_DEVICES parameter which provides information on the number. of components being
  -- interfaced to.
  -- the 4 bit for each component is defined as follows:
  -- [3:0] - bank number
  C0_CQ_MAP : std_logic_vector(47 downto 0) := X"00_00_00_00_00_01";

  --**********************************************************************************************
  -- Each of the following parameter contains the byte_lane and bit position information for
  -- the address/control, data write and data read signals. Each bit has 12 bits and the details are
  -- [3:0] - Bit position within a byte lane .
  -- [7:4] - Byte lane position within a bank. [5:4] have the byte lane position and others reserved.
  -- [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero .
  --**********************************************************************************************

  -- Mapping for address and control signals.

  C0_RD_MAP : std_logic_vector(11 downto 0) := X"103";      -- Mapping for read enable signal
  C0_WR_MAP : std_logic_vector(11 downto 0) := X"105";      -- Mapping for write enable signal

  -- Mapping for address signals. Supports upto 22 bits of address bits (22*12)
  C0_ADD_MAP : std_logic_vector(263 downto 0) := X"000_000_119_118_110_116_112_113_111_114_11A_11B_117_115_10B_100_104_102_106_10A_101_107";

  -- Mapping for the byte lanes used for address/control signals. Supports a maximum of 3 banks.
  C0_ADDR_CTL_MAP : std_logic_vector(23 downto 0) := X"00_11_10";

  -- Mapping for data WRITE signals

  -- Mapping for data write bytes (9*12)
  C0_D0_MAP  : std_logic_vector(107 downto 0) := X"137_132_136_139_138_134_133_131_135"; --byte 0
  C0_D1_MAP  : std_logic_vector(107 downto 0) := X"123_122_12B_125_124_12A_121_126_127"; --byte 1
  C0_D2_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 2
  C0_D3_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 3
  C0_D4_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 4
  C0_D5_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 5
  C0_D6_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 6
  C0_D7_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 7

  -- Mapping for byte write signals (8*12)
  C0_BW_MAP : std_logic_vector(83 downto 0) := X"000_000_000_000_000_129_128";

  -- Mapping for data READ signals

  -- Mapping for data read bytes (9*12)
  C0_Q0_MAP  : std_logic_vector(107 downto 0) := X"020_02A_025_027_02B_026_024_028_029"; --byte 0
  C0_Q1_MAP  : std_logic_vector(107 downto 0) := X"032_033_03A_035_034_03B_036_037_038"; --byte 1
  C0_Q2_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 2
  C0_Q3_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 3
  C0_Q4_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 4
  C0_Q5_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 5
  C0_Q6_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 6
  C0_Q7_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 7

  --***************************************************************************
  -- IODELAY and PHY related parameters
  --***************************************************************************
  C0_IODELAY_HP_MODE      : string := "ON";
                                    -- to phy_top
  C0_IBUF_LPWR_MODE       : string := "OFF";
                                    -- to phy_top
  C0_TCQ                  : integer := 100;
    IODELAY_GRP           : string := "IODELAY_MIG";
                                    -- It is associated to a set of IODELAYs with
                                    -- an IDELAYCTRL that have same IODELAY CONTROLLER
                                    -- clock frequency.
  SYSCLK_TYPE           : string := "DIFFERENTIAL";
                                    -- System clock type DIFFERENTIAL, SINGLE_ENDED,
                                    -- NO_BUFFER
     
  -- Number of taps in target IDELAY
  DEVICE_TAPS : integer := 32;

  
  --***************************************************************************
  -- Referece clock frequency parameters
  --***************************************************************************
  REFCLK_FREQ           : real := 200.0;
                                    -- IODELAYCTRL reference clock frequency
     
  --***************************************************************************
  -- System clock frequency parameters
  --***************************************************************************
  C0_CLK_PERIOD            : integer := 2222;
                                    -- memory tCK paramter.
                                    -- # = Clock Period in pS.
  C0_nCK_PER_CLK           : integer := 2;
                                    -- # of memory CKs per fabric CLK
  C0_DIFF_TERM_SYSCLK      : string := "TRUE";
                                    -- Differential Termination for System
                                    -- clock input pins

  

  --***************************************************************************
  -- Wait period for the read strobe (CQ) to become stable
  --***************************************************************************
    C0_CLK_STABLE            : integer := (20*1000*1000/(2222*2)) + 1;
                                    -- Cycles till CQ/CQ# is stable
  
  --***************************************************************************
  -- Debug parameter
  --***************************************************************************
  C0_DEBUG_PORT            : string := "OFF";
                                    -- # = "ON" Enable debug signals/controls.
                                    --   = "OFF" Disable debug signals/controls.
     
  C1_MEM_TYPE              : string := "QDR2PLUS";
                                    -- # of CK/CK# outputs to memory.
  C1_DATA_WIDTH            : integer := 18;
                                    -- # of DQ (data)
  C1_BW_WIDTH              : integer := 2;
                                    -- # of byte writes (data_width/9)
  C1_ADDR_WIDTH            : integer := 20;
                                    -- Address Width
  C1_NUM_DEVICES           : integer := 1;
                                    -- # of memory components connected
  C1_MEM_RD_LATENCY        : real := 2.5;
                                    -- Value of Memory part read latency
  C1_CPT_CLK_CQ_ONLY       : string := "FALSE";
                                    -- whether CQ and its inverse are used for the data capture
  C1_INTER_BANK_SKEW       : integer := 0;
                                    -- Clock skew between two adjacent banks
  C1_PHY_CONTROL_MASTER_BANK : integer := 1;
                                    -- The bank index where master PHY_CONTROL resides,
                                    -- equal to the PLL residing bank

  --***************************************************************************
  -- The following parameters are mode register settings
  --***************************************************************************
  C1_BURST_LEN             : integer := 4;
                                    -- Burst Length of the design (4 or 2).
  C1_FIXED_LATENCY_MODE    : integer := 0;
                                    -- Enable Fixed Latency
  C1_PHY_LATENCY           : integer := 0;
                                    -- Value for Fixed Latency Mode
                                    -- Expected Latency
  
  --***************************************************************************
  -- The following parameters are multiplier and divisor factors for MMCM.
  -- Based on the selected design frequency these parameters vary.
  --***************************************************************************
  C1_CLKIN_PERIOD          : integer := 2500;
                          -- Input Clock Period
  C1_CLKFBOUT_MULT         : integer := 9;
                          -- write PLL VCO multiplier
  C1_DIVCLK_DIVIDE         : integer := 4;
                          -- write PLL VCO divisor
  C1_CLKOUT0_DIVIDE        : integer := 2;
                          -- VCO output divisor for PLL output clock (CLKOUT0)
  C1_CLKOUT1_DIVIDE        : integer := 2;
                          -- VCO output divisor for PLL output clock (CLKOUT1)
  C1_CLKOUT2_DIVIDE        : integer := 32;
                          -- VCO output divisor for PLL output clock (CLKOUT2)
  C1_CLKOUT3_DIVIDE        : integer := 4;
                          -- VCO output divisor for PLL output clock (CLKOUT3)
  C1_CLKOUT4_DIVIDE        : integer := 4;
                          -- VCO output divisor for PLL output clock (CLKOUT3)

  --***************************************************************************
  -- Simulation parameters
  --***************************************************************************
  C1_SIM_BYPASS_INIT_CAL   : string := "OFF";
                                    -- # = "OFF" -  Complete memory init &
                                    --              calibration sequence
                                    -- # = "SKIP" - Skip memory init &
                                    --              calibration sequence
                                    -- # = "FAST" - Skip memory init & use
                                    --              abbreviated calib sequence
  C1_SIMULATION            : string := "FALSE";
                                    -- Should be TRUE during design simulations and
                                    -- FALSE during implementations

  --***************************************************************************
  -- The following parameters varies based on the pin out entered in MIG GUI.
  -- Do not change any of these parameters directly by editing the RTL.
  -- Any changes required should be done through GUI and the design regenerated.
  --***************************************************************************
  C1_BYTE_LANES_B0         : std_logic_vector(3 downto 0) := "1100";
                                    -- Byte lanes used in an IO column.
  C1_BYTE_LANES_B1         : std_logic_vector(3 downto 0) := "1111";
                                    -- Byte lanes used in an IO column.
  C1_BYTE_LANES_B2         : std_logic_vector(3 downto 0) := "0000";
                                    -- Byte lanes used in an IO column.
  C1_BYTE_LANES_B3         : std_logic_vector(3 downto 0) := "0000";
                                    -- Byte lanes used in an IO column.
  C1_BYTE_LANES_B4         : std_logic_vector(3 downto 0) := "0000";
                                    -- Byte lanes used in an IO column.
  C1_DATA_CTL_B0           : std_logic_vector(3 downto 0) := "1100";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane
  C1_DATA_CTL_B1           : std_logic_vector(3 downto 0) := "1100";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane
  C1_DATA_CTL_B2           : std_logic_vector(3 downto 0) := "0000";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane
  C1_DATA_CTL_B3           : std_logic_vector(3 downto 0) := "0000";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane
  C1_DATA_CTL_B4           : std_logic_vector(3 downto 0) := "0000";
                                    -- Indicates Byte lane is data byte lane
                                    -- or control Byte lane. '1' in a bit
                                    -- position indicates a data byte lane and
                                    -- a '0' indicates a control byte lane

  -- this parameter specifies the location of the capture clock with respect
  -- to read data.
  -- Each byte refers to the information needed for data capture in the corresponding byte lane
  -- Lower order nibble - is either 4'h1 or 4'h2. This refers to the capture clock in T1 or T2 byte lane
  -- Higher order nibble - 4'h0 refers to clock present in the bank below the read data,
  --                       4'h1 refers to clock present in the same bank as the read data,
  --                       4'h2 refers to clock present in the bank above the read data.
  C1_CPT_CLK_SEL_B0       : std_logic_vector(31 downto 0) := X"11_11_00_00";
  C1_CPT_CLK_SEL_B1       : std_logic_vector(31 downto 0) := X"00_00_00_00";
  C1_CPT_CLK_SEL_B2       : std_logic_vector(31 downto 0) := X"00_00_00_00";

  C1_PHY_0_BITLANES       : std_logic_vector(47 downto 0) := X"FF8_DFC_000_000";
                                    -- The bits used inside the Bank0 out of 48 pins.
  C1_PHY_1_BITLANES       : std_logic_vector(47 downto 0) := X"3FE_FFE_FFF_EFD";
                                    -- The bits used inside the Bank1 out of 48 pins.
  C1_PHY_2_BITLANES       : std_logic_vector(47 downto 0) := X"000_000_000_000";
                                    -- The bits used inside the Bank2 out of 48 pins.
  C1_PHY_3_BITLANES       : std_logic_vector(47 downto 0) := X"000_000_000_000";
                                    -- The bits used inside the Bank3 out of 48 pins.
  C1_PHY_4_BITLANES       : std_logic_vector(47 downto 0) := X"000_000_000_000";
                                    -- The bits used inside the Bank4 out of 48 pins.

  -- Differentiates the INPUT and OUTPUT bytelates (1-input, 0-output)
  C1_BYTE_GROUP_TYPE_B0   : std_logic_vector(3 downto 0) := "1100";
  C1_BYTE_GROUP_TYPE_B1   : std_logic_vector(3 downto 0) := "0000";
  C1_BYTE_GROUP_TYPE_B2   : std_logic_vector(3 downto 0) := "0000";
  C1_BYTE_GROUP_TYPE_B3   : std_logic_vector(3 downto 0) := "0000";
  C1_BYTE_GROUP_TYPE_B4   : std_logic_vector(3 downto 0) := "0000";

  -- mapping for K/K# clocks. This parameter needs to have an 8-bit value per component
  -- since the phy drives a K/K# clock pair to each memory it interfaces to. A 3 component
  -- interface is supported for now. This parameter needs to be used in conjunction with
  -- NUM_DEVICES parameter which provides information on the number. of components being
  -- interfaced to.
  -- the 8 bit for each component is defined as follows:
  -- [7:4] - bank number ; [3:0] - byte lane number
  C1_K_MAP : std_logic_vector(47 downto 0) := X"00_00_00_00_00_13";

  -- mapping for CQ/CQ# clocks. This parameter needs to have an 4-bit value per component
  -- since the phy drives a CQ/CQ# clock pair to each memory it interfaces to. A 3 component
  -- interface is supported for now. This parameter needs to be used in conjunction with
  -- NUM_DEVICES parameter which provides information on the number. of components being
  -- interfaced to.
  -- the 4 bit for each component is defined as follows:
  -- [3:0] - bank number
  C1_CQ_MAP : std_logic_vector(47 downto 0) := X"00_00_00_00_00_01";

  --**********************************************************************************************
  -- Each of the following parameter contains the byte_lane and bit position information for
  -- the address/control, data write and data read signals. Each bit has 12 bits and the details are
  -- [3:0] - Bit position within a byte lane .
  -- [7:4] - Byte lane position within a bank. [5:4] have the byte lane position and others reserved.
  -- [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero .
  --**********************************************************************************************

  -- Mapping for address and control signals.

  C1_RD_MAP : std_logic_vector(11 downto 0) := X"102";      -- Mapping for read enable signal
  C1_WR_MAP : std_logic_vector(11 downto 0) := X"103";      -- Mapping for write enable signal

  -- Mapping for address signals. Supports upto 22 bits of address bits (22*12)
  C1_ADD_MAP : std_logic_vector(263 downto 0) := X"000_000_113_11A_112_115_118_111_109_114_110_119_11B_116_117_100_107_106_10B_10A_105_104";

  -- Mapping for the byte lanes used for address/control signals. Supports a maximum of 3 banks.
  C1_ADDR_CTL_MAP : std_logic_vector(23 downto 0) := X"00_11_10";

  -- Mapping for data WRITE signals

  -- Mapping for data write bytes (9*12)
  C1_D0_MAP  : std_logic_vector(107 downto 0) := X"12A_12B_127_126_124_125_122_123_121"; --byte 0
  C1_D1_MAP  : std_logic_vector(107 downto 0) := X"131_139_138_132_133_135_137_136_134"; --byte 1
  C1_D2_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 2
  C1_D3_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 3
  C1_D4_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 4
  C1_D5_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 5
  C1_D6_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 6
  C1_D7_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 7

  -- Mapping for byte write signals (8*12)
  C1_BW_MAP : std_logic_vector(83 downto 0) := X"000_000_000_000_000_128_129";

  -- Mapping for data READ signals

  -- Mapping for data read bytes (9*12)
  C1_Q0_MAP  : std_logic_vector(107 downto 0) := X"027_022_028_023_025_024_02A_02B_026"; --byte 0
  C1_Q1_MAP  : std_logic_vector(107 downto 0) := X"036_037_035_034_039_03B_038_033_03A"; --byte 1
  C1_Q2_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 2
  C1_Q3_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 3
  C1_Q4_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 4
  C1_Q5_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 5
  C1_Q6_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 6
  C1_Q7_MAP  : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000"; --byte 7

  --***************************************************************************
  -- IODELAY and PHY related parameters
  --***************************************************************************
  C1_IODELAY_HP_MODE      : string := "ON";
                                    -- to phy_top
  C1_IBUF_LPWR_MODE       : string := "OFF";
                                    -- to phy_top
  C1_TCQ                  : integer := 100;
  

  
  --***************************************************************************
  -- System clock frequency parameters
  --***************************************************************************
  C1_CLK_PERIOD            : integer := 2222;
                                    -- memory tCK paramter.
                                    -- # = Clock Period in pS.
  C1_nCK_PER_CLK           : integer := 2;
                                    -- # of memory CKs per fabric CLK
  C1_DIFF_TERM_SYSCLK      : string := "TRUE";
                                    -- Differential Termination for System
                                    -- clock input pins

  

  --***************************************************************************
  -- Wait period for the read strobe (CQ) to become stable
  --***************************************************************************
    C1_CLK_STABLE            : integer := (20*1000*1000/(2222*2)) + 1;
                                    -- Cycles till CQ/CQ# is stable
  
  --***************************************************************************
  -- Debug parameter
  --***************************************************************************
  C1_DEBUG_PORT            : string := "OFF";
                                    -- # = "ON" Enable debug signals/controls.
                                    --   = "OFF" Disable debug signals/controls.
     
   RST_ACT_LOW           : integer := 1
                                     -- =1 for active low reset,
                                     -- =0 for active high.
   );
  port
  (
  -- Differential system clocks
  sys_clk       : in  std_logic;
  --sys_clk_p       : in  std_logic;
  --sys_clk_n       : in  std_logic;
  --Memory Interface Ports
  c0_qdriip_cq_p     : in  std_logic_vector(C0_NUM_DEVICES-1 downto 0);
  c0_qdriip_cq_n     : in  std_logic_vector(C0_NUM_DEVICES-1 downto 0);
  --c0_qdriip_qvld     : in  std_logic_vector(C0_NUM_DEVICES-1 downto 0);
  c0_qdriip_q        : in  std_logic_vector(C0_DATA_WIDTH-1 downto 0);
  c0_qdriip_k_p      : out std_logic_vector(C0_NUM_DEVICES-1 downto 0);
  c0_qdriip_k_n      : out std_logic_vector(C0_NUM_DEVICES-1 downto 0);
  c0_qdriip_d        : out std_logic_vector(C0_DATA_WIDTH-1 downto 0);
  c0_qdriip_sa       : out std_logic_vector(C0_ADDR_WIDTH-1 downto 0);
  c0_qdriip_w_n      : out std_logic;
  c0_qdriip_r_n      : out std_logic;
  c0_qdriip_bw_n     : out std_logic_vector(C0_BW_WIDTH-1 downto 0);
  c0_qdriip_dll_off_n: out std_logic;
  
    -- User Interface signals of Channel-0
  c0_app_wr_cmd0   : in  std_logic;
  c0_app_wr_addr0  : in  std_logic_vector(C0_ADDR_WIDTH-1 downto 0);
  c0_app_wr_data0  : in  std_logic_vector(C0_DATA_WIDTH*C0_BURST_LEN-1 downto 0);
  c0_app_wr_bw_n0  : in  std_logic_vector(C0_BW_WIDTH*C0_BURST_LEN-1 downto 0);
  c0_app_rd_cmd0   : in  std_logic;
  c0_app_rd_addr0  : in  std_logic_vector(C0_ADDR_WIDTH-1 downto 0);
  c0_app_rd_valid0 : out std_logic;
  c0_app_rd_data0  : out std_logic_vector(C0_DATA_WIDTH*C0_BURST_LEN-1 downto 0);

  -- User Interface signals of Channel-1. It is useful only for BL2 designs.
  -- All inputs of Channel-1 can be grounded for BL4 designs.
  c0_app_wr_cmd1   : in  std_logic;
  c0_app_wr_addr1  : in  std_logic_vector(C0_ADDR_WIDTH-1 downto 0);
  c0_app_wr_data1  : in  std_logic_vector(C0_DATA_WIDTH*2-1 downto 0);
  c0_app_wr_bw_n1  : in  std_logic_vector(C0_BW_WIDTH*2-1 downto 0);
  c0_app_rd_cmd1   : in  std_logic;
  c0_app_rd_addr1  : in  std_logic_vector(C0_ADDR_WIDTH-1 downto 0);
  c0_app_rd_valid1 : out std_logic;
  c0_app_rd_data1  : out std_logic_vector(C0_DATA_WIDTH*2-1 downto 0);

  c0_clk           : out std_logic;
  c0_rst_clk       : out std_logic;
  
    c0_init_calib_complete : out std_logic;

  --Memory Interface Ports
  c1_qdriip_cq_p     : in  std_logic_vector(C1_NUM_DEVICES-1 downto 0);
  c1_qdriip_cq_n     : in  std_logic_vector(C1_NUM_DEVICES-1 downto 0);
  --c1_qdriip_qvld     : in  std_logic_vector(C1_NUM_DEVICES-1 downto 0);
  c1_qdriip_q        : in  std_logic_vector(C1_DATA_WIDTH-1 downto 0);
  c1_qdriip_k_p      : out std_logic_vector(C1_NUM_DEVICES-1 downto 0);
  c1_qdriip_k_n      : out std_logic_vector(C1_NUM_DEVICES-1 downto 0);
  c1_qdriip_d        : out std_logic_vector(C1_DATA_WIDTH-1 downto 0);
  c1_qdriip_sa       : out std_logic_vector(C1_ADDR_WIDTH-1 downto 0);
  c1_qdriip_w_n      : out std_logic;
  c1_qdriip_r_n      : out std_logic;
  c1_qdriip_bw_n     : out std_logic_vector(C1_BW_WIDTH-1 downto 0);
  c1_qdriip_dll_off_n: out std_logic;
  
    -- User Interface signals of Channel-0
  c1_app_wr_cmd0   : in  std_logic;
  c1_app_wr_addr0  : in  std_logic_vector(C1_ADDR_WIDTH-1 downto 0);
  c1_app_wr_data0  : in  std_logic_vector(C1_DATA_WIDTH*C1_BURST_LEN-1 downto 0);
  c1_app_wr_bw_n0  : in  std_logic_vector(C1_BW_WIDTH*C1_BURST_LEN-1 downto 0);
  c1_app_rd_cmd0   : in  std_logic;
  c1_app_rd_addr0  : in  std_logic_vector(C1_ADDR_WIDTH-1 downto 0);
  c1_app_rd_valid0 : out std_logic;
  c1_app_rd_data0  : out std_logic_vector(C1_DATA_WIDTH*C1_BURST_LEN-1 downto 0);

  -- User Interface signals of Channel-1. It is useful only for BL2 designs.
  -- All inputs of Channel-1 can be grounded for BL4 designs.
  c1_app_wr_cmd1   : in  std_logic;
  c1_app_wr_addr1  : in  std_logic_vector(C1_ADDR_WIDTH-1 downto 0);
  c1_app_wr_data1  : in  std_logic_vector(C1_DATA_WIDTH*2-1 downto 0);
  c1_app_wr_bw_n1  : in  std_logic_vector(C1_BW_WIDTH*2-1 downto 0);
  c1_app_rd_cmd1   : in  std_logic;
  c1_app_rd_addr1  : in  std_logic_vector(C1_ADDR_WIDTH-1 downto 0);
  c1_app_rd_valid1 : out std_logic;
  c1_app_rd_data1  : out std_logic_vector(C1_DATA_WIDTH*2-1 downto 0);

  c1_clk           : out std_logic;
  c1_rst_clk       : out std_logic;
  
    c1_init_calib_complete : out std_logic;
     
   -- System reset
   sys_rst         : in std_logic
 );
end component;

end core_definitions;
