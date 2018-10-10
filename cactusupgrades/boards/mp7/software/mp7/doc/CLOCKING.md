# MP7 Clocking configuration

## MP7-XE Clocking XML parameters

### Generic
* **clkcfg name** :       Name of clocking configuration (not used, reference only)
* **clksrc** :            `internal` or `external`. Used to set extClk40Src in controller.py

### SI570
* **si570.cfg** :         `true` or `false` flag to enable or disable si570 configuration
* **si570.file** :        Name of text file (path is hard-coded to `{MP7_TEST}/etc/mp7/sicfg/si570/`)
 
### SI5326

* **si5326.cfgtop** :     `true` or `false` flag to enable or disable top si5326 configuration
* **si5326.cfgbot** :     `true` or `false` flag to enable or disable bottom si5326 configuration
* **si5326.filetop** :    Name of text file to configure top si5326 (path hard-coded to 
                          `{MP7_TEST}/etc/mp7/sicfg/si5326/` in controller.py)
* **si5326.filebot** :    Name of text file to configure bottom si5326 (path hard-coded to
                          `{MP7_TEST}/etc/mp7/sicfg/si5326/` in controller.py)

### SI53314

 * **si53314.basetop**:    `true` or `false` flag to enable or disable clock fan-out to 
 							datapath quads from top si53314 fan-out chip
 * **si53314.exttop**:     `true` or `false` flag to enable or disable clock fan-out to 
 							quads 119 & 219 from top si53314 fan-out chip
 * **si53314.basebot**:    `true` or `false` flag to enable or disable clock fan-out to
 							 datapath quads from bottom si53314 fan-out chip
 * **si53314.extbot**:     `true` or `false` flag to enable or disable clock fan-out to
 							quads 119 & 219 from bottom si53314 fan-out chip
 * **si53314.clkselbot**:  `0` sets si570 refclk input to bottom si53314 fan-out, `1` 
 							sets si5326 
                           refclk input to bottom si53314 fan-out (for top si53314 fan-out this is always set to '1',
                           since it only has input from top si5326)
 

### X-point

Routes the clock paths through the crosspoint. Inputs: [`fpga`, `tclkc`, `tclka`, `fclka`]. Outputs: [`tclkb`, `fpga`, `clk2`, `clk1`]  
                   (`clk2` is top clocking path, `clk1` is bottom clocking path)

* **xpoint.tclkb**:      Selects clock input to route to tclkb
* **xpoint.fpga**:       Selects clock input to route to fpga
* **xpoint.clk2**:       Selects clock input to route to top clocking path
* **xpoint.clk1**:       Selects clock input to route to bottom clocking path


### Config files summary

* **default-int_si570.xml** : Internal clk40 from fpga, refclks from si570. Top/bottom 
 							   si5326s not configured. Only bottom fan-out enabled, with 
							   input from si570. fpga routed to all xpoint outputs.
* **default-int_si5326.xml** : Internal clk40 from fpga, refclks from si5326. Top and bottom
								si5326 configured. si570 not configured. Top and bottom 
								fan-outs enabled, si5326 input to bottom fan-out. fpga 
								routed to all xpoint outputs.
* **default-ext.xml** : External clk40 from fclka (amc13), refclks from si5326. Top and bottom
						 si5326 configured. si570 not configured. Top and bottom fan-outs 
						 enabled, si5326 input to bottom fan-out. fclka (amc13) routed to 
						 all xpoint outputs.
* **test_3g.xml** : Should be used for testing 3 gigabit links. Internal clk40 from fpga. 
					 Refclks from si5326 @ 120MHz. Top and bottom si5326 configured. Both 
					 fan-outs enabled with only base output, extra disabled. si5326 input 
					 to bottom fan-out. fpga routed to all xpoint outputs.

***

## MP7-R1 Clocking XML parameters

### Generic
 * **clkcfg name** : Name of clocking configuration (not used, reference only)
 * **clksrc** : `internal` or `external`. Used to set extClk40Src in controller.py

### SI5326
 * **si5326.cfg** : `true` or `false` flag to enable or disable si5326 configuration
 * **si5326.file** : Name of text file to configure si5326 (path hard-coded to 
 					 `{MP7_TEST}/etc/mp7/sicfg/si5326/` in controller.py)

### X-point

There are 3 xpoints on R1. Main xpoint selects clk40 from 4 inputs and feeds to the clock buffers. The other two receive the clk40 from the clock buffers and fan out clk40 to the quads.
 
 * **xpoint.clk40sel** :   Selects clk40 input to main xpoint from [`si5326`, `tclkc`, `tclka`, `fclka`]
 * **xpoint.refclksel** :  Selects refclk from internal oscillator or si5326 [`osc`, `clkcln`]


### Config files summary

* **default-int.xml**:  Internal clk40 from si5326, refclks from dedicated internal                   
* **default-ext.xml**:  External clk40 from fclka (amc13), refclks from dedicated internal oscillators
