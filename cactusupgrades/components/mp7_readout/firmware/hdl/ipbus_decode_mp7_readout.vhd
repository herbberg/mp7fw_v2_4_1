-- Address decode logic for ipbus fabric
-- 
-- This file has been AUTOGENERATED from the address table - do not hand edit
-- 
-- We assume the synthesis tool is clever enough to recognise exclusive conditions
-- in the if statement.
-- 
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package ipbus_decode_mp7_readout is

  constant IPBUS_SEL_WIDTH: positive := 5; -- Should be enough for now?
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_mp7_readout(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Thu Aug 25 15:17:53 2016 
  constant N_SLV_CSR: integer := 0;
  constant N_SLV_TTS_CSR: integer := 1;
  constant N_SLV_BUFFER: integer := 2;
  constant N_SLV_HIST: integer := 3;
  constant N_SLV_TTS_HIST: integer := 4;
  constant N_SLV_TTS_CTRS: integer := 5;
  constant N_SLV_EVT_CHECK: integer := 6;
  constant N_SLV_READOUT_ZS: integer := 7;
  constant N_SLV_READOUT_CONTROL: integer := 8;
  constant N_SLAVES: integer := 9;
-- END automatically generated VHDL

    
end ipbus_decode_mp7_readout;

package body ipbus_decode_mp7_readout is

  function ipbus_sel_mp7_readout(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Thu Aug 25 15:17:53 2016 
    if    std_match(addr, "------------------------000000--") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CSR, IPBUS_SEL_WIDTH)); -- csr / base 0x00000000 / mask 0x000000fc
    elsif std_match(addr, "------------------------0000010-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TTS_CSR, IPBUS_SEL_WIDTH)); -- tts_csr / base 0x00000004 / mask 0x000000fe
    elsif std_match(addr, "------------------------000010--") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_BUFFER, IPBUS_SEL_WIDTH)); -- buffer / base 0x00000008 / mask 0x000000fc
    elsif std_match(addr, "------------------------000100--") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_HIST, IPBUS_SEL_WIDTH)); -- hist / base 0x00000010 / mask 0x000000fc
    elsif std_match(addr, "------------------------000101--") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TTS_HIST, IPBUS_SEL_WIDTH)); -- tts_hist / base 0x00000014 / mask 0x000000fc
    elsif std_match(addr, "------------------------0010----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TTS_CTRS, IPBUS_SEL_WIDTH)); -- tts_ctrs / base 0x00000020 / mask 0x000000f0
    elsif std_match(addr, "------------------------0011001-") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_EVT_CHECK, IPBUS_SEL_WIDTH)); -- evt_check / base 0x00000032 / mask 0x000000fe
    elsif std_match(addr, "------------------------01000---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_READOUT_ZS, IPBUS_SEL_WIDTH)); -- readout_zs / base 0x00000040 / mask 0x000000f8
    elsif std_match(addr, "------------------------10------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_READOUT_CONTROL, IPBUS_SEL_WIDTH)); -- readout_control / base 0x00000080 / mask 0x000000c0
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_mp7_readout;

end ipbus_decode_mp7_readout;

