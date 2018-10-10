-- Processes L1As and captures data ready for daq readout
-- F. Ball - Feb 2015

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_misc.ALL;

USE work.mp7_ttc_decl.ALL;

ENTITY mp7_readout_trigger_counter IS
    PORT (
        clk : IN std_logic;
        rst : IN std_logic;
        ec0 : IN std_logic;
        evt_ctr : IN eoctr_t;
        l1a_in : IN std_logic;
        l1a_out : OUT std_logic;
        veto_in : IN std_logic;
        veto_out : OUT std_logic;
        trigger_event : IN std_logic_vector(7 downto 0)        
    );
END mp7_readout_trigger_counter;

ARCHITECTURE rtl OF mp7_readout_trigger_counter IS

SIGNAL trig_mode_en, trig_always : std_logic;
SIGNAL trig_ctr : unsigned(11 downto 0);
type state_type IS (ST_IDLE, ST_ENABLE);
SIGNAL state : state_type;

BEGIN    
    -- trigger processor
     
    PROCESS (clk) -- a bit of pipelining 
    BEGIN
        IF rising_edge(clk) THEN
            IF unsigned(trigger_event) = 0 THEN
                trig_mode_en <= '0';
            ELSE
                trig_mode_en <= '1';
            END IF;
            
            IF unsigned(trigger_event) = 1 THEN
                trig_always <= '1';
            ELSE
                trig_always <= '0';
            END IF;
        END IF;
    END PROCESS;
 
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' OR trig_ctr = (unsigned(trigger_event)) OR (ec0 = '1') THEN --OR unsigned(evt_ctr) = 1 THEN
                trig_ctr <= (OTHERS => '0');
            ELSIF l1a_in = '1' THEN
                trig_ctr <= trig_ctr + 1;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF rst = '1' THEN
                state <= ST_IDLE;
            ELSIF trig_mode_en <= '0' THEN --trigger mode off
                state <= ST_IDLE;
            ELSIF trig_always = '1' THEN -- trigger mode always on
                state <= ST_ENABLE; 
            ELSE
                CASE state IS
                    WHEN ST_IDLE => 
                        IF trig_ctr = (unsigned(trigger_event) - 1) THEN 
                            state <= ST_ENABLE; 
                        END IF;
                    WHEN ST_ENABLE => 
                        IF l1a_in = '1' THEN
                            state <= ST_IDLE;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
    
    veto_out <= '1' WHEN state = ST_ENABLE ELSE '0';
    l1a_out <= l1a_in WHEN state = ST_ENABLE AND veto_in = '0' ELSE '0';
    
END rtl;