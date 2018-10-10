

-- Bizarre reset requirements from Xilinx.  
-- Shouldn't this be handled inside FIFO?
-- It is a lot of extra code for each FIFO.
-- It also relies on a state machine that might
-- go belly up with a dodgy clk that may occur 
-- during rest.

-- Never tested.  Decided far too complex.
-- Reset signals will be held for > 5 clk
-- periods anyway.  

library ieee;
use ieee.std_logic_1164.all;

entity fifo_rst is
  port (
    clk_in: in std_logic;
    rst_in: in std_logic;
    veto_out: out std_logic;
    rst_out: out std_logic
  );
end entity fifo_rst;

architecture behave of fifo_rst is

  type type_rst_state is (DEFAULT,RESET,RECOVER);
  signal rst_state: type_rst_state;
  signal delay: integer range 0 to 7;
  
  begin

    wr_clk_rst_proc: process(clk_in)
      if rising_edge(clk_in) then
        case rst_state is
          when DEFAULT =>
            if rst_in = '1' then
              -- Must disable fifo_wr_en enable 1 clk before reset
              veto_out <= '1';
              rst_out <= '0';
              rst_state = RESET;
              delay <= 7;
            end if;
          when RESET =>
            -- Must stay in rst for 5 RD & WR clock cycles
            rst_out <= '1';
            if delay = 0 then
              rst_out = '0';
              rst_state <= RECOVER;
              delay <= 2;
            else
              delay <= delay - 1;
            end if;
          when RECOVER =>
            -- Must keep wr_en/rd_en disabled for 2 RD & WR clock cycles after reset.
            if delay = 0 then
              veto_out <= '0';
              rst_state <= DEFAULT;
              delay <= 2;
            else
              delay <= delay - 1;
            end if;
          when others =>
              rst_state <= DEFAULT;
        end case;
      end if;
    end process
          
  end architecture behave;
