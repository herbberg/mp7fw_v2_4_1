
-- Greg,  4/4/14

-- This CPLD code is designed just for the boundary scan tests.  The CPLD will 
-- is used to construct the jtag chain and thus cannot particpate as a normal
-- boundary scan would.  It will instead be placed into "sample" only mode.
-- To avoid conflicts with other boundary scan devices all I/O connections
-- have been set to "in" only, except for the jtag chains themselves.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
   generic (ports: integer := 4);
   port (
     -- Push-button reset
     reset_switch: in std_logic; 

     cpld_por : in std_logic;
     
     led : in std_logic_vector(1 downto 0);

     -- AMC JTAG interface
     tcka:       in std_logic;
     tmsa:       in std_logic;
     tdia:       in std_logic;
     tdoa:       out std_logic;

     -- Local JTAG header
     tckb:       in std_logic;
     tmsb:       in std_logic;
     tdib:       in std_logic;
     tdob:       out std_logic;

     -- Device ports (FPGA, Atmel, SRAM1, SRAM2)
     tcko:       out std_logic_vector(ports-1 downto 0);
     tmso:       out std_logic_vector(ports-1 downto 0);
     tdio:       out std_logic_vector(ports-1 downto 0);
     tdoo:       in std_logic_vector(ports-1 downto 0);

     -- CPLD configuration switch
     sel:        in std_logic_vector(7 downto 0);

     -- reference cpld clock
     cpld_clk_100mhz : in std_logic;

     -- spi prom reference signals
     spi_sclk : in std_logic;
     spi_cs_b : in std_logic;
     spi_dq : in std_logic_vector(3 downto 0) := "ZZZZ";

     -- fpga data signals
     cpld2fpga_d : in std_logic_vector(15 downto 0) := (OTHERS => 'Z');
     cpld2fpga_a : in std_logic_vector(16 downto 1);
     cpld2fpga_ebi_nwe_0 : in std_logic;
     cpld2fpga_ebi_nrd : in std_logic;
     cpld2fpga_ipbus_new : in std_logic;
     cpld2fpga_ipbus_done : in std_logic;

     -- FPGA status / programming
     fpga_mode : in std_logic_vector(2 downto 0);
     fpga_prog_b : in std_logic := 'Z';
     fpga_init_b : in std_logic;
     fpga_done : in std_logic;
     fpga_rdwr_b : in std_logic;
     fpga_csi_b : in std_logic;
     fpga_cclk : in std_logic;
     fpga_fcs_b : in std_logic;
     fpga_emc_clk : in std_logic;
     fpga_cpld_clk : in std_logic;
     
     -- Atmel interfaces
     atmel_ebi_d : in std_logic_vector(15 downto 0) := (OTHERS => 'Z');
     atmel_ebi_a : in std_logic_vector(19 downto 0) := (OTHERS => 'Z');
     atmel_ebi_nwe_0 : in std_logic;
     atmel_ebi_nwe_1 : in std_logic;
     atmel_ebi_ncs_1 : in std_logic;
     atmel_ebi_nrd : in std_logic;
	   atmel_uc : in std_logic_vector(4 downto 0) := "ZZZZZ"
     
     );
end top;

architecture behave of top is

  attribute SCHMITT_TRIGGER: string;
  attribute SCHMITT_TRIGGER of reset_switch: signal is "true";

  signal tcki:   std_logic;
  signal tmsi:   std_logic;
  signal tdii:   std_logic;
  signal tdoi:   std_logic;
  signal xfer:   std_logic_vector(ports-1 downto -1);


  signal select_local_jtag_header : std_logic;
	 

begin

  -- Select switch mapping
  -- Just here to make this readable

  -- sel 0 = FPGA JTAG enable
  -- sel 1 = Atmel JTAG enable
  -- sel 2 = SRAM1 JTAG enable
  -- sel 3 = SRAM2 JTAG enable
  -- sel 4 = Atmel FPGA reconfiguration enable

  select_local_jtag_header <= sel(7);
  
  tcki <= tckb when select_local_jtag_header = '1' else tcka;
  tmsi <= tmsb when select_local_jtag_header = '1' else tmsa;
  tdii <= tdib when select_local_jtag_header = '1' else tdia;
  tdob <= tdoi when select_local_jtag_header = '1' else 'Z';
  tdoa <= tdoi when select_local_jtag_header = 'Z' else tdia;

  -- tck switching
  tcksw: process (tcki, sel)
  begin
    for i in 0 to ports-1 loop
      if sel(i) = '0' then
        tcko(i) <= tcki;
      else
        tcko(i) <= '0';
      end if;
    end loop;
  end process;

  -- tms switching	
  tmssw: process (tmsi, sel)
  begin
    for i in 0 to ports-1 loop
      if sel(i) = '0' then
        tmso(i) <= tmsi;
      else
        tmso(i) <= '1';
      end if;
    end loop;
  end process;

  -- tdi/tdo routing
  xfer(-1) <= tdii; 
  tdsw: process (tdii, sel, tdoo, xfer)
  begin
    for i in 0 to ports-1 loop
      if sel(i) = '0' then
        xfer(i) <= tdoo(i); -- loop through chain
        tdio(i)<= xfer(i-1); 
      else
        xfer(i) <= xfer(i-1); -- bypass
        tdio(i)<= '1'; 
      end if;
    end loop;
    tdoi <= xfer(ports-1);
  end process;


end behave;
