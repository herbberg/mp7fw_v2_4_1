# MP7 Buffers

As a reminder, each MGT channel has associated rx- and tx-side buffers that are independently configurable. The current implementation uses 1024-deep buffers that are 36 bits wide. This means that when using a 240MHz clock, a maximum of 170BX of data can be stored or played back.

## Control registers
```
	<node id="csr" address="0x0" description="Control / status register" fwinfo="endpoint;width=2">
	<node id="mode" address="0x0">
```

### Basic mode
These registers set the operation mode of each buffer.

```
<node id="mode" mask="0x3"/>
```

Sets the basic operation mode of the buffer:

 * **0**: latency buffer only (normal operation mode during running)
 * **1**: capture
 * **2**: playback (play once per orbit)
 * **3**: playback (play sequence repeatedly)
 
### Data source
```
<node id="datasrc" mask="0xc"/>
```

Selects the origin of the data that goes to the payload (for rx-side buffers) or to the MGT transmitter (for tx-side buffers):

 * **0**: MGT input data (rx) / data from payload (tx) (normal operation mode during running)
 * **1**: playback buffer output
 * **2**: pattern generator output
 * **3**: all-zeroes pattern
 
### DAQ bank
```
<node id="daq_bank" mask="0xf0"/>
```

Sets the DAQ bank that this buffer is part of for DAQ readout purposes. Each DAQ bank has independent capture and readout signals. This register is not used in test mode.

### Capture bx control
```
<node id="trig_bx" mask="0xfff00"/>
```

Defines the BX number corresponding to the first location in the buffer, for capture or playback. For capture, data will be written into loc 0 on this BX. For playback, data will be written to the buffer block output from loc 0 on this BX. Capture or playback always starts on the first clock cycle of any given BX.

### Words to capture
```
<node id="max_word" mask="0xfff00000"/>
```
Sets the location of the last word to be played back or captured. Note that this is words, not BX.

## Data control
```
<node id="data_ctrl" address="0x1">
```

These registers control there response of the buffers to the strobe signals on the data bus, used to move data at rates less the maximum 6 words / BX.

### Strobe control
```
<node id="cap_stb_mask" mask="0x1"/>
```

Controls the response of the the capture buffer to strobe signals:

 * **0**: Capture data only when strobe is high
 * **1**: Capture data regardless of the strobe signal

##
```
<node id="pb_stb_gen" mask="0x2"/>
```

Enables generation of pattern-based strobe signals from the playback buffer:

 * **0**: do not generate any strobe pattern
 * **1**: generate strobe signals according to the strobe pattern configuration (below)


```
<node id="pb_stb_en" mask="0x4"/>
```

Controls the overall output of strobes from the playback buffer:

 * **0**: hold strobe high at all times (backward compatible with old firmware)
 * **1**: issues strobes as the 'or' of the stored strobe in the buffer with the pattern-based strobe

### Patter/Zero valid

```
<node id="pb_invalid" mask="0x8"/>
```

Controls whether pattern / zero data is valid or invalid during active playback period:

 * **0**: data is valid
 * **1**: data is invalid


### Strobe pattern
```
<node id="pb_stb_patt" mask="0x3f00"/>
```

Specifies the strobe pattern to be generated when tx_stb_gen is high. Each bit represents one cycle of a given BX (i.e. six bits for 240MHz operation), with the LSB being the first cycle of each BX. Each bit controls whether strobe is asserted or not on that cycle, e.g. a bit pattern of '001001' in this register will cause 80MHz of strobes.

##  Buffer status

```
<node id="stat" address="0x2">
```

These registers indicate the buffer status.

### Locked
```
<node id="locked" mask="0x1"/>
```

No longer used - should be removed in future firmware versions.


### Capture done
```
<node id="cap_done" mask="0x2"/>
```

Asserted when a capture buffer is full. Software should wait until this bit is high before reading out the capture buffer contents.

## Data buffer

```
<node id="buffer" address="0x4" description="Capture / playback buffers for MGT channel" fwinfo="endpoint;width=1">
	<node id="addr" address="0x0"/>
	<node id="data" address="0x1" size="0x800" mode="port"/>
```
The buffer data has the following format: each location is 36 bits wide, read out as a pair of sequential words, lowest bits first - i.e. word 0 contains the lowest 18 bits of the full word (plus zeroes in higher order bits), word 1 contains the highest 18 bits. The meaning of the bits is as follows:

* **36** : strobe (captured or to be written with data)
* **35** : valid (captured or to be written with data)
* **31:0** : data

Note that for mode 2 playback, the 'valid' output from the playback buffer is the 'and' of the valid bit stored in the buffer for each data word, and an overall 'valid' flag that's asserted during the active data period defined by trig_bx and max_word.