###############################################################################
##
## (c) Copyright 2010-2012 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
## 
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.

  window new WaveWindow  -name  "Waves for 7 Series FPGAs Transceivers Wizard Example Design"
  waveform  using  "Waves for 7 Series FPGAs Transceivers Wizard Example Design"
   waveform  add  -label FRAME_CHECK_MODULE -comment gt0_frame_check
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt0_frame_check.begin_r
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt0_frame_check.track_data_r
  waveform  add  -siganls  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt0_frame_check.data_error_detected_r
  wavefrom  add  -siganls  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt0_frame_check.start_of_packet_detected_r
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt0_frame_check.RX_DATA
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt0_frame_check.ERROR_COUNT
  waveform  add  -label FRAME_CHECK_MODULE -comment gt1_frame_check
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt1_frame_check.begin_r
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt1_frame_check.track_data_r
  waveform  add  -siganls  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt1_frame_check.data_error_detected_r
  wavefrom  add  -siganls  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt1_frame_check.start_of_packet_detected_r
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt1_frame_check.RX_DATA
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt1_frame_check.ERROR_COUNT
  waveform  add  -label FRAME_CHECK_MODULE -comment gt2_frame_check
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt2_frame_check.begin_r
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt2_frame_check.track_data_r
  waveform  add  -siganls  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt2_frame_check.data_error_detected_r
  wavefrom  add  -siganls  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt2_frame_check.start_of_packet_detected_r
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt2_frame_check.RX_DATA
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt2_frame_check.ERROR_COUNT
  waveform  add  -label FRAME_CHECK_MODULE -comment gt3_frame_check
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt3_frame_check.begin_r
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt3_frame_check.track_data_r
  waveform  add  -siganls  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt3_frame_check.data_error_detected_r
  wavefrom  add  -siganls  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt3_frame_check.start_of_packet_detected_r
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt3_frame_check.RX_DATA
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.gt3_frame_check.ERROR_COUNT
  waveform  add  -label GT0_xilinx_gth_16b_5g_cpll -comment GT0_xilinx_gth_16b_5g_cpll
  waveform  add  -label CPLL_Ports  -comment  CPLL_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.CPLLFBCLKLOST_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.CPLLLOCK_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.CPLLLOCKDETCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.CPLLREFCLKLOST_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.CPLLRESET_IN
  waveform  add  -label Channel_-_Clocking_Ports  -comment  Channel_-_Clocking_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.GTREFCLK0_IN
  waveform  add  -label Channel_-_DRP_Ports_  -comment  Channel_-_DRP_Ports_
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.DRPADDR_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.DRPCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.DRPDI_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.DRPDO_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.DRPEN_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.DRPRDY_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.DRPWE_IN
  waveform  add  -label Clocking_Ports  -comment  Clocking_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.QPLLCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.QPLLREFCLK_IN
  waveform  add  -label Loopback_Ports  -comment  Loopback_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.LOOPBACK_IN
  waveform  add  -label RX_Initialization_and_Reset_Ports  -comment  RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXUSERRDY_IN
  waveform  add  -label RX_Margin_Analysis_Ports  -comment  RX_Margin_Analysis_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.EYESCANDATAERROR_OUT
  waveform  add  -label Receive_Ports_-_CDR_Ports  -comment  Receive_Ports_-_CDR_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXCDRLOCK_OUT
  waveform  add  -label Receive_Ports_-_FPGA_RX_Interface_Ports  -comment  Receive_Ports_-_FPGA_RX_Interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXUSRCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXUSRCLK2_IN
  waveform  add  -label Receive_Ports_-_FPGA_RX_interface_Ports  -comment  Receive_Ports_-_FPGA_RX_interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXDATA_OUT
  waveform  add  -label Receive_Ports_-_Pattern_Checker_Ports  -comment  Receive_Ports_-_Pattern_Checker_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXPRBSERR_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXPRBSSEL_IN
  waveform  add  -label Receive_Ports_-_Pattern_Checker_ports  -comment  Receive_Ports_-_Pattern_Checker_ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXPRBSCNTRESET_IN
  waveform  add  -label Receive_Ports_-_RX_8B/10B_Decoder_Ports  -comment  Receive_Ports_-_RX_8B/10B_Decoder_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXDISPERR_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXNOTINTABLE_OUT
  waveform  add  -label Receive_Ports_-_RX_AFE_Ports  -comment  Receive_Ports_-_RX_AFE_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.GTHRXN_IN
  waveform  add  -label Receive_Ports_-_RX_Byte_and_Word_Alignment_Ports  -comment  Receive_Ports_-_RX_Byte_and_Word_Alignment_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXBYTEISALIGNED_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXCOMMADET_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXMCOMMAALIGNEN_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXPCOMMAALIGNEN_IN
  waveform  add  -label Receive_Ports_-_RX_Equailizer_Ports  -comment  Receive_Ports_-_RX_Equailizer_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXLPMHFHOLD_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXLPMLFHOLD_IN
  waveform  add  -label Receive_Ports_-_RX_Fabric_Output_Control_Ports  -comment  Receive_Ports_-_RX_Fabric_Output_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXOUTCLK_OUT
  waveform  add  -label Receive_Ports_-_RX_Initialization_and_Reset_Ports  -comment  Receive_Ports_-_RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.GTRXRESET_IN
  waveform  add  -label Receive_Ports_-_RX_Polarity_Control_Ports  -comment  Receive_Ports_-_RX_Polarity_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXPOLARITY_IN
  waveform  add  -label Receive_Ports_-_RX8B/10B_Decoder_Ports  -comment  Receive_Ports_-_RX8B/10B_Decoder_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXCHARISCOMMA_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXCHARISK_OUT
  waveform  add  -label Receive_Ports_-RX_AFE_Ports  -comment  Receive_Ports_-RX_AFE_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.GTHRXP_IN
  waveform  add  -label Receive_Ports_-RX_Initialization_and_Reset_Ports  -comment  Receive_Ports_-RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.RXRESETDONE_OUT
  waveform  add  -label TX_Initialization_and_Reset_Ports  -comment  TX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.GTTXRESET_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXUSERRDY_IN
  waveform  add  -label Transmit_Ports_-_FPGA_TX_Interface_Ports  -comment  Transmit_Ports_-_FPGA_TX_Interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXUSRCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXUSRCLK2_IN
  waveform  add  -label Transmit_Ports_-_TX_Data_Path_interface  -comment  Transmit_Ports_-_TX_Data_Path_interface
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXDATA_IN
  waveform  add  -label Transmit_Ports_-_TX_Driver_and_OOB_signaling  -comment  Transmit_Ports_-_TX_Driver_and_OOB_signaling
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.GTHTXN_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.GTHTXP_OUT
  waveform  add  -label Transmit_Ports_-_TX_Fabric_Clock_Output_Control_Ports  -comment  Transmit_Ports_-_TX_Fabric_Clock_Output_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXOUTCLK_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXOUTCLKFABRIC_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXOUTCLKPCS_OUT
  waveform  add  -label Transmit_Ports_-_TX_Initialization_and_Reset_Ports  -comment  Transmit_Ports_-_TX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXRESETDONE_OUT
  waveform  add  -label Transmit_Ports_-_TX_Polarity_Control_Ports  -comment  Transmit_Ports_-_TX_Polarity_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXPOLARITY_IN
  waveform  add  -label Transmit_Ports_-_pattern_Generator_Ports  -comment  Transmit_Ports_-_pattern_Generator_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXPRBSSEL_IN
  waveform  add  -label Transmit_Transmit_Ports_-_8b10b_Encoder_Control_Ports  -comment  Transmit_Transmit_Ports_-_8b10b_Encoder_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt0_xilinx_gth_16b_5g_cpll_i.TXCHARISK_IN

  waveform  add  -label GT1_xilinx_gth_16b_5g_cpll -comment GT1_xilinx_gth_16b_5g_cpll
  waveform  add  -label CPLL_Ports  -comment  CPLL_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.CPLLFBCLKLOST_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.CPLLLOCK_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.CPLLLOCKDETCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.CPLLREFCLKLOST_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.CPLLRESET_IN
  waveform  add  -label Channel_-_Clocking_Ports  -comment  Channel_-_Clocking_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.GTREFCLK0_IN
  waveform  add  -label Channel_-_DRP_Ports_  -comment  Channel_-_DRP_Ports_
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.DRPADDR_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.DRPCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.DRPDI_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.DRPDO_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.DRPEN_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.DRPRDY_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.DRPWE_IN
  waveform  add  -label Clocking_Ports  -comment  Clocking_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.QPLLCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.QPLLREFCLK_IN
  waveform  add  -label Loopback_Ports  -comment  Loopback_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.LOOPBACK_IN
  waveform  add  -label RX_Initialization_and_Reset_Ports  -comment  RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXUSERRDY_IN
  waveform  add  -label RX_Margin_Analysis_Ports  -comment  RX_Margin_Analysis_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.EYESCANDATAERROR_OUT
  waveform  add  -label Receive_Ports_-_CDR_Ports  -comment  Receive_Ports_-_CDR_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXCDRLOCK_OUT
  waveform  add  -label Receive_Ports_-_FPGA_RX_Interface_Ports  -comment  Receive_Ports_-_FPGA_RX_Interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXUSRCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXUSRCLK2_IN
  waveform  add  -label Receive_Ports_-_FPGA_RX_interface_Ports  -comment  Receive_Ports_-_FPGA_RX_interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXDATA_OUT
  waveform  add  -label Receive_Ports_-_Pattern_Checker_Ports  -comment  Receive_Ports_-_Pattern_Checker_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXPRBSERR_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXPRBSSEL_IN
  waveform  add  -label Receive_Ports_-_Pattern_Checker_ports  -comment  Receive_Ports_-_Pattern_Checker_ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXPRBSCNTRESET_IN
  waveform  add  -label Receive_Ports_-_RX_8B/10B_Decoder_Ports  -comment  Receive_Ports_-_RX_8B/10B_Decoder_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXDISPERR_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXNOTINTABLE_OUT
  waveform  add  -label Receive_Ports_-_RX_AFE_Ports  -comment  Receive_Ports_-_RX_AFE_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.GTHRXN_IN
  waveform  add  -label Receive_Ports_-_RX_Byte_and_Word_Alignment_Ports  -comment  Receive_Ports_-_RX_Byte_and_Word_Alignment_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXBYTEISALIGNED_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXCOMMADET_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXMCOMMAALIGNEN_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXPCOMMAALIGNEN_IN
  waveform  add  -label Receive_Ports_-_RX_Equailizer_Ports  -comment  Receive_Ports_-_RX_Equailizer_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXLPMHFHOLD_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXLPMLFHOLD_IN
  waveform  add  -label Receive_Ports_-_RX_Fabric_Output_Control_Ports  -comment  Receive_Ports_-_RX_Fabric_Output_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXOUTCLK_OUT
  waveform  add  -label Receive_Ports_-_RX_Initialization_and_Reset_Ports  -comment  Receive_Ports_-_RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.GTRXRESET_IN
  waveform  add  -label Receive_Ports_-_RX_Polarity_Control_Ports  -comment  Receive_Ports_-_RX_Polarity_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXPOLARITY_IN
  waveform  add  -label Receive_Ports_-_RX8B/10B_Decoder_Ports  -comment  Receive_Ports_-_RX8B/10B_Decoder_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXCHARISCOMMA_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXCHARISK_OUT
  waveform  add  -label Receive_Ports_-RX_AFE_Ports  -comment  Receive_Ports_-RX_AFE_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.GTHRXP_IN
  waveform  add  -label Receive_Ports_-RX_Initialization_and_Reset_Ports  -comment  Receive_Ports_-RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.RXRESETDONE_OUT
  waveform  add  -label TX_Initialization_and_Reset_Ports  -comment  TX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.GTTXRESET_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXUSERRDY_IN
  waveform  add  -label Transmit_Ports_-_FPGA_TX_Interface_Ports  -comment  Transmit_Ports_-_FPGA_TX_Interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXUSRCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXUSRCLK2_IN
  waveform  add  -label Transmit_Ports_-_TX_Data_Path_interface  -comment  Transmit_Ports_-_TX_Data_Path_interface
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXDATA_IN
  waveform  add  -label Transmit_Ports_-_TX_Driver_and_OOB_signaling  -comment  Transmit_Ports_-_TX_Driver_and_OOB_signaling
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.GTHTXN_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.GTHTXP_OUT
  waveform  add  -label Transmit_Ports_-_TX_Fabric_Clock_Output_Control_Ports  -comment  Transmit_Ports_-_TX_Fabric_Clock_Output_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXOUTCLK_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXOUTCLKFABRIC_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXOUTCLKPCS_OUT
  waveform  add  -label Transmit_Ports_-_TX_Initialization_and_Reset_Ports  -comment  Transmit_Ports_-_TX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXRESETDONE_OUT
  waveform  add  -label Transmit_Ports_-_TX_Polarity_Control_Ports  -comment  Transmit_Ports_-_TX_Polarity_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXPOLARITY_IN
  waveform  add  -label Transmit_Ports_-_pattern_Generator_Ports  -comment  Transmit_Ports_-_pattern_Generator_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXPRBSSEL_IN
  waveform  add  -label Transmit_Transmit_Ports_-_8b10b_Encoder_Control_Ports  -comment  Transmit_Transmit_Ports_-_8b10b_Encoder_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt1_xilinx_gth_16b_5g_cpll_i.TXCHARISK_IN

  waveform  add  -label GT2_xilinx_gth_16b_5g_cpll -comment GT2_xilinx_gth_16b_5g_cpll
  waveform  add  -label CPLL_Ports  -comment  CPLL_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.CPLLFBCLKLOST_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.CPLLLOCK_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.CPLLLOCKDETCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.CPLLREFCLKLOST_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.CPLLRESET_IN
  waveform  add  -label Channel_-_Clocking_Ports  -comment  Channel_-_Clocking_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.GTREFCLK0_IN
  waveform  add  -label Channel_-_DRP_Ports_  -comment  Channel_-_DRP_Ports_
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.DRPADDR_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.DRPCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.DRPDI_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.DRPDO_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.DRPEN_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.DRPRDY_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.DRPWE_IN
  waveform  add  -label Clocking_Ports  -comment  Clocking_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.QPLLCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.QPLLREFCLK_IN
  waveform  add  -label Loopback_Ports  -comment  Loopback_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.LOOPBACK_IN
  waveform  add  -label RX_Initialization_and_Reset_Ports  -comment  RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXUSERRDY_IN
  waveform  add  -label RX_Margin_Analysis_Ports  -comment  RX_Margin_Analysis_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.EYESCANDATAERROR_OUT
  waveform  add  -label Receive_Ports_-_CDR_Ports  -comment  Receive_Ports_-_CDR_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXCDRLOCK_OUT
  waveform  add  -label Receive_Ports_-_FPGA_RX_Interface_Ports  -comment  Receive_Ports_-_FPGA_RX_Interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXUSRCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXUSRCLK2_IN
  waveform  add  -label Receive_Ports_-_FPGA_RX_interface_Ports  -comment  Receive_Ports_-_FPGA_RX_interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXDATA_OUT
  waveform  add  -label Receive_Ports_-_Pattern_Checker_Ports  -comment  Receive_Ports_-_Pattern_Checker_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXPRBSERR_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXPRBSSEL_IN
  waveform  add  -label Receive_Ports_-_Pattern_Checker_ports  -comment  Receive_Ports_-_Pattern_Checker_ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXPRBSCNTRESET_IN
  waveform  add  -label Receive_Ports_-_RX_8B/10B_Decoder_Ports  -comment  Receive_Ports_-_RX_8B/10B_Decoder_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXDISPERR_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXNOTINTABLE_OUT
  waveform  add  -label Receive_Ports_-_RX_AFE_Ports  -comment  Receive_Ports_-_RX_AFE_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.GTHRXN_IN
  waveform  add  -label Receive_Ports_-_RX_Byte_and_Word_Alignment_Ports  -comment  Receive_Ports_-_RX_Byte_and_Word_Alignment_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXBYTEISALIGNED_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXCOMMADET_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXMCOMMAALIGNEN_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXPCOMMAALIGNEN_IN
  waveform  add  -label Receive_Ports_-_RX_Equailizer_Ports  -comment  Receive_Ports_-_RX_Equailizer_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXLPMHFHOLD_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXLPMLFHOLD_IN
  waveform  add  -label Receive_Ports_-_RX_Fabric_Output_Control_Ports  -comment  Receive_Ports_-_RX_Fabric_Output_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXOUTCLK_OUT
  waveform  add  -label Receive_Ports_-_RX_Initialization_and_Reset_Ports  -comment  Receive_Ports_-_RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.GTRXRESET_IN
  waveform  add  -label Receive_Ports_-_RX_Polarity_Control_Ports  -comment  Receive_Ports_-_RX_Polarity_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXPOLARITY_IN
  waveform  add  -label Receive_Ports_-_RX8B/10B_Decoder_Ports  -comment  Receive_Ports_-_RX8B/10B_Decoder_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXCHARISCOMMA_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXCHARISK_OUT
  waveform  add  -label Receive_Ports_-RX_AFE_Ports  -comment  Receive_Ports_-RX_AFE_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.GTHRXP_IN
  waveform  add  -label Receive_Ports_-RX_Initialization_and_Reset_Ports  -comment  Receive_Ports_-RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.RXRESETDONE_OUT
  waveform  add  -label TX_Initialization_and_Reset_Ports  -comment  TX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.GTTXRESET_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXUSERRDY_IN
  waveform  add  -label Transmit_Ports_-_FPGA_TX_Interface_Ports  -comment  Transmit_Ports_-_FPGA_TX_Interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXUSRCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXUSRCLK2_IN
  waveform  add  -label Transmit_Ports_-_TX_Data_Path_interface  -comment  Transmit_Ports_-_TX_Data_Path_interface
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXDATA_IN
  waveform  add  -label Transmit_Ports_-_TX_Driver_and_OOB_signaling  -comment  Transmit_Ports_-_TX_Driver_and_OOB_signaling
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.GTHTXN_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.GTHTXP_OUT
  waveform  add  -label Transmit_Ports_-_TX_Fabric_Clock_Output_Control_Ports  -comment  Transmit_Ports_-_TX_Fabric_Clock_Output_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXOUTCLK_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXOUTCLKFABRIC_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXOUTCLKPCS_OUT
  waveform  add  -label Transmit_Ports_-_TX_Initialization_and_Reset_Ports  -comment  Transmit_Ports_-_TX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXRESETDONE_OUT
  waveform  add  -label Transmit_Ports_-_TX_Polarity_Control_Ports  -comment  Transmit_Ports_-_TX_Polarity_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXPOLARITY_IN
  waveform  add  -label Transmit_Ports_-_pattern_Generator_Ports  -comment  Transmit_Ports_-_pattern_Generator_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXPRBSSEL_IN
  waveform  add  -label Transmit_Transmit_Ports_-_8b10b_Encoder_Control_Ports  -comment  Transmit_Transmit_Ports_-_8b10b_Encoder_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt2_xilinx_gth_16b_5g_cpll_i.TXCHARISK_IN

  waveform  add  -label GT3_xilinx_gth_16b_5g_cpll -comment GT3_xilinx_gth_16b_5g_cpll
  waveform  add  -label CPLL_Ports  -comment  CPLL_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.CPLLFBCLKLOST_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.CPLLLOCK_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.CPLLLOCKDETCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.CPLLREFCLKLOST_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.CPLLRESET_IN
  waveform  add  -label Channel_-_Clocking_Ports  -comment  Channel_-_Clocking_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.GTREFCLK0_IN
  waveform  add  -label Channel_-_DRP_Ports_  -comment  Channel_-_DRP_Ports_
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.DRPADDR_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.DRPCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.DRPDI_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.DRPDO_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.DRPEN_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.DRPRDY_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.DRPWE_IN
  waveform  add  -label Clocking_Ports  -comment  Clocking_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.QPLLCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.QPLLREFCLK_IN
  waveform  add  -label Loopback_Ports  -comment  Loopback_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.LOOPBACK_IN
  waveform  add  -label RX_Initialization_and_Reset_Ports  -comment  RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXUSERRDY_IN
  waveform  add  -label RX_Margin_Analysis_Ports  -comment  RX_Margin_Analysis_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.EYESCANDATAERROR_OUT
  waveform  add  -label Receive_Ports_-_CDR_Ports  -comment  Receive_Ports_-_CDR_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXCDRLOCK_OUT
  waveform  add  -label Receive_Ports_-_FPGA_RX_Interface_Ports  -comment  Receive_Ports_-_FPGA_RX_Interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXUSRCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXUSRCLK2_IN
  waveform  add  -label Receive_Ports_-_FPGA_RX_interface_Ports  -comment  Receive_Ports_-_FPGA_RX_interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXDATA_OUT
  waveform  add  -label Receive_Ports_-_Pattern_Checker_Ports  -comment  Receive_Ports_-_Pattern_Checker_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXPRBSERR_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXPRBSSEL_IN
  waveform  add  -label Receive_Ports_-_Pattern_Checker_ports  -comment  Receive_Ports_-_Pattern_Checker_ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXPRBSCNTRESET_IN
  waveform  add  -label Receive_Ports_-_RX_8B/10B_Decoder_Ports  -comment  Receive_Ports_-_RX_8B/10B_Decoder_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXDISPERR_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXNOTINTABLE_OUT
  waveform  add  -label Receive_Ports_-_RX_AFE_Ports  -comment  Receive_Ports_-_RX_AFE_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.GTHRXN_IN
  waveform  add  -label Receive_Ports_-_RX_Byte_and_Word_Alignment_Ports  -comment  Receive_Ports_-_RX_Byte_and_Word_Alignment_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXBYTEISALIGNED_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXCOMMADET_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXMCOMMAALIGNEN_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXPCOMMAALIGNEN_IN
  waveform  add  -label Receive_Ports_-_RX_Equailizer_Ports  -comment  Receive_Ports_-_RX_Equailizer_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXLPMHFHOLD_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXLPMLFHOLD_IN
  waveform  add  -label Receive_Ports_-_RX_Fabric_Output_Control_Ports  -comment  Receive_Ports_-_RX_Fabric_Output_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXOUTCLK_OUT
  waveform  add  -label Receive_Ports_-_RX_Initialization_and_Reset_Ports  -comment  Receive_Ports_-_RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.GTRXRESET_IN
  waveform  add  -label Receive_Ports_-_RX_Polarity_Control_Ports  -comment  Receive_Ports_-_RX_Polarity_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXPOLARITY_IN
  waveform  add  -label Receive_Ports_-_RX8B/10B_Decoder_Ports  -comment  Receive_Ports_-_RX8B/10B_Decoder_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXCHARISCOMMA_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXCHARISK_OUT
  waveform  add  -label Receive_Ports_-RX_AFE_Ports  -comment  Receive_Ports_-RX_AFE_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.GTHRXP_IN
  waveform  add  -label Receive_Ports_-RX_Initialization_and_Reset_Ports  -comment  Receive_Ports_-RX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.RXRESETDONE_OUT
  waveform  add  -label TX_Initialization_and_Reset_Ports  -comment  TX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.GTTXRESET_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXUSERRDY_IN
  waveform  add  -label Transmit_Ports_-_FPGA_TX_Interface_Ports  -comment  Transmit_Ports_-_FPGA_TX_Interface_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXUSRCLK_IN
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXUSRCLK2_IN
  waveform  add  -label Transmit_Ports_-_TX_Data_Path_interface  -comment  Transmit_Ports_-_TX_Data_Path_interface
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXDATA_IN
  waveform  add  -label Transmit_Ports_-_TX_Driver_and_OOB_signaling  -comment  Transmit_Ports_-_TX_Driver_and_OOB_signaling
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.GTHTXN_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.GTHTXP_OUT
  waveform  add  -label Transmit_Ports_-_TX_Fabric_Clock_Output_Control_Ports  -comment  Transmit_Ports_-_TX_Fabric_Clock_Output_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXOUTCLK_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXOUTCLKFABRIC_OUT
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXOUTCLKPCS_OUT
  waveform  add  -label Transmit_Ports_-_TX_Initialization_and_Reset_Ports  -comment  Transmit_Ports_-_TX_Initialization_and_Reset_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXRESETDONE_OUT
  waveform  add  -label Transmit_Ports_-_TX_Polarity_Control_Ports  -comment  Transmit_Ports_-_TX_Polarity_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXPOLARITY_IN
  waveform  add  -label Transmit_Ports_-_pattern_Generator_Ports  -comment  Transmit_Ports_-_pattern_Generator_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXPRBSSEL_IN
  waveform  add  -label Transmit_Transmit_Ports_-_8b10b_Encoder_Control_Ports  -comment  Transmit_Transmit_Ports_-_8b10b_Encoder_Control_Ports
  waveform  add  -signals  xilinx_gth_16b_5g_cpll_TB.xilinx_gth_16b_5g_cpll_exdes_i.xilinx_gth_16b_5g_cpll_init_i.xilinx_gth_16b_5g_cpll_i.gt3_xilinx_gth_16b_5g_cpll_i.TXCHARISK_IN


  console submit -using simulator -wait no "run 300 us"

