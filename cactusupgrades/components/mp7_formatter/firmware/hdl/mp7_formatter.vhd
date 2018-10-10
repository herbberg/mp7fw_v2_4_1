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
use work.top_decl.all;

entity mp7_formatter is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_p: in std_logic; -- data clock and reset
		rsts_p: in std_logic_vector(N_REGION - 1 downto 0);
		ctrs: in ttc_stuff_array(N_REGION - 1 downto 0); -- local TTC counters
		d_buf: in ldata(4 * N_REGION - 1 downto 0); -- data in from buffers
		q_payload: out ldata(4 * N_REGION - 1 downto 0); -- data out to algo
		d_payload: in ldata(4 * N_REGION - 1 downto 0); -- data in from algo
		q_buf: out ldata(4 * N_REGION - 1 downto 0) -- data out to buffers
	);
		
end mp7_formatter;

architecture rtl of mp7_formatter is

	signal ctrl, stat: ipb_reg_v(0 downto 0);
	signal q_out: ldata(4 * N_REGION - 1 downto 0);

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
			q => ctrl
		);

-- Per-channel formatter block
		
	rgen: for i in N_REGION - 1 downto 0 generate
	
		cgen: for j in 3 downto 0 generate
	
			constant id: integer := i * 4 + j;
			signal q: lword;
			signal bx: std_logic_vector(11 downto 0);
			signal tag, hword, valid, valid_d, dvalid_d: std_logic;
	
		begin

-- Header stripping and capture
		
			q_payload(id).data <= d_buf(id).data;
			q_payload(id).strobe <= d_buf(id).strobe;
			q_payload(id).valid <= valid;
			q_payload(id).start <= valid and not valid_d;
		
			valid <= d_buf(id).valid when ctrl(0)(0) = '0' else d_buf(id).valid and dvalid_d;
			
			process(clk_p)
			begin
				if rising_edge(clk_p) then
					if d_buf(id).strobe = '1' then

						dvalid_d <= d_buf(id).valid;
						valid_d <= valid;

						if d_buf(id).valid = '1' and dvalid_d = '0' then
							if ctrl(0)(2) = '0' then
								bx <= d_buf(id).data(11 downto 0);
								tag <= d_buf(id).data(12);
							else
								bx <= ctrs(i).bctr;
								tag <= not or_reduce(ctrs(i).bctr);
							end if;
						end if;
						
					end if;
				end if;
			end process;

-- Header insertion
			
			process(clk_p)
			begin
				if rising_edge(clk_p) then
					if d_payload(id).strobe = '1' then
						q <= d_payload(id);
					end if;
				end if;
			end process;

			hword <= '1' when d_payload(id).valid = '1' and q.valid = '0' else '0'; 

			q_out(id).data <= ctrl(0)(31 downto 16) & "000" & tag & bx when hword = '1' else q.data;
			q_out(id).strobe <= d_payload(id).strobe;
			q_out(id).valid <= hword or q.valid;
			q_out(id).start <= '0';
						
		end generate;
		
	end generate;
	
	q_buf <= d_payload when ctrl(0)(1) = '0' else q_out;

end rtl;

