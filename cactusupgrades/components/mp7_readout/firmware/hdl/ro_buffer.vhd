-- ro_buffer
--
-- Interface between the daq bus and the AMC13, including event buffer FIFO
--
-- Dave Newbold, August 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.mp7_readout_decl.all;
use work.top_decl.all;

entity ro_buffer is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		hwm: in std_logic_vector(7 downto 0);
		lwm: in std_logic_vector(7 downto 0);
		clk_p: in std_logic;
		rst_p: in std_logic;
		resync: in std_logic;
		auto_empty: in std_logic;
		ro_rate: in std_logic_vector(3 downto 0);
		daq_bus_in: in daq_bus;
		amc13_en: in std_logic;
		amc13_data: out std_logic_vector(63 downto 0);
		amc13_valid: out std_logic;
		amc13_hdr: out std_logic;
		amc13_trl: out std_logic;
		amc13_warn: in std_logic;
		amc13_rdy: in std_logic;
		err: out std_logic;
		warn: out std_logic;
		empty: out std_logic;
		done: out std_logic;
		evt_cnt: out std_logic_vector(31 downto 0);
		rob_last: in std_logic
	);

end ro_buffer;

architecture rtl of ro_buffer is

	signal rsti, fifo_valid, fifo_wen, fifo_ren, fifo_full, fifo_warn, fifo_empty: std_logic;
	signal amc13_cyc, amc13_rdy_i, amc13_warn_i: std_logic;
	signal ctr: unsigned(15 downto 0);
	signal l1aid: std_logic_vector(7 downto 0);
	type state_type is (ST_IDLE, ST_HDR, ST_HDR2, ST_DATA, ST_LAST_STROBE, ST_TRL);
	signal state: state_type;
	signal fifo_d, fifo_q: std_logic_vector(71 downto 0);
	signal fifo_d_data, fifo_d_trl: std_logic_vector(67 downto 0);
	signal fifo_ctr: std_logic_vector(17 downto 0);
	signal d: std_logic_vector(33 downto 0);
	signal fifo_data: std_logic_vector(31 downto 0);
	signal ctr_ipb: unsigned(1 downto 0);
	signal ack, fcyc, ipb_rd, s1, s2, s3, trl, trl_d, done_i: std_logic;
	signal auto_cyc: std_logic;
	signal auto_ctr: unsigned(3 downto 0) := X"0";
	signal evt_cnt_i: unsigned(31 downto 0);
	
	attribute SHREG_EXTRACT: string;
	attribute SHREG_EXTRACT of s1: signal is "no"; -- Synchroniser not to be optimised into shreg

begin

-- reset

	rsti <= resync or rst_p when rising_edge(clk_p);
	
-- readout state machine

	process(clk_p)
	begin
		if rising_edge(clk_p) then
		
			if rsti = '1' then
				state <= ST_IDLE;
			else
				case state is

				when ST_IDLE => -- Starting state
					if fifo_full = '0' and daq_bus_in.data.strobe = '1' and daq_bus_in.data.start = '1' then
						state <= ST_HDR;
					end if;

				when ST_HDR => -- Send first header word
					if daq_bus_in.data.strobe = '1' and ctr = to_unsigned(1, 16) then
						state <= ST_HDR2;
					end if;

				when ST_HDR2 => -- Send remaining header words
					if daq_bus_in.data.strobe = '1' and ctr = to_unsigned(DAQ_N_HDR_WORDS - 1, 16) then
						state <= ST_DATA;
					end if;
				
				when ST_DATA => -- Send data
					if daq_bus_in.token = '1' and rob_last = '1' then
              --if ctr(0) = '0' then
              -- ctr is increased when state /= idle. When the token comes back there are 2 cases 
              -- a. strobe = '1', ctr is still counting. Will reflect the correct value on the next cycle. 
              -- b. strobe = '0', ctr is up to date, can be used. if ctr(0) is odd, d contains parked data 
          if ( ctr(0) = '0' and daq_bus_in.data.strobe = '0' ) or ( ctr(0) = '1' and daq_bus_in.data.strobe = '1' ) then 
							state <= ST_TRL;
						else
							state <= ST_LAST_STROBE;
						end if;
					end if;

				when ST_LAST_STROBE => -- Extra data word if odd number of 32b words from readout bus
					state <= ST_TRL;

				when ST_TRL => -- Send data
					state <= ST_IDLE;

				end case;
			end if;
		end if;
	end process;

	process(clk_p)
	begin
		if rising_edge(clk_p) then
			if rsti = '1' or state = ST_TRL then
				ctr <= (others => '0');
			elsif (daq_bus_in.data.strobe = '1' and state /= ST_IDLE) or daq_bus_in.data.start = '1' then
				ctr <= ctr + 1;
   			    d <= daq_bus_in.data.start & daq_bus_in.data.valid & daq_bus_in.data.data;
        elsif state = ST_LAST_STROBE then
            ctr <= ctr + 1;
			end if;
			if ctr = to_unsigned(1, 15) and daq_bus_in.data.strobe = '1' then
				l1aid <= daq_bus_in.data.data(7 downto 0); -- Grab L1A ID for use in trailer
			end if;
		end if;
	end process;

-- AMC13 64b word (plus debug flags) for header / data
	
	fifo_d_data(67) <= daq_bus_in.data.start;
	fifo_d_data(66) <= daq_bus_in.data.valid;
	fifo_d_data(65) <= d(33);
	fifo_d_data(64) <= d(32);
	fifo_d_data(63 downto 32) <= daq_bus_in.data.data when state /= ST_LAST_STROBE else X"FFFFFFFF";
	fifo_d_data(31 downto 0) <= d(31 downto 0);
	
