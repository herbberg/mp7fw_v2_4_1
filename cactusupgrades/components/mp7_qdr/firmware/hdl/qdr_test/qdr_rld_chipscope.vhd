--*****************************************************************************
-- (c) Copyright 2012 Xilinx, Inc. All rights reserved.
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
-- /___/  \  /    Vendor                : Xilinx
-- \   \   \/     Version               : 1.x
--  \   \         Application           : MIG
--  /   /         Filename              : qdr_rld_chipscope.vhd
-- /___/   /\     Date Last Modified    : $date$
-- \   \  /  \    Date Created          : Feb 09 2012
--  \___\/\___\
--
--Device            : 7 Series
--Design Name       : QDRII+ SRAM / RLDRAM II
--Purpose           : Chipscope cores declarations used if debug option is
--                    enabled in MIG when generating design. These are
--                    empty declarations to allow compilation to pass both in
--                    simulation and synthesis. The proper .ngc files must be
--                    referenced during the actual ISE build.
--Reference         :
--Revision History  :
--*****************************************************************************

library ieee;
use ieee.std_logic_1164.all;

package qdr_rld_chipscope is

component icon3
  port(
    CONTROL0 : inout std_logic_vector(35 downto 0);
    CONTROL1 : inout std_logic_vector(35 downto 0);
    CONTROL2 : inout std_logic_vector(35 downto 0)
    );
end component icon3;

component icon2
  port(
    CONTROL0 : inout std_logic_vector(35 downto 0);
    CONTROL1 : inout std_logic_vector(35 downto 0)
    );
end component icon2;

component ila256_8
  port(
    CLK     : in    std_logic;
    DATA    : in    std_logic_vector(255 downto 0);
    TRIG0   : in    std_logic_vector(7 downto 0);
    CONTROL : inout std_logic_vector(35 downto 0)
    );
end component ila256_8;

component ila256_16
  port(
    CLK     : in    std_logic;
    DATA    : in    std_logic_vector(255 downto 0);
    TRIG0   : in    std_logic_vector(15 downto 0);
    CONTROL : inout std_logic_vector(35 downto 0)
    );
end component ila256_16;

component ila512_16
  port(
    CLK     : in    std_logic;
    DATA    : in    std_logic_vector(511 downto 0);
    TRIG0   : in    std_logic_vector(15 downto 0);
    CONTROL : inout std_logic_vector(35 downto 0)
    );
end component ila512_16;

component ila640_32
  port(
   CLK     : in    std_logic;
   DATA    : in    std_logic_vector(639 downto 0);
   TRIG0   : in    std_logic_vector(31 downto 0);
   CONTROL : inout std_logic_vector(35 downto 0)
   );
end component ila640_32;

component vio_async_in256_sync_out72 is
  port (
  CLK      : in    std_logic;
  ASYNC_IN : in    std_logic_vector(255 downto 0);
  SYNC_OUT : out   std_logic_vector(71 downto 0);
  CONTROL  : inout std_logic_vector(35 downto 0)
  );
end component vio_async_in256_sync_out72;

component vio_ain256_aout64_sout64 is
  port (
  CLK       : in   std_logic;
  ASYNC_IN  : in   std_logic_vector(255 downto 0);
  ASYNC_OUT : out  std_logic_vector(63 downto 0);
  SYNC_OUT  : out  std_logic_vector(63 downto 0);
  CONTROL   : inout std_logic_vector(35 downto 0)
  );
end component vio_ain256_aout64_sout64;

component mig_7series_v1_8_chk_win_top
  generic (
    TCQ                      : integer;
    nCK_PER_CLK              : integer;
    DLY_WIDTH                : integer;
    DQ_PER_DQS               : integer;
    DQ_WIDTH                 : integer;
    SC_WIDTH                 : integer;
    SDC_WIDTH                : integer;
    WIN_SIZE                 : integer;
    SIM_OPTION               : string
    );
  port (
    clk                    : in   std_logic;
    rst                    : in   std_logic;
    win_start              : in   std_logic;
    win_dump               : in   std_logic;
    read_valid             : in   std_logic;
    win_bit_select         : in   std_logic_vector(6 downto 0);
    cmp_data               : in   std_logic_vector(DQ_WIDTH*2*nCK_PER_CLK-1 downto 0);
    rd_data                : in   std_logic_vector(DQ_WIDTH*2*nCK_PER_CLK-1 downto 0);
    curr_tap_cnt           : in   std_logic_vector(WIN_SIZE-1 downto 0);
    left_ram_out           : out  std_logic_vector(WIN_SIZE-1 downto 0);
    right_ram_out          : out  std_logic_vector(WIN_SIZE-1 downto 0);
    current_bit_ram_out    : out  std_logic_vector(6 downto 0);
    win_active             : out  std_logic;
    win_dump_active        : out  std_logic;
    win_clr_error          : out  std_logic;
    win_inc                : out  std_logic;
    win_dec                : out  std_logic;
    win_current_bit        : out  std_logic_vector(6 downto 0);
    win_current_byte       : out  std_logic_vector(3 downto 0);
    dbg_win_chk            : out  std_logic_vector(31 downto 0);
    dbg_clear_error        : in   std_logic
    );
end component mig_7series_v1_8_chk_win_top;

component mig_7series_v1_8_sim_chk_win
  generic (
    TCQ                      : integer
    );
  port (
    clk                    : in   std_logic;
    rst                    : in   std_logic;
    read_valid             : in   std_logic;
    init_calib_complete    : in   std_logic;
    win_active             : in   std_logic;
    win_start              : out  std_logic;
    win_dump               : out  std_logic
    );
end component mig_7series_v1_8_sim_chk_win;

  attribute syn_noprune   : boolean;
  attribute syn_black_box : boolean;

  attribute syn_noprune of icon3                        : component is TRUE;
  attribute syn_black_box of icon3                      : component is TRUE;
  attribute syn_noprune of icon2                        : component is TRUE;
  attribute syn_black_box of icon2                      : component is TRUE;
  attribute syn_noprune of ila256_8                     : component is TRUE;
  attribute syn_black_box of ila256_8                   : component is TRUE;
  attribute syn_noprune of ila256_16                    : component is TRUE;
  attribute syn_black_box of ila256_16                  : component is TRUE;
  attribute syn_noprune of ila512_16                    : component is TRUE;
  attribute syn_black_box of ila512_16                  : component is TRUE;
  attribute syn_noprune of vio_async_in256_sync_out72   : component is TRUE;
  attribute syn_black_box of vio_async_in256_sync_out72 : component is TRUE;
  attribute syn_noprune of vio_ain256_aout64_sout64     : component is TRUE;
  attribute syn_black_box of vio_ain256_aout64_sout64   : component is TRUE;

end package qdr_rld_chipscope;
