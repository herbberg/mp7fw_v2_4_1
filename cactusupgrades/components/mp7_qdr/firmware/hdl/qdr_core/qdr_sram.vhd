--*****************************************************************************
-- (c) Copyright 2009 - 2012 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 1.7
--  \   \         Application        : MIG
--  /   /         Filename           : qdr_sram.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 08:35:03 $
-- \   \  /  \    Date Created       : Mon Aug 27 2012
--  \___\/\___\
--
-- Device           : 7 Series
-- Design Name      : QDRII+ SDRAM
-- Purpose          :
--   Top-level  module. This module can be instantiated in the
--   system and interconnect as shown in example design (example_top module).
--   In addition to the memory controller, the module instantiates:
--     1. Clock generation/distribution, reset logic
--     2. IDELAY control block
--     3. Debug logic
-- Reference        :
-- Revision History :
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.core_definitions.all;

entity qdr_sram is
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
    C0_CPT_CLK_CQ_ONLY         : string  := "FALSE";
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
    C0_CLKIN_PERIOD   : integer := 2500;
    -- Input Clock Period
    C0_CLKFBOUT_MULT  : integer := 9;
    -- write PLL VCO multiplier
    C0_DIVCLK_DIVIDE  : integer := 4;
    -- write PLL VCO divisor
    C0_CLKOUT0_DIVIDE : integer := 2;
    -- VCO output divisor for PLL output clock (CLKOUT0)
    C0_CLKOUT1_DIVIDE : integer := 2;
    -- VCO output divisor for PLL output clock (CLKOUT1)
    C0_CLKOUT2_DIVIDE : integer := 32;
    -- VCO output divisor for PLL output clock (CLKOUT2)
    C0_CLKOUT3_DIVIDE : integer := 4;
    -- VCO output divisor for PLL output clock (CLKOUT3)
    C0_CLKOUT4_DIVIDE : integer := 4;
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

    IODELAY_GRP : string := "IODELAY_MIG";
    -- It is associated to a set of IODELAYs with
    -- an IDELAYCTRL that have same IODELAY CONTROLLER
    -- clock frequency.

    SYSCLK_TYPE : string := "DIFFERENTIAL";
    -- System clock type DIFFERENTIAL, SINGLE_ENDED,
    -- NO_BUFFER

    -- Number of taps in target IDELAY
    DEVICE_TAPS : integer := 32;

    --***************************************************************************
    -- Referece clock frequency parameters
    --***************************************************************************
    REFCLK_FREQ : real := 200.0;
    -- IODELAYCTRL reference clock frequency

    --***************************************************************************
    -- System clock frequency parameters
    --***************************************************************************
    C0_CLK_PERIOD       : integer := 2000;
    -- memory tCK paramter.
    -- # = Clock Period in pS.
    C0_nCK_PER_CLK      : integer := 2;
    -- # of memory CKs per fabric CLK
    C0_DIFF_TERM_SYSCLK : string  := "TRUE";
    -- Differential Termination for System
    -- clock input pins

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
    C1_CPT_CLK_CQ_ONLY         : string  := "FALSE";
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
    C1_CLKIN_PERIOD   : integer := 2500;
    -- Input Clock Period
    C1_CLKFBOUT_MULT  : integer := 9;
    -- write PLL VCO multiplier
    C1_DIVCLK_DIVIDE  : integer := 4;
    -- write PLL VCO divisor
    C1_CLKOUT0_DIVIDE : integer := 2;
    -- VCO output divisor for PLL output clock (CLKOUT0)
    C1_CLKOUT1_DIVIDE : integer := 2;
    -- VCO output divisor for PLL output clock (CLKOUT1)
    C1_CLKOUT2_DIVIDE : integer := 32;
    -- VCO output divisor for PLL output clock (CLKOUT2)
    C1_CLKOUT3_DIVIDE : integer := 4;
    -- VCO output divisor for PLL output clock (CLKOUT3)
    C1_CLKOUT4_DIVIDE : integer := 4;
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
    C1_CLK_PERIOD       : integer := 2000;
    -- memory tCK paramter.
    -- # = Clock Period in pS.
    C1_nCK_PER_CLK      : integer := 2;
    -- # of memory CKs per fabric CLK
    C1_DIFF_TERM_SYSCLK : string  := "TRUE";
    -- Differential Termination for System
    -- clock input pins



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
    -- Differential system clocks
   --sys_clk_p : in std_logic;
    --sys_clk_n : in std_logic;
    sys_clk : in std_logic;

    --Memory Interface Ports
    c0_qdriip_cq_p      : in  std_logic_vector(C0_NUM_DEVICES-1 downto 0);
    c0_qdriip_cq_n      : in  std_logic_vector(C0_NUM_DEVICES-1 downto 0);
    --c0_qdriip_qvld     : in  std_logic_vector(C0_NUM_DEVICES-1 downto 0);
    c0_qdriip_q         : in  std_logic_vector(C0_DATA_WIDTH-1 downto 0);
    c0_qdriip_k_p       : out std_logic_vector(C0_NUM_DEVICES-1 downto 0);
    c0_qdriip_k_n       : out std_logic_vector(C0_NUM_DEVICES-1 downto 0);
    c0_qdriip_d         : out std_logic_vector(C0_DATA_WIDTH-1 downto 0);
    c0_qdriip_sa        : out std_logic_vector(C0_ADDR_WIDTH-1 downto 0);
    c0_qdriip_w_n       : out std_logic;
    c0_qdriip_r_n       : out std_logic;
    c0_qdriip_bw_n      : out std_logic_vector(C0_BW_WIDTH-1 downto 0);
    c0_qdriip_dll_off_n : out std_logic;

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

    c0_clk     : out std_logic;
    c0_rst_clk : out std_logic;

    c0_init_calib_complete : out std_logic;

    --Memory Interface Ports
    c1_qdriip_cq_p      : in  std_logic_vector(C1_NUM_DEVICES-1 downto 0);
    c1_qdriip_cq_n      : in  std_logic_vector(C1_NUM_DEVICES-1 downto 0);
    --c1_qdriip_qvld     : in  std_logic_vector(C1_NUM_DEVICES-1 downto 0);
    c1_qdriip_q         : in  std_logic_vector(C1_DATA_WIDTH-1 downto 0);
    c1_qdriip_k_p       : out std_logic_vector(C1_NUM_DEVICES-1 downto 0);
    c1_qdriip_k_n       : out std_logic_vector(C1_NUM_DEVICES-1 downto 0);
    c1_qdriip_d         : out std_logic_vector(C1_DATA_WIDTH-1 downto 0);
    c1_qdriip_sa        : out std_logic_vector(C1_ADDR_WIDTH-1 downto 0);
    c1_qdriip_w_n       : out std_logic;
    c1_qdriip_r_n       : out std_logic;
    c1_qdriip_bw_n      : out std_logic_vector(C1_BW_WIDTH-1 downto 0);
    c1_qdriip_dll_off_n : out std_logic;

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

    c1_clk     : out std_logic;
    c1_rst_clk : out std_logic;

    c1_init_calib_complete : out std_logic;

    -- System reset
    sys_rst : in std_logic
    );
