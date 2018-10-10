

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity mp7_formatter_fifo is
generic(
	FIFO_SIZE : natural := 4);
port(
	clk_i : in std_logic;
	rst_i : in std_logic;
	we_i : in std_logic;
	re_i : in std_logic;
	data_i : in std_logic_vector(17 downto 0);
	data_o : out std_logic_vector(17 downto 0));
end mp7_formatter_fifo;

architecture rtl of mp7_formatter_fifo is

    type fifo_type is array (FIFO_SIZE-1 downto 0) of std_logic_vector (17 downto 0);
	signal fifo : fifo_type;
	signal wptr, rptr : integer range 0 to FIFO_SIZE-1;
	
begin

	ptr: process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = '1' then
				wptr <= 0;
			elsif we_i = '1' then
				if  (wptr < FIFO_SIZE - 1) then 
					wptr <= wptr + 1;
				else
					wptr <= 0;
				end if;
				fifo(wptr) <= data_i;
			end if;
			
			if rst_i = '1' then
				rptr <= 0;
			elsif re_i = '1' then
				if  (rptr < FIFO_SIZE - 1) then 
					rptr <= rptr + 1;
				else
					rptr <= 0;
				end if;
			end if;
					
		end if;
	end process;
		
		data_o <= fifo(rptr);

end rtl;
