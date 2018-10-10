-- A very simple bitshift
--
-- F. Ball March 2015

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY bitshift_delay IS
    GENERIC ( 
        MAX_DELAY : integer := 1;
        DELAY_WIDTH : integer := 1
    );
    PORT (
        clk : IN std_logic;
        rst : IN std_logic;
        delay : IN std_logic_vector(DELAY_WIDTH-1 DOWNTO 0);
        d : IN std_logic;
        q : OUT std_logic
    );
 
END bitshift_delay;

ARCHITECTURE rtl OF bitshift_delay IS

    SIGNAL bit_shift : std_logic_vector (MAX_DELAY-1 DOWNTO 0);
    SIGNAL q_d, del_en : std_logic := '0';
    SIGNAL sel : INTEGER RANGE 0 TO MAX_DELAY-1 := 0;
    SIGNAL rst_r : std_logic := '0';
    ATTRIBUTE max_fanout : integer;
    ATTRIBUTE max_fanout of rst_r : signal is 32;
    
BEGIN

    q <= q_d WHEN del_en = '1' ELSE d;

    PROCESS(clk) -- a bit of pipelining 
    BEGIN
        IF rising_edge(clk) THEN
            IF unsigned(delay) = 1 THEN
                q_d <= d;
            ELSE
                q_d <= bit_shift(sel);
            END IF;
        END IF;
    END PROCESS;  
    
    PROCESS(clk) -- keeps sim happy
    BEGIN
        IF rising_edge(clk) THEN
            IF unsigned(delay) > 1 THEN
                sel <= to_integer(unsigned(delay) - 2);
            END IF;
        END IF;
    END PROCESS;                                
    
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN      
            IF unsigned(delay) = 0 THEN
                del_en <= '0';
            ELSE
                del_en <= '1';
            END IF;
        END IF;
    END PROCESS;
 
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst_r = '1' THEN
                bit_shift <= (OTHERS => '0');
            ELSE
                bit_shift <= bit_shift(bit_shift'HIGH - 1 DOWNTO 0) & d;
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
          rst_r <= rst;
        END IF;
    END PROCESS;
    
    
END rtl;