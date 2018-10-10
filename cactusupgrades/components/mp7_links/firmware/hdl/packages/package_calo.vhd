

library ieee;       
use ieee.std_logic_1164.all;       
use ieee.numeric_std.all;  

package package_calo is       

  component hcal_tx is
  port (
    rst_in: in std_logic := '1';  
    clk_in: in std_logic := '0';
    pad_in: in std_logic := '0';
    data_in: in std_logic_vector(15 downto 0) := (others => '0');
    data_valid_in: in std_logic := '0';
    data_start_in: in std_logic := '0';
    data_out: out std_logic_vector(15 downto 0);
    charisk_out: out std_logic_vector(1 downto 0));
  end component;


  component hcal_rx is
  port (
    -- All the following in link clk domain
    link_rst_in: in std_logic := '1';  
    link_clk_in: in std_logic := '0';
    data_in: in std_logic_vector(15 downto 0) := (others => '0');
    charisk_in : in std_logic_vector(1 downto 0) := (others => '0');
    data_valid_out: out std_logic := '0';
    data_start_out: out std_logic := '0';
    data_out: out std_logic_vector(15 downto 0);
    pad_out: out std_logic := '0';
    -- All the following in the local clk domain
    local_rst_in: in  std_logic;
    local_clk_in: in  std_logic;
    local_clken_in: in  std_logic;
    reset_counters_in: in std_logic;
    crc_checked_cnt_out: out std_logic_vector(7 downto 0);
    crc_error_cnt_out: out std_logic_vector(7 downto 0);
    status_out: out std_logic_vector(3 downto 0));
  end component;


  component ecal_tx is
  port (
    rst_in: in std_logic := '1';  
    clk_in: in std_logic := '0';
    data_in: in std_logic_vector(15 downto 0) := (others => '0');
    data_valid_in: in std_logic := '0';
    data_start_in: in std_logic := '0';
    data_out: out std_logic_vector(15 downto 0);
    data_valid_out: out std_logic);
  end component;
  
  
  component ecal_rx is
  port (
    rst_in: in std_logic := '1';  
    clk_in: in std_logic := '0';
    data_in: in std_logic_vector(15 downto 0);
    data_valid_in: in std_logic;
    data_out: out std_logic_vector(15 downto 0) := (others => '0');
    data_valid_out: out std_logic := '0';
    data_start_out: out std_logic := '0';
    reset_counters_in: in std_logic;
    hamming_checked_cnt_out: out std_logic_vector(7 downto 0);
    hamming_error_cnt_out: out std_logic_vector(7 downto 0);
    status_out: out std_logic_vector(3 downto 0));
  end component;

end package;

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.ucrc_pkg.all;

entity hcal_tx is
port (
  rst_in: in std_logic := '1';  
  clk_in: in std_logic := '0';
  pad_in: in std_logic := '0';
  data_in: in std_logic_vector(15 downto 0) := (others => '0');
  data_valid_in: in std_logic := '0';
  data_start_in: in std_logic := '0';
  data_out: out std_logic_vector(15 downto 0);
  charisk_out: out std_logic_vector(1 downto 0));
end hcal_tx;

architecture behave of hcal_tx is

  signal crc_word: std_logic_vector(7 downto 0);
  signal data_clked, crc_data: std_logic_vector(15 downto 0);
  signal data_start_clked, data_valid_clked: std_logic;
  
  type type_packet_sm is (idle, pkt_begin, pkt_middle, pkt_end);
  signal packet_sm: type_packet_sm;
  
  signal clken, clken_clked: std_logic;
  signal start, stop, restart: std_logic;
  signal crc_rst: std_logic := '1';
  signal delay: natural;

