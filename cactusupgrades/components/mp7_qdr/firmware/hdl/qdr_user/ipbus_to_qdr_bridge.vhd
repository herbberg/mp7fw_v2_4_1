

library ieee;
use ieee.std_logic_1164.all;

entity ipbus_to_qdr_bridge is
  port (
    -- IPBus Clk Domain
    ipb_clk: in std_logic;
    ipb_rst: in std_logic;
    ipb_wr_cmd: in std_logic;
    ipb_rd_cmd: in std_logic;
    ipb_addr: std_logic_vector(19 downto 0);
    ipb_wr_data: std_logic_vector(71 downto 0);
    ipb_en : in std_logic;
    -- QDR Clk Domain
    app_clk: in std_logic;
    app_rst: in std_logic;
    app_wr_data: out std_logic_vector(71 downto 0);
    app_addr: out std_logic_vector(19 downto 0);
    app_rd_cmd: out std_logic;
    app_wr_cmd: out std_logic
  );
end entity ipbus_to_qdr_bridge;

architecture behave of ipbus_to_qdr_bridge is

  signal fifo_rst : std_logic;
  signal fifo_valid : std_logic;
  signal fifo_wr_en : std_logic;
  signal fifo_empty : std_logic;
  signal fifo_din : std_logic_vector(143 downto 0);
  signal fifo_dout : std_logic_vector(143 downto 0);
  signal fifo_rd_en : std_logic;

  begin

    -- Xilinx has specific FIFO reset requirements (UG473)
    -- Wrote simple state machine to implment it, but
    -- not a neglible amoiunt of code given that it need 
    -- to be applied to both wr_clk & rd_clk sides of
    -- every FIFO. Code left in repos just in case, but
    -- just clk reset with slowest for the moment & 
    -- apply TIG in UCF.
    
    fifo_rst <= ipb_rst or app_rst when rising_edge(ipb_clk);
    fifo_wr_en <= (ipb_wr_cmd or ipb_rd_cmd) and ipb_en;
    fifo_din <= x"000000000000" & "00" & ipb_wr_cmd & ipb_rd_cmd & ipb_addr & ipb_wr_data;
    fifo_rd_en <= not fifo_empty;

    ipbus_to_qdr : entity work.ipbus_to_qdr_v9_3 
      port map (
        wr_clk                    => ipb_clk,             --from ipbus
        rd_clk                    => app_clk,          --from qdr for fabric
        wr_ack                    => open,
        valid                     => fifo_valid,
        rst                       => fifo_rst,     --async
        wr_en 		                => fifo_wr_en,   
        rd_en                     => fifo_rd_en,   --rd_clk_domain
        din                       => fifo_din,
        dout                      => fifo_dout,    --rd_clk_domain
        full                      => open,
        empty                     => fifo_empty);  --rd_clk_domain

    app_wr_data <= fifo_dout(71 downto 0);
    app_addr<= fifo_dout(91 downto 72);
    app_rd_cmd <= fifo_dout(92) when fifo_valid = '1' else '0';
    app_wr_cmd <= fifo_dout(93) when fifo_valid = '1' else '0';


end architecture behave;
