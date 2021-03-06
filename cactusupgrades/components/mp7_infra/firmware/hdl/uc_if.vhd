-- uc_if
--
-- Wrapper for everything associated with MMC interface to ipbus.
--
-- Dave Newbold, June 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.ipbus_trans_decl.all;

entity uc_if is
	port(
		clk125: in std_logic;
		rst125: in std_logic;
    clk200: in std_logic;
    uc_pipe_nrd: in std_logic;
    uc_pipe_nwe: in std_logic;
    uc_pipe: inout std_logic_vector(15 downto 0);
    uc_spi_miso: out std_logic;
    uc_spi_mosi: in std_logic;
    uc_spi_sck: in std_logic;
    uc_spi_cs_b: in std_logic;
		clk_ipb: in std_logic; -- ipbus clock (nominally ~30MHz) & reset
		rst_ipb: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		oob_in: in ipbus_trans_out;
		oob_out: out ipbus_trans_in
	);

end uc_if;

architecture rtl of uc_if is

	signal mmc_wdata, mmc_rdata: std_logic_vector(15 downto 0);
	signal mmc_we, mmc_re, mmc_req, mmc_done: std_logic;
	signal rst125_int: std_logic := '1';

begin

    -- Incoming reset is synchronous, even if parts of the following code are async.
    -- Reclock reset here to avoid creating a large fanouton the incoming reset. 
    process(clk125)
    begin
        if rising_edge(clk125) then
            rst125_int <= rst125;
        end if;
    end process;   

	uc_trans: entity work.trans_buffer
		port map(
			clk_m => clk125,
			rst_m => rst125_int,
			m_wdata => mmc_wdata,
			m_we => mmc_we,
			m_rdata => mmc_rdata,
			m_re => mmc_re,
			m_req => mmc_req,
			m_done => mmc_done,
			clk_ipb => clk_ipb,
			t_out => oob_out,
			t_in => oob_in
		);


  spi: entity work.spi_interface
    generic map(
      width => 16
    )
    port map(
      clk => clk125,
      rst => rst125_int,
      spi_miso => uc_spi_miso,
      spi_mosi => uc_spi_mosi,
      spi_sck => uc_spi_sck,
      spi_cs_b => uc_spi_cs_b,
      buf_wdata => mmc_wdata,
      buf_we => mmc_we,
      buf_rdata => mmc_rdata,
      buf_re => mmc_re,
      buf_req => mmc_req,
      buf_done => mmc_done
     );
  

	 uc_pipe_if: entity work.uc_pipe_interface
		port map(
		  clk => clk_ipb,
		  rst => rst_ipb,
		  ipbus_in => ipb_in,
		  ipbus_out => ipb_out,
		  sclk => clk125,
		  uc_pipe_nrd => uc_pipe_nrd,
		  uc_pipe_nwe => uc_pipe_nwe,
		  uc_pipe    => uc_pipe
	 );

end rtl;

