
-- Use original source card code to generate test pattern to avoid any complications.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity gct_pattern_original is
generic(
  LHC_BUNCH_COUNT: integer);
port(
  clk40: in std_logic;
  rst40: in std_logic;
  bunch_ctr: in std_logic_vector(11 downto 0);
  clk80: in std_logic;
  rst80: in std_logic;
  counter_data: out std_logic_vector(15 downto 0);
  counter_data_valid: out std_logic);
end gct_pattern_original;


architecture behave of gct_pattern_original is

  signal counter_key                  : std_logic := '0';
  signal counter_msb                  : std_logic := '0';
  signal counter                      : integer range 0 to 8191;
  signal counter_data_valid_int       : std_logic;

  signal ttc_half_bunch_cnt           : std_logic_vector(12 downto 0);
  signal ttc_toggle                   : std_logic;
  signal ttc_phase                    : std_logic;
  signal ttc_phase_buf                : std_logic_vector(1 downto 0);
   
begin

  -- If orbit too small packet will be trucated.
  assert LHC_BUNCH_COUNT >= 200 report "LHC_BUNCH_COUNT must be >= 200" severity failure;
  
  ttc_toggle_proc: process(clk40, rst40)
  begin
    if rst40 = '1' then
       ttc_toggle <= '0';
    elsif rising_edge(clk40) then
       ttc_toggle <= not ttc_toggle;
    end if;
  end process;

  ttc_phase_proc: process(clk80, rst80)
  begin
    if rst80 = '1' then
       ttc_phase_buf <= "00";
       ttc_phase <= '0';
    elsif rising_edge(clk80) then
        ttc_phase_buf <= ttc_phase_buf(0) & ttc_toggle;
        ttc_phase <= not (ttc_phase_buf(0) xor ttc_phase_buf(1));
    end if;
  end process;

  ttc_half_bunch_cnt <= bunch_ctr & ttc_phase;

  counter <= to_integer(unsigned(ttc_half_bunch_cnt));
  counter_key <= ttc_half_bunch_cnt(0);

  -- Key used to distiguish word order and bc0 location.
  counter_msb <= '1' when counter = 2*LHC_BUNCH_COUNT - 2 else counter_key;

  counter_out: process(clk80, rst80)
  begin
    if rst80 = '1' then
       counter_data_valid <= '0';
       counter_data <= x"0000";
    elsif rising_edge(clk80) then
        counter_data_valid <= counter_data_valid_int;
        counter_data <= std_logic_vector(counter_msb & "00" & to_unsigned(counter,13));
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Stuff..
  --------------------------------------------------------------------------


  counter_data_valid_int <=   
     '0' when counter > 2*(LHC_BUNCH_COUNT - 119) + 3 and counter < 2*LHC_BUNCH_COUNT - 6 else '1';


end behave;