end entity qdr_sram;

architecture behave of qdr_sram is

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

  constant C0_N_DATA_LANES : integer := C0_DATA_WIDTH / 9;

  -- Number of bits needed to represent DEVICE_TAPS
  constant C0_TAP_BITS : integer := clogb2(DEVICE_TAPS - 1);

-- Number of bits to represent number of cq/cq#'s
  constant C0_CQ_BITS : integer := clogb2(C0_DATA_WIDTH/9 - 1);

  -- Number of bits needed to represent number of q's
  constant C0_Q_BITS : integer := clogb2(C0_DATA_WIDTH - 1);

  constant C1_N_DATA_LANES : integer := C1_DATA_WIDTH / 9;

  -- Number of bits needed to represent DEVICE_TAPS
  constant C1_TAP_BITS : integer := clogb2(DEVICE_TAPS - 1);

  -- Number of bits to represent number of cq/cq#'s
  constant C1_CQ_BITS : integer := clogb2(C1_DATA_WIDTH/9 - 1);

  -- Number of bits needed to represent number of q's
  constant C1_Q_BITS : integer := clogb2(C1_DATA_WIDTH - 1);

  -- Wire declarations
  signal c0_clk_i          : std_logic;
  signal c0_freq_refclk    : std_logic;
  signal c0_mem_refclk     : std_logic;
  signal c0_pll_locked     : std_logic;
  signal c0_sync_pulse     : std_logic;
  signal c0_rst_wr_clk     : std_logic;
  signal c0_ref_dll_lock   : std_logic;
  signal c0_rst_phaser_ref : std_logic;
  signal c0_cmp_err        : std_logic;  -- Reserve for ERROR from test bench

  signal c0_dbg_byte_sel         : std_logic_vector(C0_CQ_BITS-1 downto 0);
  signal c0_dbg_bit_sel          : std_logic_vector(C0_Q_BITS-1 downto 0);
  signal c0_dbg_pi_f_inc         : std_logic;
  signal c0_dbg_pi_f_dec         : std_logic;
  signal c0_dbg_po_f_inc         : std_logic;
  signal c0_dbg_po_f_dec         : std_logic;
  signal c0_dbg_idel_up_all      : std_logic;
  signal c0_dbg_idel_down_all    : std_logic;
  signal c0_dbg_idel_up          : std_logic;
  signal c0_dbg_idel_down        : std_logic;
  signal c0_dbg_idel_tap_cnt     : std_logic_vector(C0_TAP_BITS*C0_DATA_WIDTH-1 downto 0);
  signal c0_dbg_idel_tap_cnt_sel : std_logic_vector(C0_TAP_BITS-1 downto 0);
  signal c0_dbg_select_rdata     : std_logic_vector(2 downto 0);

  --ChipScope Readpath Debug Signals
  signal c0_dbg_phy_wr_cmd_n        : std_logic_vector(1 downto 0);  --cs debug - wr command
  signal c0_dbg_byte_sel_cnt        : std_logic_vector(2 downto 0);
  signal c0_dbg_phy_addr            : std_logic_vector(C0_ADDR_WIDTH*4-1 downto 0);  --cs debug - address
  signal c0_dbg_phy_rd_cmd_n        : std_logic_vector(1 downto 0);  --cs debug - rd command
  signal c0_dbg_phy_wr_data         : std_logic_vector(C0_DATA_WIDTH*4-1 downto 0);  --cs debug - wr data
  signal c0_dbg_phy_init_wr_only    : std_logic;
  signal c0_dbg_phy_init_rd_only    : std_logic;
  signal c0_dbg_po_counter_read_val : std_logic_vector(8 downto 0);
  signal c0_dbg_wr_init             : std_logic_vector(255 downto 0);
  signal c0_dbg_mc_phy              : std_logic_vector(255 downto 0);
  signal c0_vio_sel_rise_chk        : std_logic;

  signal c0_dbg_cq_tapcnt         : std_logic_vector(C0_TAP_BITS*C0_N_DATA_LANES-1 downto 0);  -- tap count for each cq
  signal c0_dbg_cqn_tapcnt        : std_logic_vector(C0_TAP_BITS*C0_N_DATA_LANES-1 downto 0);  -- tap count for each cq#
  signal c0_dbg_rd_stage1_cal     : std_logic_vector(255 downto 0);  -- stage 1 cal debug
  signal c0_dbg_stage2_cal        : std_logic_vector(127 downto 0);  -- stage 2 cal debug
  signal c0_dbg_cq_num            : std_logic_vector(C0_CQ_BITS-1 downto 0);  -- current cq/cq# being calibrated
  signal c0_dbg_valid_lat         : std_logic_vector(4 downto 0);  -- latency of the system
  signal c0_dbg_inc_latency       : std_logic_vector(C0_N_DATA_LANES-1 downto 0);  -- increase latency for dcb
  signal c0_dbg_dcb_din           : std_logic_vector(4*C0_DATA_WIDTH-1 downto 0);  -- dcb data in
  signal c0_dbg_dcb_dout          : std_logic_vector(4*C0_DATA_WIDTH-1 downto 0);  -- dcb data out
  signal c0_dbg_error_max_latency : std_logic_vector(C0_N_DATA_LANES-1 downto 0);  -- stage 2 cal max latency error
  signal c0_dbg_error_adj_latency : std_logic;  -- stage 2 cal latency adjustment error
  signal c0_dbg_align_rd0         : std_logic_vector(C0_DATA_WIDTH-1 downto 0);
  signal c0_dbg_align_rd1         : std_logic_vector(C0_DATA_WIDTH-1 downto 0);
  signal c0_dbg_align_fd0         : std_logic_vector(C0_DATA_WIDTH-1 downto 0);
  signal c0_dbg_align_fd1         : std_logic_vector(C0_DATA_WIDTH-1 downto 0);
  signal c0_dbg_align_rd0_r       : std_logic_vector(8 downto 0);
  signal c0_dbg_align_rd1_r       : std_logic_vector(8 downto 0);
  signal c0_dbg_align_fd0_r       : std_logic_vector(8 downto 0);
  signal c0_dbg_align_fd1_r       : std_logic_vector(8 downto 0);
  signal c0_rd_valid0_r           : std_logic;
  signal c0_rd_valid1_r           : std_logic;
  signal c0_dbg_phy_status        : std_logic_vector(7 downto 0);
  signal c0_dbg_SM_No_Pause       : std_logic;
  signal c0_dbg_SM_en             : std_logic;

  signal c0_mux_wr_data0 : std_logic_vector((C0_DATA_WIDTH*2)-1 downto 0);
  signal c0_mux_wr_data1 : std_logic_vector((C0_DATA_WIDTH*2)-1 downto 0);
  signal c0_mux_wr_bw_n0 : std_logic_vector((C0_BW_WIDTH*2)-1 downto 0);
  signal c0_mux_wr_bw_n1 : std_logic_vector((C0_BW_WIDTH*2)-1 downto 0);
  signal c0_rd_data0     : std_logic_vector((C0_DATA_WIDTH*2)-1 downto 0);
  signal c0_rd_data1     : std_logic_vector((C0_DATA_WIDTH*2)-1 downto 0);
  signal sys_clk_i       : std_logic;
  signal mmcm_clk        : std_logic;

  signal iodelay_clk                  : std_logic;
  signal iodelay_ctrl_rdy             : std_logic;
  signal clk_ref                      : std_logic;
  signal c0_init_calib_complete_i     : std_logic;
  signal c0_app_rd_valid0_i           : std_logic;
  signal c0_app_rd_valid1_i           : std_logic;
  signal c0_dbg_pi_counter_read_val_i : std_logic_vector(5 downto 0);

  -- Wire declarations
  signal c1_clk_i          : std_logic;
  signal c1_freq_refclk    : std_logic;
  signal c1_mem_refclk     : std_logic;
  signal c1_pll_locked     : std_logic;
  signal c1_sync_pulse     : std_logic;
  signal c1_rst_wr_clk     : std_logic;
  signal c1_ref_dll_lock   : std_logic;
  signal c1_rst_phaser_ref : std_logic;
  signal c1_cmp_err        : std_logic;  -- Reserve for ERROR from test bench

  signal c1_dbg_byte_sel         : std_logic_vector(C1_CQ_BITS-1 downto 0);
  signal c1_dbg_bit_sel          : std_logic_vector(C1_Q_BITS-1 downto 0);
  signal c1_dbg_pi_f_inc         : std_logic;
  signal c1_dbg_pi_f_dec         : std_logic;
  signal c1_dbg_po_f_inc         : std_logic;
  signal c1_dbg_po_f_dec         : std_logic;
  signal c1_dbg_idel_up_all      : std_logic;
  signal c1_dbg_idel_down_all    : std_logic;
  signal c1_dbg_idel_up          : std_logic;
  signal c1_dbg_idel_down        : std_logic;
  signal c1_dbg_idel_tap_cnt     : std_logic_vector(C1_TAP_BITS*C1_DATA_WIDTH-1 downto 0);
  signal c1_dbg_idel_tap_cnt_sel : std_logic_vector(C1_TAP_BITS-1 downto 0);
  signal c1_dbg_select_rdata     : std_logic_vector(2 downto 0);

  --ChipScope Readpath Debug Signals
  signal c1_dbg_phy_wr_cmd_n        : std_logic_vector(1 downto 0);  --cs debug - wr command
  signal c1_dbg_byte_sel_cnt        : std_logic_vector(2 downto 0);
  signal c1_dbg_phy_addr            : std_logic_vector(C1_ADDR_WIDTH*4-1 downto 0);  --cs debug - address
  signal c1_dbg_phy_rd_cmd_n        : std_logic_vector(1 downto 0);  --cs debug - rd command
  signal c1_dbg_phy_wr_data         : std_logic_vector(C1_DATA_WIDTH*4-1 downto 0);  --cs debug - wr data
  signal c1_dbg_phy_init_wr_only    : std_logic;
  signal c1_dbg_phy_init_rd_only    : std_logic;
  signal c1_dbg_po_counter_read_val : std_logic_vector(8 downto 0);
  signal c1_dbg_wr_init             : std_logic_vector(255 downto 0);
  signal c1_dbg_mc_phy              : std_logic_vector(255 downto 0);
  signal c1_vio_sel_rise_chk        : std_logic;

  signal c1_dbg_cq_tapcnt         : std_logic_vector(C1_TAP_BITS*C1_N_DATA_LANES-1 downto 0);  -- tap count for each cq
  signal c1_dbg_cqn_tapcnt        : std_logic_vector(C1_TAP_BITS*C1_N_DATA_LANES-1 downto 0);  -- tap count for each cq#
  signal c1_dbg_rd_stage1_cal     : std_logic_vector(255 downto 0);  -- stage 1 cal debug
  signal c1_dbg_stage2_cal        : std_logic_vector(127 downto 0);  -- stage 2 cal debug
  signal c1_dbg_cq_num            : std_logic_vector(C1_CQ_BITS-1 downto 0);  -- current cq/cq# being calibrated
  signal c1_dbg_valid_lat         : std_logic_vector(4 downto 0);  -- latency of the system
  signal c1_dbg_inc_latency       : std_logic_vector(C1_N_DATA_LANES-1 downto 0);  -- increase latency for dcb
  signal c1_dbg_dcb_din           : std_logic_vector(4*C1_DATA_WIDTH-1 downto 0);  -- dcb data in
  signal c1_dbg_dcb_dout          : std_logic_vector(4*C1_DATA_WIDTH-1 downto 0);  -- dcb data out
  signal c1_dbg_error_max_latency : std_logic_vector(C1_N_DATA_LANES-1 downto 0);  -- stage 2 cal max latency error
  signal c1_dbg_error_adj_latency : std_logic;  -- stage 2 cal latency adjustment error
  signal c1_dbg_align_rd0         : std_logic_vector(C1_DATA_WIDTH-1 downto 0);
  signal c1_dbg_align_rd1         : std_logic_vector(C1_DATA_WIDTH-1 downto 0);
  signal c1_dbg_align_fd0         : std_logic_vector(C1_DATA_WIDTH-1 downto 0);
  signal c1_dbg_align_fd1         : std_logic_vector(C1_DATA_WIDTH-1 downto 0);
  signal c1_dbg_align_rd0_r       : std_logic_vector(8 downto 0);
  signal c1_dbg_align_rd1_r       : std_logic_vector(8 downto 0);
  signal c1_dbg_align_fd0_r       : std_logic_vector(8 downto 0);
  signal c1_dbg_align_fd1_r       : std_logic_vector(8 downto 0);
  signal c1_rd_valid0_r           : std_logic;
  signal c1_rd_valid1_r           : std_logic;
  signal c1_dbg_phy_status        : std_logic_vector(7 downto 0);
  signal c1_dbg_SM_No_Pause       : std_logic;
  signal c1_dbg_SM_en             : std_logic;

  signal c1_mux_wr_data0 : std_logic_vector((C1_DATA_WIDTH*2)-1 downto 0);
  signal c1_mux_wr_data1 : std_logic_vector((C1_DATA_WIDTH*2)-1 downto 0);
  signal c1_mux_wr_bw_n0 : std_logic_vector((C1_BW_WIDTH*2)-1 downto 0);
  signal c1_mux_wr_bw_n1 : std_logic_vector((C1_BW_WIDTH*2)-1 downto 0);
  signal c1_rd_data0     : std_logic_vector((C1_DATA_WIDTH*2)-1 downto 0);
  signal c1_rd_data1     : std_logic_vector((C1_DATA_WIDTH*2)-1 downto 0);

  signal c1_init_calib_complete_i     : std_logic;
  signal c1_app_rd_valid0_i           : std_logic;
  signal c1_app_rd_valid1_i           : std_logic;
  signal c1_dbg_pi_counter_read_val_i : std_logic_vector(5 downto 0);
  
