project set "Preferred Language" "VHDL"
project set "Keep Hierarchy" "Soft" -process "Synthesize - XST"
project set "Enable Multi-Threading" "2" -process "Map"
project set "Pack I/O Registers/Latches into IOBs" "For Inputs and Outputs" -process "Map"
project set "Allow Logic Optimization Across Hierarchy" TRUE -process "Map"
project set "Register Duplication" "On" -process "Map"
project set "Generate Detailed MAP Report" TRUE -process "Map"
project set "LUT Combining" "Auto" -process "Map"
project set "Enable Multi-Threading" "2" -process "Place & Route"
project set "Generate Clock Region Report" TRUE -process "Place & Route"
#project set "Enable BitStream Compression" TRUE -process "Generate Programming File"
project set "Power Down Device if Over Safe Temperature" TRUE -process "Generate Programming File"

