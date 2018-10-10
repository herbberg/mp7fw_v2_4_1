# MP7 Channel Alignment 

It is fairly simple I hope. If you can let me have comments today, I can go ahead and do it.

The alignment block is independent for each rx channel. It consists of:

- A delay element (i.e. a shift register) with the delay (in cycles) under software control

- A means of monitoring the BX / cycle on which the alignment flag is set

- A counter to monitor whether alignment errors are observed during running

The procedure to align is:

- Either (test mode): for each active channel, establish the minimum possible delay by decreasing it from the startup value and monitoring for errors, and measure the alignment between channels

- Or (running mode): take a set of established pre-programmed delays

- Adjust the delay for each channel

- Use the monitor to confirm that the data is stably coming in at the expected BX / cycle

- Periodically monitor the error counters

The software interface is a control register and a status register. It is largely the same as the bc0_mon block. In fact, I propose to use a single piece of firmware for both.

```
    <node id="ctr_rst" mask="0x1"/>
```

Resets the error counter and bx status register on rising edge.

```
    <node id="freeze" mask="0x2"/>
```

When asserted, locks in the current bx value for comparison with the incoming signal (NB: is this actually necessary in fact? If the signal is stable anyway, we don't really need this).

```
    <node id="del_rst" mask="0x4"/>
```

Resets the delay length on rising edge (also resets counters)

```
    <node id="del_inc" mask="0x8"/>
```

Increases the delay length by one step on rising edge (also resets counters)

```
    <node id="del_dec" mask="0x10"/>
```

Decreases the delay length by one step on rising edge (also resets counters)

```
    <node id="cyc" mask="0xf"/>
```

The 240MHz cycle (i.e. 0 -> 5) of the rising edge of the alignment signal

```
    <node id="bx" mask="0xfff0"/>
```

The local BX (i.e. 0 -> 0xdeb) of the rising edge of the alignment signal

```
    <node id="err_cnt" mask="0xffff0000"/>
```

The number of times the rising edge did not occur at the same point in the orbit as the preceding orbit, or was missing. Maximum value of 0xffff

