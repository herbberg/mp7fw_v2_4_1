-- quad_wrapper_gth_dummy
--
-- Wrapper for MGT quad - this version is empty for simulation.
--
-- Dave Newbold, July 2014

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ipbus.all;
use work.drp_decl.all;
use work.mp7_data_types.all;
use work.ipbus_reg_types.all;

entity quad_wrapper_gth is
	generic(
		X_LOC: integer;
		Y_LOC: integer;
		LHC_BUNCH_COUNT: integer
	);
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		sysclk: in std_logic;
		clk_p: in std_logic;
		rst_p: in std_logic;
		d: in ldata(3 downto 0);
		q: out ldata(3 downto 0);
		refclk: in std_logic;
		qplllock: out std_logic;
    buf_rst: in std_logic_vector(3 downto 0);
    buf_ptr_inc: in std_logic_vector(3 downto 0);
    buf_ptr_dec: in std_logic_vector(3 downto 0);
    align_marker: out std_logic_vector(3 downto 0);
    txclk_mon: out std_logic;
    rxclk_mon: out std_logic_vector(3 downto 0);
    drp_in: in drp_wbus_array(3 downto 0);
    drp_out: out drp_rbus_array(3 downto 0);
    drp_in_com: in drp_wbus;
    drp_out_com: out drp_rbus
	);

end quad_wrapper_gth;

architecture rtl of quad_wrapper_gth is
	
	signal ctrl, stat: ipb_reg_v(0 downto 0);

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
			qmask => (0 => X"000003ff")
		);
		
	stat <= ctrl;

	drp_out <= (others => DRP_RBUS_NULL);
	drp_out_com <= DRP_RBUS_NULL;
	q <= (others => LWORD_NULL);
	qplllock <= '0';
	align_marker <= (others => '0');
	txclk_mon <= '0';
	rxclk_mon <= (others => '0');
		
end rtl;
