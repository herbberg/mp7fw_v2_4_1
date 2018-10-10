
-- Use original source card code to generate test pattern to avoid any complications.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- use ieee.std_logic_arith.all;

entity gct_pattern_tb is
end gct_pattern_tb;

architecture behave of gct_pattern_tb is

  constant LHC_BUNCH_COUNT : natural := 200;

  signal clk40, clk80, clk240, base_clk, clken: std_logic := '0';
  signal bunch_ctr: std_logic_vector(11 downto 0);
  signal rst40, rst80, rst240: std_logic := '1';
  signal data, data_from_clken: std_logic_vector(15 downto 0);
  signal data_valid, data_valid_from_clken: std_logic;
  signal bctr: std_logic_vector(11 downto 0);
  signal pctr: std_logic_vector(2 downto 0);
    
  constant BASE_TIME: time := 2.083 ns;
  
  
  
begin

  base_clk <= not base_clk after BASE_TIME;

  -- Make sure clks delta safe
  clks: process(base_clk)
    variable clk_cnt: natural range 0 to 11 := 0;
    variable pctr_int: integer := 5;
    variable bctr_int: integer := 0;
  begin
    if base_clk'event then

      -- 80MHz
      if (clk_cnt mod 3) = 0 then
        clk80 <= not clk80;
      end if;

      -- 40 MHz
      if (clk_cnt mod 6) = 0 then
        clk40 <= not clk40;
      end if;

      --240MHz
      clk240 <= base_clk;

      -- Sub BX Cntr
      if (clk_cnt mod 2) = 0 then
        if pctr_int < 5 then
          pctr_int := pctr_int + 1;
        else
          pctr_int := 0;
        end if;
        pctr <= std_logic_vector(to_unsigned(pctr_int, 3));
      end if;

      -- BX Cntr
      if clk_cnt = 0 then
        if bctr_int < LHC_BUNCH_COUNT-1 then
          bctr_int := bctr_int + 1;
        else
          bctr_int := 0;
        end if;
        bctr <= std_logic_vector(to_unsigned(bctr_int, 12));
      end if;
      
      if clk_cnt = 11 then
        clk_cnt := 0;
      else
        clk_cnt := clk_cnt + 1;
      end if;
      
    end if;    
  end process;
  
  rsts: process
  begin
    wait for 100 ns;
    wait until rising_edge(clk40);
      rst40 <= '0' after 1 ns;
      rst80 <= '0' after 1 ns;
      rst240 <= '0' after 1 ns;
  end process;

  -- Clock Enable
  clken <= '1' when (pctr = "000") or (pctr = "011") else '0';
  
  pattern_original: entity work.gct_pattern_original
    generic map(
      LHC_BUNCH_COUNT => LHC_BUNCH_COUNT)
    port map(
      clk40 => clk40,
      rst40 => rst40,
      bunch_ctr => bctr,
      clk80 => clk80,
      rst80 => rst80,
      counter_data => data,
      counter_data_valid => data_valid);

  pattern_for_mp7: entity work.gct_pattern_clken
    generic map(
      LHC_BUNCH_COUNT => LHC_BUNCH_COUNT)
    port map(
      clk => clk240,
      rst => rst240,
      clken => clken,
      bctr => bctr,
      pctr => pctr,
      data => data_from_clken,
      data_valid => data_valid_from_clken);


end behave;
