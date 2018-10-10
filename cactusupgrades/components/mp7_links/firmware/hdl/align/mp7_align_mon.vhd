-- mp7_align_mon
--
-- Wrapper for alignment monitor block
--
-- Dave Newbold, July 2014

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.mp7_ttc_decl.all;
use work.top_decl.all;

entity mp7_align_mon is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		ttc_cmd: in ttc_cmd_t;
		clk_p: in std_logic;
		rst_p: in std_logic;
		align_mon: in std_logic;
		align_inc: out std_logic;
		align_dec: out std_logic
	);

end mp7_align_mon;

architecture rtl of mp7_align_mon is
	
	signal ctrl, stat: ipb_reg_v(0 downto 0);
	signal stb: std_logic_vector(0 downto 0);
	signal bc0: std_logic;
	signal bctr: bctr_t;
	signal pctr: pctr_t;
	signal mctr: std_logic_vector(15 downto 0);
	signal ectr: unsigned(15 downto 0);
	signal match: std_logic;

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
			qmask => (0 => X"0000000f"),
			stb => stb
		);

	stat(0) <= std_logic_vector(ectr) & mctr;

	bc0 <= '1' when ttc_cmd = TTC_BCMD_BC0 else '0';
	
	ctr: entity work.bunch_ctr
		generic map(
			CLOCK_RATIO => CLOCK_RATIO,
			CLK_DIV => CLOCK_RATIO,
			LHC_BUNCH_COUNT => LHC_BUNCH_COUNT
		)
		port map(
			clk => clk_p,
			rst => rst_p,
			clr => '0',
			bc0 => bc0,
			bctr => bctr,
			pctr => pctr
		);

	match <= '1' when bctr = 	mctr(15 downto 4) and pctr = mctr(2 downto 0) else '0';
	
	process(clk_p)
	begin
		if rising_edge(clk_p) then
			if align_mon = '1' and ctrl(0)(2) = '0' then
				mctr <= bctr & '0' & pctr; -- Tidy this to cope with future potentially longer pctr
			end if;
			if rst_p = '1' or ctrl(0)(3) = '1' then
				ectr <= X"0000";
			elsif ctrl(0)(2) = '1' and (align_mon xor match) = '1' then
				if ectr /= X"ffff" then
					ectr <= ectr + 1;
				end if;
			end if;
		end if;
	end process;
	
	align_inc <= ctrl(0)(0) and stb(0);
	align_dec <= ctrl(0)(1) and stb(0);
		
end rtl;

