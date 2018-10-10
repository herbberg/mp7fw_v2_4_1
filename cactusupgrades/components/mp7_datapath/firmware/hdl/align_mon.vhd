-- align_mon
--
-- Dave Newbold, November 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;

entity align_mon is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_p: in std_logic;
		rst_p: in std_logic;
		bctr: in std_logic_vector(11 downto 0);
		pctr: in std_logic_vector(2 downto 0);
		sig: in std_logic;
		align_ctrl: out std_logic_vector(3 downto 0)
	);
	
end align_mon;

architecture rtl of align_mon is

	signal ctrl, stat: ipb_reg_v(0 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal sig_d, bstb: std_logic;
	signal bx: std_logic_vector(11 downto 0);
	signal cyc: std_logic_vector(2 downto 0);
	signal ctr: unsigned(7 downto 0);

begin

	reg: entity work.ipbus_syncreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipb_in,
			ipb_out => ipb_out,
			slv_clk => clk_p,
			d => stat,
			q => ctrl,
			qmask(0) => X"000000f3",
			stb => stb
		);
		
	stat(0) <= X"00" & std_logic_vector(ctr) & bx & '0' & cyc;
	align_ctrl <= ctrl(0)(7 downto 4) when stb(0) = '1' else X"0";

	bstb <= sig and not sig_d;

	process(clk_p)
	begin
		if rising_edge(clk_p) then

			sig_d <= sig;

			if rst_p = '1' or ctrl(0)(7 downto 4) /= "0000" then
				bx <= X"fff";
				cyc <= "111";
			elsif bstb = '1' and ctrl(0)(1) = '0' then
				bx <= bctr;
				cyc <= pctr;
			end if;

			if rst_p = '1' or ctrl(0)(0) = '1' or ctrl(0)(7 downto 4) /= "0000" then
				ctr <= (others => '0');
			elsif bstb = '1' and (bctr /= bx or pctr /= cyc) and ctr /= X"ff" then
				ctr <= ctr + 1;
			end if;
			
		end if;
	end process;

end rtl;
