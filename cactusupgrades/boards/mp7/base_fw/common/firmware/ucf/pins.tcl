# IO pin assignments for the MP7 board - common parts

proc false_path {patt clk} {
    set p [get_ports -quiet $patt -filter {direction != out}]
    if { [llength $p] != 0} {
        set_input_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != out}]
        set_false_path -from [get_ports $patt -filter {direction != out}]
    }
    set p [get_ports -quiet $patt -filter {direction != in}]
    if { [llength $p] != 0} {
       	set_output_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != in}]
	    set_false_path -to [get_ports $patt -filter {direction != in}]
	}
}
 
proc false_path_out {patt clk} {
	set_output_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != in}]
	set_false_path -to [get_ports $patt -filter {direction != in}]
}

# Clock fanout control pins

set_property IOSTANDARD LVCMOS18 [get_ports {clk_cntrl[*]}]
set_property SLEW SLOW [get_ports {clk_cntrl[*]}]
set_property PACKAGE_PIN BD21 [get_ports {clk_cntrl[0]}]
set_property PACKAGE_PIN BD20 [get_ports {clk_cntrl[1]}]
set_property PACKAGE_PIN BA21 [get_ports {clk_cntrl[2]}]
set_property PACKAGE_PIN BB20 [get_ports {clk_cntrl[3]}]
set_property PACKAGE_PIN BA20 [get_ports {clk_cntrl[4]}]
set_property PACKAGE_PIN AW22 [get_ports {clk_cntrl[5]}]
set_property PACKAGE_PIN AY22 [get_ports {clk_cntrl[6]}]
set_property PACKAGE_PIN AV20 [get_ports {clk_cntrl[7]}]
set_property PACKAGE_PIN AW21 [get_ports {clk_cntrl[8]}]
set_property PACKAGE_PIN AY21 [get_ports {clk_cntrl[9]}]
set_property PACKAGE_PIN AW19 [get_ports {clk_cntrl[10]}]
set_property PACKAGE_PIN AY19 [get_ports {clk_cntrl[11]}]
set_property PACKAGE_PIN AU22 [get_ports {clk_cntrl[12]}]
set_property PACKAGE_PIN AV22 [get_ports {clk_cntrl[13]}]
set_property PACKAGE_PIN AU20 [get_ports {clk_cntrl[14]}]
set_property PACKAGE_PIN AT21 [get_ports {clk_cntrl[15]}]
set_property PACKAGE_PIN AU21 [get_ports {clk_cntrl[16]}]
set_property PACKAGE_PIN AT20 [get_ports {clk_cntrl[17]}]
false_path_out  {clk_cntrl[*]} eth_refclk

# Minipod I2C busses

set_property IOSTANDARD LVCMOS18 [get_ports minipod_*]
set_property SLEW SLOW [get_ports minipod_*]
set_property PACKAGE_PIN P27 [get_ports minipod_top_rst_b]
set_property PACKAGE_PIN U30 [get_ports minipod_top_scl]
set_property PACKAGE_PIN R27 [get_ports minipod_top_sda_o]
set_property PACKAGE_PIN T30 [get_ports minipod_top_sda_i]
set_property PACKAGE_PIN T18 [get_ports minipod_bot_rst_b]
set_property PACKAGE_PIN R18 [get_ports minipod_bot_scl]
set_property PACKAGE_PIN U18 [get_ports minipod_bot_sda_o]
set_property PACKAGE_PIN R17 [get_ports minipod_bot_sda_i]
false_path minipod_* eth_refclk

# Front panel LEDs

