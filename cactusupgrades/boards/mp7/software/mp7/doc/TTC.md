

```
 <node id="ctrl" address="0x0">
            <node id="ttc_enable" mask="0x1"/>
            <node id="err_ctr_clear" mask="0x2"/>
            <node id="rst" mask="0x4"/>
            <node id="int_bc0_enable" mask="0x8"/>
            <node id="ctr_clear" mask="0x40"/>
            <node id="l1a_force" mask="0x80"/>
            <node id="throttle_en" mask="0x100"/>
            <node id="b_cmd_force" mask="0x200"/>
            <node id="ttc_sync_en" mask="0x400"/>
            <node id="ttc_sync_bx" mask="0xfff000"/>
            <node id="b_cmd" mask="0xff000000"/>
        </node>
```

So
To issue an l1a

 - With ttc_sync_en low, just hit l1a_force
    It will happen as soon as there is not an external or 
 - With ttc_sync_en high, hit l1a_force
    It will happen on that BX as soon as there is not an 'BX' is defined as the value of the bunch counter in 

It should be consistent with TTC history

To issue a b command

 - With ttc_sync_en low, program the b command into b_cmd
    Hit b_cmd_force
    It happens as soon as there is not an external b 
 - With ttc_sync_en high, program the b command into b_cmd
    Hit b_cmd_force

It will happen on that BX as soon as there is no bc0 on that BX
If you choose BX3540, and internal BC0 is active
It will therefore never happen
Finally
You can see if there is either an l1a or bcmd pending High is there is anything waiting to occur
...

        <node id="tmt" address="0x18" description="TMT cycle control" fwinfo="endpoint;width=0">
                <node id="max_phase" mask="0xf"/>
                <node id="phase" mask="0xf0"/>
                <node id="l1a_offset" mask="0xf00"/>
                <node id="pkt_offset" mask="0xf000"/>
                <node id="en" mask="0x10000"/>
        </node>

 - max_phase - essentially the time period + 1 i.e a value of 5 means it will fire the flag every 6bx
 - phase - phase of flags which is configurable up to the first 15bx
 - l1a_offset - offset the l1a flag with resepct to the time period
 - pkt_offset - controls flag to formatter, not currently hooked up to anything
 - en - enable this block

Comments?