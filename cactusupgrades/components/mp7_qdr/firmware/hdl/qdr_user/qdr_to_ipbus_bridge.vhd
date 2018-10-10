

library ieee;
use ieee.std_logic_1164.all;

entity qdr_to_ipbus_bridge is
  port (
    -- IPBus Clk Domain
    ipb_clk: in std_logic;
    ipb_rst: in std_logic;
    ipb_rd_data: out std_logic_vector(71 downto 0);
    ipb_rd_valid: out std_logic;
    -- QDR Clk Domain
    app_clk: in std_logic;
    app_rst: in std_logic;
    app_rd_data: in std_logic_vector(71 downto 0);
    app_rd_valid: in std_logic
  );
end entity qdr_to_ipbus_bridge;

architecture behave of qdr_to_ipbus_bridge is

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
    fifo_wr_en <= app_rd_valid;
    fifo_din <= x"00000000000000000" & "000" & app_rd_valid & app_rd_data;
    fifo_rd_en <= not fifo_empty;

    qdr_to_ipbus : entity work.qdr_to_ipbus_v9_3 
      port map (
        wr_clk                    => app_clk,             --from ipbus
        rd_clk                    => ipb_clk,          --from qdr for fabric
        wr_ack                    => open,
        valid                     => fifo_valid,
        rst                       => fifo_rst,     --async
        wr_en 		                => fifo_wr_en,   
        rd_en                     => fifo_rd_en,   --rd_clk_domain
        din                       => fifo_din,
        dout                      => fifo_dout,    --rd_clk_domain
        full                      => open,
        empty                     => fifo_empty);  --rd_clk_domain

    ipb_rd_data <= fifo_dout(71 downto 0);
    ipb_rd_valid <= fifo_dout(72) when fifo_valid = '1' else '0';

end architecture behave;
