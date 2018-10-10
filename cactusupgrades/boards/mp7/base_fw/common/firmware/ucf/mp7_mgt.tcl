# Constraints specific to '690 MP7

set_property LOC GTHE2_CHANNEL_X1Y36 [get_cells -hier -filter {name=~infra/eth/*/gthe2_i}]
set_property LOC GTHE2_CHANNEL_X1Y37 [get_cells -hier -filter {name=~readout/amc13/*/gthe2_i}]

# Format is x_loc y_start x_common_loc y_common_loc

set m_loc {
	{1 32 8}
	{1 28 7}
	{1 24 6}
	{1 20 5}
	{1 16 4}
	{1 12 3}
	{1 8 2}
	{1 4 1}
	{1 0 0}
	{0 0 0}
	{0 4 1}
	{0 8 2}
	{0 12 3}
	{0 16 4}
	{0 20 5}
	{0 24 6}
	{0 28 7}
	{0 32 8}
}	

# Loop over regions
for {set i 0} {$i < 18} {incr i} {
	set d [lindex $m_loc $i]
	set l [get_cells "datapath/rgen\[$i\].region/*/*/*/*/gthe2_common_*"]
	if {[llength $l] == 1} {
		set_property LOC GTHE2_COMMON_X[lindex $d 0]Y[lindex $d 2] $l
	}
	# Loop over channels
	for {set j 0} {$j < 4} {incr j} {
	  # 10g link
		set l [get_cells "datapath/rgen\[$i\].region/*/*/*/*/g_gt_instances\[$j\]*/gthe2_i"]
		if {[llength $l] != 1} {
			# 3g link
			set l [get_cells "datapath/rgen\[$i\].region/*/*/*/*/gt$j*/gthe2_i"]
		}
		if {[llength $l] != 1} {
      # 4g8 calo link
      set l [get_cells "datapath/rgen\[$i\].region/mgt_gen_gth_calo.quad/*/*/gt_4g8\[$j\]*/*/*/*/gthe2_i"]
    }
		if {[llength $l] != 1} {
      # 6g4 calo link
      set l [get_cells "datapath/rgen\[$i\].region/mgt_gen_gth_calo.quad/*/*/gt_6g4\[$j\]*/*/*/*/gthe2_i"]
    }
		if {[llength $l] != 1} {
      # 4g8 calo link tester
      set l [get_cells "datapath/rgen\[$i\].region/mgt_gen_gth_calotest.quad/*/*/gt_4g8\[$j\]*/*/*/*/gthe2_i"]
    }
		if {[llength $l] != 1} {
      # 6g4 calo link tester
      set l [get_cells "datapath/rgen\[$i\].region/mgt_gen_gth_calotest.quad/*/*/gt_6g4\[$j\]*/*/*/*/gthe2_i"]
    }
		if {[llength $l] == 1} {
			if {$i < 9} {  
				set c [expr {[lindex $d 1] + 3 - $j}]
			} else {
				set c [expr {[lindex $d 1] + $j}]
			}			
			set_property LOC GTHE2_CHANNEL_X[lindex $d 0]Y$c $l
		}		
	}
}