-- AMC13 64b word for trailer
	
	fifo_d_trl(67 downto 64) <= "0000"; -- flags
	fifo_d_trl(63 downto 32) <= X"00000000"; -- replaced by CRC32 in AMC13 block
	fifo_d_trl(31 downto 0) <= l1aid & "0000" & "00000" & std_logic_vector(ctr(15 downto 1)+1);
	
-- event buffer FIFO

	fifo_d(71) <= '1' when state = ST_HDR else '0'; -- header flag
	fifo_d(70) <= '1' when state = ST_TRL else '0'; -- trailer flag
	fifo_d(69 downto 68) <= "00"; -- not used 
	fifo_d(67 downto 0) <= fifo_d_data when state /= ST_TRL else fifo_d_trl;
	fifo_wen <= '1' when (daq_bus_in.data.strobe = '1' and ctr(0) = '1') or state = ST_TRL or state = ST_LAST_STROBE else '0';

	fifo: entity work.big_fifo_72
		generic map(
			N_FIFO => RO_CHUNKS
		)
		port map(
			clk => clk_p,
			rst => rsti,
			d => fifo_d,
			wen => fifo_wen,
			empty => fifo_empty,
			full => fifo_full,
			ctr => fifo_ctr,
			ren => fifo_ren,
			q => fifo_q,
			valid => fifo_valid
		);

	fifo_ren <= amc13_cyc or ipb_rd or auto_cyc;

-- Warning logic

	process(clk_p)
	begin
		if rising_edge(clk_p) then
			if rsti = '1' then
				fifo_warn <= '0';
			elsif unsigned(fifo_ctr(15 downto 8)) > unsigned(hwm) then
				fifo_warn <= '1';
			elsif unsigned(fifo_ctr(15 downto 8)) < unsigned(lwm) then
				fifo_warn <= '0';
			end if;
		end if;
	end process;
	
-- Auto-empty logic (for testing)

	auto_ctr <= auto_ctr + 1 when rising_edge(clk_p);
	auto_cyc <= '1' when auto_empty ='1' and auto_ctr <= unsigned(ro_rate) else '0'; -- Approx 1Gb/s per ro_rate notch

-- ipbus test interface

	with ipb_in.ipb_addr(1 downto 0) select ipb_out.ipb_rdata <=
		X"000000" & "00" & std_logic_vector(to_unsigned(RO_CHUNKS, 6)) when "00",
		X"0" & fifo_empty & fifo_full & fifo_warn & fifo_valid & "000000" & fifo_ctr when "01",
		fifo_data when "10",
		X"00000000" when others
	;
	
	with ctr_ipb select fifo_data <=	
		fifo_q(31 downto 0) when "00",
		fifo_q(63 downto 32) when "01",
		X"000000" & fifo_q(71 downto 64) when others;
		
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				ctr_ipb <= "00";
			elsif ack = '1' then
				if ctr_ipb = "10" then
					ctr_ipb <= "00";
				else
					ctr_ipb <= ctr_ipb + 1;
				end if;
			end if;
			if ack = '1' and ctr_ipb = "10" then
				fcyc <= '1';
			else
				fcyc <= '0';
			end if;
		end if;
	end process;

	-- Bit 1, data
	ack <= ipb_in.ipb_strobe and ipb_in.ipb_addr(1) and not fcyc;

	-- Bit 0, fifos and statics
    ipb_out.ipb_ack <= ack or (ipb_in.ipb_strobe and not ipb_in.ipb_addr(1));
	ipb_out.ipb_err <= '0';
		
	process(clk_p) -- synchroniser, CDC point
	begin
		if rising_edge(clk_p) then
			s1 <= fcyc; -- CDC, unrelated clocks
			s2 <= s1;
			s3 <= s2;
		end if;
	end process;
		
	ipb_rd <= s2 and not s3;

-- AMC13 interface

	process(clk_p)
	begin
		if rising_edge(clk_p) then
			amc13_data <= fifo_q(63 downto 0);
			amc13_valid <= amc13_cyc;
			amc13_hdr <= fifo_q(71);
			amc13_trl <= fifo_q(70);
			amc13_rdy_i <= amc13_rdy;
			amc13_warn_i <= amc13_warn;
		end if;
	end process;

	amc13_cyc <= amc13_rdy_i and not amc13_warn_i and amc13_en and fifo_valid; -- CDC (on amc13_en), unrelated clocks
	
-- status flags
	
	process(clk_p)
  begin
    if rising_edge(clk_p) then
      -- Clked to remove timing error on err(fifo_full).
      -- Decided to include all status signals
      err <= fifo_full;
      warn <= fifo_warn;
      empty <= fifo_empty;
      done <= done_i;
    end if;
  end process;	
		
	trl <= fifo_valid and fifo_ren and fifo_q(70);
	
	process(clk_p)
	begin
		if rising_edge(clk_p) then
			trl_d <= trl;
			if rsti = '1' then
				evt_cnt_i <= (others => '0');
			elsif trl = '1' then
				evt_cnt_i <= evt_cnt_i + 1;
			end if;
			done_i <= ((done_i or (trl_d and fifo_empty)) and fifo_empty) or rsti; 
		end if;
	end process;
	
	evt_cnt <= std_logic_vector(evt_cnt_i);


end rtl;
