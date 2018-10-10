-- tts_sm
--
-- The TTS state machine
--
-- Dave Newbold, November 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

entity tts_sm is
	port(
		clk: in std_logic;
		rst: in std_logic;
		tts: out std_logic_vector(3 downto 0);
		resync: in std_logic;
		resync_pend: in std_logic;
		rdy: in std_logic;
		src_warn: in std_logic;
		src_err: in std_logic;
		rob_warn: in std_logic;
		rob_err: in std_logic;
		amc13_rdy: in std_logic;
		trig_err: in std_logic;
		throttle: out std_logic;
		uptime_ctr: out std_logic_vector(63 downto 0);
		busy_ctr: out std_logic_vector(63 downto 0);
		ready_ctr: out std_logic_vector(63 downto 0);
		warn_ctr: out std_logic_vector(63 downto 0);
		oos_ctr: out std_logic_vector(63 downto 0)		
	);

end tts_sm;

architecture rtl of tts_sm is

	type state_type is (ST_BUSY, ST_READY, ST_WARN, ST_OOS, ST_ERR);
	signal state: state_type;
	signal resync_ctr: unsigned(5 downto 0);
	signal resync_done, ready, warn, oos, err: std_logic;
	signal uptime_ctr_i, busy_ctr_i, ready_ctr_i, warn_ctr_i, oos_ctr_i: unsigned(63 downto 0);

begin

	ready <= rdy and amc13_rdy and resync_done;
	warn <= rob_warn or src_warn;
	oos <= src_err or rob_err;

	process(clk)
	begin
		if rising_edge(clk) then
		
			if rst = '1' or resync_pend = '1' or ready = '0' then
				state <= ST_BUSY;
			else
				case state is

				when ST_BUSY => -- Hang on a mo
				
					if ready = '1' then
						state <= ST_READY;
					end if;
	
				when ST_READY => -- Let's go
				
					if warn = '1' then
						state <= ST_WARN;
					elsif oos = '1' then
						state <= ST_OOS;
					elsif err = '1' then
						state <= ST_ERR;
					end if;

				when ST_WARN => -- Whoa, slow down egghead
				
					if warn = '0' then
						state <= ST_READY;
					elsif oos = '1' then
						state <= ST_OOS;
					elsif err = '1' then
						state <= ST_ERR;
					end if;

				when others => -- I warned you... stuck now...
				
				end case;
			end if;
		end if;
	end process;
	
-- Resync counter (leave a long delay after resync or reset to get everything lined up)

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or resync = '1' then
				resync_ctr <= (others => '0');
			elsif resync_ctr /= "111111" then
				resync_ctr <= resync_ctr + 1;
			end if;
		end if;
	end process;
	
	resync_done <= and_reduce(std_logic_vector(resync_ctr));
	
-- TTS encoding

	with state select tts <=
		"0100" when ST_BUSY,
		"1000" when ST_READY,
		"0001" when ST_WARN,
		"0010" when ST_OOS,
		"1100" when others;
		
	throttle <= '1' when state /= ST_READY else '0';
	
-- Counters

	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' or resync = '1' then
				uptime_ctr_i <= (others => '0');
				busy_ctr_i <= (others => '0');
				ready_ctr_i <= (others => '0');
				warn_ctr_i <= (others => '0');
				oos_ctr_i <= (others => '0');
			else
				uptime_ctr_i <= uptime_ctr_i + 1;
				if state = ST_BUSY then
					busy_ctr_i <= busy_ctr_i + 1;
				end if;
				if state = ST_READY then
					ready_ctr_i <= ready_ctr_i + 1;
				end if;
				if state = ST_WARN then
					warn_ctr_i <= warn_ctr_i + 1;
				end if;
				if state = ST_OOS then
					oos_ctr_i <= oos_ctr_i + 1;
				end if;					
			end if;
		end if;
	end process;
	
	uptime_ctr <= std_logic_vector(uptime_ctr_i);
	busy_ctr <= std_logic_vector(busy_ctr_i);
	ready_ctr <= std_logic_vector(ready_ctr_i);
	warn_ctr <= std_logic_vector(warn_ctr_i);
	oos_ctr <= std_logic_vector(oos_ctr_i);

end rtl;
