-- sy89540_cntrl
--
-- ipbus interface to Greg's xpoint control block
--
-- Dave Newbold, July 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ipbus.all;
use work.ipbus_reg_types.all;
use work.ipbus_decode_mp7xe_xpoint.all;

entity mp7xe_xpoint is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
    -- Configure X-points & buffers
		clk_cntrl: out std_logic_vector(17 downto 0);
    -- SI5326 "TOP" Clk Distribution Path
		si5326_top_rst: out std_logic; -- IO signals to SI5326 clock device
		si5326_top_int: in std_logic := '0';
		si5326_top_lol: in std_logic := '0';
		si5326_top_scl: out std_logic;
		si5326_top_sda_i: in std_logic := '0';
		si5326_top_sda_o: out std_logic;
    -- SI5326 "BOTTOM" Clk Distribution Path
		si5326_bot_rst: out std_logic; -- IO signals to SI5326 clock device
		si5326_bot_int: in std_logic := '0';
		si5326_bot_lol: in std_logic := '0';
		si5326_bot_scl: out std_logic;
		si5326_bot_sda_i: in std_logic := '0';
		si5326_bot_sda_o: out std_logic;
    -- SI570 "BOTTOM" Clk Distribution Path
		si570_scl: out std_logic;
		si570_sda_i: in std_logic := '0';
		si570_sda_o: out std_logic
	);
	
end mp7xe_xpoint;

architecture rtl of mp7xe_xpoint is

	signal ipbw: ipb_wbus_array(N_SLAVES - 1 downto 0);
	signal ipbr: ipb_rbus_array(N_SLAVES - 1 downto 0);
	signal stat, ctrl: ipb_reg_v(0 downto 0);
  signal prog, prog_pulse: std_logic;

begin

	fabric: entity work.ipbus_fabric_sel
    generic map(
    	NSLV => N_SLAVES,
    	SEL_WIDTH => IPBUS_SEL_WIDTH)
    port map(
      ipb_in => ipb_in,
      ipb_out => ipb_out,
      sel => ipbus_sel_mp7xe_xpoint(ipb_in.ipb_addr),
      ipb_to_slaves => ipbw,
      ipb_from_slaves => ipbr
    );

	i2c_si570_top: entity work.ipbus_i2c_master
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_I2C_SI570_BOT),
			ipb_out => ipbr(N_SLV_I2C_SI570_BOT),
			scl => si570_scl,
			sda_o => si570_sda_o,
			sda_i => si570_sda_i
	);
	
	i2c_si5326_top: entity work.ipbus_i2c_master
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_I2C_SI5326_TOP),
			ipb_out => ipbr(N_SLV_I2C_SI5326_TOP),
			scl => si5326_top_scl,
			sda_o => si5326_top_sda_o,
			sda_i => si5326_top_sda_i
		);
	
	i2c_si5326_bot: entity work.ipbus_i2c_master
		port map(
			clk => clk,
			rst => rst,
			ipb_in => ipbw(N_SLV_I2C_SI5326_BOT),
			ipb_out => ipbr(N_SLV_I2C_SI5326_BOT),
			scl => si5326_bot_scl,
			sda_o => si5326_bot_sda_o,
			sda_i => si5326_bot_sda_i
		);

	reg: entity work.ipbus_ctrlreg_v
		generic map(
			N_CTRL => 1,
			N_STAT => 1
		)
		port map(
			clk => clk,
			reset => rst,
			ipbus_in => ipbw(N_SLV_CSR),
			ipbus_out => ipbr(N_SLV_CSR),
			d => stat,
			q => ctrl
		);
    
	stat(0)(0) <= '0';
  stat(0)(1) <= '0';
	-- stat(0)(2) used for x-point (see below)
	stat(0)(3) <= '0';
	stat(0)(4) <= si5326_top_int;
	stat(0)(5) <= si5326_top_lol;
	stat(0)(6) <= si5326_bot_int;
	stat(0)(7) <= si5326_bot_lol;
	stat(0)(31 downto 8) <= (others => '0');
	  
  si5326_top_rst <= ctrl(0)(4);
  si5326_bot_rst <= ctrl(0)(6);
  
  clk_cntrl(0) <= ctrl(0)(8); -- OE 0&5, TOP, For 690 only (X11)
  clk_cntrl(1) <= ctrl(0)(9); -- OE 1-4, TOP, For 485 & 690 (X14 & X17)
  clk_cntrl(2) <= ctrl(0)(10); -- CLK_SEL, TOP, '0' for CLK0 (unconnected), '1' for CLK1 (SI5326), 
  clk_cntrl(3) <= ctrl(0)(11); -- OE 0&5, BOT, For 690 only (X11)
  clk_cntrl(4) <= ctrl(0)(12); -- OE 1-4, BOT, For 485 & 690 (X14 & X17)
  clk_cntrl(5) <= ctrl(0)(13); -- CLK_SEL, BOT, '0' for CLK0 (SI570), '1' for CLK1 (SI5326), 
  clk_cntrl(11 downto 6) <= (others => '0'); -- Unused on MP7XE
  
	-- Inputs to xpoint_u36
	-----------------------
	-- Input 0 = From FPGA
	-- Input 1 = TCLK-C
	-- Input 2 = TCLK-A
	-- Input 3 = FCLK-A
	
	-- Outputs to xpoint_u36
	------------------------	
	-- Output 0 = TCLKB & TCLKD
	-- Output 1 = FPGA.  Used for CLK40
	-- Output 2 = TOP SI5325, CLK1 Input
	-- Output 3 = BOT SI5325, CLK1 Input
		
	xpoint_u36: entity work.xpoint
		port map ( 
			clk_i => clk,
			rst_i => rst,
			prog_i => prog_pulse,
			done_o => stat(0)(2),
			sel_for_out0_i => ctrl(0)(25 downto 24),
			sel_for_out1_i => ctrl(0)(27 downto 26),
			sel_for_out2_i => ctrl(0)(29 downto 28),
			sel_for_out3_i => ctrl(0)(31 downto 30),
			load_o => clk_cntrl(15),
			config_o => clk_cntrl(14),
			sin_o(0) => clk_cntrl(16),
			sin_o(1) => clk_cntrl(17),
			sout_o(0) => clk_cntrl(12),
			sout_o(1) => clk_cntrl(13)
		);
		
		
  prog_proc : process(clk, rst)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        prog <= '0';
        prog_pulse <= '0';
      else
        prog <= ctrl(0)(2);
        prog_pulse <= (not prog) and ctrl(0)(2);
      end if;
    end if;
  end process;
  
end rtl;
