

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_definitions.all;
--use work.test_definitions.all;
use work.ipbus.all;
use work.package_utilities.all;


entity qdr_ipbus is
  generic (
      C0_MEM_TYPE                : string  := "QDR2PLUS";
      -- # of CK/CK# outputs to memory.
      C0_DATA_WIDTH              : integer := 18;
      -- # of DQ (data)
      C0_BW_WIDTH                : integer := 2;
      -- # of byte writes (data_width/9)
      C0_ADDR_WIDTH              : integer := 20;
      -- Address Width
      C0_NUM_DEVICES             : integer := 1;
      -- # of memory components connected
      C0_MEM_RD_LATENCY          : real    := 2.5;
      -- Value of Memory part read latency
      C0_CPT_CLK_CQ_ONLY         : string  := "TRUE";
      -- whether CQ and its inverse are used for the data capture
      C0_INTER_BANK_SKEW         : integer := 0;
      -- Clock skew between two adjacent banks
      C0_PHY_CONTROL_MASTER_BANK : integer := 1;
      -- The bank index where master PHY_CONTROL resides,
      -- equal to the PLL residing bank

      --***************************************************************************
      -- The following parameters are mode register settings
      --***************************************************************************
      C0_BURST_LEN          : integer := 4;
      -- Burst Length of the design (4 or 2).
      C0_FIXED_LATENCY_MODE : integer := 0;
      -- Enable Fixed Latency
      C0_PHY_LATENCY        : integer := 0;
      -- Value for Fixed Latency Mode
      -- Expected Latency

      --***************************************************************************
      -- The following parameters are multiplier and divisor factors for MMCM.
      -- Based on the selected design frequency these parameters vary.
      --***************************************************************************
      C0_CLKIN_PERIOD   : integer := 8000;  -- 125 MHz
      -- Input Clock Period
      C0_CLKFBOUT_MULT  : integer := 8;  -- 1000 MHz
      -- write PLL VCO multiplier
      C0_DIVCLK_DIVIDE  : integer := 1;  -- 1000 MHz
      -- write PLL VCO divisor
      C0_CLKOUT0_DIVIDE : integer := 2;   -- 500 MHz
      -- VCO output divisor for PLL output clock (CLKOUT0)
      C0_CLKOUT1_DIVIDE : integer := 2;   -- 500 MHz
      -- VCO output divisor for PLL output clock (CLKOUT1)
      C0_CLKOUT2_DIVIDE : integer := 32;  -- 31.25 MHz
      -- VCO output divisor for PLL output clock (CLKOUT2)
      C0_CLKOUT3_DIVIDE : integer := 4;  -- 250 MHz
      -- VCO output divisor for PLL output clock (CLKOUT3)
      C0_CLKOUT4_DIVIDE : integer := 5;  -- 200 MHz
      -- VCO output divisor for PLL output clock (CLKOUT4)

      --***************************************************************************
      -- Simulation parameters
      --***************************************************************************
      C0_SIM_BYPASS_INIT_CAL : string := "OFF";
      -- # = "OFF" -  Complete memory init &
      --              calibration sequence
      -- # = "SKIP" - Skip memory init &
      --              calibration sequence
      -- # = "FAST" - Skip memory init & use
      --              abbreviated calib sequence
      C0_SIMULATION          : string := "FALSE";
      -- Should be TRUE during design simulations and
      -- FALSE during implementations

      --***************************************************************************
      -- The following parameters varies based on the pin out entered in MIG GUI.
      -- Do not change any of these parameters directly by editing the RTL.
      -- Any changes required should be done through GUI and the design regenerated.
      --***************************************************************************
      C0_BYTE_LANES_B0 : std_logic_vector(3 downto 0) := "1100";
      -- Byte lanes used in an IO column.
      C0_BYTE_LANES_B1 : std_logic_vector(3 downto 0) := "1111";
      -- Byte lanes used in an IO column.
      C0_BYTE_LANES_B2 : std_logic_vector(3 downto 0) := "0000";
      -- Byte lanes used in an IO column.
      C0_BYTE_LANES_B3 : std_logic_vector(3 downto 0) := "0000";
      -- Byte lanes used in an IO column.
      C0_BYTE_LANES_B4 : std_logic_vector(3 downto 0) := "0000";
      -- Byte lanes used in an IO column.
      C0_DATA_CTL_B0   : std_logic_vector(3 downto 0) := "1100";
      -- Indicates Byte lane is data byte lane
      -- or control Byte lane. '1' in a bit
      -- position indicates a data byte lane and
      -- a '0' indicates a control byte lane
      C0_DATA_CTL_B1   : std_logic_vector(3 downto 0) := "1100";
      -- Indicates Byte lane is data byte lane
      -- or control Byte lane. '1' in a bit
      -- position indicates a data byte lane and
      -- a '0' indicates a control byte lane
      C0_DATA_CTL_B2   : std_logic_vector(3 downto 0) := "0000";
      -- Indicates Byte lane is data byte lane
      -- or control Byte lane. '1' in a bit
      -- position indicates a data byte lane and
      -- a '0' indicates a control byte lane
      C0_DATA_CTL_B3   : std_logic_vector(3 downto 0) := "0000";
      -- Indicates Byte lane is data byte lane
      -- or control Byte lane. '1' in a bit
      -- position indicates a data byte lane and
      -- a '0' indicates a control byte lane
      C0_DATA_CTL_B4   : std_logic_vector(3 downto 0) := "0000";
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
      C0_CPT_CLK_SEL_B0 : std_logic_vector(31 downto 0) := X"11_11_00_00";
      C0_CPT_CLK_SEL_B1 : std_logic_vector(31 downto 0) := X"00_00_00_00";
      C0_CPT_CLK_SEL_B2 : std_logic_vector(31 downto 0) := X"00_00_00_00";

      C0_PHY_0_BITLANES : std_logic_vector(47 downto 0) := X"DFC_FF1_000_000";
      -- The bits used inside the Bank0 out of 48 pins.
      C0_PHY_1_BITLANES : std_logic_vector(47 downto 0) := X"3FE_FFE_FFF_CFF";
      -- The bits used inside the Bank1 out of 48 pins.
      C0_PHY_2_BITLANES : std_logic_vector(47 downto 0) := X"000_000_000_000";
      -- The bits used inside the Bank2 out of 48 pins.
      C0_PHY_3_BITLANES : std_logic_vector(47 downto 0) := X"000_000_000_000";
      -- The bits used inside the Bank3 out of 48 pins.
      C0_PHY_4_BITLANES : std_logic_vector(47 downto 0) := X"000_000_000_000";
      -- The bits used inside the Bank4 out of 48 pins.

      -- Differentiates the INPUT and OUTPUT bytelates (1-input, 0-output)
      C0_BYTE_GROUP_TYPE_B0 : std_logic_vector(3 downto 0) := "1100";
      C0_BYTE_GROUP_TYPE_B1 : std_logic_vector(3 downto 0) := "0000";
      C0_BYTE_GROUP_TYPE_B2 : std_logic_vector(3 downto 0) := "0000";
      C0_BYTE_GROUP_TYPE_B3 : std_logic_vector(3 downto 0) := "0000";
      C0_BYTE_GROUP_TYPE_B4 : std_logic_vector(3 downto 0) := "0000";

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

      C0_RD_MAP : std_logic_vector(11 downto 0) := X"103";  -- Mapping for read enable signal
      C0_WR_MAP : std_logic_vector(11 downto 0) := X"105";  -- Mapping for write enable signal

      -- Mapping for address signals. Supports upto 22 bits of address bits (22*12)
      C0_ADD_MAP : std_logic_vector(263 downto 0) := X"000_000_119_118_110_116_112_113_111_114_11A_11B_117_115_10B_100_104_102_106_10A_101_107";

      -- Mapping for the byte lanes used for address/control signals. Supports a maximum of 3 banks.
      C0_ADDR_CTL_MAP : std_logic_vector(23 downto 0) := X"00_11_10";

      -- Mapping for data WRITE signals

      -- Mapping for data write bytes (9*12)
      C0_D0_MAP : std_logic_vector(107 downto 0) := X"137_132_136_139_138_134_133_131_135";  --byte 0
      C0_D1_MAP : std_logic_vector(107 downto 0) := X"123_122_12B_125_124_12A_121_126_127";  --byte 1
      C0_D2_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 2
      C0_D3_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 3
      C0_D4_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 4
      C0_D5_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 5
      C0_D6_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 6
      C0_D7_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 7

      -- Mapping for byte write signals (8*12)
      C0_BW_MAP : std_logic_vector(83 downto 0) := X"000_000_000_000_000_129_128";

      -- Mapping for data READ signals

      -- Mapping for data read bytes (9*12)
      C0_Q0_MAP : std_logic_vector(107 downto 0) := X"020_02A_025_027_02B_026_024_028_029";  --byte 0
      C0_Q1_MAP : std_logic_vector(107 downto 0) := X"032_033_03A_035_034_03B_036_037_038";  --byte 1
      C0_Q2_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 2
      C0_Q3_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 3
      C0_Q4_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 4
      C0_Q5_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 5
      C0_Q6_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 6
      C0_Q7_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 7

      --***************************************************************************
      -- IODELAY and PHY related parameters
      --***************************************************************************
      C0_IODELAY_HP_MODE : string  := "ON";
      -- to phy_top
      C0_IBUF_LPWR_MODE  : string  := "OFF";
      -- to phy_top
      C0_TCQ             : integer := 100;
      IODELAY_GRP        : string  := "IODELAY_MIG";
      -- It is associated to a set of IODELAYs with
      -- an IDELAYCTRL that have same IODELAY CONTROLLER
      -- clock frequency.
      SYSCLK_TYPE        : string  := "DIFFERENTIAL";
      -- System clock type DIFFERENTIAL, SINGLE_ENDED,
      -- NO_BUFFER

      -- Number of taps in target IDELAY
      DEVICE_TAPS : integer := 32;

      --***************************************************************************
      -- Referece clock frequency parameters
      --***************************************************************************
      REFCLK_FREQ      : real   := 200.0;
      -- IODELAYCTRL reference clock frequency

      --***************************************************************************
      -- System clock frequency parameters
      --***************************************************************************
      C0_CLK_PERIOD       : integer := 2222;
      -- memory tCK paramter.
      -- # = Clock Period in pS.
      C0_nCK_PER_CLK      : integer := 2;
      -- # of memory CKs per fabric CLK
      C0_DIFF_TERM_SYSCLK : string  := "TRUE";
      -- Differential Termination for System
      -- clock input pins

      --***************************************************************************
      -- Traffic Gen related parameters
      --***************************************************************************
      C0_BL_WIDTH            : integer                       := 8;
      C0_PORT_MODE           : string                        := "BI_MODE";
      C0_DATA_MODE           : std_logic_vector(3 downto 0)  := "0010";
      C0_TST_MEM_INSTR_MODE  : string                        := "R_W_INSTR_MODE";
      C0_EYE_TEST            : string                        := "FALSE";
      -- set EYE_TEST = "TRUE" to probe memory
      -- signals. Traffic Generator will only
      -- write to one single location and no
      -- read transactions will be generated.
      C0_DATA_PATTERN        : string                        := "DGEN_ALL";
      -- "DGEN_HAMMER", "DGEN_WALKING1",
      -- "DGEN_WALKING0","DGEN_ADDR","
      -- "DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"
      C0_CMD_PATTERN         : string                        := "CGEN_ALL";
      -- "CGEN_PRBS","CGEN_FIXED","CGEN_BRAM",
      -- "CGEN_SEQUENTIAL", "CGEN_ALL"
      C0_CMD_WDT               : std_logic_vector(31 downto 0) := X"000003ff";
      C0_WR_WDT                : std_logic_vector(31 downto 0) := X"00001fff";
      C0_RD_WDT                : std_logic_vector(31 downto 0) := X"000003ff";
      C0_BEGIN_ADDRESS         : std_logic_vector(31 downto 0) := X"00000000";
      C0_END_ADDRESS           : std_logic_vector(31 downto 0) := X"00000fff";
      C0_PRBS_EADDR_MASK_POS   : std_logic_vector(31 downto 0) := X"fffff000";

      --***************************************************************************
      -- Wait period for the read strobe (CQ) to become stable
      --***************************************************************************
      C0_CLK_STABLE : integer := (20*1000*1000/(2222*2)) + 1;
      -- Cycles till CQ/CQ# is stable

      --***************************************************************************
      -- Debug parameter
      --***************************************************************************
      C0_DEBUG_PORT : string := "OFF";
      -- # = "ON" Enable debug signals/controls.
      --   = "OFF" Disable debug signals/controls.

      C1_MEM_TYPE                : string  := "QDR2PLUS";
      -- # of CK/CK# outputs to memory.
      C1_DATA_WIDTH              : integer := 18;
      -- # of DQ (data)
      C1_BW_WIDTH                : integer := 2;
      -- # of byte writes (data_width/9)
      C1_ADDR_WIDTH              : integer := 20;
      -- Address Width
      C1_NUM_DEVICES             : integer := 1;
      -- # of memory components connected
      C1_MEM_RD_LATENCY          : real    := 2.5;
      -- Value of Memory part read latency
      C1_CPT_CLK_CQ_ONLY         : string  := "TRUE";
      -- whether CQ and its inverse are used for the data capture
      C1_INTER_BANK_SKEW         : integer := 0;
      -- Clock skew between two adjacent banks
      C1_PHY_CONTROL_MASTER_BANK : integer := 1;
      -- The bank index where master PHY_CONTROL resides,
      -- equal to the PLL residing bank

      --***************************************************************************
      -- The following parameters are mode register settings
      --***************************************************************************
      C1_BURST_LEN          : integer := 4;
      -- Burst Length of the design (4 or 2).
      C1_FIXED_LATENCY_MODE : integer := 0;
      -- Enable Fixed Latency
      C1_PHY_LATENCY        : integer := 0;
      -- Value for Fixed Latency Mode
      -- Expected Latency

      --***************************************************************************
      -- The following parameters are multiplier and divisor factors for MMCM.
      -- Based on the selected design frequency these parameters vary.
      --***************************************************************************
      C1_CLKIN_PERIOD   : integer := 8000;  -- 125 MHz
      -- Input Clock Period
      C1_CLKFBOUT_MULT  : integer := 8;  -- 1000 MHz
      -- write PLL VCO multiplier
      C1_DIVCLK_DIVIDE  : integer := 1;  -- 1000 MHz
      -- write PLL VCO divisor
      C1_CLKOUT0_DIVIDE : integer := 2;   -- 500 MHz
      -- VCO output divisor for PLL output clock (CLKOUT0)
      C1_CLKOUT1_DIVIDE : integer := 2;   -- 500 MHz
      -- VCO output divisor for PLL output clock (CLKOUT1)
      C1_CLKOUT2_DIVIDE : integer := 32;  -- 31.25 MHz
      -- VCO output divisor for PLL output clock (CLKOUT2)
      C1_CLKOUT3_DIVIDE : integer := 4;  -- 250 MHz
      -- VCO output divisor for PLL output clock (CLKOUT3)
      C1_CLKOUT4_DIVIDE : integer := 5;  -- 200 MHz
      -- VCO output divisor for PLL output clock (CLKOUT4)

      --***************************************************************************
      -- Simulation parameters
      --***************************************************************************
      C1_SIM_BYPASS_INIT_CAL : string := "OFF";
      -- # = "OFF" -  Complete memory init &
      --              calibration sequence
      -- # = "SKIP" - Skip memory init &
      --              calibration sequence
      -- # = "FAST" - Skip memory init & use
      --              abbreviated calib sequence
      C1_SIMULATION          : string := "FALSE";
      -- Should be TRUE during design simulations and
      -- FALSE during implementations

      --***************************************************************************
      -- The following parameters varies based on the pin out entered in MIG GUI.
      -- Do not change any of these parameters directly by editing the RTL.
      -- Any changes required should be done through GUI and the design regenerated.
      --***************************************************************************
      C1_BYTE_LANES_B0 : std_logic_vector(3 downto 0) := "1100";
      -- Byte lanes used in an IO column.
      C1_BYTE_LANES_B1 : std_logic_vector(3 downto 0) := "1111";
      -- Byte lanes used in an IO column.
      C1_BYTE_LANES_B2 : std_logic_vector(3 downto 0) := "0000";
      -- Byte lanes used in an IO column.
      C1_BYTE_LANES_B3 : std_logic_vector(3 downto 0) := "0000";
      -- Byte lanes used in an IO column.
      C1_BYTE_LANES_B4 : std_logic_vector(3 downto 0) := "0000";
      -- Byte lanes used in an IO column.
      C1_DATA_CTL_B0   : std_logic_vector(3 downto 0) := "1100";
      -- Indicates Byte lane is data byte lane
      -- or control Byte lane. '1' in a bit
      -- position indicates a data byte lane and
      -- a '0' indicates a control byte lane
      C1_DATA_CTL_B1   : std_logic_vector(3 downto 0) := "1100";
      -- Indicates Byte lane is data byte lane
      -- or control Byte lane. '1' in a bit
      -- position indicates a data byte lane and
      -- a '0' indicates a control byte lane
      C1_DATA_CTL_B2   : std_logic_vector(3 downto 0) := "0000";
      -- Indicates Byte lane is data byte lane
      -- or control Byte lane. '1' in a bit
      -- position indicates a data byte lane and
      -- a '0' indicates a control byte lane
      C1_DATA_CTL_B3   : std_logic_vector(3 downto 0) := "0000";
      -- Indicates Byte lane is data byte lane
      -- or control Byte lane. '1' in a bit
      -- position indicates a data byte lane and
      -- a '0' indicates a control byte lane
      C1_DATA_CTL_B4   : std_logic_vector(3 downto 0) := "0000";
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
      C1_CPT_CLK_SEL_B0 : std_logic_vector(31 downto 0) := X"11_11_00_00";
      C1_CPT_CLK_SEL_B1 : std_logic_vector(31 downto 0) := X"00_00_00_00";
      C1_CPT_CLK_SEL_B2 : std_logic_vector(31 downto 0) := X"00_00_00_00";

      C1_PHY_0_BITLANES : std_logic_vector(47 downto 0) := X"FF8_DFC_000_000";
      -- The bits used inside the Bank0 out of 48 pins.
      C1_PHY_1_BITLANES : std_logic_vector(47 downto 0) := X"3FE_FFE_FFF_EFD";
      -- The bits used inside the Bank1 out of 48 pins.
      C1_PHY_2_BITLANES : std_logic_vector(47 downto 0) := X"000_000_000_000";
      -- The bits used inside the Bank2 out of 48 pins.
      C1_PHY_3_BITLANES : std_logic_vector(47 downto 0) := X"000_000_000_000";
      -- The bits used inside the Bank3 out of 48 pins.
      C1_PHY_4_BITLANES : std_logic_vector(47 downto 0) := X"000_000_000_000";
      -- The bits used inside the Bank4 out of 48 pins.

      -- Differentiates the INPUT and OUTPUT bytelates (1-input, 0-output)
      C1_BYTE_GROUP_TYPE_B0 : std_logic_vector(3 downto 0) := "1100";
      C1_BYTE_GROUP_TYPE_B1 : std_logic_vector(3 downto 0) := "0000";
      C1_BYTE_GROUP_TYPE_B2 : std_logic_vector(3 downto 0) := "0000";
      C1_BYTE_GROUP_TYPE_B3 : std_logic_vector(3 downto 0) := "0000";
      C1_BYTE_GROUP_TYPE_B4 : std_logic_vector(3 downto 0) := "0000";

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

      C1_RD_MAP : std_logic_vector(11 downto 0) := X"102";  -- Mapping for read enable signal
      C1_WR_MAP : std_logic_vector(11 downto 0) := X"103";  -- Mapping for write enable signal

      -- Mapping for address signals. Supports upto 22 bits of address bits (22*12)
      C1_ADD_MAP : std_logic_vector(263 downto 0) := X"000_000_113_11A_112_115_118_111_109_114_110_119_11B_116_117_100_107_106_10B_10A_105_104";

      -- Mapping for the byte lanes used for address/control signals. Supports a maximum of 3 banks.
      C1_ADDR_CTL_MAP : std_logic_vector(23 downto 0) := X"00_11_10";

      -- Mapping for data WRITE signals

      -- Mapping for data write bytes (9*12)
      C1_D0_MAP : std_logic_vector(107 downto 0) := X"12A_12B_127_126_124_125_122_123_121";  --byte 0
      C1_D1_MAP : std_logic_vector(107 downto 0) := X"131_139_138_132_133_135_137_136_134";  --byte 1
      C1_D2_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 2
      C1_D3_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 3
      C1_D4_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 4
      C1_D5_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 5
      C1_D6_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 6
      C1_D7_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 7

      -- Mapping for byte write signals (8*12)
      C1_BW_MAP : std_logic_vector(83 downto 0) := X"000_000_000_000_000_128_129";

      -- Mapping for data READ signals

      -- Mapping for data read bytes (9*12)
      C1_Q0_MAP : std_logic_vector(107 downto 0) := X"027_022_028_023_025_024_02A_02B_026";  --byte 0
      C1_Q1_MAP : std_logic_vector(107 downto 0) := X"036_037_035_034_039_03B_038_033_03A";  --byte 1
      C1_Q2_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 2
      C1_Q3_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 3
      C1_Q4_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 4
      C1_Q5_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 5
      C1_Q6_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 6
      C1_Q7_MAP : std_logic_vector(107 downto 0) := X"000_000_000_000_000_000_000_000_000";  --byte 7

      --***************************************************************************
      -- IODELAY and PHY related parameters
      --***************************************************************************
      C1_IODELAY_HP_MODE : string  := "ON";
      -- to phy_top
      C1_IBUF_LPWR_MODE  : string  := "OFF";
      -- to phy_top
      C1_TCQ             : integer := 100;

      --***************************************************************************
      -- System clock frequency parameters
      --***************************************************************************
      C1_CLK_PERIOD       : integer := 2222;
      -- memory tCK paramter.
      -- # = Clock Period in pS.
      C1_nCK_PER_CLK      : integer := 2;
      -- # of memory CKs per fabric CLK
      C1_DIFF_TERM_SYSCLK : string  := "TRUE";
      -- Differential Termination for System
      -- clock input pins

      --***************************************************************************
      -- Traffic Gen related parameters
      --***************************************************************************
      C1_BL_WIDTH            : integer                       := 8;
      C1_PORT_MODE           : string                        := "BI_MODE";
      C1_DATA_MODE           : std_logic_vector(3 downto 0)  := "0010";
      C1_TST_MEM_INSTR_MODE  : string                        := "R_W_INSTR_MODE";
      C1_EYE_TEST            : string                        := "FALSE";
      -- set EYE_TEST = "TRUE" to probe memory
      -- signals. Traffic Generator will only
      -- write to one single location and no
      -- read transactions will be generated.
      C1_DATA_PATTERN        : string                        := "DGEN_ALL";
      -- "DGEN_HAMMER", "DGEN_WALKING1",
      -- "DGEN_WALKING0","DGEN_ADDR","
      -- "DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"
      C1_CMD_PATTERN         : string                        := "CGEN_ALL";
      -- "CGEN_PRBS","CGEN_FIXED","CGEN_BRAM",
      -- "CGEN_SEQUENTIAL", "CGEN_ALL"
      C1_CMD_WDT               : std_logic_vector(31 downto 0) := X"000003ff";
      C1_WR_WDT                : std_logic_vector(31 downto 0) := X"00001fff";
      C1_RD_WDT                : std_logic_vector(31 downto 0) := X"000003ff";
      C1_BEGIN_ADDRESS         : std_logic_vector(31 downto 0) := X"00000000";
      C1_END_ADDRESS           : std_logic_vector(31 downto 0) := X"00000fff";
      C1_PRBS_EADDR_MASK_POS   : std_logic_vector(31 downto 0) := X"fffff000";

      --***************************************************************************
      -- Wait period for the read strobe (CQ) to become stable
      --***************************************************************************
      C1_CLK_STABLE : integer := (20*1000*1000/(2222*2)) + 1;
      -- Cycles till CQ/CQ# is stable

      --***************************************************************************
      -- Debug parameter
      --***************************************************************************
      C1_DEBUG_PORT : string := "OFF";
      -- # = "ON" Enable debug signals/controls.
      --   = "OFF" Disable debug signals/controls.

      RST_ACT_LOW : integer := 1
      -- =1 for active low reset,
      -- =0 for active high.
      );
  port (
  
		-- IP Bus Interface
		ipb_clk: in std_logic;
		ipb_rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;

    -- System clock (125MHz)
    sys_clk : in std_logic;

    --Memory Interface Ports
    c0_qdriip_cq_p      : in  std_logic_vector(C0_NUM_DEVICES-1 downto 0);
    c0_qdriip_cq_n      : in  std_logic_vector(C0_NUM_DEVICES-1 downto 0);
    c0_qdriip_q         : in  std_logic_vector(C0_DATA_WIDTH-1 downto 0);
    c0_qdriip_k_p       : out std_logic_vector(C0_NUM_DEVICES-1 downto 0);
    c0_qdriip_k_n       : out std_logic_vector(C0_NUM_DEVICES-1 downto 0);
    c0_qdriip_d         : out std_logic_vector(C0_DATA_WIDTH-1 downto 0);
    c0_qdriip_sa        : out std_logic_vector(C0_ADDR_WIDTH-1 downto 0);
    c0_qdriip_w_n       : out std_logic;
    c0_qdriip_r_n       : out std_logic;
    c0_qdriip_bw_n      : out std_logic_vector(C0_BW_WIDTH-1 downto 0);
    c0_qdriip_dll_off_n : out std_logic;

    --Memory Interface Ports
    c1_qdriip_cq_p      : in  std_logic_vector(C1_NUM_DEVICES-1 downto 0);
    c1_qdriip_cq_n      : in  std_logic_vector(C1_NUM_DEVICES-1 downto 0);
    c1_qdriip_q         : in  std_logic_vector(C1_DATA_WIDTH-1 downto 0);
    c1_qdriip_k_p       : out std_logic_vector(C1_NUM_DEVICES-1 downto 0);
    c1_qdriip_k_n       : out std_logic_vector(C1_NUM_DEVICES-1 downto 0);
    c1_qdriip_d         : out std_logic_vector(C1_DATA_WIDTH-1 downto 0);
    c1_qdriip_sa        : out std_logic_vector(C1_ADDR_WIDTH-1 downto 0);
    c1_qdriip_w_n       : out std_logic;
    c1_qdriip_r_n       : out std_logic;
    c1_qdriip_bw_n      : out std_logic_vector(C1_BW_WIDTH-1 downto 0);
    c1_qdriip_dll_off_n : out std_logic
    );
