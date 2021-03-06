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

package ipbus_decode_mp7_infra is

  constant IPBUS_SEL_WIDTH: positive := 5; -- Should be enough for now?
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_mp7_infra(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Fri Aug 26 12:22:57 2016 
  constant N_SLV_CTRL: integer := 0;
  constant N_SLV_TTC: integer := 1;
  constant N_SLV_I2C_MINIPODS_TOP: integer := 2;
  constant N_SLV_I2C_MINIPODS_BOT: integer := 3;
  constant N_SLV_CLOCKING: integer := 4;
  constant N_SLV_READOUT: integer := 5;
  constant N_SLV_DATAPATH: integer := 6;
  constant N_SLV_UC: integer := 7;
  constant N_SLV_PAYLOAD: integer := 8;
  constant N_SLAVES: integer := 9;
-- END automatically generated VHDL

    
end ipbus_decode_mp7_infra;

package body ipbus_decode_mp7_infra is

  function ipbus_sel_mp7_infra(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Fri Aug 26 12:22:57 2016 
    if    std_match(addr, "0000---------------0---0000-----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CTRL, IPBUS_SEL_WIDTH)); -- ctrl / base 0x00000000 / mask 0xf00011e0
    elsif std_match(addr, "0000---------------0---0010-----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_TTC, IPBUS_SEL_WIDTH)); -- ttc / base 0x00000040 / mask 0xf00011e0
    elsif std_match(addr, "0000---------------0---0011-0---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_I2C_MINIPODS_TOP, IPBUS_SEL_WIDTH)); -- i2c.minipods_top / base 0x00000060 / mask 0xf00011e8
    elsif std_match(addr, "0000---------------0---0011-1---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_I2C_MINIPODS_BOT, IPBUS_SEL_WIDTH)); -- i2c.minipods_bot / base 0x00000068 / mask 0xf00011e8
    elsif std_match(addr, "0000---------------0---0100-----") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CLOCKING, IPBUS_SEL_WIDTH)); -- clocking / base 0x00000080 / mask 0xf00011e0
    elsif std_match(addr, "0000---------------0---1--------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_READOUT, IPBUS_SEL_WIDTH)); -- readout / base 0x00000100 / mask 0xf0001100
    elsif std_match(addr, "0000---------------1------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_DATAPATH, IPBUS_SEL_WIDTH)); -- datapath / base 0x00001000 / mask 0xf0001000
    elsif std_match(addr, "0111---------------0---0000-0---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_UC, IPBUS_SEL_WIDTH)); -- uc / base 0x70000000 / mask 0xf00011e8
    elsif std_match(addr, "1-------------------------------") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_PAYLOAD, IPBUS_SEL_WIDTH)); -- payload / base 0x80000000 / mask 0x80000000
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_mp7_infra;

end ipbus_decode_mp7_infra;

