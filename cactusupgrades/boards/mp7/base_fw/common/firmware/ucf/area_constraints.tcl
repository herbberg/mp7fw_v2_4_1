# Area constraints for MP7

# Control region (X1Y9)

create_pblock ctrl
resize_pblock [get_pblocks ctrl] -add {CLOCKREGION_X0Y9:CLOCKREGION_X1Y9}
add_cells_to_pblock [get_pblocks ctrl] [get_cells -quiet [list infra ttc ctrl readout]]

# There area  few exceptions to the area constraints above due to resource availability
# In the past overwrote main constraint with "LOC" constraint in ISE.  Does not work
# in Vivado.  Use another pblock instead.

create_pblock mmcm_ttc
add_cells_to_pblock [get_pblocks mmcm_ttc] [get_cells ttc/clocks/mmcm]
resize_pblock [get_pblocks mmcm_ttc] -add {CLOCKREGION_X0Y9}

create_pblock mmcm_infra_clocks
add_cells_to_pblock [get_pblocks mmcm_infra_clocks] [get_cells infra/clocks/mmcm]
resize_pblock [get_pblocks mmcm_infra_clocks] -add {CLOCKREGION_X1Y7}

create_pblock mmcm_infra_eth
add_cells_to_pblock [get_pblocks mmcm_infra_eth] [get_cells infra/eth/mmcm]
resize_pblock [get_pblocks mmcm_infra_eth] -add {CLOCKREGION_X1Y9}

# Basic payload area

create_pblock payload
resize_pblock [get_pblocks payload] -add {SLICE_X30Y0:SLICE_X191Y449}
resize_pblock [get_pblocks payload] -add {RAMB18_X2Y0:RAMB18_X12Y179}
resize_pblock [get_pblocks payload] -add {RAMB36_X2Y0:RAMB36_X12Y89}

# Quad and per-region area constraints

set q_coords {
	{SLICE_X192Y400:SLICE_X221Y449 RAMB18_X14Y160:RAMB18_X14Y179 RAMB18_X13Y170:RAMB18_X13Y179}
	{SLICE_X192Y350:SLICE_X221Y399 RAMB18_X14Y140:RAMB18_X14Y159 RAMB18_X13Y140:RAMB18_X13Y149}
	{SLICE_X192Y300:SLICE_X221Y349 RAMB18_X13Y120:RAMB18_X14Y139}
	{SLICE_X192Y250:SLICE_X221Y299 RAMB18_X14Y100:RAMB18_X14Y119 RAMB18_X13Y110:RAMB18_X13Y119}
	{SLICE_X192Y200:SLICE_X221Y249 RAMB18_X14Y80:RAMB18_X14Y99 RAMB18_X13Y80:RAMB18_X13Y89}
	{SLICE_X192Y150:SLICE_X221Y199 RAMB18_X13Y60:RAMB18_X14Y79}
	{SLICE_X192Y100:SLICE_X221Y149 RAMB18_X14Y40:RAMB18_X14Y59 RAMB18_X13Y50:RAMB18_X13Y59}
	{SLICE_X192Y50:SLICE_X221Y99 RAMB18_X14Y20:RAMB18_X14Y39 RAMB18_X13Y20:RAMB18_X13Y29}
	{SLICE_X192Y0:SLICE_X221Y49 RAMB18_X13Y0:RAMB18_X14Y19}
	{SLICE_X0Y0:SLICE_X29Y49 RAMB18_X0Y0:RAMB18_X1Y19}
	{SLICE_X0Y50:SLICE_X29Y99 RAMB18_X0Y20:RAMB18_X1Y39}	
	{SLICE_X0Y100:SLICE_X29Y149 RAMB18_X0Y40:RAMB18_X1Y59}	
	{SLICE_X0Y150:SLICE_X29Y199 RAMB18_X0Y60:RAMB18_X1Y79}	
	{SLICE_X0Y200:SLICE_X29Y249 RAMB18_X0Y80:RAMB18_X1Y99}	
	{SLICE_X0Y250:SLICE_X29Y299 RAMB18_X0Y100:RAMB18_X1Y119}	
	{SLICE_X0Y300:SLICE_X29Y349 RAMB18_X0Y120:RAMB18_X1Y139}	
	{SLICE_X0Y350:SLICE_X29Y399 RAMB18_X0Y140:RAMB18_X1Y159}	
	{SLICE_X0Y400:SLICE_X29Y449 RAMB18_X0Y160:RAMB18_X1Y179}	
}

set p_coords {
	SLICE_X106Y400:SLICE_X191Y449
	SLICE_X106Y350:SLICE_X191Y399
	SLICE_X106Y300:SLICE_X191Y349
	SLICE_X106Y250:SLICE_X191Y299
	SLICE_X106Y200:SLICE_X191Y249
	SLICE_X106Y150:SLICE_X191Y199
	SLICE_X106Y100:SLICE_X191Y149
	SLICE_X106Y50:SLICE_X191Y99
	SLICE_X106Y0:SLICE_X191Y49
	SLICE_X30Y0:SLICE_X105Y49
	SLICE_X30Y50:SLICE_X105Y99
	SLICE_X30Y100:SLICE_X105Y149
	SLICE_X30Y150:SLICE_X105Y199
	SLICE_X30Y200:SLICE_X105Y249
	SLICE_X30Y250:SLICE_X105Y299
	SLICE_X30Y300:SLICE_X105Y349
	SLICE_X30Y350:SLICE_X105Y399
	SLICE_X30Y400:SLICE_X105Y449
}

for {set i 0} {$i < 7} {incr i} {
	set bq [create_pblock quad_$i]
	resize_pblock $bq -add [lindex $q_coords $i]
	add_cells_to_pblock $bq "datapath/rgen\[$i\].region"
	set br [create_pblock payload_$i]
	resize_pblock $br -add [lindex $p_coords $i]
}

# "Cross-device" registers for readout and TTC path

add_cells_to_pblock [get_pblocks payload_6] [get_cells -quiet datapath/rgen[6].region/pgen.*]
