-- mp7_align
--
-- Wrapper for auto-alignment block
--
-- Dave Newbold, July 2013

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.package_links.all;
use work.package_utilities.all;
use work.top_decl.all;

entity mp7_align is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_p: in std_logic;
		qsel: in std_logic_vector(4 downto 0);
		bctr: in std_logic_vector(11 downto 0);
		pctr: in std_logic_vector(2 downto 0);
		align_master: out std_logic_vector(4 * N_REGION - 1 downto 0);
		align_rst: out std_logic;
		align_ptr_inc: out std_logic_vector(4 * N_REGION - 1 downto 0);
		align_ptr_dec: out std_logic_vector(4 * N_REGION - 1 downto 0);
		align_marker: in std_logic_vector(4 * N_REGION - 1 downto 0);
		qplllock: in std_logic
	);

end mp7_align;

architecture rtl of mp7_align is

  constant MASTER_LINK_PRIMARY: integer := 0;
  constant MASTER_LINK_SECONDARY: integer := 3;
	
  signal ctrl: ipb_reg_v(2 downto 0);
	signal stat: ipb_reg_v(3 downto 0);
  
  signal align_marker_r, align_marker_f: std_logic_vector(4 * N_REGION -1 downto 0) := (others => '0');

  signal align_enable, align_status: std_logic := '0';
  signal fixed_latency: std_logic;
  signal bunch_ctr_req: std_logic_vector(11 downto 0);
  signal sub_bunch_ctr_req: std_logic_vector(2 downto 0);
  signal aligned_links: std_logic_vector(71  downto 0); -- Is link aligned?
  signal min_bunch_ctr: std_logic_vector(11 downto 0); 
  signal min_sub_bunch_ctr: std_logic_vector(2 downto 0);
  signal status : std_logic_vector(8 downto 0);
	signal rst_ctrl_i, rst_ctrl_r: std_logic;
	signal align_margin: std_logic_vector(3 downto 0);  -- How far to back off after rd/wt ptr clash
	signal align_disable: std_logic_vector(71  downto 0); -- Disable channels from alignment process
  signal master_sel: std_logic;
  
  attribute KEEP: string;
	attribute KEEP of rst_ctrl_i: signal is "TRUE"; -- TIG constraint is applied here
	
begin

	reg: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 3,
			N_STAT => 4
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipb_in,
			ipbus_out => ipb_out,
			d => stat,
			q => ctrl
		);

	rst_ctrl_i <= rst;
		
	process(clk_p)
	begin
		if rising_edge(clk_p) then
			align_enable <= ctrl(0)(0);	
			align_margin <= ctrl(0)(4 downto 1);
      master_sel <= ctrl(0)(5);	
			align_disable(23 downto 0) <= ctrl(0)(31 downto 8); 
			align_disable(55 downto 24) <= ctrl(1); 
			align_disable(71 downto 56) <= ctrl(2)(15 downto 0); 
      bunch_ctr_req <= ctrl(2)(27 downto 16); 
      sub_bunch_ctr_req <= ctrl(2)(30 downto 28);  
      fixed_latency <= ctrl(2)(31);       
			rst_ctrl_r <= rst_ctrl_i; -- Pipelining to get reset to align block
		end if;
	end process;
	
	---------------------------------------------------------------------------------------------------
	-- Controller for rxdata_simple_cdc_buf.  Aligns links and minimises latency.
	-- Note that alignment status of all links has deliberately left outside the 
	-- state machine to allow the user to use several clk cycles to determine whether 
	-- all teh links are aligned.
	--
	-- Note, if the user uses several clk cycles to perform a staged and_reduce of all 
	-- all links to generate "align_status_in" then align_slaves_in and align_master_in
	-- should also be delayed by the same quantity.
	---------------------------------------------------------------------------------------------------

  -- Place regs in entity.  Allows floorplanning if required.
  -- Currently allows regs to float between transceiver & floorplanned reg
  align_reg_float: reg_data
  	generic map( 
  		WIDTH => align_marker'length)
  	port map( 
  		clk => clk_p,
  		d => align_marker,
  		q => align_marker_f
  	);

  -- Place regs in entity.  Allows floorplanning if required.
  align_reg: reg_data
  	generic map( 
  		WIDTH => align_marker'length)
  	port map( 
  		clk => clk_p,
  		d => align_marker_f,
  		q => align_marker_r
  	);

	align: rxdata_simple_cdc_ctrl
		generic map(
			NQUAD => N_REGION,
      CLOCK_RATIO => CLOCK_RATIO,
			LOCAL_LHC_CLK_MULTIPLE => CLOCK_RATIO,
			LOCAL_LHC_BUNCH_COUNT => LHC_BUNCH_COUNT,
      MASTER_LINK_PRIMARY => MASTER_LINK_PRIMARY,
      MASTER_LINK_SECONDARY => MASTER_LINK_SECONDARY
		)  
		port map(
			local_rst_in => rst_ctrl_r,
			local_clk_in => clk_p,
			align_enable_in => align_enable,  
			align_marker_in => align_marker_r, 
			master_sel_in => master_sel, 
      buf_master_out => align_master, -- Could be removed with better state machine.
			align_margin_in => align_margin,
			align_disable_in => align_disable(4 * N_REGION - 1 downto 0),
      fixed_latency_in => fixed_latency,
      bunch_ctr_req_in => bunch_ctr_req,
      sub_bunch_ctr_req_in => sub_bunch_ctr_req,    
			buf_rst_out => align_rst,
			buf_ptr_inc_out => align_ptr_inc,
			buf_ptr_dec_out => align_ptr_dec,
      aligned_links_out => aligned_links(4 * N_REGION - 1 downto 0),
      min_bunch_ctr_out => min_bunch_ctr,
      min_sub_bunch_ctr_out => min_sub_bunch_ctr,
			status_out => status,
			bctr => bctr,
			pctr => pctr
		);
		
	aligned_links(71 downto 4 * N_REGION) <= (others => '0');
		
	stat(0)(3 downto 0) <= status(3 downto 0);
	stat(0)(4) <= qplllock;
	stat(0)(11 downto 5) <= (others => '0');
	stat(0)(23 downto 12) <= min_bunch_ctr;
	stat(0)(26 downto 24) <= min_sub_bunch_ctr;
	stat(0)(29 downto 27) <= status(8 downto 6);
	stat(0)(31 downto 30) <= status(5 downto 4);
	stat(1) <= aligned_links(31 downto 0);
	stat(2) <= aligned_links(63 downto 32);
	stat(3)(7 downto 0) <= aligned_links(71 downto 64);
	stat(3)(31 downto 8) <= (others => '0');


end rtl;

