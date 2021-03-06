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

package ipbus_decode_mp7xe_xpoint is

  constant IPBUS_SEL_WIDTH: positive := 5; -- Should be enough for now?
  subtype ipbus_sel_t is std_logic_vector(IPBUS_SEL_WIDTH - 1 downto 0);
  function ipbus_sel_mp7xe_xpoint(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t;

-- START automatically  generated VHDL the Fri Jul 31 06:12:46 2015 
  constant N_SLV_CSR: integer := 0;
  constant N_SLV_I2C_SI570_BOT: integer := 1;
  constant N_SLV_I2C_SI5326_BOT: integer := 2;
  constant N_SLV_I2C_SI5326_TOP: integer := 3;
  constant N_SLAVES: integer := 4;
-- END automatically generated VHDL

    
end ipbus_decode_mp7xe_xpoint;

package body ipbus_decode_mp7xe_xpoint is

  function ipbus_sel_mp7xe_xpoint(addr : in std_logic_vector(31 downto 0)) return ipbus_sel_t is
    variable sel: ipbus_sel_t;
  begin

-- START automatically  generated VHDL the Fri Jul 31 06:12:46 2015 
    if    std_match(addr, "---------------------------00---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_CSR, IPBUS_SEL_WIDTH)); -- csr / base 0x00000000 / mask 0x00000018
    elsif std_match(addr, "---------------------------01---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_I2C_SI570_BOT, IPBUS_SEL_WIDTH)); -- i2c_si570_bot / base 0x00000008 / mask 0x00000018
    elsif std_match(addr, "---------------------------10---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_I2C_SI5326_BOT, IPBUS_SEL_WIDTH)); -- i2c_si5326_bot / base 0x00000010 / mask 0x00000018
    elsif std_match(addr, "---------------------------11---") then
      sel := ipbus_sel_t(to_unsigned(N_SLV_I2C_SI5326_TOP, IPBUS_SEL_WIDTH)); -- i2c_si5326_top / base 0x00000018 / mask 0x00000018
-- END automatically generated VHDL

    else
        sel := ipbus_sel_t(to_unsigned(N_SLAVES, IPBUS_SEL_WIDTH));
    end if;

    return sel;

  end function ipbus_sel_mp7xe_xpoint;

end ipbus_decode_mp7xe_xpoint;

