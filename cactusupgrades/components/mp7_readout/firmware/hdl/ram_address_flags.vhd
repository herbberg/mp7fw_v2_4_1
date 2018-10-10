-- Keeos track of the read/write pointers in the RAM
-- Assume read pointer will never overtake write pointer
-- F. Ball

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

LIBRARY unisim;
USE unisim.VComponents.ALL;

USE work.top_decl.ALL;

USE work.ipbus.ALL;
USE work.ipbus_reg_types.ALL;
USE work.ipbus_decode_mp7_readout_control.ALL;

USE work.mp7_readout_decl.ALL;
USE work.mp7_data_types.ALL;
USE work.mp7_ttc_decl.ALL;

ENTITY ram_address_flags IS
    GENERIC (
        RAM_DEPTH : integer := 511;
        ADDR_WIDTH : integer
    );
    PORT (
        clk : IN std_logic;
        rst_i : IN std_logic;
        actr : IN std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
        dctr : IN std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
        raddr : IN std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
        init_sel : IN std_logic;
        ren : IN std_logic;
        hwm : IN std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
        lwm : IN std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
        warn : OUT std_logic;
        full : OUT std_logic;
        occupancy : OUT std_logic_vector(ADDR_WIDTH-1 DOWNTO 0);
        max_occ : OUT std_logic_vector(ADDR_WIDTH-1 DOWNTO 0)
    );

END ram_address_flags;

ARCHITECTURE rtl OF ram_address_flags IS

    TYPE state_type IS (ST_IDLE, ST_WARN, ST_FULL);
    SIGNAL state : state_type;
    TYPE read_state_type IS (ST_IDLE, ST_INIT, ST_READ);
    SIGNAL read_state : read_state_type;
    SIGNAL s_dctr, s_raddr, dr_daddr, reduced_daddr : unsigned(ADDR_WIDTH-1 DOWNTO 0);
    SIGNAL bank_ptr : integer := 0;
    SIGNAL s_hwm, s_lwm : unsigned(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL daddr : unsigned(ADDR_WIDTH DOWNTO 0);
    SIGNAL s_occupancy, s_max_occ : unsigned(ADDR_WIDTH - 1 DOWNTO 0);
    SIGNAL rst : std_logic;

BEGIN

    s_hwm <= RAM_DEPTH - unsigned(hwm);
    s_lwm <= RAM_DEPTH - unsigned(lwm);
    
    s_occupancy <= unsigned(RAM_DEPTH - dr_daddr - 1);
    occupancy <= std_logic_vector(s_occupancy);
    max_occ <= std_logic_vector(s_max_occ);
    
    rst <= rst_i when rising_edge(clk);

    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                read_state <= ST_IDLE;
            ELSE
            
                CASE read_state IS
                    WHEN ST_IDLE =>
                        IF init_sel = '1' THEN
                            read_state <= ST_INIT;
                        END IF;
                    WHEN ST_INIT =>
                        IF ren = '1' THEN
                            read_state <= ST_READ;
                        END IF;
                    WHEN ST_READ =>
                        IF s_dctr = 1 THEN
                            read_state <= ST_IDLE;
                        END IF;
                END CASE;
                
            END IF;
        END IF;
    END PROCESS;
    
    -- find the absolute difference between the pointers
    
    PROCESS(clk)           
    BEGIN
        IF rising_edgE(clk) THEN
            IF rst = '1' THEN
                daddr <= (OTHERS => '0');
                reduced_daddr <= (OTHERS => '0');
                dr_daddr <= (OTHERS => '1');  -- so as not to trip the state machine below !          
            ELSE
                daddr <= ('1' & unsigned(actr)) - s_raddr; -- difference between the write pointer and the read pointer
                reduced_daddr <= daddr(ADDR_WIDTH-1 DOWNTO 0);
                dr_daddr <= (RAM_DEPTH - 1) - reduced_daddr; -- (RAM depth - difference between r/w ptrs)                
            END IF;
        END IF;
    END PROCESS;
    
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                s_raddr <= (OTHERS => '0');
                s_dctr <= (OTHERS => '0');
            ELSE
                IF init_sel = '1' THEN
                    s_raddr <= unsigned(raddr);
                    s_dctr <= unsigned(dctr);            
                ELSIF read_state = ST_READ THEN
                    s_dctr <= s_dctr - 1; 
                    s_raddr <= s_raddr + 1; 
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
    -- now check if the derandomisers are overwriting data
    
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                state <= ST_IDLE;            
            ELSE
            
                CASE state IS
                    WHEN ST_IDLE =>
                        IF dr_daddr <= s_hwm THEN -- high water mark
                            state <= ST_WARN;
                        END IF;
                    WHEN ST_WARN =>
                        IF dr_daddr = 0  THEN
                            state <= ST_FULL;
                        ELSIF dr_daddr >= s_lwm THEN -- wait until it's left the low water mark
                            state <= ST_IDLE;
                        END IF;
                    WHEN ST_FULL => -- worse than death
                        state <= ST_FULL;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
    
--    warn <= '1' WHEN state = ST_WARN else '0';
--    full <= '1' WHEN state = ST_FULL else '0';
    
    process(clk)
    begin
        if rising_edge(clk) then
            if state = ST_WARN then
                warn <= '1';
            else
                warn <= '0';
            end if;
            
            if state = ST_FULL then
                full <= '1';
            else
                full <= '0';
            end if;

        end if;
    end process;
    
    PROCESS(clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                s_max_occ <= (others => '0');
            ELSE
                IF unsigned(s_occupancy) > s_max_occ THEN
                    s_max_occ <= s_occupancy;
                END IF;
            END IF;
        END IF;
    END PROCESS;
                                
END rtl;