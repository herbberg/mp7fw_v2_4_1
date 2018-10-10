# MP7 State history


This ticket documents the software interface to the 'state history' block. This block is used in several places in the base firmware, so far:
- To record incoming TTC commands
- To record TTS state transitions
- To record debugging info for readout chain
The block records a user-defined 12b state data word every time it receives a trigger signal. This forms part of a 72b word including other information:
* **71:60** state_data
* **59:36** event number
* **35:12** orbit number
* **11:0** bunch number
By default, these words are stored in a 1024 entry deep circular buffer, such that older entries get overwritten by new ones after 1024 triggers (the buffer length is configurable at build time). The state history block allows the trigger to be based on a mask register, to allow certain state changes to cause triggers and not others, under software control (more below).
The address table looks like:

```
<node description="State history buffer" fwinfo="endpoint">
<node id="csr" address="0x0" description="State history CSR" fwinfo="endpoint;width=1">
<node id="ctrl" address="0x0">
<node id="freeze" mask="0x1"/>
```
When asserted, causes the contents of the buffer to be frozen for software inspection, and any new triggers to be discarded.

```
<node id="rst" mask="0x2"/>
```

Resets the buffer pointers (but not content) when asserted.

```
<node id="mask" mask="0xff00"/>
```

Provides masking information to the user-defined trigger logic. The meaning of the eight bits is specific to particular application.

```
<node id="stat" address="0x1">
<node id="ptr" mask="0xffff"/>
```

The write pointer into the buffer. This is exposed so that software knows the range of valid entries to read. The exact meaning depends on the flag below.

```
<node id="wrap_flag" mask="0x10000"/>
```

Indicates whether more than 1024 triggers have been recorded.
If this flag *is not* set, software should read out words starting at address 0 and ending at address ptr -1. The entries will be in time order.
if this flat *is* set, the buffer has wrapped around. Software should read out words starting at address ptr and ending at address ptr - 1 (i.e. 1024 words in total). The entries will be in time order.

```
<node id="buffer" address="0x2" description="History buffer" fwinfo="endpoint;width=1">
```

A standard 'ported ram', 72b wide (so a group of four successive 18b words represents one buffer address). Read only.

```
<node id="addr" address="0x0"/>
```

The buffer address to read (bottom two bits represent location within one buffer entry, so should always initially be "00").

```
<node id="data" address="0x1" size="0x800" mode="port"/>
```

The data port; only the bottom 18 bits are significant.
For the TTC application, the state_data is "0000000" & ttc_l1a & ttc_cmd. The trigger is any l1a or ttc command. mask(0) prevents bc0 causing a trigger. mask(1) prevents l1 from causing a trigger.
    For the TTS application, the state data is X"00" & tts. The trigger is any transition in TTS state.