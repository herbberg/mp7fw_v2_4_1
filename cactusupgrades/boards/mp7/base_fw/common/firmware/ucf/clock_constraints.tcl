# Timing constraints for MP7

# TTC clock (40MHz) - external
create_clock -period 24.2 -name clk_40_ext [get_ports clk40_in_p]
set_input_jitter clk_40_ext 0.5

# Ethernet RefClk (125MHz) - external
create_clock -period 8 -name eth_refclk [get_ports eth_clkp]

# Clock rate setting for refclks (kind of arbitrary, 250MHz here) - external
create_clock -name configurable_refclks -period 4.000 [get_ports {refclkn[*]}]

# Clock from Ethernet Transceiver (derived from Ethernet RefClk)
create_clock -period 16 -name eth_transceiver [get_pins infra/eth/phy/transceiver_inst/gtwizard_inst/gtwizard_v2_5_gbe_gth_i/gt0_gtwizard_v2_5_gbe_gth_i/gthe2_i/TXOUTCLK]

# The decoupled_clk is driven from a flip-flop to circumvent Xilinx rules for the ethernet sys clk.   Derived from eth_refclk.
create_clock -period 16 -name decoupled_clk [get_pins infra/eth/decoupled_clk_src_reg/Q]

# Fake 40MHz clock for tests without external clock source.  Derived from eth_refclk.
create_generated_clock -name clk_40_pseudo -source [get_pins infra/clocks/mmcm/CLKIN1] [get_pins infra/clocks/mmcm/CLKOUT2]

# IPBus Clock - Give it a sensible name - not "I".  Derived from eth_refclk.
create_generated_clock -name ipbus_clk -source [get_pins infra/clocks/mmcm/CLKIN1] [get_pins infra/clocks/mmcm/CLKOUT1]

# Block analysis of duplicate analysis of TTC clock path when clk_40_pseudo used.
set_case_analysis 1 [get_pins ttc/clocks/mmcm/CLKIN2]


##############################################################################
# Datapath clks
##############################################################################

# Xilinx prefers 1 clk definition per clock, but you end up with a stupid 
# number of clk definitions. For refclks easier to place all clocks into 
# single definition.  Unfortunately it is currenntly limited to 64 clks.
# Hence split problem up into many more clk definitions.
 
set mgt_type "gth_3g gth_10g gth_10g_std_lat"
set mgt_clkdir "rx tx"
set mgt_chans "0 1 2 3"

set rx_mgt_clks {}
set tx_mgt_clks {}

foreach k $mgt_type {	
	foreach j $mgt_clkdir {	
		foreach i $mgt_chans {
			if {$j == "rx"} {
				set mgt_clkpin "RXOUTCLK"
			}
			if {$j == "tx"} { 
				set mgt_clkpin "TXOUTCLK"
			}
			if {$k == "gth_3g"} {
				set mgt_clks [get_pins "datapath/rgen[*].region/mgt_gen_gth_3g.quad/*/*/*/gt$i*/gthe2_i/$mgt_clkpin"]
                set mgt_clk_period 6.6
			}
			if {$k == "gth_10g"} {
                set mgt_clks [get_pins "datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/gt$i*/gthe2_i/$mgt_clkpin"]
                set mgt_clk_period 4
            }
			if {$k == "gth_10g_std_lat"} {
				set mgt_clks [get_pins "datapath/rgen[*].region/mgt_gen_gth_10g.quad/*/*/*/g_gt_instances\[$i\]*/gthe2_i/$mgt_clkpin"]
				set mgt_clk_period 4
			}
			if {[llength $mgt_clks] != 0} {
				if {[info exists clkname]} { unset clkname }
				append clkname "" $k _ $j $i _clk
				create_clock -period $mgt_clk_period -name "$clkname" "$mgt_clks"
				if {$j == "rx"} {
                    append rx_mgt_clks $clkname " "
                 }
                 if {$j == "tx"} { 
                    append tx_mgt_clks $clkname " "
                 }
			}
        }
	}
}

# Clock relationship
    
# Clocks originating from eth_refclk
# Originally used single group for all clocks generated from eth_refclk.
set_clock_groups -asynch -group [get_clocks ipbus_clk]
set_clock_groups -asynch -group [get_clocks decoupled_clk]

# Clocks originating from ethernet transceiver txout clk
set_clock_groups -asynch -group [get_clocks -include_generated_clocks eth_transceiver]

# All rx transceiver data path clocks
set_clock_groups -asynch -group $rx_mgt_clks

# All tx transceiver data path clocks + TTC clocks in single group
# Required so that local set_max_delay / set_min_delay constraints not overridden by set_clock_groups -asynch
set ttc_clks [get_clocks -include_generated_clocks clk_40_ext]
puts $ttc_clks 
puts $tx_mgt_clks
set_clock_groups -asynch -group "$ttc_clks $tx_mgt_clks"

# AMC13 transceiver clock
set_clock_groups -asynch -group [get_clocks -filter {NAME =~ readout/amc13/*/TXOUTCLK}]



# Special path constraints
set_false_path -through [get_nets {*refclk_mon[*]} -hierarchical]

#  Search design for false path endpoints
set_false_path -to [get_cells -hier -filter {MP7_FALSE_PATH_DEST_CELL == TRUE}]

# Tx path for MGTs

for {set i 0} {$i < 18} {incr i} {
	for {set j 0} {$j < 4} {incr j} {
		set tx_ff_out [get_pins -quiet "datapath/rgen[$i].region/*/*/tx_gen[$j].tx_clk_bridge/buf*_reg[*]/C"]
		set tx_ff_in [get_pins -quiet "datapath/rgen[$i].region/*/*/tx_gen[$j].tx_clk_bridge/data_out_reg[*]/D"]
		if {[llength $tx_ff_out] != 0} {
			set_max_delay -from $tx_ff_out -to $tx_ff_in -datapath_only 4.0
			set_min_delay -to $tx_ff_in 0.2
		}
		set false_regs {}
        append false_regs [get_pins -quiet "datapath/rgen[$i].region/*/*/tx_gen[$j].tx_clk_bridge/dv_array_clk0_reg[*]/D"]
        append false_regs " "
        append false_regs [get_pins -quiet "datapath/rgen[$i].region/*/*/reg_gen[$j].txpolarity_reg[*]/D"]
        foreach k $false_regs {
            puts $k 
            set_false_path -to $k
        }
	}
}
