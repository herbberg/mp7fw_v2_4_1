-- mp7_formatter
--
-- Formatter block for algo data
--
-- ctrl(0)(0): enable header stripping
-- ctrl(0)(1): enable header insertion
-- ctrl(0)(2): inserted header info from incoming hdr (0) or bx counter (1)
-- ctrl(0)(3): control datavalid from ttc
-- ctrl(0)(31:24): source ID
-- ctrl(0)(23:16): dest ID

-- ctrl(1)(0): enable data valid signal from the payload to be over-ridden
-- ctrl(1)(3:1): sub-bx start of datavalid 
-- ctrl(1)(15:4): bx start of datavalid 
-- ctrl(1)(18:16): sub-bx stop of datavalid 
-- ctrl(1)(30:19): bx stop of datavalid 
-- ctrl(1)(31): enable 
--
-- NB: strobe is not implemented yet
--
-- Dave Newbold, July 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.mp7_data_types.all;
use work.mp7_ttc_decl.all;
use work.ipbus_reg_types.all;

entity mp7_formatter_demux is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		board_id: in std_logic_vector(7 downto 0);
		clk_p: in std_logic; -- data clock and reset
		rst_p: in std_logic;
		bctr: in bctr_t; -- local bunch counter
		pctr: in pctr_t; -- local sub-bunch counter
		d_buf: in ldata(3 downto 0); -- data in from buffers
		q_payload: out ldata(3 downto 0); -- data out to algo
		d_payload: in ldata(3 downto 0); -- data in from algo
		q_buf: out ldata(3 downto 0) -- data out to buffers
	);
		
end mp7_formatter_demux;

architecture rtl of mp7_formatter_demux is

	signal ctrl, stat: ipb_reg_v(1 downto 0);
	signal q_buf_int: ldata(3 downto 0);
	signal q_buf_ctrl: std_logic_vector(1 downto 0);
	
begin
	
-- Control register

	ctrlreg: entity work.ipbus_reg_v
		generic map(
			N_REG => 2
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			q => ctrl,
			qmask(0) => X"ffff0007",
			qmask(1) => X"7fffffff"
		);

-- Per-channel formatter block
		
	cgen: for i in 3 downto 0 generate

		signal q: lword;
		signal bx: std_logic_vector(11 downto 0);
		signal tag, hword, valid, valid_d, dvalid_d: std_logic;
		signal local_hword, local_valid, local_valid_d: std_logic;

		attribute mark_debug :string;
		attribute keep : string;
		attribute mark_debug of local_valid, local_valid_d : signal is "true";
			
	begin

-- Header stripping and capture
	
		q_payload(i).data <= d_buf(i).data;
		q_payload(i).strobe <= d_buf(i).strobe;
		q_payload(i).valid <= valid;
		q_payload(i).start <= valid and not valid_d;
	
		valid <= d_buf(i).valid when ctrl(0)(0) = '0' else d_buf(i).valid and dvalid_d;
		
		process(clk_p)
		begin
			if rising_edge(clk_p) then
				if d_buf(i).strobe = '1' then

					dvalid_d <= d_buf(i).valid;
					valid_d <= valid;

					if d_buf(i).valid = '1' and dvalid_d = '0' then
						if ctrl(0)(2) = '0' then
							bx <= d_buf(i).data(11 downto 0);
							tag <= d_buf(i).data(12);
						else
							bx <= bctr;
							tag <= not or_reduce(bctr);
						end if;
					end if;
					
				end if;
			end if;
		end process;

-- Header insertion
		
		process(clk_p)
		begin
			if rising_edge(clk_p) then
				if d_payload(i).strobe = '1' then
					q <= d_payload(i);
				end if;
			end if;
		end process;

		hword <= '1' when d_payload(i).valid = '1' and q.valid = '0' else '0'; 

	
		process(clk_p)
		begin
				if rising_edge(clk_p) then
						-- Create local outgoing data-valid signal independent of incoming data.  
						-- This allows systems to come up in parallel (i.e. each system can 
						-- have links sending commas & alignment data before full sys ready)
						-- It does require user to understand incoming data position & therefore 
						-- calulate outgoing position. 
						if (bctr = ctrl(1)(15 downto 4)) and  (pctr = ctrl(1)(3 downto 1)) then
								-- Start valid
								local_valid <= '1';
						elsif (bctr = ctrl(1)(30 downto 19)) and  (pctr = ctrl(1)(18 downto 16)) then
								-- Stop valid
								local_valid <= '0';
						end if;
						local_valid_d <= local_valid;
				end if;
		end process;

		local_hword <= '1' when local_valid = '1' and local_valid_d = '0' else '0'; 

		q_buf_ctrl <= ctrl(1)(0) & ctrl(0)(1);
		
		process(q_buf_ctrl, d_payload, q, tag, bx, hword, local_hword, local_valid, local_valid_d)
		begin
			case q_buf_ctrl is
			when "00" =>
				-- No DataValid over-ride. No Hdr
				q_buf_int(i) <= d_payload(i);
			when "01" =>
				-- No DataValid over-ride. Hdr
				if hword = '1' then
					q_buf_int(i).data <= ctrl(0)(31 downto 16) & "000" & tag & bx;
				else 
					q_buf_int(i).data <= q.data;
				end if;
				q_buf_int(i).strobe <= d_payload(i).strobe;
				q_buf_int(i).valid <= hword or q.valid;
				q_buf_int(i).start <= '0';
			when "10" =>
				-- DataValid over-ride. No hdr
				q_buf_int(i).data <= d_payload(i).data;
				q_buf_int(i).strobe <= d_payload(i).strobe;
				q_buf_int(i).valid <= local_valid;
				q_buf_int(i).start <= '0';
			when others =>
				-- DataValid over-ride. Hdr.
				-- No need to delay data.  Advance hdr by 1 clk cycle.
				if local_hword = '1' then
					q_buf_int(i).data <= ctrl(0)(31 downto 16) & "000" & '0' & bx;
				else
					q_buf_int(i).data <= d_payload(i).data;
				end if;
				q_buf_int(i).strobe <= d_payload(i).strobe;
				q_buf_int(i).valid <= local_valid or local_valid_d;
				q_buf_int(i).start <= '0';
			end case;
		end process;
		
		q_buf(i) <= q_buf_int(i);

	end generate;

end rtl;
