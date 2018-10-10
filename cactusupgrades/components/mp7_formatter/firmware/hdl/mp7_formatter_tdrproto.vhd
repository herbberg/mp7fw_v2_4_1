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

entity mp7_formatter_tdrproto is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		board_id: in std_logic_vector(7 downto 0);
		clk_p: in std_logic; -- data clock and reset
		rst_p: in std_logic;
		bctr: in bctr_t; -- local bunch counter
		tmt_sync: in tmt_sync_t;
		d_buf: in ldata(3 downto 0); -- data in from buffers
		q_payload: out ldata(3 downto 0); -- data out to algo
		d_payload: in ldata(3 downto 0); -- data in from algo
		q_buf: out ldata(3 downto 0) -- data out to buffers
	);
		
end mp7_formatter_tdrproto;

architecture rtl of mp7_formatter_tdrproto is

	signal ctrl: ipb_reg_v(0 downto 0);
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
			q => ctrl,
			qmask(0) => X"ffff0007"
		);

-- Per-channel formatter block
		
	cgen: for i in 3 downto 0 generate

		signal q: lword;
		signal bx_i, bx_o, bx_g: std_logic_vector(11 downto 0);
		signal tag_i, tag_o, tag_g, hword, valid, valid_d, dvalid_d: std_logic;

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
            tag_g <= tag_i;
            tag_o <= tag_g;
            bx_g <= bx_i;
            bx_o <= bx_g;
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

		q_out(i).data <= ctrl(0)(31 downto 16) & "000" & tag_o & bx_o when hword = '1' else q.data;
		q_out(i).strobe <= d_payload(i).strobe;
		q_out(i).valid <= hword or q.valid;
		q_out(i).start <= '0';
					
	end generate;
		
	q_buf <= d_payload when ctrl(0)(1) = '0' else q_out;

end rtl;
