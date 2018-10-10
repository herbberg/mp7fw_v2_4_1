
----------------------------------------------------------------------------------------------------
-- 16 BIT parallel CRC generator (unmodified copy of module in library)
-- CRC algorythm used by Xilinx
-- feedback taps at bit 15, 2, and 0
-- Implemented by Matt
-- modified to have synchronous reset by Magnus
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity gct_crc is port (
   clk:        in std_logic;
   rst:        in std_logic;
   ena:        in std_logic;
   datin:      in std_logic_vector(15 downto 0);
   dataout:    out std_logic_vector(15 downto 0));
end gct_crc;

architecture behave of gct_crc is
   signal crcfb: std_logic_vector(15 downto 0);
begin
   -- parallel crc generator
   cp: process (clk) begin
      if (clk'event and clk = '1') then
         if rst = '1' then
            crcfb <= (others => '0');
         elsif ena = '1' then
            crcfb(15) <= datin(15) xor datin(14) xor datin(13) xor datin(12) xor datin(11) xor
                         datin(10) xor datin(9) xor datin(8) xor datin(7) xor datin(6) xor
                         datin(5) xor datin(4) xor datin(3) xor crcfb(12) xor crcfb(11) xor
                         crcfb(10) xor crcfb(9) xor crcfb(8) xor crcfb(7) xor crcfb(6) xor
                         crcfb(5) xor crcfb(4) xor crcfb(3) xor crcfb(2) xor datin(0) xor
                         crcfb(1) xor crcfb(0) xor crcfb(15) xor crcfb(14);
            crcfb(14) <= datin(3) xor datin(2) xor crcfb(13) xor crcfb(12);
            crcfb(13) <= datin(4) xor datin(3) xor crcfb(12) xor crcfb(11);
            crcfb(12) <= datin(5) xor datin(4) xor crcfb(11) xor crcfb(10);
            crcfb(11) <= datin(6) xor datin(5) xor crcfb(10) xor crcfb(9);
            crcfb(10) <= datin(7) xor datin(6) xor crcfb(9) xor crcfb(8);
            crcfb(9)  <= datin(8) xor datin(7) xor crcfb(8) xor crcfb(7);
            crcfb(8)  <= datin(9) xor datin(8) xor crcfb(7) xor crcfb(6);
            crcfb(7)  <= datin(10) xor datin(9) xor crcfb(6) xor crcfb(5);
            crcfb(6)  <= datin(11) xor datin(10) xor crcfb(5) xor crcfb(4);
            crcfb(5)  <= datin(12) xor datin(11) xor crcfb(4) xor crcfb(3);
            crcfb(4)  <= datin(13) xor datin(12) xor crcfb(3) xor crcfb(2);
            crcfb(3)  <= datin(14) xor datin(13) xor datin(0) xor crcfb(2) xor crcfb(15) xor crcfb(1);
            crcfb(2)  <= datin(15) xor datin(14) xor datin(1) xor crcfb(1) xor crcfb(14) xor crcfb(0);
            crcfb(1)  <= datin(14) xor datin(13) xor datin(12) xor datin(11) xor datin(10) xor
                         datin(9) xor datin(8) xor datin(7) xor datin(6) xor datin(5) xor
                         datin(4) xor datin(3) xor datin(2) xor datin(1) xor crcfb(14) xor
                         crcfb(13) xor crcfb(12) xor crcfb(11) xor crcfb(10) xor crcfb(9) xor
                         crcfb(8) xor crcfb(7) xor crcfb(6) xor crcfb(5) xor crcfb(4) xor
                         crcfb(3) xor crcfb(2) xor crcfb(1);
            crcfb(0)  <= datin(15) xor datin(14) xor datin(13) xor datin(12) xor datin(11) xor
                         datin(10) xor datin(9) xor datin(8) xor datin(7) xor datin(6) xor
                         datin(5) xor datin(4) xor datin(3) xor datin(2) xor datin(0) xor
                         crcfb(13) xor crcfb(12) xor crcfb(11) xor crcfb(10) xor crcfb(9) xor
                         crcfb(8) xor crcfb(7) xor crcfb(6) xor crcfb(5) xor crcfb(4) xor
                         crcfb(3) xor crcfb(2) xor crcfb(15) xor crcfb(1) xor crcfb(0);
         end if;
      end if;
   end process;
   
   dataout <= crcfb;
   
end behave;