set_property IOSTANDARD LVCMOS18 [get_ports {leds[*]}]
set_property SLEW SLOW [get_ports {leds[*]}]
set_property PACKAGE_PIN AN20 [get_ports {leds[0]}]
set_property PACKAGE_PIN AR21 [get_ports {leds[1]}]
set_property PACKAGE_PIN AR22 [get_ports {leds[2]}]
set_property PACKAGE_PIN AP19 [get_ports {leds[3]}]
set_property PACKAGE_PIN AN22 [get_ports {leds[4]}]
set_property PACKAGE_PIN AP22 [get_ports {leds[5]}]
set_property PACKAGE_PIN AM22 [get_ports {leds[6]}]
set_property PACKAGE_PIN AM21 [get_ports {leds[7]}]
set_property PACKAGE_PIN AJ22 [get_ports {leds[8]}]
set_property PACKAGE_PIN AJ21 [get_ports {leds[9]}]
set_property PACKAGE_PIN AM20 [get_ports {leds[10]}]
set_property PACKAGE_PIN AN19 [get_ports {leds[11]}]
false_path_out {leds[*]} eth_refclk

# Interface to MMC

set_property IOSTANDARD LVCMOS18 [get_ports {ebi_d[*]}]
set_property SLEW SLOW [get_ports {ebi_d[*]}]
set_property PACKAGE_PIN BC27 [get_ports {ebi_d[0]}]
set_property PACKAGE_PIN BD27 [get_ports {ebi_d[1]}]
set_property PACKAGE_PIN BD29 [get_ports {ebi_d[2]}]
set_property PACKAGE_PIN BD30 [get_ports {ebi_d[3]}]
set_property PACKAGE_PIN BB30 [get_ports {ebi_d[4]}]
set_property PACKAGE_PIN BC30 [get_ports {ebi_d[5]}]
set_property PACKAGE_PIN BC28 [get_ports {ebi_d[6]}]
set_property PACKAGE_PIN BC29 [get_ports {ebi_d[7]}]
set_property PACKAGE_PIN BA30 [get_ports {ebi_d[8]}]
set_property PACKAGE_PIN AW29 [get_ports {ebi_d[9]}]
set_property PACKAGE_PIN AY29 [get_ports {ebi_d[10]}]
set_property PACKAGE_PIN AW27 [get_ports {ebi_d[11]}]
set_property PACKAGE_PIN AY27 [get_ports {ebi_d[12]}]
set_property PACKAGE_PIN BA31 [get_ports {ebi_d[13]}]
set_property PACKAGE_PIN AY28 [get_ports {ebi_d[14]}]
set_property PACKAGE_PIN BA28 [get_ports {ebi_d[15]}]

set_property PACKAGE_PIN AY23 [get_ports ebi_nrd]
set_property IOSTANDARD LVCMOS18 [get_ports ebi_nrd]
set_property PACKAGE_PIN AY26 [get_ports ebi_nwe]
set_property IOSTANDARD LVCMOS18 [get_ports ebi_nwe]

set_property IOSTANDARD LVCMOS18 [get_ports {ebi_a[*]}]
set_property SLEW SLOW [get_ports {ebi_a[*]}]
set_property PACKAGE_PIN AM23 [get_ports {ebi_a[1]}]
set_property PACKAGE_PIN AL23 [get_ports {ebi_a[2]}]
set_property PACKAGE_PIN AP26 [get_ports {ebi_a[3]}]
set_property PACKAGE_PIN AN25 [get_ports {ebi_a[4]}]
set_property PACKAGE_PIN AP25 [get_ports {ebi_a[5]}]
set_property PACKAGE_PIN AP24 [get_ports {ebi_a[6]}]
set_property PACKAGE_PIN AU27 [get_ports {ebi_a[7]}]
set_property PACKAGE_PIN AT26 [get_ports {ebi_a[8]}]
set_property PACKAGE_PIN AN24 [get_ports {ebi_a[9]}]
set_property PACKAGE_PIN AN23 [get_ports {ebi_a[10]}]
set_property PACKAGE_PIN AT25 [get_ports {ebi_a[11]}]
set_property PACKAGE_PIN AT24 [get_ports {ebi_a[12]}]
set_property PACKAGE_PIN AU23 [get_ports {ebi_a[13]}]
set_property PACKAGE_PIN AT23 [get_ports {ebi_a[14]}]
set_property PACKAGE_PIN AU26 [get_ports {ebi_a[15]}]
set_property PACKAGE_PIN AU25 [get_ports {ebi_a[16]}]
false_path ebi_* eth_refclk
