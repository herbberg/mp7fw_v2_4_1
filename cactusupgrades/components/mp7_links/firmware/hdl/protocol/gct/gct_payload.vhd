

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.ipbus.all;
use work.mp7_data_types.all;
use work.top_decl.all;
use work.mp7_ttc_decl.all;
use work.mp7_brd_decl.all;

entity gct_payload is
	port(
		clk: in std_logic; -- ipbus signals
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		clk_payload: in std_logic;
		clk_p: in std_logic; -- data clock
		rst_loc: in std_logic_vector(N_REGION - 1 downto 0);
		clken_loc: in std_logic_vector(N_REGION - 1 downto 0);
		bc0: out std_logic;
    ctrs: in ttc_stuff_array(N_REGION - 1 downto 0); -- local TTC counters		
		d: in ldata(4 * N_REGION - 1 downto 0); -- data in
		q: out ldata(4 * N_REGION - 1 downto 0) -- data out
	);
end gct_payload;


architecture rtl of gct_payload is


begin

	ipb_out <= IPB_RBUS_NULL;


	rgen: for i in N_REGION - 1 downto 0 generate
	
		cgen: for j in 3 downto 0 generate

			constant id: integer := i * 4 + j;
    
    begin
        
      pattern_for_mp7: entity work.gct_pattern_clken
        generic map(
          LHC_BUNCH_COUNT => LHC_BUNCH_COUNT)
        port map(
          clk => clk_p,
          rst => rst_loc(i),
          clken => d(id).strobe,
          bctr => ctrs(i).bctr,
          pctr => ctrs(i).pctr,
          data => q(id).data(15 downto 0),
          data_valid => q(id).valid);
          
      q(id).data(31 downto 16)  <= (others => '0');
      q(id).strobe <= d(id).strobe;
      q(id).start <= '0';
      			
		end generate;
		
	end generate;
	
	bc0 <= '0';

end rtl;

