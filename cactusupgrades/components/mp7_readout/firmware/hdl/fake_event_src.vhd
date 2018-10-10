-- fake_event_src
--
-- Interface between the daq bus and the AMC13, including event buffer FIFO
--
-- Dave Newbold, August 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.VComponents.all;

use work.mp7_readout_decl.all;
use work.mp7_ttc_decl.all;
use work.top_decl.all;
use work.mp7_top_decl.all;

entity fake_event_src is
	generic(
		USER_DATA: std_logic_vector(31 downto 0)
	);
	port(
		board_id: in std_logic_vector(15 downto 0);
		evt_size: in std_logic_vector(11 downto 0);
		ttc_clk: in std_logic;
		resync: in std_logic;
		l1a: in std_logic;
		l1a_flag: in std_logic;
		bunch_ctr: in bctr_t;
		evt_ctr: in eoctr_t;
		orb_ctr: in eoctr_t;
		clk_p: in std_logic;
		rst_p: in std_logic;
		throttle: in std_logic;
		daq_bus_out: out daq_bus; -- DAQ daisy-chain bus
		daq_bus_in: in daq_bus;
		err: out std_logic;
		rob_last: out std_logic;
		done: out std_logic
	);

end fake_event_src;

architecture rtl of fake_event_src is

	signal rsti, l1a_d, fifo_wen, fifo_ren, fifo_full, fifo_empty: std_logic;
	signal fifo_d, fifo_q: std_logic_vector(63 downto 0);
	type state_type is (ST_IDLE, ST_HDR, ST_DATA);
	signal state: state_type;
	signal hdr_done, data_done: std_logic;
	signal ctr: unsigned(12 downto 0);
	signal hdr_word: std_logic_vector(31 downto 0);
	signal rst_ctr: unsigned(2 downto 0);

begin

-- reset

	process(clk_p)
	begin
		if rising_edge(clk_p) then
			if resync = '1' then
				rst_ctr <= "000";
				rsti <= '1';
			elsif rst_ctr < "111" then
				rst_ctr <= rst_ctr + 1;
				rsti <= '1';
			else
                rsti <= '0';
			end if;
		end if;
	end process;
	
	-- Timing failure in Viv 2016.1.  Rewrote reset (see above).
	-- There are jumps from 240MHz to 40MHz domain 
	-- that should be reg to reg due to clk uncertainty.
	-- rsti <= '0' when rst_ctr = "111" else '1';

-- trigger FIFO
	
	process(ttc_clk)
	begin
		if rising_edge(ttc_clk) then
			l1a_d <= l1a;
		end if;
	end process;
	
	fifo_wen <= l1a and not l1a_d and not rsti;
	fifo_d <= "000" & l1a_flag & evt_ctr(23 downto 0) & orb_ctr(23 downto 0) & bunch_ctr;
	
	trig_fifo: FIFO36E1
		generic map(
			DATA_WIDTH => 72,
			FIFO_MODE => "FIFO36_72"
		)
		port map(
			di => fifo_d,
			dip => X"00",
			do => fifo_q,
			empty => fifo_empty,
			full => fifo_full,
			injectdbiterr => '0',
			injectsbiterr => '0',
			rdclk => clk_p,
			rden => fifo_ren,
			regce => '1',
			rst => rsti,
			rstreg => '0',
			wrclk => ttc_clk,
			wren => fifo_wen
		);

-- readout state machine

	process(clk_p)
	begin
		if rising_edge(clk_p) then
		
			if rsti = '1' then
				state <= ST_IDLE;
			else
				case state is

				when ST_IDLE =>  -- Starting state
					if fifo_empty = '0' and fifo_full = '0' and throttle = '0' then
						state <= ST_HDR;
					end if;

				when ST_HDR => -- Send header words
					if hdr_done = '1' then
						if fifo_q(60) = '0' then
							state <= ST_DATA;
						else
							state <= ST_IDLE;
						end if;
					end if;
				
				when ST_DATA => -- Send data
					if data_done = '1' then
						state <= ST_IDLE;
					end if;

				end case;
			end if;
		end if;
	end process;
	
	hdr_done <= '1' when ctr = to_unsigned(DAQ_N_HDR_WORDS - 1, 13) else '0';
	data_done <= '1' when ctr = unsigned(evt_size) - 2 & '1' else '0'; -- ctr counts 32b words, evt_size is in 64b units.
	
	process(clk_p)
	begin
		if rising_edge(clk_p) then
			if state = ST_IDLE then
				ctr <= (others => '0');
			else
				ctr <= ctr + 1;
			end if;
		end if;
	end process;
	
	fifo_ren <= '1' when state = ST_IDLE and fifo_empty = '0' and fifo_full = '0' and throttle = '0' and rsti = '0' else '0';

-- Output data

	with ctr(2 downto 0) select hdr_word <=
		fifo_q(11 downto 0) & X"00" & evt_size when "000",
		X"00" & fifo_q(59 downto 36) when "001",
		fifo_q(27 downto 12) & board_id when "010",
		USER_DATA when "011",
		X"00" & FW_REV WHEN "100",
        ALGO_REV WHEN "101",
		(others => '0') when others;

	with state select daq_bus_out.data.data <=
		hdr_word when ST_HDR,
		board_id & "000" & std_logic_vector(ctr) when others;
		
	daq_bus_out.data.valid <= '1' when state /= ST_IDLE else '0';
	daq_bus_out.data.start <= '1' when state = ST_HDR else '0';
	daq_bus_out.data.strobe <= '1' when state /= ST_IDLE else '0';
	
	daq_bus_out.init <= fifo_ren;
	daq_bus_out.token <= '1' when state = ST_DATA and data_done = '1' else '0';
	rob_last <= '1' when daq_bus_in.token = '1' else '0';

	err <= fifo_full;
	done <= '1' when state = ST_IDLE and fifo_empty = '1' else '0';

end rtl;
