-- mp7_formatter
--
-- Dave Newbold, July 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;

use work.ipbus.all;
use work.mp7_data_types.all;
use work.mp7_ttc_decl.all;
use work.ipbus_reg_types.all;

entity mp7_formatter_s1proto is
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
		q_buf: out ldata(3 downto 0) --  data out to buffers
	);
		
end mp7_formatter_s1proto;

architecture rtl of mp7_formatter_s1proto is

	signal ctrl: ipb_reg_v(0 downto 0);

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
			qmask(0) => X"0000fff2"
		);
		
	bgen: for i in 3 downto 0 generate
	
		signal mbx, mbx_d, f, valid_d: std_logic;

	begin
	
		process(clk_p)
		begin
			if rising_edge(clk_p) then
				if d_payload(i).strobe = '1' then

					if bctr = ctrl(0)(15 downto 4) then
						mbx <= '1';
					else
						mbx <= '0';
					end if;
					
					q_buf(i).data(14 downto 0) <= d_payload(i).data(14 downto 0);
					q_buf(i).data(15) <= d_payload(i).data(15) or (mbx and ctrl(0)(1));
					q_buf(i).data(31 downto 16) <= (others => '0');
					q_buf(i).valid <= d_payload(i).valid;
					q_buf(i).start <= d_payload(i).start;

				end if;

				q_buf(i).strobe <= d_payload(i).strobe;

			end if;
		end process;
		
	end generate;
	
	q_payload <= d_buf;

end rtl;