begin

  clken <= not pad_in;

  -- Incoming 16b data aligned to BX boundaries.
  -- Need to realign data for CRC  

  buf: process(clk_in)
  begin
    if rising_edge(clk_in) then
      clken_clked <= clken;
      if clken = '1' then
        data_clked  <= data_in;
        data_start_clked <= data_start_in;
        data_valid_clked <= data_valid_in;
      end if;
    end if;
  end process;
    
  start <= '1' when (data_valid_clked = '0') and (data_valid_in = '1')
    else '1' when data_start_in = '1' 
    else '0';

  stop <= '1' when data_valid_in = '0' 
    else '0';
  
  sm: process(clk_in)
  begin 
    if rising_edge(clk_in) then
      if rst_in = '1' then
        packet_sm <= idle;
        restart <= '0';
      else
        if clken = '1' then
          case packet_sm is
          when idle =>
            if start = '1' then
              packet_sm <= pkt_begin;
            end if;
          when pkt_begin => 
            packet_sm <= pkt_middle;
            delay <= 5;
          when pkt_middle => 
            if delay = 0 then
              packet_sm <= pkt_end;
              restart <= '1';
            else
              delay <= delay - 1;
            end if;
          when pkt_end => 
            restart <= '0';
            if stop = '1' then 
              packet_sm <= idle;
            else
              packet_sm <= pkt_begin;
            end if;  
          end case;
        end if;
      end if;
    end if;
  end process;

  crc_data <= data_in(7 downto 0) & data_clked(15 downto 8);
  crc_rst <= start or restart;
  
  ---------------------------------------------------------------------------
  -- CRC methods
  ---------------------------------------------------------------------------
    
  ucrc_inst: ucrc_par
  generic map (
    POLYNOMIAL => "00000111",
    INIT_VALUE => "11111111",
    DATA_WIDTH => 16,
    SYNC_RESET => 1)
  port map(
    clk_i => clk_in,
    rst_i => crc_rst,
    clken_i => clken_clked,
    data_i => crc_data,
    match_o => open,
    crc_o => crc_word);
  
  ---------------------------------------------------------------------------
  -- Outputs
  ---------------------------------------------------------------------------
  
  data_out <= x"f7f7" when clken_clked = '0'
    -- else data_in_clked2 when packet_sm_clked = pkt_begin
    -- Force comma until software catches up
    else (data_clked(15 downto 8) & x"BC") when packet_sm = pkt_begin
    else data_clked when packet_sm = pkt_middle
    else (crc_word & data_clked(7 downto 0)) when packet_sm = pkt_end
    else x"50BC";

  charisk_out <= "11" when clken_clked = '0'
    -- else data_in_clked when packet_sm_clked = pkt_begin
    -- Force comma until software catches up
    else "01" when packet_sm = pkt_begin
    else "00" when packet_sm = pkt_middle
    else "00" when packet_sm = pkt_end
    else "01";
   
end behave;

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ucrc_pkg.all;
use work.package_utilities.all;


entity hcal_rx is
port (
  -- All the following in link clk domain
  link_rst_in: in std_logic := '1';  
  link_clk_in: in std_logic := '0';
  data_in: in std_logic_vector(15 downto 0) := (others => '0');
  charisk_in : in std_logic_vector(1 downto 0) := (others => '0');
  data_valid_out: out std_logic := '0';
  data_start_out: out std_logic := '0';
  data_out: out std_logic_vector(15 downto 0);
  pad_out: out std_logic := '0';
  -- All the following in the local clk domain
  local_rst_in: in  std_logic;
  local_clk_in: in  std_logic;
  local_clken_in: in  std_logic;
  reset_counters_in: in std_logic;
  crc_checked_cnt_out: out std_logic_vector(7 downto 0);
  crc_error_cnt_out: out std_logic_vector(7 downto 0);
  status_out: out std_logic_vector(3 downto 0));
end hcal_rx;

architecture behave of hcal_rx is

  signal crc_word: std_logic_vector(7 downto 0);
  signal data, data_clked, crc_data: std_logic_vector(15 downto 0);
  
  type type_packet_sm is (idle, pkt_begin, pkt_middle, pkt_end);
  signal packet_sm: type_packet_sm;
  
  signal clken, clken_clked: std_logic;
  signal start, valid: std_logic;
  signal crc_rst: std_logic := '1';
  signal delay: natural;
  
  signal crc_error, crc_valid, crc_check: std_logic;
  signal crc_error_cnt, crc_checked_cnt: unsigned(7 downto 0);   
  signal crc_error_local_clk, crc_check_local_clk: std_logic;
  signal charisk, charisk_clked : std_logic_vector(1 downto 0);

 
