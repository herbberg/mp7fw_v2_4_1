////////////////////////////////////////////////////////////////////////////////
//   ____  ____ 
//  /   /\/   / 
// /___/  \  /    Vendor: Xilinx 
// \   \   \/     Version : 2.6
//  \   \         Application : 7 Series FPGAs Transceivers Wizard
//  /   /         Filename : xilinx_gth_16b_5g_cpll_gt_frame_gen.v
// /___/   /\      
// \   \  /  \ 
//  \___\/\___\ 
//
//
// Module xilinx_gth_16b_5g_cpll_GT_FRAME_GEN
// Generated by Xilinx 7 Series FPGAs Transceivers Wizard
// 
// 
// (c) Copyright 2010-2012 Xilinx, Inc. All rights reserved.
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


`timescale 1ns / 1ps
`define DLY #1

//***********************************Entity Declaration*******************************

module xilinx_gth_16b_5g_cpll_GT_FRAME_GEN #
(
    // parameter to set the number of words in the BRAM
    parameter   WORDS_IN_BRAM =   512
)
(
   // User Interface
    output reg  [79:0]  TX_DATA_OUT,
    output reg  [7:0]   TXCTRL_OUT,

      // System Interface
    input  wire         USER_CLK,
    input  wire         SYSTEM_RESET 
); 


//********************************* Wire Declarations********************************* 

    wire            tied_to_ground_i;
    wire    [31:0]  tied_to_ground_vec_i;
    wire    [63:0]  tx_data_bram_i;
    wire    [7:0]   tx_ctrl_i;

//***************************Internal Register Declarations*************************** 

    reg     [8:0]   read_counter_i;
    reg     [79:0] rom [0:511];
    reg     [79:0]  tx_data_ram_r;
    (*keep = "true" *) reg     system_reset_r; 


//*********************************Main Body of Code**********************************

    assign tied_to_ground_vec_i  =   32'h00000000;
    assign tied_to_ground_i      =   1'b0;
    assign tied_to_vcc_i         =   1'b1;
    
    //___________ synchronizing the async reset for ease of timing simulation ________
    always@(posedge USER_CLK)
       system_reset_r <= `DLY SYSTEM_RESET;

    //____________________________ Counter to read from BRAM __________________________    

    always @(posedge USER_CLK)
        if(system_reset_r || (read_counter_i == "111111111"))  
        begin
             read_counter_i   <=  `DLY    9'd0;
        end
        else read_counter_i   <=  `DLY    read_counter_i + 9'd1;

    // Assign TX_DATA_OUT to BRAM output
    always @(posedge USER_CLK)
        if(system_reset_r) TX_DATA_OUT <= `DLY 80'h0000000000; 
        else             TX_DATA_OUT <= `DLY {tx_data_bram_i,tx_data_ram_r[15:0]};   

    // Assign TXCTRL_OUT to BRAM output
    always @(posedge USER_CLK)
        if(system_reset_r) TXCTRL_OUT <= `DLY 8'h0; 
        else             TXCTRL_OUT <= `DLY tx_ctrl_i;  


    //________________________________ BRAM Inference Logic _____________________________    

    assign tx_data_bram_i      = tx_data_ram_r[79:16];
    assign tx_ctrl_i           = tx_data_ram_r[15:8];
  
    initial
    begin
           $readmemh("gt_rom_init_tx.dat",rom,0,511);
    end

    always @(posedge USER_CLK)
           tx_data_ram_r <= `DLY rom[read_counter_i];

endmodule 


