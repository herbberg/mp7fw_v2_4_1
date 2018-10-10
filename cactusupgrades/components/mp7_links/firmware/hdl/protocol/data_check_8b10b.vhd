library ieee;
use ieee.std_logic_1164.all;

entity data_check_8b10b is
  generic(
    BYTE_WIDTH : natural := 2);
  port (
    rx_usr_clk_in : in std_logic;
    rx_byte_is_aligned_in : in std_logic;
    rx_data_in : in std_logic_vector(8 * BYTE_WIDTH - 1 downto 0);
    rx_char_is_k_in : in std_logic_vector(BYTE_WIDTH - 1 downto 0);
    data_check_out : out std_logic);
end data_check_8b10b;

architecture rtl of data_check_8b10b is
  constant DATA_WIDTH : natural := 8 * BYTE_WIDTH;
  constant RX_DATA : std_logic_vector(31 downto 0) := x"505050BC";
  constant RX_CHAR_IS_K : std_logic_vector(3 downto 0) := "0001";

  constant CNT_MAX: natural := 2**2-1;
  signal cnt: natural range 0 to CNT_MAX;

begin

  -- The 16b interface failed to come out of reset in ~1 in 50 times and thus a data valid
  -- check was implemented.  The 32b interface configured 4 transceivers 5000 times without 
  -- fail, but final sys mut be very reliable.  Hence add data valid check.  If this fails
  -- the rxfsm will reset the transceiver.

  data_check_proc: process(rx_usr_clk_in)
  begin
    if (rising_edge(rx_usr_clk_in)) then
      if rx_byte_is_aligned_in = '0' then
        data_check_out <= '0';
        cnt <= 0;
      else
        
        if rx_char_is_k_in(0) = '1' then 
          if rx_data_in(7 downto 0) = x"BC" then
            -- Comma word
            if cnt < CNT_MAX then
              cnt <= cnt + 1;
            end if;
          elsif rx_data_in(7 downto 0) = x"F7" then
            -- Padding word
            null;
          else
            -- Illegal word
            cnt <= 0;
          end if;
        end if;
        
        if cnt = CNT_MAX then
          data_check_out <= '1';
        else
          data_check_out <= '0';
        end if;

      end if;
    end if;
  end process data_check_proc;
    
end rtl;