begin

--***************************************************************************

  c0_mux_data_bl4 : if (C0_BURST_LEN = 4) generate
    c0_mux_wr_data0 <= c0_app_wr_data0(C0_DATA_WIDTH*4-1 downto C0_DATA_WIDTH*2);
    c0_mux_wr_bw_n0 <= c0_app_wr_bw_n0(C0_BW_WIDTH*4-1 downto C0_BW_WIDTH*2);
  end generate;

  c0_mux_data_bl2 : if (C0_BURST_LEN = 2) generate
    c0_mux_wr_data0 <= c0_app_wr_data0;
    c0_mux_wr_bw_n0 <= c0_app_wr_bw_n0;
  end generate;

  c0_mux_wr_data1 <= c0_app_wr_data0(C0_DATA_WIDTH*2-1 downto 0) when (C0_BURST_LEN = 4)
                     else c0_app_wr_data1;
  c0_mux_wr_bw_n1 <= c0_app_wr_bw_n0(C0_BW_WIDTH*2-1 downto 0) when (C0_BURST_LEN = 4)
                     else c0_app_wr_bw_n1;
  c0_app_rd_data0 <= (c0_rd_data0 & c0_rd_data1) when (C0_BURST_LEN = 4)
                     else c0_rd_data0;
  c0_app_rd_data1        <= c0_rd_data1;
  c0_init_calib_complete <= c0_init_calib_complete_i;
  c0_app_rd_valid0       <= c0_app_rd_valid0_i;
  c0_app_rd_valid1       <= c0_app_rd_valid1_i;

  c1_mux_data_bl4 : if (C1_BURST_LEN = 4) generate
    c1_mux_wr_data0 <= c1_app_wr_data0(C1_DATA_WIDTH*4-1 downto C1_DATA_WIDTH*2);
    c1_mux_wr_bw_n0 <= c1_app_wr_bw_n0(C1_BW_WIDTH*4-1 downto C1_BW_WIDTH*2);
  end generate;

  c1_mux_data_bl2 : if (C1_BURST_LEN = 2) generate
    c1_mux_wr_data0 <= c1_app_wr_data0;
    c1_mux_wr_bw_n0 <= c1_app_wr_bw_n0;
  end generate;

  c1_mux_wr_data1 <= c1_app_wr_data0(C1_DATA_WIDTH*2-1 downto 0) when (C1_BURST_LEN = 4)
                     else c1_app_wr_data1;
  c1_mux_wr_bw_n1 <= c1_app_wr_bw_n0(C1_BW_WIDTH*2-1 downto 0) when (C1_BURST_LEN = 4)
                     else c1_app_wr_bw_n1;
  c1_app_rd_data0 <= (c1_rd_data0 & c1_rd_data1) when (C1_BURST_LEN = 4)
                     else c1_rd_data0;
  c1_app_rd_data1        <= c1_rd_data1;
  c1_init_calib_complete <= c1_init_calib_complete_i;
  c1_app_rd_valid0       <= c1_app_rd_valid0_i;
  c1_app_rd_valid1       <= c1_app_rd_valid1_i;

  u_mig_7series_v1_8_iodelay_ctrl : mig_7series_v1_8_iodelay_ctrl
    generic map
    (
      TCQ         => C0_TCQ,
      IODELAY_GRP => IODELAY_GRP,
      RST_ACT_LOW => RST_ACT_LOW
      )
    port map
    (
      -- Outputs
      iodelay_ctrl_rdy => iodelay_ctrl_rdy,
      clk_ref          => clk_ref,

      -- Inputs
      clk_ref_i => iodelay_clk,
      sys_rst   => sys_rst
      );

