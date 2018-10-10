# Readout


## TO ADD
[25/04/15 20:09:39] Dave Newbold: The ipbus to the readout block has changed
[25/04/15 20:09:48] Dave Newbold: The good news is it's much simpler now
[25/04/15 20:10:00] Dave Newbold:

```
         <node id="fifo_flags" address="0x0" permission="r">
                <node id="fifo_cnt" mask="0x3ffff"/>
                <node id="fifo_valid" mask="0x1000000"/>
                <node id="fifo_warn" mask="0x2000000"/>
                <node id="fifo_full" mask="0x4000000"/>
                <node id="fifo_empty" mask="0x8000000"/>
        </node>
        <node id="data" address="0x1" size="0x3000" mode="port" permission="r"/>

```
[25/04/15 20:10:14] Dave Newbold: Just read three words per FIFO entry. The rest is automatic
[25/04/15 20:10:25] Dave Newbold: So you can do a block read now

```
[25/04/15 20:11:45] Dave Newbold: So suppose fifo_cnt = 5
[25/04/15 20:11:52] Dave Newbold: Then you read out 5 * 3 = 15 words via ipbus
[25/04/15 20:11:59] Dave Newbold: The first word is the lower data 32 bits
[25/04/15 20:12:03] Dave Newbold: Second is the upper 32 bits
[25/04/15 20:12:05] Dave Newbold: Third is flags
[25/04/15 20:12:15] Dave Newbold: FIFO reading is done automatically when you read the flags
```

## DAQ Control registers
```
<node id="csr" address="0x0" description="DAQ/Readout CSR" fwinfo="endpoint;width=1">
```


```
<node id="ctrl" address="0x0”> 
<node id="src_sel" mask="0x1”/>
```

Data source selection:
0 - selects the real react control
1 - selects the fake data source

```
<node id="amc13_en" mask="0x2”/>
```

Enables DAQ link between MP7 and amc13

```
<node id="auto_empty" mask="0x4”/>
```

Controls whether the buffer automatically empties itself as if the AMC13 were active. This feature is for rate testing of the internal DAQ path.

## DAQ Stat registers

```
<node id="stat" address="0x1">
<node id="src_err" mask="0x1”/>
```

Set if the fake event source trigger FIFO fills up; this should only happen if we abuse the system by using huge rates.

```
<node id="rob_err" mask="0x2”/>
```

Readout buffer in error. When does that happen?

```
<node id="amc13_warn" mask="0x4”/>
```

A warning signal from the AMC13 interface that its buffer is getting full. I have little idea what this actually means..

```
<node id="amc13_rdy" mask="0x8”/>
```

The ready bit for the amc13 interface.

```
<node id="evt_count" mask="0xffff0000”/>
```

Event counter. At what stage the events are counted? Outgoing events? Incoming requests?

```
<node id="tts_csr" address="0x2" description="TTS CSR" fwinfo="endpoint;width=1">
```

## TTS control block

```
<node id="ctrl" address="0x0">
<node id="tts" mask="0xf”/>
```

 — ??

```
<node id="board_rdy" mask="0x10”/>
```

Software needs to set this to allow the TTS state machine to transition to 'ready' state from 'error'. In other words, set this once the DAQ is all set up and the board is ready to go.

```
<node id="tts_force" mask="0x20”/>
```

Force the TTS status.
1 = warning
2 = out of sync
4 = busy
8 = ready
12 = error
0 or 15 = disconnected

## TTS Stat registers

```
<node id="stat" address="0x1">
<node id="tts_stat" mask="0xf”/>
```

The TTS status of the board.

```
<node id="buffer" address="0x4" size="0x4" description="DAQ/Readout buffer" fwinfo=" endpoint;width=2">
```

## DAQ Readout buffer

```
<node id="fifo_flags" address="0x0" permission="r”> 
<node id="fifo_empty" mask="0x8”/>
```

Checks if the readout buffer is empty...

```
<node id="fifo_full"  mask="0x4”/>
```

...Or full

```
<node id="fifo_warn"  mask="0x2”/>
```

The warning flag

```
<node id="fifo_valid" mask="0x1”/>
```

If the data is valid

```
<node id="dataL" address="0x1" permission="r”/> — first half of the 64-bit word to be sent to the AMC13
<node id="dataH" address="0x2" permission="r”/> — second half the 64-but word to be sent to the AMC13
<node id="data_flags" address="0x3" permission="r”> — various flags/header info
        <node id="amc13_hdr" mask="0x80”/> — contains the AMC13 header...
        <node id="amc13_trl" mask="0x40”/> — … and trailer
        <node id="daqbus_start" mask="0x8”/> — The start bit for the daq_bus, tells readout buffer to start writing
        <node id="daqbus_valid" mask="0x4”/>
```

Tells user if the data was valid, only used in the buffers and not passed to AMC13

```
<node id="daqbus_start_del" mask="0x2”/>
<node id="daqbus_valid_del" mask="0x1”/> — ???
```
These two bits above are the start and valid bits, but the for the top 32b word of the 64b readout word (i.e. dataH)

```
<node id="hist" module="file://state_history.xml" address="0x8”/> 
```
I think these two parts are standard components, probably already explained
State history of what?

```
<node id="tts_hist" module="file://state_history.xml" address="0xc"/>
```

TTS State history

```
<node id="readout_ctrl" module="file://mp7_readout_control.xml" address="0xf0”/>
```

See the next section

# Readout Control

```
<node description="Readout Control" fwinfo="endpoint">
```

Readout control block

```
<node id="delay" address="0x0" description="Delay Select" fwinfo="endpoint;width=3">
<node id="l1a_delay" address="0x0" />
```

Delays the processing of the L1A in the readout control by N clk cycles (default 0)

```
<node id="capture_size" address="0x1”/>
```

How many clk cycles worth of data you want to store in the derand, (default is 6)


```
<node id="token_delay" address="0x2" />
```

Delays the time in clk cycles between issuing the capture and putting the token down the daq_bus. Helpful for tuning the time it takes for the data to be written into the derand. (default 30)

```
<node id="bank_enable" address="0x3" />
```

Enable the capture of different bank categories. The enabled banks in the bitword are captured from the buffers with the corresponding bank bits set.


```
<node id="event_size" address="0x4" />
```

Number of clk cycles you expect the event to be - so this is the size in number of clk cycles the header + data in the daq_bus is expected to be. This number is also put in the header of the payload to the AMC13 (default 131)