begin

  -- Can only detect packet start after 1st 2 words.
  start <= '1' when charisk_in = "00" and charisk = "01" else '0';
  clken <= '0' when charisk_in = "11" else '1';

  buf: process(link_clk_in)
  begin
    if rising_edge(link_clk_in) then
      clken_clked <= clken;
      if clken = '1' then
        -- Need to buf data because cannot immediately detect start 
        charisk <= charisk_in;
        data <= data_in;
        data_clked <= data;
        charisk <= charisk_in;
        charisk_clked <= charisk;
        crc_check <= crc_valid;
      end if;
    end if;
  end process;                   
  
  sm: process(link_clk_in)
  begin 
    if rising_edge(link_clk_in) then
      if link_rst_in = '1' then
        packet_sm <= idle;
      else
        if clken = '1' then
          case packet_sm is
          when idle =>
            if start = '1' then
              packet_sm <= pkt_begin;
            end if;
          when pkt_begin => 
            packet_sm <= pkt_middle;
            delay <= 5;
          when pkt_middle => 
            if delay = 0 then
              packet_sm <= pkt_end;
            else
              delay <= delay - 1;
            end if;
          when pkt_end => 
            if start = '0' then 
              packet_sm <= idle;
            else
              packet_sm <= pkt_begin;
            end if;  
          end case;
        end if;
      end if;
    end if;
  end process;

  crc_data <= data(7 downto 0) & data_clked(15 downto 8);
  crc_rst <= start;
  
  ---------------------------------------------------------------------------
  -- CRC methods
  ---------------------------------------------------------------------------
    
  ucrc_inst: ucrc_par
  generic map (
    POLYNOMIAL => "00000111",
    INIT_VALUE => "11111111",
    DATA_WIDTH => 16,
    SYNC_RESET => 1)
  port map(
    clk_i => link_clk_in,
    rst_i => crc_rst,
    clken_i => clken_clked,
    data_i => crc_data,
    match_o => open,
    crc_o => crc_word);

  ---------------------------------------------------------------------------
  -- Error detection & counters
  -------------------------------------------------------------------------

  crc_valid <= '1' when packet_sm = pkt_end else '0';

  process(link_rst_in, link_clk_in)
  begin
    if rising_edge(link_clk_in) then
      if link_rst_in = '1' then
        crc_error <= '0';
      else
        if clken = '1' then
          if crc_valid = '1' then
            -- check crc 
            if crc_word /= data_clked(15 downto 8) then
              crc_error <= '1';
            else
              crc_error <= '0';
            end if;
          else
            crc_error <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  
  crc_valid_cdc: async_pulse_sync
  port map(
      async_pulse_in => crc_check,
      sync_clk_in => local_clk_in,
      sync_pulse_out => open,
      sync_pulse_sgl_clk_out => crc_check_local_clk);  

  
  crc_error_cdc: async_pulse_sync
  port map(
      async_pulse_in => crc_error,
      sync_clk_in => local_clk_in,
      sync_pulse_out => open,
      sync_pulse_sgl_clk_out => crc_error_local_clk);  

  
  -- No clken here.  Just counters. No sync to incoming data.  
  status_counters: process(local_rst_in, local_clk_in)
  begin
    if rising_edge(local_clk_in) then
      if local_rst_in = '1' or reset_counters_in = '1' then
        crc_error_cnt <= (others => '0');
        crc_checked_cnt <= (others => '0');
      else
        if crc_error_local_clk = '1' and crc_error_cnt /= X"ff" then
          crc_error_cnt <= crc_error_cnt + 1;
        end if;
        if crc_check_local_clk = '1' and crc_checked_cnt /= X"ff" then
          crc_checked_cnt <= crc_checked_cnt + 1;
        end if;
      end if;
    end if;
  end process;
    
  
  ---------------------------------------------------------------------------
  -- Outputs
  ---------------------------------------------------------------------------
  
  valid <= '1' when start = '1' 
    else '1' when packet_sm = pkt_begin
    else '1' when packet_sm = pkt_middle
    else '0';
  
  pad_out <= not clken;
  data_valid_out <= valid;
  data_start_out <= start;
  data_out <= data;
  
  crc_error_cnt_out <= std_logic_vector(crc_error_cnt);
  crc_checked_cnt_out <= std_logic_vector(crc_checked_cnt);
  status_out <= (others => '0');

