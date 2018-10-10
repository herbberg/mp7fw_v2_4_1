-- Delays various triggered signals through a bitshift
--
-- F. Ball March 2015

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY unisim;

USE work.mp7_ttc_decl.ALL;

ENTITY mp7_readout_l1a_delay IS
    PORT (
        clk_p : IN std_logic;
        rst : IN std_logic;
        ttc_clk : IN std_logic;
        l1a_delay : IN std_logic_vector(3 DOWNTO 0);
        token_delay : IN std_logic_vector(15 DOWNTO 0);
        l1a_in : IN std_logic;
        l1a_out : OUT std_logic;
        evt_ctr_in : IN eoctr_t;
        evt_ctr_out : OUT eoctr_t;
        token_en_in : IN std_logic;
        token_en_out : OUT std_logic
 
    );
 
END mp7_readout_l1a_delay;

ARCHITECTURE rtl OF mp7_readout_l1a_delay IS

    SIGNAL l1a_d, l1a_token : std_logic;

    TYPE evt_array IS ARRAY(15 DOWNTO 0) OF eoctr_t;
    SIGNAL evt_bit_shift : evt_array;
    SIGNAL l1a_bit_shift : std_logic_vector (15 DOWNTO 0); 
    SIGNAL token_en_bitshift : std_logic_vector(63 DOWNTO 0);

    SIGNAL l1a_del_en, token_del_en : std_logic := '0';
    SIGNAL l1a_del_sel, token_del_sel : INTEGER := 0;
BEGIN
    PROCESS (ttc_clk)
    BEGIN
        IF rising_edge(ttc_clk) THEN
            IF rst = '1' THEN
                l1a_del_en <= '0';
            ELSIF unsigned(L1A_DELAY) = 0 THEN
                l1a_del_en <= '0';
            ELSE
                l1a_del_en <= '1';
            END IF;
 
            l1a_del_sel <= to_integer(unsigned(L1A_DELAY) - 1);
        END IF;
    END PROCESS;
 
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst = '1' THEN
                token_del_en <= '0'; 
            ELSIF unsigned(TOKEN_DELAY) = 0 THEN
                token_del_en <= '0';
            ELSE
                token_del_en <= '1';
            END IF;
 
            token_del_sel <= to_integer(unsigned(TOKEN_DELAY) - 1);
        END IF;
    END PROCESS;
 
    PROCESS (ttc_clk)
    BEGIN
        IF rising_edge(ttc_clk) THEN
            IF l1a_del_en = '0' THEN
                l1a_out <= l1a_in;
                evt_ctr_out <= evt_ctr_in;
            ELSE
                l1a_out <= l1a_bit_shift(l1a_del_sel);
                evt_ctr_out <= evt_bit_shift(l1a_del_sel);
            END IF; 
        END IF;
    END PROCESS;
 
    PROCESS (clk_p)
    BEGIN
        IF rising_edge(clk_p) THEN
            IF token_del_en = '0' THEN
                token_en_out <= token_en_in;
            ELSE
                token_en_out <= token_en_bitshift(token_del_sel);
            END IF;
        END IF;
    END PROCESS;
 
    PROCESS (ttc_clk) -- delays L1A and event number through a bitshift
    BEGIN
        IF rising_edge(ttc_clk) THEN
            IF rst = '1' THEN
                l1a_bit_shift <= (OTHERS => '0');
                evt_bit_shift <= (OTHERS => (OTHERS => '0'));
            ELSE
                l1a_bit_shift <= l1a_bit_shift(l1a_bit_shift'HIGH - 1 DOWNTO 0) & l1a_in;
                evt_bit_shift <= evt_bit_shift(evt_bit_shift'HIGH - 1 DOWNTO 0) & evt_ctr_in;
            END IF;
        END IF;
    END PROCESS;
 
    PROCESS (clk_p) -- delays daq bus initial token through a bitshift
    BEGIN
        IF rising_edge(clk_p) THEN
            IF rst = '1' THEN
                token_en_bitshift <= (OTHERS => '0');
            ELSE
                token_en_bitshift <= token_en_bitshift(token_en_bitshift'HIGH - 1 DOWNTO 0) & token_en_in;
            END IF;
        END IF;
    END PROCESS;
END rtl;