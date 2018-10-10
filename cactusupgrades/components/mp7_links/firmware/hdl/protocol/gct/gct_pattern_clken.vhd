
-- Use the same approach as code written in source card for easy comparison (i.e based on counter)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity gct_pattern_clken is
generic(
  LHC_BUNCH_COUNT: integer);
port(
  clk: in std_logic;
  rst: in std_logic;
  clken: in std_logic;
	bctr: in std_logic_vector(11 downto 0);
	pctr: in std_logic_vector(2 downto 0);
  data: out std_logic_vector(15 downto 0);
  data_valid: out std_logic);
end gct_pattern_clken;


architecture behave of gct_pattern_clken is

  signal data_msb, data_valid_int: std_logic := '0';
  signal phase, counter_key: std_logic;
  signal counter: integer range 0 to 8191;
  signal pctr_int: integer range 0 to 7;   

begin
  
  -- If orbit too small packet will be trucated.
  assert LHC_BUNCH_COUNT >= 200 report "LHC_BUNCH_COUNT must be >= 200" severity failure;

  -- Create LSB toggling @ 80MHz
  pctr_int <= to_integer(unsigned(pctr));
  phase <= '0' when pctr_int < 3 else '1';
      
  data_gen: process(clk, rst)
  begin
    if rising_edge(clk) then
      if clken = '1' then
        counter <= to_integer(unsigned(bctr & phase));
        counter_key <= phase;
        data_valid <= data_valid_int;
        data <= std_logic_vector(data_msb & "00" & to_unsigned(counter, 13));
      end if;
    end if;
  end process;
      
  -- Key used to distiguish word order and bc0 location.
  data_msb <= '1' when counter = 2*LHC_BUNCH_COUNT - 2 else counter_key;
  
  data_valid_int <= '0' when 
    counter > 2*(LHC_BUNCH_COUNT - 119) + 3 and counter < 2*LHC_BUNCH_COUNT - 6 else '1';
    

end behave;
