//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 1.7
//  \   \         Application        : MIG
//  /   /         Filename           : sim_tb_top.v
// /___/   /\     Date Last Modified : $Date: 2011/06/07 13:45:16 $
// \   \  /  \    Date Created       : Fri Jan 14 2011
//  \___\/\___\
//
// Device           : 7 Series
// Design Name      : QDRII+ SRAM
// Purpose          :
//                   Top-level testbench for testing QDRII+.
//                   Instantiates:
//                     1. IP_TOP (top-level representing FPGA, contains core,
//                        clocking, built-in testbench/memory checker and other
//                        support structures)
//                     2. QDRII+ Memory Instantiations (Samsung only)
//                     3. Miscellaneous clock generation and reset logic
// Reference        :
// Revision History :
//******************************************************************************

`timescale  1 ps/100 fs

module sim_tb_top;


   localparam C0_MEM_TYPE              = "QDR2PLUS";
                                     // # of CK/CK# outputs to memory.
   localparam C0_DATA_WIDTH            = 18;
                                     // # of DQ (data)
   localparam C0_BW_WIDTH              = 2;
                                     // # of byte writes (data_width/9)
   localparam C0_ADDR_WIDTH            = 20;
                                     // Address Width
   localparam C0_NUM_DEVICES           = 1;
                                     // # of memory components connected
   localparam C0_MEM_RD_LATENCY        = 2.5;
                                     // Value of Memory part read latency
   localparam C0_CPT_CLK_CQ_ONLY       = "FALSE";
                                     // CQ and its inverse are used for data capture
   parameter C0_INTER_BANK_SKEW        = 0;
                                     // Clock skew between two adjacent banks
   parameter C0_PHY_CONTROL_MASTER_BANK = 1;
                                     // The bank index where master PHY_CONTROL resides,
                                     // equal to the PLL residing bank

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   localparam C0_BURST_LEN             = 4;
                                     // Burst Length of the design (4 or 2).
   localparam C0_FIXED_LATENCY_MODE    = 0;
                                     // Enable Fixed Latency
   localparam C0_PHY_LATENCY           = 0;
                                     // Value for Fixed Latency Mode
                                     // Expected Latency
   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for MMCM.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   localparam C0_CLKIN_PERIOD          = 2500;
                                     // Input Clock Period
   localparam C0_CLKFBOUT_MULT         = 9;
                                     // write PLL VCO multiplier
   localparam C0_DIVCLK_DIVIDE         = 4;
                                     // write PLL VCO divisor
   localparam C0_CLKOUT0_DIVIDE        = 2;
                                     // VCO output divisor for PLL output clock (CLKOUT0)
   localparam C0_CLKOUT1_DIVIDE        = 2;
                                     // VCO output divisor for PLL output clock (CLKOUT1)
   localparam C0_CLKOUT2_DIVIDE        = 32;
                                     // VCO output divisor for PLL output clock (CLKOUT2)
   localparam C0_CLKOUT3_DIVIDE        = 4;
                                     // VCO output divisor for PLL output clock (CLKOUT3)

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   localparam C0_SIM_BYPASS_INIT_CAL   = "FAST";
                                     // # = "OFF" -  Complete memory init &
                                     //              calibration sequence
                                     // # = "SKIP" - Skip memory init &
                                     //              calibration sequence
                                     // # = "FAST" - Skip memory init & use
                                     //              abbreviated calib sequence
   localparam C0_SIMULATION            = "TRUE";
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementations

   //***************************************************************************
   // The following parameters varies based on the pin out entered in MIG GUI.
   // Do not change any of these parameters directly by editing the RTL.
   // Any changes required should be done through GUI and the design regenerated.
   //***************************************************************************
   localparam C0_BYTE_LANES_B0         = 4'b1100;
                                     // Byte lanes used in an IO column.
   localparam C0_BYTE_LANES_B1         = 4'b1111;
                                     // Byte lanes used in an IO column.
   localparam C0_BYTE_LANES_B2         = 4'b0000;
                                     // Byte lanes used in an IO column.
   localparam C0_BYTE_LANES_B3         = 4'b0000;
                                     // Byte lanes used in an IO column.
   localparam C0_BYTE_LANES_B4         = 4'b0000;
                                     // Byte lanes used in an IO column.
   localparam C0_DATA_CTL_B0           = 4'b1100;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C0_DATA_CTL_B1           = 4'b1100;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C0_DATA_CTL_B2           = 4'b0000;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C0_DATA_CTL_B3           = 4'b0000;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C0_DATA_CTL_B4           = 4'b0000;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C0_PHY_0_BITLANES       = 48'hDFC_FF1_000_000;
                                     // The bits used inside the Bank0 out of 48 pins.
   localparam C0_PHY_1_BITLANES       = 48'h3FE_FFE_FFF_CFF;
                                     // The bits used inside the Bank1 out of 48 pins.
   localparam C0_PHY_2_BITLANES       = 48'h000_000_000_000;
                                     // The bits used inside the Bank2 out of 48 pins.
   localparam C0_PHY_3_BITLANES       = 48'h000_000_000_000;
                                     // The bits used inside the Bank3 out of 48 pins.
   localparam C0_PHY_4_BITLANES       = 48'h000_000_000_000;
                                     // The bits used inside the Bank4 out of 48 pins.

   // this parameter specifies the location of the capture clock with respect
   // to read data.
   // Each byte refers to the information needed for data capture in the corresponding byte lane
   // Lower order nibble - is either 4'h1 or 4'h2. This refers to the capture clock in T1 or T2 byte lane
   // Higher order nibble - 4'h0 refers to clock present in the bank below the read data,
   //                       4'h1 refers to clock present in the same bank as the read data,
   //                       4'h2 refers to clock present in the bank above the read data.
   parameter C0_CPT_CLK_SEL_B0  = 32'h11_11_00_00;
   parameter C0_CPT_CLK_SEL_B1  = 32'h00_00_00_00;
   parameter C0_CPT_CLK_SEL_B2  = 32'h00_00_00_00;

   // Differentiates the INPUT and OUTPUT bytelates (1-input, 0-output)
   localparam C0_BYTE_GROUP_TYPE_B0 = 4'b1100;
   localparam C0_BYTE_GROUP_TYPE_B1 = 4'b0000;
   localparam C0_BYTE_GROUP_TYPE_B2 = 4'b0000;
   localparam C0_BYTE_GROUP_TYPE_B3 = 4'b0000;
   localparam C0_BYTE_GROUP_TYPE_B4 = 4'b0000;

   // mapping for K/K# clocks. This parameter needs to have an 8-bit value per component
   // since the phy drives a K/K# clock pair to each memory it interfaces to. A 3 component
   // interface is supported for now. This parameter needs to be used in conjunction with
   // NUM_DEVICES parameter which provides information on the number. of components being
   // interfaced to.
   // the 8 bit for each component is defined as follows:
   // [7:4] - bank number ; [3:0] - byte lane number
   localparam C0_K_MAP = 48'h00_00_00_00_00_13;

   // mapping for CQ/CQ# clocks. This parameter needs to have an 4-bit value per component
   // since the phy drives a CQ/CQ# clock pair to each memory it interfaces to. A 3 component
   // interface is supported for now. This parameter needs to be used in conjunction with
   // NUM_DEVICES parameter which provides information on the number. of components being
   // interfaced to.
   // the 4 bit for each component is defined as follows:
   // [3:0] - bank number
   localparam C0_CQ_MAP = 48'h00_00_00_00_00_01;

   //**********************************************************************************************
   // Each of the following parameter contains the byte_lane and bit position information for
   // the address/control, data write and data read signals. Each bit has 12 bits and the details are
   // [3:0] - Bit position within a byte lane .
   // [7:4] - Byte lane position within a bank. [5:4] have the byte lane position and others reserved.
   // [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero .
   //**********************************************************************************************

   // Mapping for address and control signals.

   localparam C0_RD_MAP = 12'h103;      // Mapping for read enable signal
   localparam C0_WR_MAP = 12'h105;      // Mapping for write enable signal

   // Mapping for address signals. Supports upto 22 bits of address bits (22*12)
   localparam C0_ADD_MAP = 264'h000_000_119_118_110_116_112_113_111_114_11A_11B_117_115_10B_100_104_102_106_10A_101_107;

   // Mapping for the byte lanes used for address/control signals. Supports a maximum of 3 banks.
   localparam C0_ADDR_CTL_MAP = 24'h00_11_10;

   // Mapping for data WRITE signals

   // Mapping for data write bytes (9*12)
   localparam C0_D0_MAP  = 108'h137_132_136_139_138_134_133_131_135; //byte 0
   localparam C0_D1_MAP  = 108'h123_122_12B_125_124_12A_121_126_127; //byte 1
   localparam C0_D2_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 2
   localparam C0_D3_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 3
   localparam C0_D4_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 4
   localparam C0_D5_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 5
   localparam C0_D6_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 6
   localparam C0_D7_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 7

   // Mapping for byte write signals (8*12)
   localparam C0_BW_MAP = 84'h000_000_000_000_000_129_128;

   // Mapping for data READ signals

   // Mapping for data read bytes (9*12)
   localparam C0_Q0_MAP  = 108'h020_02A_025_027_02B_026_024_028_029; //byte 0
   localparam C0_Q1_MAP  = 108'h032_033_03A_035_034_03B_036_037_038; //byte 1
   localparam C0_Q2_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 2
   localparam C0_Q3_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 3
   localparam C0_Q4_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 4
   localparam C0_Q5_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 5
   localparam C0_Q6_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 6
   localparam C0_Q7_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 7

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   localparam C0_IODELAY_HP_MODE       = "ON";
                                     // to phy_top
   localparam C0_IBUF_LPWR_MODE        = "OFF";
                                     // to phy_top
   localparam C0_TCQ                   = 100;
   localparam IODELAY_GRP           = "IODELAY_MIG";
                                     // It is associated to a set of IODELAYs with
                                     // an IDELAYCTRL that have same IODELAY CONTROLLER
                                     // clock frequency.
   localparam SYSCLK_TYPE           = "DIFFERENTIAL";
                                     // System clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER
   localparam REFCLK_TYPE           = "DIFFERENTIAL";
                                     // Reference clock type DIFFERENTIAL, SINGLE_ENDED,
                                     // NO_BUFFER, USE_SYSTEM_CLOCK
   localparam RST_ACT_LOW           = 1;
                                     // =1 for active low reset,
                                     // =0 for active high.

   
   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
   localparam REFCLK_FREQ           = 200.0;
                                     // IODELAYCTRL reference clock frequency
   localparam DIFF_TERM_REFCLK      = "TRUE";
                                     // Differential Termination for idelay
                                     // reference clock input pins

   // Number of taps in target IDELAY
   localparam integer DEVICE_TAPS = 32;
      
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   localparam C0_CLK_PERIOD            = 2222;
                                     // memory tCK paramter.
                                     // # = Clock Period in pS.
   localparam C0_nCK_PER_CLK           = 2;
                                     // # of memory CKs per fabric CLK
   localparam C0_DIFF_TERM_SYSCLK      = "TRUE";
                                     // Differential Termination for System
                                     // clock input pins

   //***************************************************************************
   // Traffic Gen related parameters
   //***************************************************************************
   localparam C0_BL_WIDTH              = 8;
   localparam C0_PORT_MODE             = "BI_MODE";
   localparam C0_DATA_MODE             = 4'b0010;
   localparam C0_EYE_TEST              = "FALSE";
                                     // set EYE_TEST = "TRUE" to probe memory
                                     // signals. Traffic Generator will only
                                     // write to one single location and no
                                     // read transactions will be generated.
   localparam C0_DATA_PATTERN          = "DGEN_ALL";
                                      // "DGEN_HAMMER"; "DGEN_WALKING1",
                                      // "DGEN_WALKING0","DGEN_ADDR","
                                      // "DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"
   localparam C0_CMD_PATTERN           = "CGEN_ALL";
                                      // "CGEN_PRBS","CGEN_FIXED","CGEN_BRAM",
                                      // "CGEN_SEQUENTIAL", "CGEN_ALL"
   localparam C0_BEGIN_ADDRESS         = 32'h00000000;
   localparam C0_END_ADDRESS           = 32'h00000fff;
   localparam C0_PRBS_EADDR_MASK_POS   = 32'hfffff000;

   //***************************************************************************
   // Wait period for the read strobe (CQ) to become stable
   //***************************************************************************
   localparam C0_CLK_STABLE            = (20*1000*1000/(C0_CLK_PERIOD*2));
                                     // Cycles till CQ/CQ# is stable

   //***************************************************************************
   // Debug parameter
   //***************************************************************************
   localparam C0_DEBUG_PORT            = "OFF";
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.
      
   localparam C1_MEM_TYPE              = "QDR2PLUS";
                                     // # of CK/CK# outputs to memory.
   localparam C1_DATA_WIDTH            = 18;
                                     // # of DQ (data)
   localparam C1_BW_WIDTH              = 2;
                                     // # of byte writes (data_width/9)
   localparam C1_ADDR_WIDTH            = 20;
                                     // Address Width
   localparam C1_NUM_DEVICES           = 1;
                                     // # of memory components connected
   localparam C1_MEM_RD_LATENCY        = 2.5;
                                     // Value of Memory part read latency
   localparam C1_CPT_CLK_CQ_ONLY       = "FALSE";
                                     // CQ and its inverse are used for data capture
   parameter C1_INTER_BANK_SKEW        = 0;
                                     // Clock skew between two adjacent banks
   parameter C1_PHY_CONTROL_MASTER_BANK = 1;
                                     // The bank index where master PHY_CONTROL resides,
                                     // equal to the PLL residing bank

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   localparam C1_BURST_LEN             = 4;
                                     // Burst Length of the design (4 or 2).
   localparam C1_FIXED_LATENCY_MODE    = 0;
                                     // Enable Fixed Latency
   localparam C1_PHY_LATENCY           = 0;
                                     // Value for Fixed Latency Mode
                                     // Expected Latency
   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for MMCM.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   localparam C1_CLKIN_PERIOD          = 2500;
                                     // Input Clock Period
   localparam C1_CLKFBOUT_MULT         = 9;
                                     // write PLL VCO multiplier
   localparam C1_DIVCLK_DIVIDE         = 4;
                                     // write PLL VCO divisor
   localparam C1_CLKOUT0_DIVIDE        = 2;
                                     // VCO output divisor for PLL output clock (CLKOUT0)
   localparam C1_CLKOUT1_DIVIDE        = 2;
                                     // VCO output divisor for PLL output clock (CLKOUT1)
   localparam C1_CLKOUT2_DIVIDE        = 32;
                                     // VCO output divisor for PLL output clock (CLKOUT2)
   localparam C1_CLKOUT3_DIVIDE        = 4;
                                     // VCO output divisor for PLL output clock (CLKOUT3)

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   localparam C1_SIM_BYPASS_INIT_CAL   = "FAST";
                                     // # = "OFF" -  Complete memory init &
                                     //              calibration sequence
                                     // # = "SKIP" - Skip memory init &
                                     //              calibration sequence
                                     // # = "FAST" - Skip memory init & use
                                     //              abbreviated calib sequence
   localparam C1_SIMULATION            = "TRUE";
                                     // Should be TRUE during design simulations and
                                     // FALSE during implementations

   //***************************************************************************
   // The following parameters varies based on the pin out entered in MIG GUI.
   // Do not change any of these parameters directly by editing the RTL.
   // Any changes required should be done through GUI and the design regenerated.
   //***************************************************************************
   localparam C1_BYTE_LANES_B0         = 4'b1100;
                                     // Byte lanes used in an IO column.
   localparam C1_BYTE_LANES_B1         = 4'b1111;
                                     // Byte lanes used in an IO column.
   localparam C1_BYTE_LANES_B2         = 4'b0000;
                                     // Byte lanes used in an IO column.
   localparam C1_BYTE_LANES_B3         = 4'b0000;
                                     // Byte lanes used in an IO column.
   localparam C1_BYTE_LANES_B4         = 4'b0000;
                                     // Byte lanes used in an IO column.
   localparam C1_DATA_CTL_B0           = 4'b1100;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C1_DATA_CTL_B1           = 4'b1100;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C1_DATA_CTL_B2           = 4'b0000;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C1_DATA_CTL_B3           = 4'b0000;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C1_DATA_CTL_B4           = 4'b0000;
                                     // Indicates Byte lane is data byte lane
                                     // or control Byte lane. '1' in a bit
                                     // position indicates a data byte lane and
                                     // a '0' indicates a control byte lane
   localparam C1_PHY_0_BITLANES       = 48'hFF8_DFC_000_000;
                                     // The bits used inside the Bank0 out of 48 pins.
   localparam C1_PHY_1_BITLANES       = 48'h3FE_FFE_FFF_EFD;
                                     // The bits used inside the Bank1 out of 48 pins.
   localparam C1_PHY_2_BITLANES       = 48'h000_000_000_000;
                                     // The bits used inside the Bank2 out of 48 pins.
   localparam C1_PHY_3_BITLANES       = 48'h000_000_000_000;
                                     // The bits used inside the Bank3 out of 48 pins.
   localparam C1_PHY_4_BITLANES       = 48'h000_000_000_000;
                                     // The bits used inside the Bank4 out of 48 pins.

   // this parameter specifies the location of the capture clock with respect
   // to read data.
   // Each byte refers to the information needed for data capture in the corresponding byte lane
   // Lower order nibble - is either 4'h1 or 4'h2. This refers to the capture clock in T1 or T2 byte lane
   // Higher order nibble - 4'h0 refers to clock present in the bank below the read data,
   //                       4'h1 refers to clock present in the same bank as the read data,
   //                       4'h2 refers to clock present in the bank above the read data.
   parameter C1_CPT_CLK_SEL_B0  = 32'h11_11_00_00;
   parameter C1_CPT_CLK_SEL_B1  = 32'h00_00_00_00;
   parameter C1_CPT_CLK_SEL_B2  = 32'h00_00_00_00;

   // Differentiates the INPUT and OUTPUT bytelates (1-input, 0-output)
   localparam C1_BYTE_GROUP_TYPE_B0 = 4'b1100;
   localparam C1_BYTE_GROUP_TYPE_B1 = 4'b0000;
   localparam C1_BYTE_GROUP_TYPE_B2 = 4'b0000;
   localparam C1_BYTE_GROUP_TYPE_B3 = 4'b0000;
   localparam C1_BYTE_GROUP_TYPE_B4 = 4'b0000;

   // mapping for K/K# clocks. This parameter needs to have an 8-bit value per component
   // since the phy drives a K/K# clock pair to each memory it interfaces to. A 3 component
   // interface is supported for now. This parameter needs to be used in conjunction with
   // NUM_DEVICES parameter which provides information on the number. of components being
   // interfaced to.
   // the 8 bit for each component is defined as follows:
   // [7:4] - bank number ; [3:0] - byte lane number
   localparam C1_K_MAP = 48'h00_00_00_00_00_13;

   // mapping for CQ/CQ# clocks. This parameter needs to have an 4-bit value per component
   // since the phy drives a CQ/CQ# clock pair to each memory it interfaces to. A 3 component
   // interface is supported for now. This parameter needs to be used in conjunction with
   // NUM_DEVICES parameter which provides information on the number. of components being
   // interfaced to.
   // the 4 bit for each component is defined as follows:
   // [3:0] - bank number
   localparam C1_CQ_MAP = 48'h00_00_00_00_00_01;

   //**********************************************************************************************
   // Each of the following parameter contains the byte_lane and bit position information for
   // the address/control, data write and data read signals. Each bit has 12 bits and the details are
   // [3:0] - Bit position within a byte lane .
   // [7:4] - Byte lane position within a bank. [5:4] have the byte lane position and others reserved.
   // [11:8] - Bank position. [10:8] have the bank position. [11] tied to zero .
   //**********************************************************************************************

   // Mapping for address and control signals.

   localparam C1_RD_MAP = 12'h102;      // Mapping for read enable signal
   localparam C1_WR_MAP = 12'h103;      // Mapping for write enable signal

   // Mapping for address signals. Supports upto 22 bits of address bits (22*12)
   localparam C1_ADD_MAP = 264'h000_000_113_11A_112_115_118_111_109_114_110_119_11B_116_117_100_107_106_10B_10A_105_104;

   // Mapping for the byte lanes used for address/control signals. Supports a maximum of 3 banks.
   localparam C1_ADDR_CTL_MAP = 24'h00_11_10;

   // Mapping for data WRITE signals

   // Mapping for data write bytes (9*12)
   localparam C1_D0_MAP  = 108'h12A_12B_127_126_124_125_122_123_121; //byte 0
   localparam C1_D1_MAP  = 108'h131_139_138_132_133_135_137_136_134; //byte 1
   localparam C1_D2_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 2
   localparam C1_D3_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 3
   localparam C1_D4_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 4
   localparam C1_D5_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 5
   localparam C1_D6_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 6
   localparam C1_D7_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 7

   // Mapping for byte write signals (8*12)
   localparam C1_BW_MAP = 84'h000_000_000_000_000_128_129;

   // Mapping for data READ signals

   // Mapping for data read bytes (9*12)
   localparam C1_Q0_MAP  = 108'h027_022_028_023_025_024_02A_02B_026; //byte 0
   localparam C1_Q1_MAP  = 108'h036_037_035_034_039_03B_038_033_03A; //byte 1
   localparam C1_Q2_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 2
   localparam C1_Q3_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 3
   localparam C1_Q4_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 4
   localparam C1_Q5_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 5
   localparam C1_Q6_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 6
   localparam C1_Q7_MAP  = 108'h000_000_000_000_000_000_000_000_000; //byte 7

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   localparam C1_IODELAY_HP_MODE       = "ON";
                                     // to phy_top
   localparam C1_IBUF_LPWR_MODE        = "OFF";
                                     // to phy_top
   localparam C1_TCQ                   = 100;
   

   
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   localparam C1_CLK_PERIOD            = 2222;
                                     // memory tCK paramter.
                                     // # = Clock Period in pS.
   localparam C1_nCK_PER_CLK           = 2;
                                     // # of memory CKs per fabric CLK
   localparam C1_DIFF_TERM_SYSCLK      = "TRUE";
                                     // Differential Termination for System
                                     // clock input pins

   //***************************************************************************
   // Traffic Gen related parameters
   //***************************************************************************
   localparam C1_BL_WIDTH              = 8;
   localparam C1_PORT_MODE             = "BI_MODE";
   localparam C1_DATA_MODE             = 4'b0010;
   localparam C1_EYE_TEST              = "FALSE";
                                     // set EYE_TEST = "TRUE" to probe memory
                                     // signals. Traffic Generator will only
                                     // write to one single location and no
                                     // read transactions will be generated.
   localparam C1_DATA_PATTERN          = "DGEN_ALL";
                                      // "DGEN_HAMMER"; "DGEN_WALKING1",
                                      // "DGEN_WALKING0","DGEN_ADDR","
                                      // "DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"
   localparam C1_CMD_PATTERN           = "CGEN_ALL";
                                      // "CGEN_PRBS","CGEN_FIXED","CGEN_BRAM",
                                      // "CGEN_SEQUENTIAL", "CGEN_ALL"
   localparam C1_BEGIN_ADDRESS         = 32'h00000000;
   localparam C1_END_ADDRESS           = 32'h00000fff;
   localparam C1_PRBS_EADDR_MASK_POS   = 32'hfffff000;

   //***************************************************************************
   // Wait period for the read strobe (CQ) to become stable
   //***************************************************************************
   localparam C1_CLK_STABLE            = (20*1000*1000/(C1_CLK_PERIOD*2));
                                     // Cycles till CQ/CQ# is stable

   //***************************************************************************
   // Debug parameter
   //***************************************************************************
   localparam C1_DEBUG_PORT            = "OFF";
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.
      

  //**************************************************************************//
  // Local parameters Declarations
  //**************************************************************************//

  // Memory Component parameters
   localparam C0_MEMORY_WIDTH          = C0_DATA_WIDTH/C0_NUM_DEVICES;
   localparam C0_BW_COMP               = C0_BW_WIDTH/C0_NUM_DEVICES;

  //============================================================================
  //                        Delay Specific Parameters
  //============================================================================
   localparam C0_TPROP_PCB_CTRL        = 0.00;             //Board delay value
   localparam C0_TPROP_PCB_CQ          = 0.00;             //CQ delay
   localparam C0_TPROP_PCB_DATA        = 0.00;             //DQ delay value
   localparam C0_TPROP_PCB_DATA_RD     = 0.00;             //READ DQ delay value


  localparam real REFCLK_PERIOD = (1000000.0/(2*REFCLK_FREQ));
  localparam RESET_PERIOD = 200000; //in pSec  
    
  // Memory Component parameters
   localparam C1_MEMORY_WIDTH          = C1_DATA_WIDTH/C1_NUM_DEVICES;
   localparam C1_BW_COMP               = C1_BW_WIDTH/C1_NUM_DEVICES;

  //============================================================================
  //                        Delay Specific Parameters
  //============================================================================
   localparam C1_TPROP_PCB_CTRL        = 0.00;             //Board delay value
   localparam C1_TPROP_PCB_CQ          = 0.00;             //CQ delay
   localparam C1_TPROP_PCB_DATA        = 0.00;             //DQ delay value
   localparam C1_TPROP_PCB_DATA_RD     = 0.00;             //READ DQ delay value


    

  //**************************************************************************//
  // Wire Declarations
  //**************************************************************************//
  reg                                sys_rst_n;
  wire                               sys_rst;



   reg                      c0_sys_clk;


   wire                     c0_sys_clk_p;
   wire                     c0_sys_clk_n;


   reg                      clk_ref;


   wire                     clk_ref_p;
   wire                     clk_ref_n;


   reg                     c0_qdriip_w_n_delay;
   reg                     c0_qdriip_r_n_delay;
   reg                     c0_qdriip_dll_off_n_delay;
   reg [C0_NUM_DEVICES-1:0]   c0_qdriip_k_p_delay;
   reg [C0_NUM_DEVICES-1:0]   c0_qdriip_k_n_delay;
   reg [C0_ADDR_WIDTH-1:0]    c0_qdriip_sa_delay;
   reg [C0_BW_WIDTH-1:0]      c0_qdriip_bw_n_delay;
   reg [C0_DATA_WIDTH-1:0]    c0_qdriip_d_delay;
   reg [C0_DATA_WIDTH-1:0]    c0_qdriip_q_delay;
   reg [C0_NUM_DEVICES-1:0]   c0_qdriip_qvld_delay;
   reg [C0_NUM_DEVICES-1:0]   c0_qdriip_cq_p_delay;
   reg [C0_NUM_DEVICES-1:0]   c0_qdriip_cq_n_delay;


  wire                               init_calib_complete;
  wire                               tg_compare_error;

   wire                     c0_qdriip_w_n;
   wire                     c0_qdriip_r_n;
   wire                     c0_qdriip_dll_off_n;
   wire [C0_NUM_DEVICES-1:0]   c0_qdriip_k_p;
   wire [C0_NUM_DEVICES-1:0]   c0_qdriip_k_n;
   wire [C0_ADDR_WIDTH-1:0]    c0_qdriip_sa;
   wire [C0_BW_WIDTH-1:0]      c0_qdriip_bw_n;
   wire [C0_DATA_WIDTH-1:0]    c0_qdriip_d;
   wire [C0_DATA_WIDTH-1:0]    c0_qdriip_q;
   wire [C0_NUM_DEVICES-1:0]   c0_qdriip_qvld;
   wire [C0_NUM_DEVICES-1:0]   c0_qdriip_cq_p;
   wire [C0_NUM_DEVICES-1:0]   c0_qdriip_cq_n;



   reg                      c1_sys_clk;


   wire                     c1_sys_clk_p;
   wire                     c1_sys_clk_n;




   reg                     c1_qdriip_w_n_delay;
   reg                     c1_qdriip_r_n_delay;
   reg                     c1_qdriip_dll_off_n_delay;
   reg [C1_NUM_DEVICES-1:0]   c1_qdriip_k_p_delay;
   reg [C1_NUM_DEVICES-1:0]   c1_qdriip_k_n_delay;
   reg [C1_ADDR_WIDTH-1:0]    c1_qdriip_sa_delay;
   reg [C1_BW_WIDTH-1:0]      c1_qdriip_bw_n_delay;
   reg [C1_DATA_WIDTH-1:0]    c1_qdriip_d_delay;
   reg [C1_DATA_WIDTH-1:0]    c1_qdriip_q_delay;
   reg [C1_NUM_DEVICES-1:0]   c1_qdriip_qvld_delay;
   reg [C1_NUM_DEVICES-1:0]   c1_qdriip_cq_p_delay;
   reg [C1_NUM_DEVICES-1:0]   c1_qdriip_cq_n_delay;



   wire                     c1_qdriip_w_n;
   wire                     c1_qdriip_r_n;
   wire                     c1_qdriip_dll_off_n;
   wire [C1_NUM_DEVICES-1:0]   c1_qdriip_k_p;
   wire [C1_NUM_DEVICES-1:0]   c1_qdriip_k_n;
   wire [C1_ADDR_WIDTH-1:0]    c1_qdriip_sa;
   wire [C1_BW_WIDTH-1:0]      c1_qdriip_bw_n;
   wire [C1_DATA_WIDTH-1:0]    c1_qdriip_d;
   wire [C1_DATA_WIDTH-1:0]    c1_qdriip_q;
   wire [C1_NUM_DEVICES-1:0]   c1_qdriip_qvld;
   wire [C1_NUM_DEVICES-1:0]   c1_qdriip_cq_p;
   wire [C1_NUM_DEVICES-1:0]   c1_qdriip_cq_n;



//**************************************************************************//

  //**************************************************************************//
  // Reset Generation
  //**************************************************************************//
  initial begin
    sys_rst_n = 1'b0;
    #RESET_PERIOD
      sys_rst_n = 1'b1;
   end

   assign sys_rst = RST_ACT_LOW ? sys_rst_n : ~sys_rst_n;

  //**************************************************************************//
  // Clock Generation
  //**************************************************************************//


   initial
     c0_sys_clk    = 1'b0;
   // Generate design clock
   always #(C0_CLKIN_PERIOD/2.0) c0_sys_clk = ~c0_sys_clk;



   assign c0_sys_clk_p = c0_sys_clk;
   assign c0_sys_clk_n = ~c0_sys_clk;


   initial
     clk_ref     = 1'b0;
   // Generate 200 MHz reference clock
   always #(REFCLK_PERIOD) clk_ref = ~clk_ref;



   assign clk_ref_p = clk_ref;
   assign clk_ref_n = ~clk_ref;



   initial
     c1_sys_clk    = 1'b0;
   // Generate design clock
   always #(C1_CLKIN_PERIOD/2.0) c1_sys_clk = ~c1_sys_clk;



   assign c1_sys_clk_p = c1_sys_clk;
   assign c1_sys_clk_n = ~c1_sys_clk;





 

 //===========================================================================
  //                            BOARD Parameters
  //===========================================================================
  //These parameter values can be changed to model varying board delays
  //between the Virtex-6 device and the QDR II memory model
  // always @(qdriip_k_p or qdriip_k_n or qdriip_sa or qdriip_bw_n or qdriip_w_n or
  //          qdriip_d or qdriip_r_n or qdriip_q or qdriip_qvld or qdriip_cq_p or
  //          qdriip_cq_n or qdriip_dll_off_n)

   always @*
   begin
     c0_qdriip_k_p_delay       <= #C0_TPROP_PCB_CTRL    c0_qdriip_k_p;
     c0_qdriip_k_n_delay       <= #C0_TPROP_PCB_CTRL    c0_qdriip_k_n;
     c0_qdriip_sa_delay        <= #C0_TPROP_PCB_CTRL    c0_qdriip_sa;
     c0_qdriip_bw_n_delay      <= #C0_TPROP_PCB_CTRL    c0_qdriip_bw_n;
     c0_qdriip_w_n_delay       <= #C0_TPROP_PCB_CTRL    c0_qdriip_w_n;
     c0_qdriip_d_delay         <= #C0_TPROP_PCB_DATA    c0_qdriip_d;
     c0_qdriip_r_n_delay       <= #C0_TPROP_PCB_CTRL    c0_qdriip_r_n;
     c0_qdriip_q_delay         <= #C0_TPROP_PCB_DATA_RD c0_qdriip_q;
     c0_qdriip_qvld_delay      <= #C0_TPROP_PCB_DATA_RD c0_qdriip_qvld;
     c0_qdriip_cq_p_delay      <= #C0_TPROP_PCB_CQ      c0_qdriip_cq_p;
     c0_qdriip_cq_n_delay      <= #C0_TPROP_PCB_CQ      c0_qdriip_cq_n;
     c0_qdriip_dll_off_n_delay <= #C0_TPROP_PCB_CTRL    c0_qdriip_dll_off_n;
   end




 //===========================================================================
  //                            BOARD Parameters
  //===========================================================================
  //These parameter values can be changed to model varying board delays
  //between the Virtex-6 device and the QDR II memory model
  // always @(qdriip_k_p or qdriip_k_n or qdriip_sa or qdriip_bw_n or qdriip_w_n or
  //          qdriip_d or qdriip_r_n or qdriip_q or qdriip_qvld or qdriip_cq_p or
  //          qdriip_cq_n or qdriip_dll_off_n)

   always @*
   begin
     c1_qdriip_k_p_delay       <= #C1_TPROP_PCB_CTRL    c1_qdriip_k_p;
     c1_qdriip_k_n_delay       <= #C1_TPROP_PCB_CTRL    c1_qdriip_k_n;
     c1_qdriip_sa_delay        <= #C1_TPROP_PCB_CTRL    c1_qdriip_sa;
     c1_qdriip_bw_n_delay      <= #C1_TPROP_PCB_CTRL    c1_qdriip_bw_n;
     c1_qdriip_w_n_delay       <= #C1_TPROP_PCB_CTRL    c1_qdriip_w_n;
     c1_qdriip_d_delay         <= #C1_TPROP_PCB_DATA    c1_qdriip_d;
     c1_qdriip_r_n_delay       <= #C1_TPROP_PCB_CTRL    c1_qdriip_r_n;
     c1_qdriip_q_delay         <= #C1_TPROP_PCB_DATA_RD c1_qdriip_q;
     c1_qdriip_qvld_delay      <= #C1_TPROP_PCB_DATA_RD c1_qdriip_qvld;
     c1_qdriip_cq_p_delay      <= #C1_TPROP_PCB_CQ      c1_qdriip_cq_p;
     c1_qdriip_cq_n_delay      <= #C1_TPROP_PCB_CQ      c1_qdriip_cq_n;
     c1_qdriip_dll_off_n_delay <= #C1_TPROP_PCB_CTRL    c1_qdriip_dll_off_n;
   end




  //===========================================================================
  //                         FPGA Memory Controller
  //===========================================================================

  qdr_test #(

   .C0_MEM_TYPE                (C0_MEM_TYPE),
   .C0_DATA_WIDTH              (C0_DATA_WIDTH),
   .C0_BW_WIDTH                (C0_BW_WIDTH),
   .C0_ADDR_WIDTH              (C0_ADDR_WIDTH),
   .C0_NUM_DEVICES             (C0_NUM_DEVICES),
   .C0_MEM_RD_LATENCY          (C0_MEM_RD_LATENCY),
   .C0_CPT_CLK_CQ_ONLY         (C0_CPT_CLK_CQ_ONLY),
   .C0_INTER_BANK_SKEW         (C0_INTER_BANK_SKEW),
   .C0_PHY_CONTROL_MASTER_BANK (C0_PHY_CONTROL_MASTER_BANK),

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   .C0_BURST_LEN               (C0_BURST_LEN),
   .C0_FIXED_LATENCY_MODE      (C0_FIXED_LATENCY_MODE),
   .C0_PHY_LATENCY             (C0_PHY_LATENCY),
   .C0_CLK_STABLE              (C0_CLK_STABLE),
   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for MMCM.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   .C0_CLKIN_PERIOD                  (C0_CLKIN_PERIOD),
   .C0_CLKFBOUT_MULT                 (C0_CLKFBOUT_MULT),
   .C0_DIVCLK_DIVIDE                 (C0_DIVCLK_DIVIDE),
   .C0_CLKOUT0_DIVIDE                (C0_CLKOUT0_DIVIDE),
   .C0_CLKOUT1_DIVIDE                (C0_CLKOUT1_DIVIDE),
   .C0_CLKOUT2_DIVIDE                (C0_CLKOUT2_DIVIDE),
   .C0_CLKOUT3_DIVIDE                (C0_CLKOUT3_DIVIDE),

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   .C0_SIM_BYPASS_INIT_CAL     (C0_SIM_BYPASS_INIT_CAL),
   .C0_SIMULATION              (C0_SIMULATION),

   //***************************************************************************
   // The following parameters varies based on the pin out entered in MIG GUI.
   // Do not change any of these parameters directly by editing the RTL.
   // Any changes required should be done through GUI and the design regenerated.
   //***************************************************************************
   .C0_BYTE_LANES_B0           (C0_BYTE_LANES_B0),
   .C0_BYTE_LANES_B1           (C0_BYTE_LANES_B1),
   .C0_BYTE_LANES_B2           (C0_BYTE_LANES_B2),
   .C0_BYTE_LANES_B3           (C0_BYTE_LANES_B3),
   .C0_BYTE_LANES_B4           (C0_BYTE_LANES_B4),
   .C0_DATA_CTL_B0             (C0_DATA_CTL_B0),
   .C0_DATA_CTL_B1             (C0_DATA_CTL_B1),
   .C0_DATA_CTL_B2             (C0_DATA_CTL_B2),
   .C0_DATA_CTL_B3             (C0_DATA_CTL_B3),
   .C0_DATA_CTL_B4             (C0_DATA_CTL_B4),
   .C0_PHY_0_BITLANES         (C0_PHY_0_BITLANES),
   .C0_PHY_1_BITLANES         (C0_PHY_1_BITLANES),
   .C0_PHY_2_BITLANES         (C0_PHY_2_BITLANES),
   .C0_PHY_3_BITLANES         (C0_PHY_3_BITLANES),
   .C0_PHY_4_BITLANES         (C0_PHY_4_BITLANES),

   .C0_CPT_CLK_SEL_B0         (C0_CPT_CLK_SEL_B0),       //Capture clock placement parameters
   .C0_CPT_CLK_SEL_B1         (C0_CPT_CLK_SEL_B1),
   .C0_CPT_CLK_SEL_B2         (C0_CPT_CLK_SEL_B2),

   .C0_BYTE_GROUP_TYPE_B0     (C0_BYTE_GROUP_TYPE_B0),   //Differentiates data write and read byte lanes
   .C0_BYTE_GROUP_TYPE_B1     (C0_BYTE_GROUP_TYPE_B1),
   .C0_BYTE_GROUP_TYPE_B2     (C0_BYTE_GROUP_TYPE_B2),
   .C0_BYTE_GROUP_TYPE_B3     (C0_BYTE_GROUP_TYPE_B3),
   .C0_BYTE_GROUP_TYPE_B4     (C0_BYTE_GROUP_TYPE_B4),

   .C0_K_MAP    (C0_K_MAP),
   .C0_CQ_MAP   (C0_CQ_MAP),
   .C0_RD_MAP   (C0_RD_MAP),     // Mapping for read enable signal
   .C0_WR_MAP   (C0_WR_MAP),     // Mapping for write enable signal
   .C0_ADD_MAP  (C0_ADD_MAP),
   .C0_ADDR_CTL_MAP   (C0_ADDR_CTL_MAP),

   .C0_D0_MAP    (C0_D0_MAP), //byte 0
   .C0_D1_MAP    (C0_D1_MAP), //byte 1
   .C0_D2_MAP    (C0_D2_MAP), //byte 2
   .C0_D3_MAP    (C0_D3_MAP), //byte 3
   .C0_D4_MAP    (C0_D4_MAP), //byte 4
   .C0_D5_MAP    (C0_D5_MAP), //byte 5
   .C0_D6_MAP    (C0_D6_MAP), //byte 6
   .C0_D7_MAP    (C0_D7_MAP), //byte 7
   .C0_BW_MAP    (C0_BW_MAP),

   .C0_Q0_MAP    (C0_Q0_MAP), //byte 0
   .C0_Q1_MAP    (C0_Q1_MAP), //byte 1
   .C0_Q2_MAP    (C0_Q2_MAP), //byte 2
   .C0_Q3_MAP    (C0_Q3_MAP), //byte 3
   .C0_Q4_MAP    (C0_Q4_MAP), //byte 4
   .C0_Q5_MAP    (C0_Q5_MAP), //byte 5
   .C0_Q6_MAP    (C0_Q6_MAP), //byte 6
   .C0_Q7_MAP    (C0_Q7_MAP), //byte 7

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   .C0_IODELAY_HP_MODE         (C0_IODELAY_HP_MODE),
   .C0_IBUF_LPWR_MODE          (C0_IBUF_LPWR_MODE),
   .C0_TCQ                     (C0_TCQ),
   .IODELAY_GRP                   (IODELAY_GRP),
   .SYSCLK_TYPE                   (SYSCLK_TYPE),
   .REFCLK_TYPE                   (REFCLK_TYPE),
   .DEVICE_TAPS                   (DEVICE_TAPS),

   
   //***************************************************************************
   // Referece clock frequency parameters
   //***************************************************************************
   .REFCLK_FREQ                   (REFCLK_FREQ),
   .DIFF_TERM_REFCLK              (DIFF_TERM_REFCLK),
      
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   .C0_CLK_PERIOD                    (C0_CLK_PERIOD),
   .C0_nCK_PER_CLK                   (C0_nCK_PER_CLK),
   .C0_DIFF_TERM_SYSCLK              (C0_DIFF_TERM_SYSCLK),
      
      

   .C0_BL_WIDTH                (C0_BL_WIDTH),
   .C0_PORT_MODE               (C0_PORT_MODE),
   .C0_DATA_MODE               (C0_DATA_MODE),
   .C0_EYE_TEST                (C0_EYE_TEST),
   .C0_DATA_PATTERN            (C0_DATA_PATTERN),
   .C0_CMD_PATTERN             (C0_CMD_PATTERN),
   .C0_BEGIN_ADDRESS           (C0_BEGIN_ADDRESS),
   .C0_END_ADDRESS             (C0_END_ADDRESS),
   .C0_PRBS_EADDR_MASK_POS     (C0_PRBS_EADDR_MASK_POS),

   //***************************************************************************
   // Debug parameters
   //***************************************************************************
   .C0_DEBUG_PORT              (C0_DEBUG_PORT),
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.
      
   .C1_MEM_TYPE                (C1_MEM_TYPE),
   .C1_DATA_WIDTH              (C1_DATA_WIDTH),
   .C1_BW_WIDTH                (C1_BW_WIDTH),
   .C1_ADDR_WIDTH              (C1_ADDR_WIDTH),
   .C1_NUM_DEVICES             (C1_NUM_DEVICES),
   .C1_MEM_RD_LATENCY          (C1_MEM_RD_LATENCY),
   .C1_CPT_CLK_CQ_ONLY         (C1_CPT_CLK_CQ_ONLY),
   .C1_INTER_BANK_SKEW         (C1_INTER_BANK_SKEW),
   .C1_PHY_CONTROL_MASTER_BANK (C1_PHY_CONTROL_MASTER_BANK),

   //***************************************************************************
   // The following parameters are mode register settings
   //***************************************************************************
   .C1_BURST_LEN               (C1_BURST_LEN),
   .C1_FIXED_LATENCY_MODE      (C1_FIXED_LATENCY_MODE),
   .C1_PHY_LATENCY             (C1_PHY_LATENCY),
   .C1_CLK_STABLE              (C1_CLK_STABLE),
   
   //***************************************************************************
   // The following parameters are multiplier and divisor factors for MMCM.
   // Based on the selected design frequency these parameters vary.
   //***************************************************************************
   .C1_CLKIN_PERIOD                  (C1_CLKIN_PERIOD),
   .C1_CLKFBOUT_MULT                 (C1_CLKFBOUT_MULT),
   .C1_DIVCLK_DIVIDE                 (C1_DIVCLK_DIVIDE),
   .C1_CLKOUT0_DIVIDE                (C1_CLKOUT0_DIVIDE),
   .C1_CLKOUT1_DIVIDE                (C1_CLKOUT1_DIVIDE),
   .C1_CLKOUT2_DIVIDE                (C1_CLKOUT2_DIVIDE),
   .C1_CLKOUT3_DIVIDE                (C1_CLKOUT3_DIVIDE),

   //***************************************************************************
   // Simulation parameters
   //***************************************************************************
   .C1_SIM_BYPASS_INIT_CAL     (C1_SIM_BYPASS_INIT_CAL),
   .C1_SIMULATION              (C1_SIMULATION),

   //***************************************************************************
   // The following parameters varies based on the pin out entered in MIG GUI.
   // Do not change any of these parameters directly by editing the RTL.
   // Any changes required should be done through GUI and the design regenerated.
   //***************************************************************************
   .C1_BYTE_LANES_B0           (C1_BYTE_LANES_B0),
   .C1_BYTE_LANES_B1           (C1_BYTE_LANES_B1),
   .C1_BYTE_LANES_B2           (C1_BYTE_LANES_B2),
   .C1_BYTE_LANES_B3           (C1_BYTE_LANES_B3),
   .C1_BYTE_LANES_B4           (C1_BYTE_LANES_B4),
   .C1_DATA_CTL_B0             (C1_DATA_CTL_B0),
   .C1_DATA_CTL_B1             (C1_DATA_CTL_B1),
   .C1_DATA_CTL_B2             (C1_DATA_CTL_B2),
   .C1_DATA_CTL_B3             (C1_DATA_CTL_B3),
   .C1_DATA_CTL_B4             (C1_DATA_CTL_B4),
   .C1_PHY_0_BITLANES         (C1_PHY_0_BITLANES),
   .C1_PHY_1_BITLANES         (C1_PHY_1_BITLANES),
   .C1_PHY_2_BITLANES         (C1_PHY_2_BITLANES),
   .C1_PHY_3_BITLANES         (C1_PHY_3_BITLANES),
   .C1_PHY_4_BITLANES         (C1_PHY_4_BITLANES),

   .C1_CPT_CLK_SEL_B0         (C1_CPT_CLK_SEL_B0),       //Capture clock placement parameters
   .C1_CPT_CLK_SEL_B1         (C1_CPT_CLK_SEL_B1),
   .C1_CPT_CLK_SEL_B2         (C1_CPT_CLK_SEL_B2),

   .C1_BYTE_GROUP_TYPE_B0     (C1_BYTE_GROUP_TYPE_B0),   //Differentiates data write and read byte lanes
   .C1_BYTE_GROUP_TYPE_B1     (C1_BYTE_GROUP_TYPE_B1),
   .C1_BYTE_GROUP_TYPE_B2     (C1_BYTE_GROUP_TYPE_B2),
   .C1_BYTE_GROUP_TYPE_B3     (C1_BYTE_GROUP_TYPE_B3),
   .C1_BYTE_GROUP_TYPE_B4     (C1_BYTE_GROUP_TYPE_B4),

   .C1_K_MAP    (C1_K_MAP),
   .C1_CQ_MAP   (C1_CQ_MAP),
   .C1_RD_MAP   (C1_RD_MAP),     // Mapping for read enable signal
   .C1_WR_MAP   (C1_WR_MAP),     // Mapping for write enable signal
   .C1_ADD_MAP  (C1_ADD_MAP),
   .C1_ADDR_CTL_MAP   (C1_ADDR_CTL_MAP),

   .C1_D0_MAP    (C1_D0_MAP), //byte 0
   .C1_D1_MAP    (C1_D1_MAP), //byte 1
   .C1_D2_MAP    (C1_D2_MAP), //byte 2
   .C1_D3_MAP    (C1_D3_MAP), //byte 3
   .C1_D4_MAP    (C1_D4_MAP), //byte 4
   .C1_D5_MAP    (C1_D5_MAP), //byte 5
   .C1_D6_MAP    (C1_D6_MAP), //byte 6
   .C1_D7_MAP    (C1_D7_MAP), //byte 7
   .C1_BW_MAP    (C1_BW_MAP),

   .C1_Q0_MAP    (C1_Q0_MAP), //byte 0
   .C1_Q1_MAP    (C1_Q1_MAP), //byte 1
   .C1_Q2_MAP    (C1_Q2_MAP), //byte 2
   .C1_Q3_MAP    (C1_Q3_MAP), //byte 3
   .C1_Q4_MAP    (C1_Q4_MAP), //byte 4
   .C1_Q5_MAP    (C1_Q5_MAP), //byte 5
   .C1_Q6_MAP    (C1_Q6_MAP), //byte 6
   .C1_Q7_MAP    (C1_Q7_MAP), //byte 7

   //***************************************************************************
   // IODELAY and PHY related parameters
   //***************************************************************************
   .C1_IODELAY_HP_MODE         (C1_IODELAY_HP_MODE),
   .C1_IBUF_LPWR_MODE          (C1_IBUF_LPWR_MODE),
   .C1_TCQ                     (C1_TCQ),
   

   
   //***************************************************************************
   // System clock frequency parameters
   //***************************************************************************
   .C1_CLK_PERIOD                    (C1_CLK_PERIOD),
   .C1_nCK_PER_CLK                   (C1_nCK_PER_CLK),
   .C1_DIFF_TERM_SYSCLK              (C1_DIFF_TERM_SYSCLK),
      
      

   .C1_BL_WIDTH                (C1_BL_WIDTH),
   .C1_PORT_MODE               (C1_PORT_MODE),
   .C1_DATA_MODE               (C1_DATA_MODE),
   .C1_EYE_TEST                (C1_EYE_TEST),
   .C1_DATA_PATTERN            (C1_DATA_PATTERN),
   .C1_CMD_PATTERN             (C1_CMD_PATTERN),
   .C1_BEGIN_ADDRESS           (C1_BEGIN_ADDRESS),
   .C1_END_ADDRESS             (C1_END_ADDRESS),
   .C1_PRBS_EADDR_MASK_POS     (C1_PRBS_EADDR_MASK_POS),

   //***************************************************************************
   // Debug parameters
   //***************************************************************************
   .C1_DEBUG_PORT              (C1_DEBUG_PORT),
                                     // # = "ON" Enable debug signals/controls.
                                     //   = "OFF" Disable debug signals/controls.
      
      .RST_ACT_LOW               (RST_ACT_LOW)
   ) u_ip_top (


    .c0_sys_clk_p          (c0_sys_clk_p),
    .c0_sys_clk_n          (c0_sys_clk_n),


    .clk_ref_p          (clk_ref_p),
    .clk_ref_n          (clk_ref_n),


    .c0_qdriip_dll_off_n      (c0_qdriip_dll_off_n),
    .c0_qdriip_cq_p           (c0_qdriip_cq_p),
    .c0_qdriip_cq_n           (c0_qdriip_cq_n),
    .c0_qdriip_qvld           (c0_qdriip_qvld),
    .c0_qdriip_q              (c0_qdriip_q),
    .c0_qdriip_k_p            (c0_qdriip_k_p),
    .c0_qdriip_k_n            (c0_qdriip_k_n),
    .c0_qdriip_d              (c0_qdriip_d),
    .c0_qdriip_sa             (c0_qdriip_sa),
    .c0_qdriip_w_n            (c0_qdriip_w_n),
    .c0_qdriip_r_n            (c0_qdriip_r_n),
    .c0_qdriip_bw_n           (c0_qdriip_bw_n),



    .c1_sys_clk_p          (c1_sys_clk_p),
    .c1_sys_clk_n          (c1_sys_clk_n),



    .c1_qdriip_dll_off_n      (c1_qdriip_dll_off_n),
    .c1_qdriip_cq_p           (c1_qdriip_cq_p),
    .c1_qdriip_cq_n           (c1_qdriip_cq_n),
    .c1_qdriip_qvld           (c1_qdriip_qvld),
    .c1_qdriip_q              (c1_qdriip_q),
    .c1_qdriip_k_p            (c1_qdriip_k_p),
    .c1_qdriip_k_n            (c1_qdriip_k_n),
    .c1_qdriip_d              (c1_qdriip_d),
    .c1_qdriip_sa             (c1_qdriip_sa),
    .c1_qdriip_w_n            (c1_qdriip_w_n),
    .c1_qdriip_r_n            (c1_qdriip_r_n),
    .c1_qdriip_bw_n           (c1_qdriip_bw_n),


      .init_calib_complete (init_calib_complete),
      .tg_compare_error    (tg_compare_error),
      .sys_rst             (sys_rst)
     );

  //**************************************************************************//
  // Memory Models instantiations
  //**************************************************************************//

  // MIG does not output Cypress memory models. You have to instantiate the
  // appropriate Cypress memory model for the cypress controller designs
  // generated from MIG. Memory model instance name must be modified as per
  // the model downloaded from the memory vendor website
  genvar c0_i;
  generate
    for(c0_i=0; c0_i<C0_NUM_DEVICES; c0_i=c0_i+1)begin : C0_COMP_INST
      cyqdr2_b4 c0_cyqdr2_b4
        (
         .TCK   ( 1'b0 ),
         .TMS   ( 1'b1 ),
         .TDI   ( 1'b1 ),
         .TDO   (),
         .D     ( c0_qdriip_d_delay[(C0_MEMORY_WIDTH*c0_i)+:C0_MEMORY_WIDTH] ),
         .Q     ( c0_qdriip_q [(C0_MEMORY_WIDTH*c0_i)+:C0_MEMORY_WIDTH]),
         .A     ( c0_qdriip_sa_delay ),
         .K     ( c0_qdriip_k_p_delay[c0_i] ),
         .Kb    ( c0_qdriip_k_n_delay[c0_i] ),
         .RPSb  ( c0_qdriip_r_n_delay ),
         .WPSb  ( c0_qdriip_w_n_delay ),
         .BWS0b ( c0_qdriip_bw_n_delay[(c0_i*C0_BW_COMP)] ),
         .BWS1b ( c0_qdriip_bw_n_delay[(c0_i*C0_BW_COMP)+1] ),
         .CQ    ( c0_qdriip_cq_p[c0_i] ),
         .CQb   ( c0_qdriip_cq_n[c0_i] ),
         .ZQ    ( 1'b1 ),
         .DOFF  ( c0_qdriip_dll_off_n_delay ),
         .QVLD  ( c0_qdriip_qvld[c0_i] ),
         .ODT   ( 1'b1 )
         );
    end
  endgenerate
  // MIG does not output Cypress memory models. You have to instantiate the
  // appropriate Cypress memory model for the cypress controller designs
  // generated from MIG. Memory model instance name must be modified as per
  // the model downloaded from the memory vendor website
  genvar c1_i;
  generate
    for(c1_i=0; c1_i<C1_NUM_DEVICES; c1_i=c1_i+1)begin : C1_COMP_INST
      cyqdr2_b4 c1_cyqdr2_b4
        (
         .TCK   ( 1'b0 ),
         .TMS   ( 1'b1 ),
         .TDI   ( 1'b1 ),
         .TDO   (),
         .D     ( c1_qdriip_d_delay[(C1_MEMORY_WIDTH*c1_i)+:C1_MEMORY_WIDTH] ),
         .Q     ( c1_qdriip_q [(C1_MEMORY_WIDTH*c1_i)+:C1_MEMORY_WIDTH]),
         .A     ( c1_qdriip_sa_delay ),
         .K     ( c1_qdriip_k_p_delay[c1_i] ),
         .Kb    ( c1_qdriip_k_n_delay[c1_i] ),
         .RPSb  ( c1_qdriip_r_n_delay ),
         .WPSb  ( c1_qdriip_w_n_delay ),
         .BWS0b ( c1_qdriip_bw_n_delay[(c1_i*C1_BW_COMP)] ),
         .BWS1b ( c1_qdriip_bw_n_delay[(c1_i*C1_BW_COMP)+1] ),
         .CQ    ( c1_qdriip_cq_p[c1_i] ),
         .CQb   ( c1_qdriip_cq_n[c1_i] ),
         .ZQ    ( 1'b1 ),
         .DOFF  ( c1_qdriip_dll_off_n_delay ),
         .QVLD  ( c1_qdriip_qvld[c1_i] ),
         .ODT   ( 1'b1 )
         );
    end
  endgenerate


  //***************************************************************************
  // Reporting the test case status
  // Status reporting logic exists both in simulation test bench (sim_tb_top)
  // and sim.do file for ModelSim. Any update in simulation run time or time out
  // in this file need to be updated in sim.do file as well.
  //***************************************************************************
  initial
  begin : Logging
     fork
        begin : calibration_done
           wait (init_calib_complete);
           $display("Calibration Done");
           #50000000.0;
           if (!tg_compare_error) begin
              $display("TEST PASSED");
           end
           else begin
              $display("TEST FAILED: DATA ERROR");
           end
           disable calib_not_done;
            $finish;
        end

        begin : calib_not_done
           if (C0_SIM_BYPASS_INIT_CAL == "OFF")
             #2500000000.0;
           else
             #700000000.0;
           if (!init_calib_complete) begin
              $display("TEST FAILED: INITIALIZATION DID NOT COMPLETE");
           end
           disable calibration_done;
            $finish;
        end
     join
  end
    

endmodule
