# IO pin assignments for the MP7 board - R1 specific parts

proc false_path {patt clk} {
    set p [get_ports -quiet $patt -filter {direction != out}]
    if {llength $p != 0} {
        set_input_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != out}]
        set_false_path -from [get_ports $patt -filter {direction != out}]
    }
    set p [get_ports -quiet $patt -filter {direction != in}]
    if {llength $p != 0} {
       	set_output_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != in}]
	    set_false_path -to [get_ports $patt -filter {direction != in}]
	}
}

proc false_path_out {patt clk} {
	set_output_delay 0 -clock [get_clocks $clk] [get_ports $patt -filter {direction != in}]
	set_false_path -to [get_ports $patt -filter {direction != in}]
}

# Clock IO

set_property PACKAGE_PIN H29 [get_ports {clk40_in_n}]
set_property IOSTANDARD LVDS [get_ports {clk40_in_n}]
set_property DIFF_TERM TRUE [get_ports {clk40_in_n}]
set_property PACKAGE_PIN K16 [get_ports {ttc_in_n}]
set_property IOSTANDARD LVDS [get_ports {ttc_in_n}]
set_property DIFF_TERM TRUE [get_ports {ttc_in_n}]
set_property PACKAGE_PIN A9 [get_ports eth_clkn]
set_input_delay 0 -clock [get_clocks clk_40_ext] [get_ports {ttc_in_*}]

# MGT refclks

set_property PACKAGE_PIN J36 [get_ports {refclkn[0]}]
set_property PACKAGE_PIN U36 [get_ports {refclkn[1]}]
set_property PACKAGE_PIN AH38 [get_ports {refclkn[2]}]
set_property PACKAGE_PIN J9 [get_ports {refclkn[3]}]
set_property PACKAGE_PIN W9 [get_ports {refclkn[4]}]
set_property PACKAGE_PIN AF7 [get_ports {refclkn[5]}]
set_property PACKAGE_PIN AT38 [get_ports {refclkn[6]}]
set_property PACKAGE_PIN AT7 [get_ports {refclkn[7]}]
set_property PACKAGE_PIN A36 [get_ports {refclkn[8]}]

# Clock multiplier control pins

set_property IOSTANDARD LVCMOS18 [get_ports {si5326_*}]
set_property PACKAGE_PIN AP16 [get_ports {si5326_rst}]
set_property PACKAGE_PIN AR16 [get_ports {si5326_int}]
set_property PACKAGE_PIN AR18 [get_ports {si5326_lol}]
set_property PACKAGE_PIN AR17 [get_ports {si5326_scl}]
set_property PACKAGE_PIN AT16 [get_ports {si5326_sda}]
false_path si5326_* eth_refclk

# Mezzanine connector

set_property IOSTANDARD LVDS [get_ports {mezz_*}]
set_property PACKAGE_PIN AR33 [get_ports {mezz_p[0]}]
set_property PACKAGE_PIN AK33 [get_ports {mezz_p[1]}]
set_property PACKAGE_PIN AU33 [get_ports {mezz_p[2]}]
set_property PACKAGE_PIN AJ32 [get_ports {mezz_p[3]}]
set_property PACKAGE_PIN AP31 [get_ports {mezz_p[4]}]
set_property PACKAGE_PIN AJ30 [get_ports {mezz_p[5]}]
set_property PACKAGE_PIN AR31 [get_ports {mezz_p[6]}]
set_property PACKAGE_PIN AK31 [get_ports {mezz_p[7]}]
set_property PACKAGE_PIN AU31 [get_ports {mezz_p[8]}]
set_property PACKAGE_PIN AL30 [get_ports {mezz_p[9]}]
set_property PACKAGE_PIN AU13 [get_ports {mezz_p[10]}]
set_property PACKAGE_PIN AJ14 [get_ports {mezz_p[11]}]
set_property PACKAGE_PIN AT14 [get_ports {mezz_p[12]}]
set_property PACKAGE_PIN AL14 [get_ports {mezz_p[13]}]
set_property PACKAGE_PIN AV12 [get_ports {mezz_p[14]}]
set_property PACKAGE_PIN AM13 [get_ports {mezz_p[15]}]
set_property PACKAGE_PIN AU12 [get_ports {mezz_p[16]}]
set_property PACKAGE_PIN AK13 [get_ports {mezz_p[17]}]
set_property PACKAGE_PIN AU10 [get_ports {mezz_p[18]}]
set_property PACKAGE_PIN AN13 [get_ports {mezz_p[19]}]
set_property PACKAGE_PIN AV32 [get_ports {mezz_p[20]}]
set_property PACKAGE_PIN AV34 [get_ports {mezz_p[21]}]
set_property PACKAGE_PIN AW34 [get_ports {mezz_p[22]}]
set_property PACKAGE_PIN AY33 [get_ports {mezz_p[23]}]
set_property PACKAGE_PIN BA34 [get_ports {mezz_p[24]}]
set_property PACKAGE_PIN AV14 [get_ports {mezz_p[25]}]
set_property PACKAGE_PIN AW11 [get_ports {mezz_p[26]}]
set_property PACKAGE_PIN AY13 [get_ports {mezz_p[27]}]
set_property PACKAGE_PIN AY12 [get_ports {mezz_p[28]}]
set_property PACKAGE_PIN BA11 [get_ports {mezz_p[29]}]
false_path_out mezz_* eth_refclk
