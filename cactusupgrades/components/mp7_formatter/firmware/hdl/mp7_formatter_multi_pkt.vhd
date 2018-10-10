-- mp7_formatter
--
-- Formatter block for algo data
--
-- ctrl(0): enable header stripping
-- ctrl(1): enable header insertion
-- ctrl(2): inserted header info from incoming hdr (0) or bx counter (1)
-- ctrl(31:24): source ID
-- ctrl(23:16): dest ID
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

entity mp7_formatter_multi_pkt is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		board_id: in std_logic_vector(7 downto 0);
		clk_p: in std_logic; -- data clock and reset
		rst_p: in std_logic;
		bctr: in bctr_t; -- local bunch counter
		d_buf: in ldata(3 downto 0); -- data in from buffers
		q_payload: out ldata(3 downto 0); -- data out to algo
		d_payload: in ldata(3 downto 0); -- data in from algo
		q_buf: out ldata(3 downto 0) -- data out to buffers
	);
		
end mp7_formatter_multi_pkt;

architecture rtl of mp7_formatter_multi_pkt is

	signal ctrl, ctrl_dummy: ipb_reg_v(0 downto 0);
	signal q_out: ldata(3 downto 0);

begin
	
-- Control register

	ctrlreg: entity work.ipbus_reg_v
		generic map(
			N_REG => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			q => ctrl_dummy,  --ctrl,
			qmask(0) => X"ffff0007"
		);
		
	-- Temporarily hardcode config until software catches up.
	ctrl(0) <= x"00000003";

-- Per-channel formatter block
		
	cgen: for i in 3 downto 0 generate

		signal q: lword;
		signal bx_i, bx_o, bx_g: std_logic_vector(11 downto 0);
		signal tag_i, tag_o, tag_g, hword, valid, valid_d, dvalid_d: std_logic;
		
		
		signal f_data_i, f_data_o : std_logic_vector(17 downto 0);
		signal f_rst, f_we, f_re, f_rst_ctr_inc, f_rst_en: std_logic;
    	signal f_rst_ctr : integer range 0 to 255;


	begin

-- Header stripping and capture
	
		q_payload(i).data <= d_buf(i).data;
		q_payload(i).strobe <= d_buf(i).strobe;
		q_payload(i).valid <= valid;
		q_payload(i).start <= valid and not valid_d;
	
		valid <= d_buf(i).valid when ctrl(0)(0) = '0' else d_buf(i).valid and dvalid_d;

		bx_i <= d_buf(i).data(11 downto 0) when ctrl(0)(2) = '0' else bctr;
		tag_i <= d_buf(i).data(12) when ctrl(0)(2) = '0' else not or_reduce(bctr);
		
		process(clk_p)
		begin
			if rising_edge(clk_p) then
				if d_buf(i).strobe = '1' then
					dvalid_d <= d_buf(i).valid;
					valid_d <= valid;
				  
					if (d_buf(i).valid = '1') and (dvalid_d = '0') then
						-- Added extra pipeline register because a TMT output event now 
						-- exits after a 2nd TMT input event has entered the device. 
						-- Note that the current approach is not robust against failure 
						-- of the input channels that are also used for output
						-- (i.e. no tag or bx will be available for the output).
						
--						tag_g <= tag_i;
--						tag_o <= tag_g;
--						bx_g <= bx_i;
--						bx_o <= bx_g;
						
					end if;
					
				end if;
			end if;
		end process;

-- Fifo for storage of header
		
		f_rst_proc: process(clk_p)
		begin
			if rising_edge(clk_p) then
				-- Extra reg stage
				if d_buf(i).strobe = '1' and d_buf(i).valid = '0' then
					f_rst_ctr_inc <= '1';
				else
					f_rst_ctr_inc <= '0';
				end if;
				-- Reset fifo after large gap in packets.
				if f_rst_ctr_inc = '1' and f_rst_ctr /= 255 then 
					f_rst_ctr <= f_rst_ctr + 1;
				else 
					f_rst_ctr <= 0;
				end if; 
				--  Another reg stage to ease timing
				if f_rst_ctr = 255 then
					f_rst_en <= '1';
				else
					f_rst_en <= '0';
				end if;
			end if;
		end process;


        -- Only reg data going into fifo.  Avoids re-writing fifo exit code.
		f_reg_proc: process(clk_p)
		begin
			if rising_edge(clk_p) then
                if (d_buf(i).valid = '1' and (dvalid_d = '0'))  then
                  f_we <= '1';
                else
                  f_we <= '0'; 
                end if;
                f_data_i <= "00000" & tag_i & bx_i;
                if (f_rst_en = '1' and d_buf(i).valid = '0') or rst_p = '1' then
                    f_rst <= '1';
                else
                    f_rst <= '0';
                end if;
                -- f_re <= hword;
			end if;
		end process;

--		f_we <= '1' when (d_buf(i).valid = '1' and (dvalid_d = '0')) else '0';
--		f_data_i <= "00000" & tag_i & bx_i;
--		f_rst <= '1' when (f_rst_ctr = 255 and d_buf(i).valid = '0') or rst_p = '1' else '0';
		f_re <= hword;



		f_inst: entity work.mp7_formatter_fifo
		generic map(
			FIFO_SIZE => 16)
		port map(
			clk_i => clk_p,
			rst_i => f_rst,
			we_i => f_we,
			re_i => f_re,
			data_i => f_data_i,
			data_o => f_data_o);
			
		tag_o <= f_data_o(12);
		bx_o <= f_data_o(11 downto 0);

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

		q_out(i).data <= ctrl(0)(31 downto 16) & "000" & tag_o & bx_o when hword = '1' else q.data;
		q_out(i).strobe <= d_payload(i).strobe;
		q_out(i).valid <= hword or q.valid;
		q_out(i).start <= '0';
					
	end generate;
		
	q_buf <= d_payload when ctrl(0)(1) = '0' else q_out;

end rtl;