end behave;

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
USE work.mp7_data_types.all;
	
entity ecal_tx is
port (
  rst_in: in std_logic := '1';  
  clk_in: in std_logic := '0';
  data_in: in std_logic_vector(15 downto 0) := (others => '0');
  data_valid_in: in std_logic := '0';
  data_start_in: in std_logic := '0';
  data_out: out std_logic_vector(15 downto 0);
  data_valid_out: out std_logic);
end ecal_tx;

architecture behave of ecal_tx is

  signal link_inc_ham_code, link_exc_ham_code: lword := LWORD_NULL;
  
begin

  link_exc_ham_code.data <= x"0000" & data_in;
  link_exc_ham_code.valid <= data_valid_in;
  link_exc_ham_code.start <= data_start_in;
  link_exc_ham_code.strobe <= '1';
  
  ---------------------------------------------------------------------------
  -- CRC methods
  ---------------------------------------------------------------------------

  oslb_inst: entity work.oslb
  port map ( 
    clk => clk_in,
    link_in => link_exc_ham_code,
    link_out => link_inc_ham_code,
    hamming_error_out => open,
    region_out => open);

  ---------------------------------------------------------------------------
  -- Outputs
  ---------------------------------------------------------------------------
  
  data_out <= link_inc_ham_code.data(15 downto 0);
  data_valid_out <= link_inc_ham_code.valid;
   
end behave;

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.mp7_data_types.all;
use ieee.numeric_std.all;


entity ecal_rx is
port (
  rst_in: in std_logic := '1';  
  clk_in: in std_logic := '0';
  data_in: in std_logic_vector(15 downto 0);
  data_valid_in: in std_logic;
  data_out: out std_logic_vector(15 downto 0) := (others => '0');
  data_valid_out: out std_logic := '0';
  data_start_out: out std_logic := '0';
  reset_counters_in: in std_logic;
  hamming_checked_cnt_out: out std_logic_vector(7 downto 0);
  hamming_error_cnt_out: out std_logic_vector(7 downto 0);
  status_out: out std_logic_vector(3 downto 0));
end ecal_rx;

architecture behave of ecal_rx is

  signal link: lword := LWORD_NULL;
  signal hamming_error, hamming_check: std_logic;
  
  signal hamming_error_cnt, hamming_checked_cnt: unsigned(7 downto 0);   
  
begin

  link.data(15 downto 0) <= data_in;
  link.data(31 downto 16) <= x"0000";
  link.valid <= data_valid_in;
  link.start <= '0';
  link.strobe <= '1';
  
  ---------------------------------------------------------------------------
  -- hamming methods
  ---------------------------------------------------------------------------

  oslb_inst: entity work.oslb
  port map ( 
    clk => clk_in,
    link_in => link,
    link_out => open,
    hamming_error_out => hamming_error,
    hamming_check_out => hamming_check,
    region_out => open);

  ---------------------------------------------------------------------------
  -- Error detection & counters
  ---------------------------------------------------------------------------

  status_counters: process(rst_in, clk_in)
  begin
    if rising_edge(clk_in) then
      if rst_in = '1' or reset_counters_in = '1' then
        hamming_error_cnt <= (others => '0');
        hamming_checked_cnt <= (others => '0');
      else
        if hamming_error = '1' and hamming_error_cnt /= X"ff" then
          hamming_error_cnt <= hamming_error_cnt + 1;
        end if;
        if hamming_check = '1' and hamming_checked_cnt /= X"ff" then
          hamming_checked_cnt <= hamming_checked_cnt + 1;
        end if;
      end if;
    end if;
  end process;
  
  ---------------------------------------------------------------------------
  -- Outputs
  ---------------------------------------------------------------------------

  data_out <= link.data(15 downto 0);
  data_valid_out <= link.valid;
  data_start_out <= link.start;

  hamming_error_cnt_out <= std_logic_vector(hamming_error_cnt);
  hamming_checked_cnt_out <= std_logic_vector(hamming_checked_cnt);

  status_out <= (others => '0');

end behave;

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