end entity qdr_ipbus;

architecture behave of qdr_ipbus is

  function parity ( word: std_logic_vector ) return std_logic  is
    constant word_low: integer:= word'low;
    constant word_high: integer:= word'high;
    variable result: std_logic;
  begin
    result := '0';
    for i in word_low to word_high loop
      result := result xor word(i);
    end loop;
    return result;
  end parity;

  -- clogb2 function - ceiling of log base 2
  function clogb2 (size : integer) return integer is
    variable base : integer := 0;
    variable inp  : integer := 0;
  begin
    inp := size;
    while (inp > 0) loop
      inp  := inp/2;
      base := base + 1;
    end loop;
    return base;
  end function;

  constant C0_APP_DATA_WIDTH : integer := C0_BURST_LEN*C0_DATA_WIDTH;
  constant C0_APP_MASK_WIDTH : integer := C0_APP_DATA_WIDTH / 9;
  -- Number of bits needed to represent DEVICE_TAPS
  constant C0_TAP_BITS       : integer := clogb2(DEVICE_TAPS - 1);
  -- Number of bits to represent number of cq/cq#'s
  constant C0_CQ_BITS        : integer := clogb2(C0_DATA_WIDTH/9 - 1);
  -- Number of bits needed to represent number of q's
  constant C0_Q_BITS         : integer := clogb2(C0_DATA_WIDTH - 1);
  constant C1_APP_DATA_WIDTH : integer := C1_BURST_LEN*C1_DATA_WIDTH;
  constant C1_APP_MASK_WIDTH : integer := C1_APP_DATA_WIDTH / 9;
  -- Number of bits needed to represent DEVICE_TAPS
  constant C1_TAP_BITS       : integer := clogb2(DEVICE_TAPS - 1);
  -- Number of bits to represent number of cq/cq#'s
  constant C1_CQ_BITS        : integer := clogb2(C1_DATA_WIDTH/9 - 1);
  -- Number of bits needed to represent number of q's
  constant C1_Q_BITS         : integer := clogb2(C1_DATA_WIDTH - 1);

  signal ipb_wr_cmd: std_logic;
  signal ipb_wr_data: std_logic_vector(71 downto 0);
  signal ipb_rd_cmd: std_logic;
  signal ipb_addr: std_logic_vector(19 downto 0);
  signal ipb_rd_valid: std_logic;
  signal ipb_rd_data: std_logic_vector(71 downto 0);
  signal ipb_cal_complete: std_logic;

  signal c0_app_wr_cmd: std_logic;
  signal c0_app_wr_data: std_logic_vector(C0_DATA_WIDTH*C0_BURST_LEN-1 downto 0);
  signal c0_app_rd_cmd: std_logic;
  signal c0_app_addr: std_logic_vector(C0_ADDR_WIDTH-1 downto 0);
  signal c0_app_rd_valid: std_logic;
  signal c0_app_rd_data: std_logic_vector(C0_DATA_WIDTH*C0_BURST_LEN-1 downto 0);
  signal c0_ipb_cal_complete: std_logic;
  
  signal c0_ipb_en: std_logic;
  signal c0_ipb_rd_data: std_logic_vector(C1_DATA_WIDTH*C1_BURST_LEN-1 downto 0);
  signal c0_ipb_rd_valid: std_logic;
  
  signal c1_app_wr_cmd: std_logic;
  signal c1_app_wr_data: std_logic_vector(C1_DATA_WIDTH*C1_BURST_LEN-1 downto 0);
  signal c1_app_rd_cmd: std_logic;
  signal c1_app_addr: std_logic_vector(C1_ADDR_WIDTH-1 downto 0);
  signal c1_app_rd_valid: std_logic;
  signal c1_app_rd_data: std_logic_vector(C1_DATA_WIDTH*C1_BURST_LEN-1 downto 0);
  signal c1_ipb_cal_complete: std_logic;
  
  signal c1_ipb_en: std_logic;
  signal c1_ipb_rd_data: std_logic_vector(C1_DATA_WIDTH*C1_BURST_LEN-1 downto 0);
  signal c1_ipb_rd_valid: std_logic;

  signal stb, stb_d, cyc, busy, rdy: std_logic;
  
  signal ipb_rd_data_reg: std_logic_vector(C1_DATA_WIDTH*C1_BURST_LEN-1 downto 0);
  signal ipb_rd_error_reg: std_logic;
  
  signal c0_app_clk, c0_app_rst, c0_app_cal_complete: std_logic;
  signal c1_app_clk, c1_app_rst, c1_app_cal_complete: std_logic;
    
  constant sys_rst : std_logic := '1';

	begin
  
    -----------------------------------------------------------------
    -- IPBus manipulation : 32bit bus, 72bit QDR interface, etc
    -----------------------------------------------------------------

		stb <= ipb_in.ipb_strobe and not busy;
		cyc <= stb and not stb_d;
	
		ipbus_proc: process(ipb_clk)
      variable parity_check, parity_error: std_logic;
		begin
			if rising_edge(ipb_clk) then
				busy <= (busy or cyc) and not (rdy or ipb_rst);
				stb_d <= stb;
				-- Buffer addr (reduced load on ipbus).  Same add used for rd & wr
				ipb_addr <= ipb_in.ipb_addr(C0_ADDR_WIDTH downto 1);
        -- Select RAM to use
				c0_ipb_en <= not ipb_in.ipb_addr(C0_ADDR_WIDTH + 1);
				c1_ipb_en <= ipb_in.ipb_addr(C0_ADDR_WIDTH + 1);
				-- 72bit user interface to RAM => Double write from ipbus required.
				if ipb_in.ipb_addr(0) = '0' then
          -- Add parity checkbits.  MAp to QDR byte lanes.
          for i in 0 to 3 loop
            ipb_wr_data(9*i+7 downto 9*i) <= ipb_in.ipb_wdata(8*i+7 downto 8*i);
            ipb_wr_data(9*i+8) <= parity(ipb_in.ipb_wdata(8*i+7 downto 8*i));
          end loop;
          -- Inititate read on lower word request
          -- i.e. must get the data before we can send it to user
					-- Signbal cyc ensures cmd only pulse generated
					ipb_rd_cmd <= cyc and (not ipb_in.ipb_write);
          -- Data delayed by a clk so delay ack too.
          if ipb_in.ipb_write = '0' then
            rdy <= ipb_rd_valid;
          else
            rdy <= cyc;
          end if;
				elsif ipb_in.ipb_addr(0) = '1' then
          for i in 0 to 3 loop
            ipb_wr_data(36+9*i+7 downto 36+9*i) <= ipb_in.ipb_wdata(8*i+7 downto 8*i);
            ipb_wr_data(36+9*i+8) <= parity(ipb_in.ipb_wdata(8*i+7 downto 8*i));
          end loop;
          -- Inititate upper on UPPER word request 
          -- i.e. when we have the full word to execute the write
					-- Signbal cyc ensures cmd only pulse generated
					ipb_wr_cmd <= cyc and ipb_in.ipb_write;
          rdy <= cyc;
				end if;
        -- Check parity regardless of whether data valid (more efficient)
        -- Massive combinatorial logic, but 31.25MHz & 6 input LUTs.
        parity_error := '0';
        for i in 0 to 7 loop
          parity_check := parity(ipb_rd_data(9*i+7 downto 9*i));
          if parity_check /= ipb_rd_data(9*i+8) then
            parity_error := '1';
          end if;
        end loop;
				-- Capture read data
				if ipb_rd_valid = '1' then
          -- Strip out parity bits
          for i in 0 to 7 loop
            ipb_rd_data_reg(8*i+7 downto 8*i) <= ipb_rd_data(9*i+7 downto 9*i);
          end loop;     
					--ipb_rd_data_reg <= ipb_rd_data;
          -- Massive combinatorial logic, but 31.25MHz & 6 input LUTs.
          ipb_rd_error_reg <= parity_error;
        END IF;
			end if;
		end process;
    
    ipb_rd_data <= c0_ipb_rd_data when c0_ipb_en = '1' else c1_ipb_rd_data;
    ipb_rd_valid <= c0_ipb_rd_valid when c0_ipb_en = '1' else c1_ipb_rd_valid;
    ipb_cal_complete <= c0_ipb_cal_complete when c0_ipb_en = '1' else c1_ipb_cal_complete;

		-- IPBus return path
		ipb_out.ipb_rdata <= ipb_rd_data_reg(31 downto 0) when ipb_in.ipb_addr(0) = '0' 
			else ipb_rd_data_reg(63 downto 32); 
		ipb_out.ipb_ack <= rdy and ipb_in.ipb_strobe;
		ipb_out.ipb_err <= ipb_rd_error_reg or (not ipb_cal_complete);

    -----------------------------------------------------------------
    -- Controller 0: Bridge To/From IPbus/QDR clock domains
    -----------------------------------------------------------------

    c0_ipbus_to_qdr_br : entity work.ipbus_to_qdr_bridge 
      port map (
        -- IPBus Clk Domain
        ipb_clk => ipb_clk,
        ipb_rst => ipb_rst,
        ipb_wr_cmd => ipb_wr_cmd,
        ipb_rd_cmd => ipb_rd_cmd,
        ipb_addr => ipb_addr,
        ipb_wr_data => ipb_wr_data,
        ipb_en => c0_ipb_en,
        -- QDR Clk Domain
        app_clk => c0_app_clk,
        app_rst => c0_app_rst,
        app_wr_data => c0_app_wr_data,
        app_addr => c0_app_addr,
        app_rd_cmd => c0_app_rd_cmd,
        app_wr_cmd => c0_app_wr_cmd
  );

  c0_qdr_to_ipbus_br : entity work.qdr_to_ipbus_bridge 
      port map (
        -- IPBus Clk Domain
        ipb_clk => ipb_clk,
        ipb_rst => ipb_rst,
        ipb_rd_data => c0_ipb_rd_data,
        ipb_rd_valid => c0_ipb_rd_valid,
        -- QDR Clk Domain
        app_clk => c0_app_clk,
        app_rst => c0_app_rst,
        app_rd_data => c0_app_rd_data,
        app_rd_valid => c0_app_rd_valid
  );
  
    -- Overkill, but ho hum....
    c0_cal_complete: async_pulse_sync 
      generic map(
        negative_logic => "false")
      port map(
        async_pulse_in => c0_app_cal_complete,
        sync_clk_in => ipb_clk,
        sync_pulse_out => c0_ipb_cal_complete,
        sync_pulse_sgl_clk_out => open
      );

    -----------------------------------------------------------------
    -- Controller 1: Bridge To/From IPbus/QDR clock domains
    -----------------------------------------------------------------

    c1_ipbus_to_qdr_br : entity work.ipbus_to_qdr_bridge 
      port map (
        -- IPBus Clk Domain
        ipb_clk => ipb_clk,
        ipb_rst => ipb_rst,
        ipb_wr_cmd => ipb_wr_cmd,
        ipb_rd_cmd => ipb_rd_cmd,
        ipb_addr => ipb_addr,
        ipb_wr_data => ipb_wr_data,
        ipb_en => c1_ipb_en,
        -- QDR Clk Domain
        app_clk => c1_app_clk,
        app_rst => c1_app_rst,
        app_wr_data => c1_app_wr_data,
        app_addr => c1_app_addr,
        app_rd_cmd => c1_app_rd_cmd,
        app_wr_cmd => c1_app_wr_cmd
  );

  c1_qdr_to_ipbus_br : entity work.qdr_to_ipbus_bridge 
      port map (
        -- IPBus Clk Domain
        ipb_clk => ipb_clk,
        ipb_rst => ipb_rst,
        ipb_rd_data => c1_ipb_rd_data,
        ipb_rd_valid => c1_ipb_rd_valid,
        -- QDR Clk Domain
        app_clk => c1_app_clk,
        app_rst => c1_app_rst,
        app_rd_data => c1_app_rd_data,
        app_rd_valid => c1_app_rd_valid
  );
  
    -- Overkill, but ho hum....
    c1_cal_complete: async_pulse_sync 
      generic map(
        negative_logic => "false")
      port map(
        async_pulse_in => c1_app_cal_complete,
        sync_clk_in => ipb_clk,
        sync_pulse_out => c1_ipb_cal_complete,
        sync_pulse_sgl_clk_out => open
      );

    -----------------------------------------------------------------
    -- QDR
    -----------------------------------------------------------------

    u_qdr_sram : qdr_sram
    generic map (

      C0_MEM_TYPE                => C0_MEM_TYPE,  --Memory Type (QDR2PLUS, QDR2)
      C0_CLK_STABLE              => C0_CLK_STABLE ,  --Cycles till CQ/CQ# is stable
      C0_ADDR_WIDTH              => C0_ADDR_WIDTH ,  --Adress Width
      C0_DATA_WIDTH              => C0_DATA_WIDTH ,  --Data Width
      C0_BW_WIDTH                => C0_BW_WIDTH,  --Byte Write Width
      C0_BURST_LEN               => C0_BURST_LEN,   --Burst Length
      C0_NUM_DEVICES             => C0_NUM_DEVICES,  --Memory Devices
      C0_FIXED_LATENCY_MODE      => C0_FIXED_LATENCY_MODE,  --Fixed Latency for data reads
      C0_PHY_LATENCY             => C0_PHY_LATENCY,  --Value for Fixed Latency Mode
      C0_MEM_RD_LATENCY          => C0_MEM_RD_LATENCY,  --Value of Memory part read latency
      C0_CPT_CLK_CQ_ONLY         => C0_CPT_CLK_CQ_ONLY,  --Only CQ is used for data capture and no CQ#
      C0_SIMULATION              => C0_SIMULATION,  --TRUE during design simulation
      C0_INTER_BANK_SKEW         => C0_INTER_BANK_SKEW,  --Clock skew between adjacent banks
      C0_PHY_CONTROL_MASTER_BANK => C0_PHY_CONTROL_MASTER_BANK,

      C0_SIM_BYPASS_INIT_CAL => C0_SIM_BYPASS_INIT_CAL,
      C0_IBUF_LPWR_MODE      => C0_IBUF_LPWR_MODE ,  --Input buffer low power mode
      C0_IODELAY_HP_MODE     => C0_IODELAY_HP_MODE,  --IODELAY High Performance Mode

      C0_DATA_CTL_B0  => C0_DATA_CTL_B0,  --Data write/read bits in all banks
      C0_DATA_CTL_B1  => C0_DATA_CTL_B1,
      C0_DATA_CTL_B2  => C0_DATA_CTL_B2,
      C0_DATA_CTL_B3  => C0_DATA_CTL_B3,
      C0_DATA_CTL_B4  => C0_DATA_CTL_B4,
      C0_ADDR_CTL_MAP => C0_ADDR_CTL_MAP,

      C0_BYTE_LANES_B0 => C0_BYTE_LANES_B0,  --Byte lanes used for the complete design
      C0_BYTE_LANES_B1 => C0_BYTE_LANES_B1,
      C0_BYTE_LANES_B2 => C0_BYTE_LANES_B2,
      C0_BYTE_LANES_B3 => C0_BYTE_LANES_B3,
      C0_BYTE_LANES_B4 => C0_BYTE_LANES_B4,

      C0_BYTE_GROUP_TYPE_B0 => C0_BYTE_GROUP_TYPE_B0,  --Differentiates data write and read byte lanes
      C0_BYTE_GROUP_TYPE_B1 => C0_BYTE_GROUP_TYPE_B1,
      C0_BYTE_GROUP_TYPE_B2 => C0_BYTE_GROUP_TYPE_B2,
      C0_BYTE_GROUP_TYPE_B3 => C0_BYTE_GROUP_TYPE_B3,
      C0_BYTE_GROUP_TYPE_B4 => C0_BYTE_GROUP_TYPE_B4,

      C0_CPT_CLK_SEL_B0 => C0_CPT_CLK_SEL_B0,  --Capture clock placement parameters
      C0_CPT_CLK_SEL_B1 => C0_CPT_CLK_SEL_B1,
      C0_CPT_CLK_SEL_B2 => C0_CPT_CLK_SEL_B2,

      C0_PHY_0_BITLANES => C0_PHY_0_BITLANES,  --Bits used for the complete design
      C0_PHY_1_BITLANES => C0_PHY_1_BITLANES,
      C0_PHY_2_BITLANES => C0_PHY_2_BITLANES,
      C0_PHY_3_BITLANES => C0_PHY_3_BITLANES,
      C0_PHY_4_BITLANES => C0_PHY_4_BITLANES,

      C0_ADD_MAP => C0_ADD_MAP,         -- Address bits mapping
      C0_RD_MAP  => C0_RD_MAP,
      C0_WR_MAP  => C0_WR_MAP,

      C0_D0_MAP => C0_D0_MAP,           -- Data write bits mapping
      C0_D1_MAP => C0_D1_MAP,
      C0_D2_MAP => C0_D2_MAP,
      C0_D3_MAP => C0_D3_MAP,
      C0_D4_MAP => C0_D4_MAP,
      C0_D5_MAP => C0_D5_MAP,
      C0_D6_MAP => C0_D6_MAP,
      C0_D7_MAP => C0_D7_MAP,
      C0_BW_MAP => C0_BW_MAP,
      C0_K_MAP  => C0_K_MAP,

      C0_Q0_MAP => C0_Q0_MAP,           -- Data read bits mapping
      C0_Q1_MAP => C0_Q1_MAP,
      C0_Q2_MAP => C0_Q2_MAP,
      C0_Q3_MAP => C0_Q3_MAP,
      C0_Q4_MAP => C0_Q4_MAP,
      C0_Q5_MAP => C0_Q5_MAP,
      C0_Q6_MAP => C0_Q6_MAP,
      C0_Q7_MAP => C0_Q7_MAP,
      C0_CQ_MAP => C0_CQ_MAP,

      C0_DEBUG_PORT => C0_DEBUG_PORT,   -- Debug using Chipscope controls
      C0_TCQ        => C0_TCQ,          -- Register Delay

      C0_nCK_PER_CLK      => C0_nCK_PER_CLK,
      C0_CLK_PERIOD       => C0_CLK_PERIOD,
      C0_DIFF_TERM_SYSCLK => C0_DIFF_TERM_SYSCLK,
      C0_CLKIN_PERIOD     => C0_CLKIN_PERIOD,
      C0_CLKFBOUT_MULT    => C0_CLKFBOUT_MULT,  --Infrastructure M and D values
      C0_DIVCLK_DIVIDE    => C0_DIVCLK_DIVIDE,
      C0_CLKOUT0_DIVIDE   => C0_CLKOUT0_DIVIDE,
      C0_CLKOUT1_DIVIDE   => C0_CLKOUT1_DIVIDE,
      C0_CLKOUT2_DIVIDE   => C0_CLKOUT2_DIVIDE,
      C0_CLKOUT3_DIVIDE   => C0_CLKOUT3_DIVIDE,
      C0_CLKOUT4_DIVIDE   => C0_CLKOUT4_DIVIDE,

      SYSCLK_TYPE      => SYSCLK_TYPE,
      REFCLK_FREQ      => REFCLK_FREQ,
      IODELAY_GRP      => IODELAY_GRP,

      DEVICE_TAPS => DEVICE_TAPS,       -- Number of taps in the IDELAY chain

      C1_MEM_TYPE                => C1_MEM_TYPE,  --Memory Type (QDR2PLUS, QDR2)
      C1_CLK_STABLE              => C1_CLK_STABLE ,  --Cycles till CQ/CQ# is stable
      C1_ADDR_WIDTH              => C1_ADDR_WIDTH ,  --Adress Width
      C1_DATA_WIDTH              => C1_DATA_WIDTH ,  --Data Width
      C1_BW_WIDTH                => C1_BW_WIDTH,  --Byte Write Width
      C1_BURST_LEN               => C1_BURST_LEN,   --Burst Length
      C1_NUM_DEVICES             => C1_NUM_DEVICES,  --Memory Devices
      C1_FIXED_LATENCY_MODE      => C1_FIXED_LATENCY_MODE,  --Fixed Latency for data reads
      C1_PHY_LATENCY             => C1_PHY_LATENCY,  --Value for Fixed Latency Mode
      C1_MEM_RD_LATENCY          => C1_MEM_RD_LATENCY,  --Value of Memory part read latency
      C1_CPT_CLK_CQ_ONLY         => C1_CPT_CLK_CQ_ONLY,  --Only CQ is used for data capture and no CQ#
      C1_SIMULATION              => C1_SIMULATION,  --TRUE during design simulation
      C1_INTER_BANK_SKEW         => C1_INTER_BANK_SKEW,  --Clock skew between adjacent banks
      C1_PHY_CONTROL_MASTER_BANK => C1_PHY_CONTROL_MASTER_BANK,

      C1_SIM_BYPASS_INIT_CAL => C1_SIM_BYPASS_INIT_CAL,
      C1_IBUF_LPWR_MODE      => C1_IBUF_LPWR_MODE ,  --Input buffer low power mode
      C1_IODELAY_HP_MODE     => C1_IODELAY_HP_MODE,  --IODELAY High Performance Mode

      C1_DATA_CTL_B0  => C1_DATA_CTL_B0,  --Data write/read bits in all banks
      C1_DATA_CTL_B1  => C1_DATA_CTL_B1,
      C1_DATA_CTL_B2  => C1_DATA_CTL_B2,
      C1_DATA_CTL_B3  => C1_DATA_CTL_B3,
      C1_DATA_CTL_B4  => C1_DATA_CTL_B4,
      C1_ADDR_CTL_MAP => C1_ADDR_CTL_MAP,

      C1_BYTE_LANES_B0 => C1_BYTE_LANES_B0,  --Byte lanes used for the complete design
      C1_BYTE_LANES_B1 => C1_BYTE_LANES_B1,
      C1_BYTE_LANES_B2 => C1_BYTE_LANES_B2,
      C1_BYTE_LANES_B3 => C1_BYTE_LANES_B3,
      C1_BYTE_LANES_B4 => C1_BYTE_LANES_B4,

      C1_BYTE_GROUP_TYPE_B0 => C1_BYTE_GROUP_TYPE_B0,  --Differentiates data write and read byte lanes
      C1_BYTE_GROUP_TYPE_B1 => C1_BYTE_GROUP_TYPE_B1,
      C1_BYTE_GROUP_TYPE_B2 => C1_BYTE_GROUP_TYPE_B2,
      C1_BYTE_GROUP_TYPE_B3 => C1_BYTE_GROUP_TYPE_B3,
      C1_BYTE_GROUP_TYPE_B4 => C1_BYTE_GROUP_TYPE_B4,

      C1_CPT_CLK_SEL_B0 => C1_CPT_CLK_SEL_B0,  --Capture clock placement parameters
      C1_CPT_CLK_SEL_B1 => C1_CPT_CLK_SEL_B1,
      C1_CPT_CLK_SEL_B2 => C1_CPT_CLK_SEL_B2,

      C1_PHY_0_BITLANES => C1_PHY_0_BITLANES,  --Bits used for the complete design
      C1_PHY_1_BITLANES => C1_PHY_1_BITLANES,
      C1_PHY_2_BITLANES => C1_PHY_2_BITLANES,
      C1_PHY_3_BITLANES => C1_PHY_3_BITLANES,
      C1_PHY_4_BITLANES => C1_PHY_4_BITLANES,

      C1_ADD_MAP => C1_ADD_MAP,         -- Address bits mapping
      C1_RD_MAP  => C1_RD_MAP,
      C1_WR_MAP  => C1_WR_MAP,

      C1_D0_MAP => C1_D0_MAP,           -- Data write bits mapping
      C1_D1_MAP => C1_D1_MAP,
      C1_D2_MAP => C1_D2_MAP,
      C1_D3_MAP => C1_D3_MAP,
      C1_D4_MAP => C1_D4_MAP,
      C1_D5_MAP => C1_D5_MAP,
      C1_D6_MAP => C1_D6_MAP,
      C1_D7_MAP => C1_D7_MAP,
      C1_BW_MAP => C1_BW_MAP,
      C1_K_MAP  => C1_K_MAP,

      C1_Q0_MAP => C1_Q0_MAP,           -- Data read bits mapping
      C1_Q1_MAP => C1_Q1_MAP,
      C1_Q2_MAP => C1_Q2_MAP,
      C1_Q3_MAP => C1_Q3_MAP,
      C1_Q4_MAP => C1_Q4_MAP,
      C1_Q5_MAP => C1_Q5_MAP,
      C1_Q6_MAP => C1_Q6_MAP,
      C1_Q7_MAP => C1_Q7_MAP,
      C1_CQ_MAP => C1_CQ_MAP,

      C1_DEBUG_PORT => C1_DEBUG_PORT,   -- Debug using Chipscope controls
      C1_TCQ        => C1_TCQ,          --Register Delay


      C1_nCK_PER_CLK      => C1_nCK_PER_CLK,
      C1_CLK_PERIOD       => C1_CLK_PERIOD,
      C1_DIFF_TERM_SYSCLK => C1_DIFF_TERM_SYSCLK,
      C1_CLKIN_PERIOD     => C1_CLKIN_PERIOD,
      C1_CLKFBOUT_MULT    => C1_CLKFBOUT_MULT,  --Infrastructure M and D values
      C1_DIVCLK_DIVIDE    => C1_DIVCLK_DIVIDE,
      C1_CLKOUT0_DIVIDE   => C1_CLKOUT0_DIVIDE,
      C1_CLKOUT1_DIVIDE   => C1_CLKOUT1_DIVIDE,
      C1_CLKOUT2_DIVIDE   => C1_CLKOUT2_DIVIDE,
      C1_CLKOUT3_DIVIDE   => C1_CLKOUT3_DIVIDE,
      C1_CLKOUT4_DIVIDE   => C1_CLKOUT4_DIVIDE,

      RST_ACT_LOW => RST_ACT_LOW
      )
    port map (

      -- Memory interface ports
      c0_qdriip_cq_p         => c0_qdriip_cq_p,
      c0_qdriip_cq_n         => c0_qdriip_cq_n,
      c0_qdriip_q            => c0_qdriip_q,
      c0_qdriip_k_p          => c0_qdriip_k_p,
      c0_qdriip_k_n          => c0_qdriip_k_n,
      c0_qdriip_d            => c0_qdriip_d,
      c0_qdriip_sa           => c0_qdriip_sa,
      c0_qdriip_w_n          => c0_qdriip_w_n,
      c0_qdriip_r_n          => c0_qdriip_r_n,
      c0_qdriip_bw_n         => c0_qdriip_bw_n,
      c0_qdriip_dll_off_n    => c0_qdriip_dll_off_n,
      -- Has QDR finished initial calibration
      c0_init_calib_complete => c0_app_cal_complete,
      -- Application interface ports
      c0_app_wr_cmd0   => c0_app_wr_cmd,
      c0_app_wr_cmd1   => '0',
      c0_app_wr_addr0  => c0_app_addr,
      c0_app_wr_addr1  => (others => '0'),
      c0_app_rd_cmd0   => c0_app_rd_cmd,
      c0_app_rd_cmd1   => '0',
      c0_app_rd_addr0  => c0_app_addr,
      c0_app_rd_addr1  => (others => '0'),
      c0_app_wr_data0  => c0_app_wr_data,
      c0_app_wr_data1  => (others => '0'),
      c0_app_wr_bw_n0  => (others => '0'),
      c0_app_wr_bw_n1  => (others => '0'),
      c0_app_rd_valid0 => c0_app_rd_valid,
      c0_app_rd_valid1 => open,
      c0_app_rd_data0  => c0_app_rd_data,
      c0_app_rd_data1  => open,
      c0_clk           => c0_app_clk,
      c0_rst_clk       => c0_app_rst,

      -- System clock ports
      sys_clk => sys_clk,
      
      -- Memory interface ports
      c1_qdriip_cq_p         => c1_qdriip_cq_p,
      c1_qdriip_cq_n         => c1_qdriip_cq_n,
      c1_qdriip_q            => c1_qdriip_q,
      c1_qdriip_k_p          => c1_qdriip_k_p,
      c1_qdriip_k_n          => c1_qdriip_k_n,
      c1_qdriip_d            => c1_qdriip_d,
      c1_qdriip_sa           => c1_qdriip_sa,
      c1_qdriip_w_n          => c1_qdriip_w_n,
      c1_qdriip_r_n          => c1_qdriip_r_n,
      c1_qdriip_bw_n         => c1_qdriip_bw_n,
      c1_qdriip_dll_off_n    => c1_qdriip_dll_off_n,
      -- Has QDR finished initial calibration
      c1_init_calib_complete => c1_app_cal_complete,
      -- Application interface ports
      c1_app_wr_cmd0   => c1_app_wr_cmd,
      c1_app_wr_cmd1   => '0',
      c1_app_wr_addr0  => c1_app_addr,
      c1_app_wr_addr1  => (others => '0'),
      c1_app_rd_cmd0   => c1_app_rd_cmd,
      c1_app_rd_cmd1   => '0',
      c1_app_rd_addr0  => c1_app_addr,
      c1_app_rd_addr1  => (others => '0'),
      c1_app_wr_data0  => c1_app_wr_data,
      c1_app_wr_data1  => (others => '0'),
      c1_app_wr_bw_n0  => (others => '0'),
      c1_app_wr_bw_n1  => (others => '0'),
      c1_app_rd_valid0 => c1_app_rd_valid,
      c1_app_rd_valid1 => open,
      c1_app_rd_data0  => c1_app_rd_data,
      c1_app_rd_data1  => open,
      c1_clk           => c1_app_clk,
      c1_rst_clk       => c1_app_rst,

      sys_rst => sys_rst
      );




end architecture behave;