--  c0_u_ddr3_clk_ibuf : mig_7series_v1_8_clk_ibuf
--    generic map
--    (
--      DIFF_TERM_SYSCLK => C0_DIFF_TERM_SYSCLK
--      )
--    port map
--    (
--      sys_clk_p => sys_clk_p,
--      sys_clk_n => sys_clk_n,
--      mmcm_clk  => mmcm_clk
--      );

  c0_u_ddr3_clk_ibuf : mig_7series_v1_8_clk_nobuf
    port map
    (
      sys_clk => sys_clk,
      mmcm_clk  => mmcm_clk
      );

  c0_clk <= c0_clk_i;

  c0_u_infrastructure : mig_7series_v1_8_infrastructure
    generic map (
      TCQ            => C0_TCQ,
      nCK_PER_CLK    => C0_nCK_PER_CLK,
      CLKIN_PERIOD   => C0_CLKIN_PERIOD,
      CLKFBOUT_MULT  => C0_CLKFBOUT_MULT,
      DIVCLK_DIVIDE  => C0_DIVCLK_DIVIDE,
      CLKOUT0_PHASE  => 45.0,
      CLKOUT0_DIVIDE => C0_CLKOUT0_DIVIDE,
      CLKOUT1_DIVIDE => C0_CLKOUT1_DIVIDE,
      CLKOUT2_DIVIDE => C0_CLKOUT2_DIVIDE,
      CLKOUT3_DIVIDE => C0_CLKOUT3_DIVIDE,
      CLKOUT4_DIVIDE => C0_CLKOUT4_DIVIDE,
      RST_ACT_LOW    => RST_ACT_LOW
      )
    port map (
      -- Outputs
      rstdiv0        => c0_rst_wr_clk,
      clk            => c0_clk_i,
      mem_refclk     => c0_mem_refclk,
      iodelay_clk    => iodelay_clk,
      freq_refclk    => c0_freq_refclk,
      sync_pulse     => c0_sync_pulse,
      pll_locked     => c0_pll_locked,
      rst_phaser_ref => c0_rst_phaser_ref,

      -- Inputs
      mmcm_clk         => mmcm_clk,
      sys_rst          => sys_rst,
      iodelay_ctrl_rdy => iodelay_ctrl_rdy,
      ref_dll_lock     => c0_ref_dll_lock
      );

  c1_clk <= c1_clk_i;

  c1_u_infrastructure : mig_7series_v1_8_infrastructure
    generic map (
      TCQ            => C1_TCQ,
      nCK_PER_CLK    => C1_nCK_PER_CLK,
      CLKIN_PERIOD   => C1_CLKIN_PERIOD,
      CLKFBOUT_MULT  => C1_CLKFBOUT_MULT,
      DIVCLK_DIVIDE  => C1_DIVCLK_DIVIDE,
      CLKOUT0_PHASE  => 45.0,
      CLKOUT0_DIVIDE => C1_CLKOUT0_DIVIDE,
      CLKOUT1_DIVIDE => C1_CLKOUT1_DIVIDE,
      CLKOUT2_DIVIDE => C1_CLKOUT2_DIVIDE,
      CLKOUT3_DIVIDE => C1_CLKOUT3_DIVIDE,
      CLKOUT4_DIVIDE => C1_CLKOUT4_DIVIDE,
      RST_ACT_LOW    => RST_ACT_LOW
      )
    port map (
      -- Outputs
      rstdiv0        => c1_rst_wr_clk,
      clk            => c1_clk_i,
      mem_refclk     => c1_mem_refclk,
      iodelay_clk    => open,
      freq_refclk    => c1_freq_refclk,
      sync_pulse     => c1_sync_pulse,
      pll_locked     => c1_pll_locked,
      rst_phaser_ref => c1_rst_phaser_ref,

      -- Inputs
      mmcm_clk         => mmcm_clk,
      sys_rst          => sys_rst,
      iodelay_ctrl_rdy => iodelay_ctrl_rdy,
      ref_dll_lock     => c1_ref_dll_lock
      );

  c0_u_qdr_phy_top : mig_7series_v1_8_qdr_phy_top
    generic map (

      MEM_TYPE           => C0_MEM_TYPE,        --Memory Type (QDR2PLUS, QDR2)
      CLK_PERIOD         => C0_CLK_PERIOD,
      nCK_PER_CLK        => C0_nCK_PER_CLK,
      REFCLK_FREQ        => REFCLK_FREQ,
      IODELAY_GRP        => IODELAY_GRP,
      RST_ACT_LOW        => RST_ACT_LOW,
      CLK_STABLE         => C0_CLK_STABLE ,     --Cycles till CQ/CQ# is stable
      ADDR_WIDTH         => C0_ADDR_WIDTH ,     --Adress Width
      DATA_WIDTH         => C0_DATA_WIDTH ,     --Data Width
      BW_WIDTH           => C0_BW_WIDTH,        --Byte Write Width
      BURST_LEN          => C0_BURST_LEN,       --Burst Length
      NUM_DEVICES        => C0_NUM_DEVICES,     --Memory Devices
      N_DATA_LANES       => C0_N_DATA_LANES,
      FIXED_LATENCY_MODE => C0_FIXED_LATENCY_MODE,  --Fixed Latency for data reads
      PHY_LATENCY        => C0_PHY_LATENCY,     --Value for Fixed Latency Mode
      MEM_RD_LATENCY     => C0_MEM_RD_LATENCY,  --Value of Memory part read latency
      CPT_CLK_CQ_ONLY    => C0_CPT_CLK_CQ_ONLY,  --Only CQ is used for data capture and no CQ#
      SIMULATION         => C0_SIMULATION,      --TRUE during design simulation
      MASTER_PHY_CTL     => C0_PHY_CONTROL_MASTER_BANK,
      PLL_LOC            => C0_PHY_CONTROL_MASTER_BANK,
      INTER_BANK_SKEW    => C0_INTER_BANK_SKEW,

      CQ_BITS             => C0_CQ_BITS,   --clogb2(NUM_DEVICES - 1)
      Q_BITS              => C0_Q_BITS,    --clogb2(DATA_WIDTH - 1)
      DEVICE_TAPS         => DEVICE_TAPS,  -- Number of taps in the IDELAY chain
      TAP_BITS            => C0_TAP_BITS,  -- clogb2(DEVICE_TAPS - 1)
      SIM_BYPASS_INIT_CAL => C0_SIM_BYPASS_INIT_CAL,
      IBUF_LPWR_MODE      => C0_IBUF_LPWR_MODE ,  --Input buffer low power mode
      IODELAY_HP_MODE     => C0_IODELAY_HP_MODE,  --IODELAY High Performance Mode

      DATA_CTL_B0  => C0_DATA_CTL_B0,   --Data write/read bits in all banks
      DATA_CTL_B1  => C0_DATA_CTL_B1,
      DATA_CTL_B2  => C0_DATA_CTL_B2,
      DATA_CTL_B3  => C0_DATA_CTL_B3,
      DATA_CTL_B4  => C0_DATA_CTL_B4,
      ADDR_CTL_MAP => C0_ADDR_CTL_MAP,

      BYTE_LANES_B0 => C0_BYTE_LANES_B0,  --Byte lanes used for the complete design
      BYTE_LANES_B1 => C0_BYTE_LANES_B1,
      BYTE_LANES_B2 => C0_BYTE_LANES_B2,
      BYTE_LANES_B3 => C0_BYTE_LANES_B3,
      BYTE_LANES_B4 => C0_BYTE_LANES_B4,

      BYTE_GROUP_TYPE_B0 => C0_BYTE_GROUP_TYPE_B0,  --Differentiates data write and read byte lanes
      BYTE_GROUP_TYPE_B1 => C0_BYTE_GROUP_TYPE_B1,
      BYTE_GROUP_TYPE_B2 => C0_BYTE_GROUP_TYPE_B2,
      BYTE_GROUP_TYPE_B3 => C0_BYTE_GROUP_TYPE_B3,
      BYTE_GROUP_TYPE_B4 => C0_BYTE_GROUP_TYPE_B4,

      CPT_CLK_SEL_B0 => C0_CPT_CLK_SEL_B0,  --Capture clock placement parameters
      CPT_CLK_SEL_B1 => C0_CPT_CLK_SEL_B1,
      CPT_CLK_SEL_B2 => C0_CPT_CLK_SEL_B2,

      BIT_LANES_B0 => C0_PHY_0_BITLANES,  --Bits used for the complete design
      BIT_LANES_B1 => C0_PHY_1_BITLANES,
      BIT_LANES_B2 => C0_PHY_2_BITLANES,
      BIT_LANES_B3 => C0_PHY_3_BITLANES,
      BIT_LANES_B4 => C0_PHY_4_BITLANES,

      ADD_MAP => C0_ADD_MAP,            -- Address bits mapping
      RD_MAP  => C0_RD_MAP,
      WR_MAP  => C0_WR_MAP,

      D0_MAP => C0_D0_MAP,              -- Data write bits mapping
      D1_MAP => C0_D1_MAP,
      D2_MAP => C0_D2_MAP,
      D3_MAP => C0_D3_MAP,
      D4_MAP => C0_D4_MAP,
      D5_MAP => C0_D5_MAP,
      D6_MAP => C0_D6_MAP,
      D7_MAP => C0_D7_MAP,
      BW_MAP => C0_BW_MAP,
      K_MAP  => C0_K_MAP,

      Q0_MAP => C0_Q0_MAP,              -- Data read bits mapping
      Q1_MAP => C0_Q1_MAP,
      Q2_MAP => C0_Q2_MAP,
      Q3_MAP => C0_Q3_MAP,
      Q4_MAP => C0_Q4_MAP,
      Q5_MAP => C0_Q5_MAP,
      Q6_MAP => C0_Q6_MAP,
      Q7_MAP => C0_Q7_MAP,
      CQ_MAP => C0_CQ_MAP,

      DEBUG_PORT => C0_DEBUG_PORT,      -- Debug using Chipscope controls
      TCQ        => C0_TCQ              --Register Delay
      )
    port map (

      -- clocking and reset
      clk            => c0_clk_i,       --Fabric logic clock
      rst_wr_clk     => c0_rst_wr_clk,  -- fabric reset based on PLL lock and system input reset.
      --clk_ref                        => clk_ref,            -- Idelay_ctrl reference clock
      clk_mem        => c0_mem_refclk,  -- Memory clock to hard PHY
      freq_refclk    => c0_freq_refclk,
      sync_pulse     => c0_sync_pulse,
      pll_lock       => c0_pll_locked,
      rst_clk        => c0_rst_clk,  --output generated based on read clocks being stable
      sys_rst        => sys_rst,        -- input system reset
      ref_dll_lock   => c0_ref_dll_lock,
      rst_phaser_ref => c0_rst_phaser_ref,

      --PHY Write Path Interface
      wr_cmd0  => c0_app_wr_cmd0,       --wr command 0
      wr_cmd1  => c0_app_wr_cmd1,       --wr command 1
      wr_addr0 => c0_app_wr_addr0,      --wr address 0
      wr_addr1 => c0_app_wr_addr1,      --wr address 1
      rd_cmd0  => c0_app_rd_cmd0,       --rd command 0
      rd_cmd1  => c0_app_rd_cmd1,       --rd command 1
      rd_addr0 => c0_app_rd_addr0,      --rd address 0
      rd_addr1 => c0_app_rd_addr1,      --rd address 1
      wr_data0 => c0_mux_wr_data0,      --app write data 0
      wr_data1 => c0_mux_wr_data1,      --app write data 1
      wr_bw_n0 => c0_mux_wr_bw_n0,      --app byte writes 0
      wr_bw_n1 => c0_mux_wr_bw_n1,      --app byte writes 1

      --PHY Read Path Interface
      init_calib_complete => c0_init_calib_complete_i,  --Calibration complete
      rd_valid0           => c0_app_rd_valid0_i,  --Read valid for rd_data0
      rd_valid1           => c0_app_rd_valid1_i,  --Read valid for rd_data1
      rd_data0            => c0_rd_data0,         --Read data 0
      rd_data1            => c0_rd_data1,         --Read data 1

      --Memory Interface
      qdr_dll_off_n => c0_qdriip_dll_off_n,  --QDR - turn off dll in mem
      qdr_k_p       => c0_qdriip_k_p,        --QDR clock K
      qdr_k_n       => c0_qdriip_k_n,        --QDR clock K#
      qdr_sa        => c0_qdriip_sa,         --QDR Memory Address
      qdr_w_n       => c0_qdriip_w_n,        --QDR Write
      qdr_r_n       => c0_qdriip_r_n,        --QDR Read
      qdr_bw_n      => c0_qdriip_bw_n,       --QDR Byte Writes to Mem
      qdr_d         => c0_qdriip_d,          --QDR Data to Memory
      qdr_q         => c0_qdriip_q,          --QDR Data from Memory
      --qdr_qvld                       => c0_qdriip_qvld,        --QDR Data Valid from Mem
      qdr_cq_p      => c0_qdriip_cq_p,       --QDR echo clock CQ
      qdr_cq_n      => c0_qdriip_cq_n,       --QDR echo clock CQ#

      --Debug interface
      dbg_phy_status          => c0_dbg_phy_status,
      dbg_SM_en               => c0_dbg_SM_en,
      dbg_SM_No_Pause         => c0_dbg_SM_No_Pause,
      dbg_po_counter_read_val => c0_dbg_po_counter_read_val,
      dbg_pi_counter_read_val => c0_dbg_pi_counter_read_val_i,
      dbg_phy_init_wr_only    => c0_dbg_phy_init_wr_only,
      dbg_phy_init_rd_only    => c0_dbg_phy_init_rd_only,

      dbg_byte_sel         => c0_dbg_byte_sel,
      dbg_bit_sel          => c0_dbg_bit_sel,
      dbg_pi_f_inc         => c0_dbg_pi_f_inc,
      dbg_pi_f_dec         => c0_dbg_pi_f_dec,
      dbg_po_f_inc         => c0_dbg_po_f_inc,
      dbg_po_f_dec         => c0_dbg_po_f_dec,
      dbg_idel_up_all      => c0_dbg_idel_up_all,
      dbg_idel_down_all    => c0_dbg_idel_down_all,
      dbg_idel_up          => c0_dbg_idel_up,
      dbg_idel_down        => c0_dbg_idel_down,
      dbg_idel_tap_cnt     => c0_dbg_idel_tap_cnt,
      dbg_idel_tap_cnt_sel => c0_dbg_idel_tap_cnt_sel,
      dbg_select_rdata     => c0_dbg_select_rdata,

      dbg_align_rd0_r => c0_dbg_align_rd0_r,
      dbg_align_rd1_r => c0_dbg_align_rd1_r,
      dbg_align_fd0_r => c0_dbg_align_fd0_r,
      dbg_align_fd1_r => c0_dbg_align_fd1_r,
      dbg_align_rd0   => c0_dbg_align_rd0,
      dbg_align_rd1   => c0_dbg_align_rd1,
      dbg_align_fd0   => c0_dbg_align_fd0,
      dbg_align_fd1   => c0_dbg_align_fd1,

      dbg_byte_sel_cnt      => c0_dbg_byte_sel_cnt,
      dbg_phy_wr_cmd_n      => c0_dbg_phy_wr_cmd_n,
      dbg_phy_addr          => c0_dbg_phy_addr,
      dbg_phy_rd_cmd_n      => c0_dbg_phy_rd_cmd_n,
      dbg_phy_wr_data       => c0_dbg_phy_wr_data,
      dbg_wr_init           => c0_dbg_wr_init,
      dbg_mc_phy            => c0_dbg_mc_phy,
      dbg_rd_stage1_cal     => c0_dbg_rd_stage1_cal,
      dbg_stage2_cal        => c0_dbg_stage2_cal,
      dbg_valid_lat         => c0_dbg_valid_lat,
      dbg_inc_latency       => c0_dbg_inc_latency,
      dbg_error_max_latency => c0_dbg_error_max_latency,
      dbg_error_adj_latency => c0_dbg_error_adj_latency
      );


  c1_u_qdr_phy_top : mig_7series_v1_8_qdr_phy_top
    generic map (

      MEM_TYPE           => C1_MEM_TYPE,        --Memory Type (QDR2PLUS, QDR2)
      CLK_PERIOD         => C1_CLK_PERIOD,
      nCK_PER_CLK        => C1_nCK_PER_CLK,
      REFCLK_FREQ        => REFCLK_FREQ,
      IODELAY_GRP        => IODELAY_GRP,
      RST_ACT_LOW        => RST_ACT_LOW,
      CLK_STABLE         => C1_CLK_STABLE ,     --Cycles till CQ/CQ# is stable
      ADDR_WIDTH         => C1_ADDR_WIDTH ,     --Adress Width
      DATA_WIDTH         => C1_DATA_WIDTH ,     --Data Width
      BW_WIDTH           => C1_BW_WIDTH,        --Byte Write Width
      BURST_LEN          => C1_BURST_LEN,       --Burst Length
      NUM_DEVICES        => C1_NUM_DEVICES,     --Memory Devices
      N_DATA_LANES       => C1_N_DATA_LANES,
      FIXED_LATENCY_MODE => C1_FIXED_LATENCY_MODE,  --Fixed Latency for data reads
      PHY_LATENCY        => C1_PHY_LATENCY,     --Value for Fixed Latency Mode
      MEM_RD_LATENCY     => C1_MEM_RD_LATENCY,  --Value of Memory part read latency
      CPT_CLK_CQ_ONLY    => C1_CPT_CLK_CQ_ONLY,  --Only CQ is used for data capture and no CQ#
      SIMULATION         => C1_SIMULATION,      --TRUE during design simulation
      MASTER_PHY_CTL     => C1_PHY_CONTROL_MASTER_BANK,
      PLL_LOC            => C1_PHY_CONTROL_MASTER_BANK,
      INTER_BANK_SKEW    => C1_INTER_BANK_SKEW,

      CQ_BITS             => C1_CQ_BITS,   --clogb2(NUM_DEVICES - 1)
      Q_BITS              => C1_Q_BITS,    --clogb2(DATA_WIDTH - 1)
      DEVICE_TAPS         => DEVICE_TAPS,  -- Number of taps in the IDELAY chain
      TAP_BITS            => C1_TAP_BITS,  -- clogb2(DEVICE_TAPS - 1)
      SIM_BYPASS_INIT_CAL => C1_SIM_BYPASS_INIT_CAL,
      IBUF_LPWR_MODE      => C1_IBUF_LPWR_MODE ,  --Input buffer low power mode
      IODELAY_HP_MODE     => C1_IODELAY_HP_MODE,  --IODELAY High Performance Mode

      DATA_CTL_B0  => C1_DATA_CTL_B0,   --Data write/read bits in all banks
      DATA_CTL_B1  => C1_DATA_CTL_B1,
      DATA_CTL_B2  => C1_DATA_CTL_B2,
      DATA_CTL_B3  => C1_DATA_CTL_B3,
      DATA_CTL_B4  => C1_DATA_CTL_B4,
      ADDR_CTL_MAP => C1_ADDR_CTL_MAP,

      BYTE_LANES_B0 => C1_BYTE_LANES_B0,  --Byte lanes used for the complete design
      BYTE_LANES_B1 => C1_BYTE_LANES_B1,
      BYTE_LANES_B2 => C1_BYTE_LANES_B2,
      BYTE_LANES_B3 => C1_BYTE_LANES_B3,
      BYTE_LANES_B4 => C1_BYTE_LANES_B4,

      BYTE_GROUP_TYPE_B0 => C1_BYTE_GROUP_TYPE_B0,  --Differentiates data write and read byte lanes
      BYTE_GROUP_TYPE_B1 => C1_BYTE_GROUP_TYPE_B1,
      BYTE_GROUP_TYPE_B2 => C1_BYTE_GROUP_TYPE_B2,
      BYTE_GROUP_TYPE_B3 => C1_BYTE_GROUP_TYPE_B3,
      BYTE_GROUP_TYPE_B4 => C1_BYTE_GROUP_TYPE_B4,

      CPT_CLK_SEL_B0 => C1_CPT_CLK_SEL_B0,  --Capture clock placement parameters
      CPT_CLK_SEL_B1 => C1_CPT_CLK_SEL_B1,
      CPT_CLK_SEL_B2 => C1_CPT_CLK_SEL_B2,

      BIT_LANES_B0 => C1_PHY_0_BITLANES,  --Bits used for the complete design
      BIT_LANES_B1 => C1_PHY_1_BITLANES,
      BIT_LANES_B2 => C1_PHY_2_BITLANES,
      BIT_LANES_B3 => C1_PHY_3_BITLANES,
      BIT_LANES_B4 => C1_PHY_4_BITLANES,

      ADD_MAP => C1_ADD_MAP,            -- Address bits mapping
      RD_MAP  => C1_RD_MAP,
      WR_MAP  => C1_WR_MAP,

      D0_MAP => C1_D0_MAP,              -- Data write bits mapping
      D1_MAP => C1_D1_MAP,
      D2_MAP => C1_D2_MAP,
      D3_MAP => C1_D3_MAP,
      D4_MAP => C1_D4_MAP,
      D5_MAP => C1_D5_MAP,
      D6_MAP => C1_D6_MAP,
      D7_MAP => C1_D7_MAP,
      BW_MAP => C1_BW_MAP,
      K_MAP  => C1_K_MAP,

      Q0_MAP => C1_Q0_MAP,              -- Data read bits mapping
      Q1_MAP => C1_Q1_MAP,
      Q2_MAP => C1_Q2_MAP,
      Q3_MAP => C1_Q3_MAP,
      Q4_MAP => C1_Q4_MAP,
      Q5_MAP => C1_Q5_MAP,
      Q6_MAP => C1_Q6_MAP,
      Q7_MAP => C1_Q7_MAP,
      CQ_MAP => C1_CQ_MAP,

      DEBUG_PORT => C1_DEBUG_PORT,      -- Debug using Chipscope controls
      TCQ        => C1_TCQ              --Register Delay
      )
    port map (

      -- clocking and reset
      clk            => c1_clk_i,       --Fabric logic clock
      rst_wr_clk     => c1_rst_wr_clk,  -- fabric reset based on PLL lock and system input reset.
      --clk_ref                        => clk_ref,            -- Idelay_ctrl reference clock
      clk_mem        => c1_mem_refclk,  -- Memory clock to hard PHY
      freq_refclk    => c1_freq_refclk,
      sync_pulse     => c1_sync_pulse,
      pll_lock       => c1_pll_locked,
      rst_clk        => c1_rst_clk,  --output generated based on read clocks being stable
      sys_rst        => sys_rst,        -- input system reset
      ref_dll_lock   => c1_ref_dll_lock,
      rst_phaser_ref => c1_rst_phaser_ref,

      --PHY Write Path Interface
      wr_cmd0  => c1_app_wr_cmd0,       --wr command 0
      wr_cmd1  => c1_app_wr_cmd1,       --wr command 1
      wr_addr0 => c1_app_wr_addr0,      --wr address 0
      wr_addr1 => c1_app_wr_addr1,      --wr address 1
      rd_cmd0  => c1_app_rd_cmd0,       --rd command 0
      rd_cmd1  => c1_app_rd_cmd1,       --rd command 1
      rd_addr0 => c1_app_rd_addr0,      --rd address 0
      rd_addr1 => c1_app_rd_addr1,      --rd address 1
      wr_data0 => c1_mux_wr_data0,      --app write data 0
      wr_data1 => c1_mux_wr_data1,      --app write data 1
      wr_bw_n0 => c1_mux_wr_bw_n0,      --app byte writes 0
      wr_bw_n1 => c1_mux_wr_bw_n1,      --app byte writes 1

      --PHY Read Path Interface
      init_calib_complete => c1_init_calib_complete_i,  --Calibration complete
      rd_valid0           => c1_app_rd_valid0_i,  --Read valid for rd_data0
      rd_valid1           => c1_app_rd_valid1_i,  --Read valid for rd_data1
      rd_data0            => c1_rd_data0,         --Read data 0
      rd_data1            => c1_rd_data1,         --Read data 1

      --Memory Interface
      qdr_dll_off_n => c1_qdriip_dll_off_n,  --QDR - turn off dll in mem
      qdr_k_p       => c1_qdriip_k_p,        --QDR clock K
      qdr_k_n       => c1_qdriip_k_n,        --QDR clock K#
      qdr_sa        => c1_qdriip_sa,         --QDR Memory Address
      qdr_w_n       => c1_qdriip_w_n,        --QDR Write
      qdr_r_n       => c1_qdriip_r_n,        --QDR Read
      qdr_bw_n      => c1_qdriip_bw_n,       --QDR Byte Writes to Mem
      qdr_d         => c1_qdriip_d,          --QDR Data to Memory
      qdr_q         => c1_qdriip_q,          --QDR Data from Memory
      --qdr_qvld                       => c1_qdriip_qvld,        --QDR Data Valid from Mem
      qdr_cq_p      => c1_qdriip_cq_p,       --QDR echo clock CQ
      qdr_cq_n      => c1_qdriip_cq_n,       --QDR echo clock CQ#

      --Debug interface
      dbg_phy_status          => c1_dbg_phy_status,
      dbg_SM_en               => c1_dbg_SM_en,
      dbg_SM_No_Pause         => c1_dbg_SM_No_Pause,
      dbg_po_counter_read_val => c1_dbg_po_counter_read_val,
      dbg_pi_counter_read_val => c1_dbg_pi_counter_read_val_i,
      dbg_phy_init_wr_only    => c1_dbg_phy_init_wr_only,
      dbg_phy_init_rd_only    => c1_dbg_phy_init_rd_only,

      dbg_byte_sel         => c1_dbg_byte_sel,
      dbg_bit_sel          => c1_dbg_bit_sel,
      dbg_pi_f_inc         => c1_dbg_pi_f_inc,
      dbg_pi_f_dec         => c1_dbg_pi_f_dec,
      dbg_po_f_inc         => c1_dbg_po_f_inc,
      dbg_po_f_dec         => c1_dbg_po_f_dec,
      dbg_idel_up_all      => c1_dbg_idel_up_all,
      dbg_idel_down_all    => c1_dbg_idel_down_all,
      dbg_idel_up          => c1_dbg_idel_up,
      dbg_idel_down        => c1_dbg_idel_down,
      dbg_idel_tap_cnt     => c1_dbg_idel_tap_cnt,
      dbg_idel_tap_cnt_sel => c1_dbg_idel_tap_cnt_sel,
      dbg_select_rdata     => c1_dbg_select_rdata,

      dbg_align_rd0_r => c1_dbg_align_rd0_r,
      dbg_align_rd1_r => c1_dbg_align_rd1_r,
      dbg_align_fd0_r => c1_dbg_align_fd0_r,
      dbg_align_fd1_r => c1_dbg_align_fd1_r,
      dbg_align_rd0   => c1_dbg_align_rd0,
      dbg_align_rd1   => c1_dbg_align_rd1,
      dbg_align_fd0   => c1_dbg_align_fd0,
      dbg_align_fd1   => c1_dbg_align_fd1,

      dbg_byte_sel_cnt      => c1_dbg_byte_sel_cnt,
      dbg_phy_wr_cmd_n      => c1_dbg_phy_wr_cmd_n,
      dbg_phy_addr          => c1_dbg_phy_addr,
      dbg_phy_rd_cmd_n      => c1_dbg_phy_rd_cmd_n,
      dbg_phy_wr_data       => c1_dbg_phy_wr_data,
      dbg_wr_init           => c1_dbg_wr_init,
      dbg_mc_phy            => c1_dbg_mc_phy,
      dbg_rd_stage1_cal     => c1_dbg_rd_stage1_cal,
      dbg_stage2_cal        => c1_dbg_stage2_cal,
      dbg_valid_lat         => c1_dbg_valid_lat,
      dbg_inc_latency       => c1_dbg_inc_latency,
      dbg_error_max_latency => c1_dbg_error_max_latency,
      dbg_error_adj_latency => c1_dbg_error_adj_latency
      );

  --*********************************************************************
  -- Resetting all RTL debug inputs as the debug ports are not enabled
  --*********************************************************************
  c0_dbg_phy_init_wr_only <= '0';
  c0_dbg_phy_init_rd_only <= '0';
  c0_dbg_byte_sel         <= (others => '0');
  c0_dbg_bit_sel          <= (others => '0');
  c0_dbg_pi_f_inc         <= '0';
  c0_dbg_pi_f_dec         <= '0';
  c0_dbg_po_f_inc         <= '0';
  c0_dbg_po_f_dec         <= '0';
  c0_dbg_idel_up_all      <= '0';
  c0_dbg_idel_down_all    <= '0';
  c0_dbg_idel_up          <= '0';
  c0_dbg_idel_down        <= '0';
  c0_dbg_SM_en            <= '1';
  c0_dbg_SM_No_Pause      <= '1';

  --*********************************************************************
  -- Resetting all RTL debug inputs as the debug ports are not enabled
  --*********************************************************************
  c1_dbg_phy_init_wr_only <= '0';
  c1_dbg_phy_init_rd_only <= '0';
  c1_dbg_byte_sel         <= (others => '0');
  c1_dbg_bit_sel          <= (others => '0');
  c1_dbg_pi_f_inc         <= '0';
  c1_dbg_pi_f_dec         <= '0';
  c1_dbg_po_f_inc         <= '0';
  c1_dbg_po_f_dec         <= '0';
  c1_dbg_idel_up_all      <= '0';
  c1_dbg_idel_down_all    <= '0';
  c1_dbg_idel_up          <= '0';
  c1_dbg_idel_down        <= '0';
  c1_dbg_SM_en            <= '1';
  c1_dbg_SM_No_Pause      <= '1';
  

end architecture behave;
