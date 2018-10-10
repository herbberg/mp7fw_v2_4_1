library ieee;
use ieee.std_logic_1164.all;

entity data_check_8b10bx16b is
  generic(
    BYTE_WIDTH : natural := 2);
  port (
    rx_usr_clk_in : in std_logic;
    rx_byte_is_aligned_in : in std_logic;
    rx_data_in : in std_logic_vector(8 * BYTE_WIDTH - 1 downto 0);
    rx_char_is_k_in : in std_logic_vector(1 downto 0);
    data_check_out : out std_logic);
end data_check_8b10bx16b;

architecture rtl of data_check_8b10bx16b is
  constant DATA_WIDTH : natural := 8 * BYTE_WIDTH;
  constant RX_DATA : std_logic_vector := x"505050BC";
  constant RX_CHAR_IS_K : std_logic_vector := x"0001";

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
      else  
        if (rx_data_in(7 downto 0) = x"BC") and (rx_char_is_k_in(0) = '1') then
          if (rx_data_in(DATA_WIDTH-1 downto 8) = RX_DATA(DATA_WIDTH-1 downto 8)) and (rx_char_is_k_in(BYTE_WIDTH-1 downto 1) = RX_CHAR_IS_K(BYTE_WIDTH-1 downto 1)) then
            data_check_out <= '1';
          else 
            data_check_out <= '0';
          end if;
        end if;
      end if;
    end if;
  end process data_check_proc;
    
end rtl;
