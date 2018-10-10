-- amc13_link (simulation version)
--
-- Do-nothing replacement for AMC13 interface for simulation purposes
-- To emulate AMC13 readout, use the auto empty feature of the ro_buffer with appropriate settings
--
-- Dave Newbold, August 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity amc13_link is
	port(
		clk: in std_logic; -- ipb clock (also used as sysclk for reset SMs, etc)
		rst: in std_logic; -- ipb reset
		gt_refclk: in std_logic; -- GTH refclk
		clk_p: in std_logic; -- data clock
		data: in std_logic_vector(63 downto 0); -- data to transmit
		valid: in std_logic; -- data valid flag
		hdr: in std_logic; -- header flag
		trl: in std_logic; -- trailer flag
		warn: out std_logic; -- buffer warning signal
		ready: out std_logic; -- ready signal
		clk_tts: in std_logic; -- TTS clock (40MHz)
		tts: in std_logic_vector(3 downto 0); -- TTS status
		debug: out std_logic_vector(27 downto 0);
		resync_empty: in std_logic
);

end amc13_link;

architecture behavioural of amc13_link is

begin

	warn <= '0';
	ready <= '1';
	debug <= X"a000000";

end behavioural;
