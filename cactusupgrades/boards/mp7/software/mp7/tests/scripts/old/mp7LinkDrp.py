#!/bin/env python
import uhal
import sys


def prbsTest(hw):

    drp = hw.getNode('datapath.region.drp')
    mgt = hw.getNode('datapath.region.mgt')
    #ctrl = hw.getNode('ctrl')
    ctrl = hw.ctrl

    ctrl.getNode('csr.ctrl.quad_sel').write(0x0)        
    ctrl.getNode('csr.ctrl.chan_sel').write(0x0)        
    
#    mgt.getNode ("rw_regs.ch0.control.prbs_enable").write(0x1)
    mgt.getNode ("rw_regs.ch0.control.tx_fsm_reset").write(0x1)
    mgt.getNode ("rw_regs.ch0.control.tx_fsm_reset").write(0x0)
    drp.getClient().dispatch()        
    time.sleep(0.1)
    mgt.getNode ("rw_regs.ch0.control.rx_fsm_reset").write(0x1)
    mgt.getNode ("rw_regs.ch0.control.rx_fsm_reset").write(0x0)
    drp.getClient().dispatch()
                
                
                
    for i in range(10):    
        v = drp.getNode("rx_prbs_err_cnt").read()
        drp.getClient().dispatch()
        print  v.value()
        hw.log.info('PRBS Error Counter = %d', v.value())
        time.sleep(1)

    #mgt.getNode ("rw_regs.ch0.control.prbs_enable").write(0x0)

def qdrTest(hw):

    ram0 = hw.getNode('qdr.ram0')
    ram1 = hw.getNode('qdr.ram1')
    
    N=8
    # Fill list with random info
    ram0_data = [0]*N
    ram1_data = [0]*N
    
    #for i in range(N):
    #   xx.append( rand_uint32() )
    
    ram0_data[0]=0x00000000
    ram0_data[1]=0x00000000
    ram0_data[2]=0x00000000
    ram0_data[3]=0x00000000
    ram0_data[4]=0x9999AAAA
    ram0_data[5]=0xBBBBCCCC
    ram0_data[6]=0xDDDDEEEE
    ram0_data[7]=0xFFFF0000

    ram1_data[0]=0x11111111
    ram1_data[1]=0x11111111
    ram1_data[2]=0x11111111
    ram1_data[3]=0x11111111
    ram1_data[4]=0x9999AAAA
    ram1_data[5]=0xBBBBCCCC
    ram1_data[6]=0xDDDDEEEE
    ram1_data[7]=0xFFFF0000        

    # Write
    ram0.writeBlock(ram0_data)
    ram1.writeBlock(ram1_data)

    # Read back values
    mem0 = ram0.readBlock(N)
    ram0.getClient().dispatch()
    for x in mem0:
        print hex(x)

    mem1 = ram1.readBlock(N)
    ram1.getClient().dispatch()
    for x in mem1:
        print hex(x)
       
def eyeMeasure(hw, horizontal, vertical, prescale):

    drp = hw.getNode('datapath.region.drp')

    # Convert horizontal to 2's complement, 11 bit plus 'phase unification'
    if horizontal < 0:
        # Making python handle this appropriately is slightly painful...
        horizontal = -horizontal
        tmp = bytearray([(horizontal>>8) & 0x7, horizontal & 0xFF])
        # Invert bytes, add one and carry
        tmp[0] = tmp[0] ^ 0x7
        tmp[1] = tmp[1] ^ 0xFF
        tmp[1] += 1
        if tmp[1] == 0:
            tmp[0] += 1
        tmp[0] |= 0x8 # Phase unification
        horizontal = (int(tmp[0]) << 8) + int(tmp[1])

    drp.getNode ("es_horz_offset").write(horizontal);

    # Ignore DFE
    v = 0
    if vertical < 0:
        # v = 1 << 7.  Bug?  Value 'v' overwritten by next line.
        v = -vertical
    else:
        v = vertical

    # Vertical
    drp.getNode ("es_vert_offset").write(v);
    # Prescale
    drp.getNode ("es_prescale").write(prescale);
    
    # Trigger ES control
    drp.getNode ("es_control.run").write(0);
    drp.getNode ("es_control.run").write(1);
    drp.getClient().dispatch()

    while True:
        done = drp.getNode ("es_control_status.done").read();
        drp.getClient().dispatch()
        if done:
            break
    
    sample_cnt = done = drp.getNode ("es_sample_count").read();
    error_cnt = done = drp.getNode ("es_error_count").read();
    drp.getClient().dispatch()

    return [sample_cnt.value(), error_cnt.value()]



def eyeScan(hw):

    drp = hw.getNode('datapath.region.drp')
    mgt = hw.getNode('datapath.region.mgt')
    
    prescale_max = 8

    f = open('eye_' + '.log', 'w')
    
    #mgt.getNode ("rw_regs.ch0.control.prbs_enable").write(0x1);
            
    # Qual mask
    drp.getNode ("es_qual_mask_15to00").write(0xFFFF);
    drp.getNode ("es_qual_mask_31to16").write(0xFFFF);
    drp.getNode ("es_qual_mask_47to32").write(0xFFFF);
    drp.getNode ("es_qual_mask_63to48").write(0xFFFF);
    drp.getNode ("es_qual_mask_79to64").write(0xFFFF);

    # Sdata mask
    drp.getNode ("es_sdata_mask_15to00").write(0);
    drp.getNode ("es_sdata_mask_31to16").write(0);
    drp.getNode ("es_sdata_mask_47to32").write(0xFF00);
    drp.getNode ("es_sdata_mask_63to48").write(0xFFFF);
    drp.getNode ("es_sdata_mask_79to64").write(0xFFFF);
    drp.getClient().dispatch()

    for i in range(-32, 33, 2):  # Was step of 1
        sys.stdout.flush()
        for j in range(-127, 128, 2):  # Was step of 1
            print "i=", i, ", j=", j
            for p in range(0, prescale_max+1):

                y = eyeMeasure(hw, i, j, p)

                # Keep going up in prescale until error count is > 0
                # or we reach the maximum acceptable prescale
                if y[1] == 0 and p != prescale_max:
                    continue

                # Count must be greater than zero for a prescale of 2
                if y[1] == 0:
                    # 95% confidence minimum, count must be 65535
                    ret = 1.0 / (float(y[0]) * float(3 * (2 ** (p+1))))
                else:
                    ret = float(y[1]) / (float(y[0]) * float(2 ** (p+1)) )
        
                f.write(str(i)+','+str(j)+','+str(ret)+'\n')
                break

def mgtRateChange(hw):

    ctrl = hw.ctrl

    ctrl.getNode('csr.ctrl.quad_sel').write(0x0)        
    ctrl.getNode('csr.ctrl.chan_sel').write(0x1)  

    # All based on 125MHz RefClk. Not the best selection for a CPLL.  
    # Normally CPLL limited to multiplying by a factor of ~20.
    
    drp = hw.getNode('datapath.region.drp')
    drp_com = hw.getNode('datapath.region.drp_com')
    mgt = hw.getNode('datapath.region.mgt')
    
    use_qpll =  False # bool(int(sys.argv[1]))
    #mgt.getNode ("rw_regs.ch1.control.prbs_enable").write(0x1)
    mgt.getNode ("rw_regs.ch1.control.loopback").write(0x1)
    #mgt.getNode ("rw_regs.ch1.control.tx_use_cpll_n_qpll").write(0x0)
    #mgt.getNode ("rw_regs.ch1.control.tx_use_cpll_n_qpll").write(0x0)
    mgt.getClient().dispatch()
    
    rate = '2.5' # str(sys.argv[2])

    time.sleep(1)

    # Turn on the transceivers
    mgt.getNode ("rw_regs.ch1.control.tx_power_down").write(0x0);
    mgt.getNode ("rw_regs.ch1.control.rx_power_down").write(0x0);
    mgt.getClient().dispatch()

    time.sleep(1)

    # CPLL configurations
    # GTH CPLL has a nominal operating range between 1.6 GHz to 5.16 GHz.

    cpll_fbdiv = {
        '10.0'  : 6,  # 8  # PLL @ 5.0 GHz
        '6.25'  : 3, # 5  # PLL @ 3.125 GHz
        '6.0'   : 5, # 6  # PLL @ 3.0 GHz
        '5.0'   : 2, # 4  # PLL @ 2.5 GHz
        '4.0'   : 2, # 4  # PLL @ 2.0 GHz
        '3.125' : 3, # 5  # PLL @ 3.125 GHz
        '3.0'   : 5, # 6  # PLL @ 3.0 GHz
        '2.5'   : 2, # 4  # PLL @ 2.5 GHz
        '2.0'   : 2, # 4  # PLL @ 2.0 GHz
        '1.25'  : 2, # 4  # PLL @ 2.5 GHz
        '1.0'   : 2, # 4  # PLL @ 2.0 GHz
    }

    cpll_fbdiv_45 = {
        '10.0'  : 1, # 5
        '6.25'  : 1, # 5
        '6.0'   : 0, # 4
        '5.0'   : 1, # 5
        '4.0'   : 0, # 4
        '3.125' : 1, # 5
        '3.0'   : 0, # 4
        '2.5'   : 1, # 5
        '2.0'   : 0, # 4
        '1.25'  : 1, # 5
        '1.0'   : 0, # 4
    }

    cpll_refclk_div = {
        '10.0'  : 16, # 1
        '6.25'  : 16, # 1
        '6.0'   : 16, # 1
        '5.0'   : 16, # 1
        '4.0'   : 16, # 1
        '3.125' : 16, # 1
        '3.0'   : 16, # 1
        '2.5'   : 16, # 1
        '2.0'   : 16, # 1
        '1.25'  : 16, # 1
        '1.0'   : 16, # 1
    }

    cpll_rxout_div = {
        '10.0'  : 0, # 1
        '6.25'  : 0, # 1
        '6.0'   : 0, # 1
        '5.0'   : 0, # 1
        '4.0'   : 0, # 1
        '3.125' : 1, # 2
        '3.0'   : 1, # 2
        '2.5'   : 1, # 2
        '2.0'   : 1, # 2
        '1.25'  : 2, # 4
        '1.0'   : 2, # 4
    }

    cpll_txout_div = {
        '10.0'  : 0, # 1
        '6.25'  : 0, # 1
        '6.0'   : 0, # 1
        '5.0'   : 0, # 1
        '4.0'   : 0, # 1
        '3.125' : 1, # 2
        '3.0'   : 1, # 2
        '2.5'   : 1, # 2
        '2.0'   : 1, # 2
        '1.25'  : 2, # 4
        '1.0'   : 2, # 4
    }

    #cpll_rxcdr_cfg_1 = {
        #0   : 0x1040, # 1
        #1   : 0x1020, # 2
        #2   : 0x1010, # 4
        #3   : 0x1008, # 8
    #}

    # QPLL configurations.  Based on AR51625

    qpll_cfg = {
        '10.0'  : 0x04801C7,   # PLL @ 10.0 GHz
        '8.0'   : 0x04801C7,   # PLL @ 8.0 GHz
        '6.25'  : 0x0480187,   # PLL @ 12.5 GHz
        '5.0'   : 0x04801C7,   # PLL @ 10.0 GHz
        '4.0'   : 0x04801C7,   # PLL @ 8.0 GHz
        '3.125' : 0x0480187,   # PLL @ 12.5 GHz
        '2.5'   : 0x04801C7,   # PLL @ 10.0 GHz
        '2.0'   : 0x04801C7,   # PLL @ 8.0 GHz
        '1.25'  : 0x04801C7,   # PLL @ 10.0 GHz
        '1.0'   : 0x04801C7,   # PLL @ 8.0 GHz
    }

    qpll_refclk_div = {
        '10.0'  : 16, # 1
        '8.0'   : 16, # 1
        '6.25'  : 0,  # 2
        '5.0'   : 16, # 1
        '4.0'   : 16, # 1
        '3.125' : 0,  # 2
        '2.5'   : 16, # 1
        '2.0'   : 16, # 1
        '1.25'  : 16, # 1
        '1.0'   : 16, # 1
    }

    # Firmware uses different values for QPLL_LOCK_CFG, but these are equilavent.
    # See footnote on AR51625 (repeated below)
    
    # The revision 07/29/2013 changes are only required for frequencies 
    # in the range 11.85 to 12 GHz range. 
    # Note that in the frequency range of 8 to 11.3 GHz the value changed from 
    # 16'h05E8 to 16'h01E8 but these are equivalent for this frequency range.

    qpll_lock_cfg = {
        '10.0'  : 0x01e8,
        '8.0'   : 0x01e8,
        '6.25'  : 0x01e8,
        '5.0'   : 0x01e8,
        '4.0'   : 0x01e8,
        '3.125' : 0x01e8,
        '2.5'   : 0x01e8,
        '2.0'   : 0x01e8,
        '1.25'  : 0x01e8,
        '1.0'   : 0x01e8,
    }

    qpll_fbdiv = {
        '10.0'  : 0x120, # 80  Was 0x120
        '8.0'   : 0x0E0, # 64
        '6.25'  : 0x170, # 100
        '5.0'   : 0x120, # 80 Was 0x120
        '4.0'   : 0x0E0, # 64
        '3.125' : 0x170, # 100
        '2.5'   : 0x120, # 80
        '2.0'   : 0x0E0, # 64
        '1.25'  : 0x120, # 80
        '1.0'   : 0x0E0, # 64
    }

    qpll_fbdiv_ratio = {
        '10.0'  : 0x1,
        '8.0'   : 0x1,
        '6.25'  : 0x1,
        '5.0'   : 0x1,
        '4.0'   : 0x1,
        '3.125' : 0x1,
        '2.5'   : 0x1,
        '2.0'   : 0x1,
        '1.25'  : 0x1,
        '1.0'   : 0x1,
    }

    qpll_rxout_div = {
        '10.0'  : 0, # 1
        '8.0'   : 0, # 1
        '6.25'  : 0, # 1
        '5.0'   : 1, # 2
        '4.0'   : 1, # 2
        '3.125' : 1, # 2
        '2.5'   : 2, # 4
        '2.0'   : 2, # 4
        '1.25'  : 3, # 8
        '1.0'   : 3, # 8
    }

    qpll_txout_div = {
        '10.0'  : 0, # 1
        '8.0'   : 0, # 1
        '6.25'  : 0, # 1
        '5.0'   : 1, # 2
        '4.0'   : 1, # 2
        '3.125' : 1, # 2
        '2.5'   : 2, # 4
        '2.0'   : 2, # 4
        '1.25'  : 3, # 8
        '1.0'   : 3, # 8
    }

    # Following based on CDR setting < +/- 200 ppm 

    # Full-rate: RXOUT_DIV=1
    # 83'h0_0020_07FE_2000_C208_001A (> 6.6 Gb/s)
    # 83'h0_0020_07FE_2000_C208_0018 (<= 6.6 Gb/s)

    # Half-rate: RXOUT_DIV=2 (1.6 to 6.55 Gb/s)
    # 83'h0_0020_07FE_1000_C220_0018

    # Quarter-rate: RXOUT_DIV=4 (0.8 to 3.275 Gb/s)
    # 83'h0_0020_07FE_0800_C220_0018

    # One-eighth rate: RXOUT_DIV=8 (0.5 to 1.6375 Gb/s)
    # 83'h0_0020_07FE_0400_C220_0018

    qpll_rxcdr_cfg_5 = {
        '10.0'  : 0,
        '8.0'   : 0,
        '6.25'  : 0,
        '5.0'   : 0,
        '4.0'   : 0,
        '3.125' : 0,
        '2.5'   : 0,
        '2.0'   : 0,
        '1.25'  : 0,
        '1.0'   : 0,
    }

    qpll_rxcdr_cfg_4 = {
        '10.0'  : 0x0020,
        '8.0'   : 0x0020,
        '6.25'  : 0x0020,
        '5.0'   : 0x0020,
        '4.0'   : 0x0020,
        '3.125' : 0x0020,
        '2.5'   : 0x0020,
        '2.0'   : 0x0020,
        '1.25'  : 0x0020,
        '1.0'   : 0x0020,
    }

    qpll_rxcdr_cfg_3 = {
        '10.0'  : 0x07FE,
        '8.0'   : 0x07FE,
        '6.25'  : 0x07FE,
        '5.0'   : 0x07FE,
        '4.0'   : 0x07FE,
        '3.125' : 0x07FE,
        '2.5'   : 0x07FE,
        '2.0'   : 0x07FE,
        '1.25'  : 0x07FE,
        '1.0'   : 0x07FE,
    }

    qpll_rxcdr_cfg_2 = {
        '10.0'  : 0x2000,
        '8.0'   : 0x2000,
        '6.25'  : 0x2000,
        '5.0'   : 0x1000,
        '4.0'   : 0x1000,
        '3.125' : 0x1000,
        '2.5'   : 0x0800,
        '2.0'   : 0x0800,
        '1.25'  : 0x0400,
        '1.0'   : 0x0400,
    }

    qpll_rxcdr_cfg_1 = {
        '10.0'  : 0xC208,
        '8.0'   : 0xC208,
        '6.25'  : 0xC208,
        '5.0'   : 0xC220,
        '4.0'   : 0xC220,
        '3.125' : 0xC220,
        '2.5'   : 0xC220,
        '2.0'   : 0xC220,
        '1.25'  : 0xC220,
        '1.0'   : 0xC220,
    }

    qpll_rxcdr_cfg_0 = {
        '10.0'  : 0x001A,
        '8.0'   : 0x001A,
        '6.25'  : 0x0018,
        '5.0'   : 0x0018,
        '4.0'   : 0x0018,
        '3.125' : 0x0018,
        '2.5'   : 0x0018,
        '2.0'   : 0x0018,
        '1.25'  : 0x0018,
        '1.0'   : 0x0018,
    }

    #qpll_pma_rsv_1 = {
        #'10.0'  : 0x0000,
        #'8.0'   : 0x0000,
        #'6.25'  : 0x0000,
        #'5.0'   : 0x0000,
        #'4.0'   : 0x0000,
        #'3.125' : 0x0000,
        #'2.5'   : 0x0000,
        #'2.0'   : 0x0000,
        #'1.25'  : 0x0000,
        #'1.0'   : 0x0000,
    #}

    #qpll_pma_rsv_0 = {
        #'10.0'  : 0x0080,
        #'8.0'   : 0x0080,
        #'6.25'  : 0x0080,
        #'5.0'   : 0x0080,
        #'4.0'   : 0x0080,
        #'3.125' : 0x0080,
        #'2.5'   : 0x0080,
        #'2.0'   : 0x0080,
        #'1.25'  : 0x0080,
        #'1.0'   : 0x0080,
    #}

################################################################################################################

    if use_qpll:
        new_qpll_cfg = qpll_cfg[rate]
        new_qpll_refclk_div = qpll_refclk_div[rate]
        new_qpll_lock_cfg = qpll_lock_cfg[rate]
        new_qpll_fbdiv = qpll_fbdiv[rate]
        new_qpll_fbdiv_ratio = qpll_fbdiv_ratio[rate]
        # Common settings (i.e. clash possible)               
        new_rxout_div = qpll_rxout_div[rate]
        new_txout_div = qpll_txout_div[rate]
    else:
        #new_cpll_cfg = (cpll_refclk_div[rate] << 8) | (cpll_fbdiv_45[rate] << 7) | cpll_fbdiv[rate]
        new_cpll_refclk_div = cpll_refclk_div[rate]
        new_cpll_fbdiv = cpll_fbdiv[rate]
        new_cpll_fbdiv_45 = cpll_fbdiv_45[rate]
        # Common settings (i.e. clash possible)        
        new_rxout_div = cpll_rxout_div[rate]
        new_txout_div = cpll_txout_div[rate]
                
    # Constant.  Could be removed
    new_pma_rsv_0 = 0x0080
    new_pma_rsv_1 = 0x0000
    new_cpll_cfg = 0x00BC07DC

    # Common to both CPLL & QPLL
    new_rxcdr_cfg_0 = qpll_rxcdr_cfg_0[rate]
    new_rxcdr_cfg_1 = qpll_rxcdr_cfg_1[rate]
    new_rxcdr_cfg_2 = qpll_rxcdr_cfg_2[rate]
    new_rxcdr_cfg_3 = qpll_rxcdr_cfg_3[rate]
    new_rxcdr_cfg_4 = qpll_rxcdr_cfg_4[rate]
    new_rxcdr_cfg_5 = qpll_rxcdr_cfg_5[rate]

################################################################################################################
#
#        if use_qpll:
#            
#            # Update settings
#            drp_com.getNode ("qpll_fbdiv_ratio").write(new_qpll_fbdiv_ratio)
#            drp.getClient().dispatch()

    #v2 = drp_com.getNode ("qpll_fbdiv").read()
    #drp.getClient().dispatch()
    #print 'QPLL_FBDIV:', hex(v2)
    
    #drp_com.getNode ("qpll_fbdiv").write(new_qpll_fbdiv)
    #drp.getClient().dispatch()
    
#            drp_com.getNode ("qpll_lock_cfg").write(new_qpll_lock_cfg)
#            drp.getClient().dispatch()
#            drp_com.getNode ("qpll_cfg_15to00").write(new_qpll_cfg & 0xFFFF)
#           drp.getClient().dispatch()
#            drp_com.getNode ("qpll_cfg_26to16").write((new_qpll_cfg >> 16) & 0x7FF)
#            drp.getClient().dispatch()
#            drp_com.getNode ("qpll_refclk_div").write(new_qpll_refclk_div)
#            drp.getClient().dispatch()
#        

    #v2 = drp_com.getNode ("qpll_fbdiv").read()
    #drp.getClient().dispatch()
    #print 'QPLL_FBDIV:', hex(v2)
    
#            
#        v1 = drp_com.getNode ("qpll_fbdiv_ratio").read()#
#        v2 = drp_com.getNode ("qpll_fbdiv").read()
#        v3 = drp_com.getNode ("qpll_refclk_div").read()
#            drp_com.getClient().dispatch()
#            
#            # print 'QPLL_CFG:', hex(((x.gt_drp_quad_read(quad, QPLL_REFCLK_DIV) & 0x7FF) << 16) | x.gt_drp_quad_read(quad, QPLL_CFG))
#            # print 'QPLL_LOCK_CFG:', hex( drp_common.getNode ("qpll_lock_cfg").read() )
#            
#            print 'QPLL_FBDIV_RATIO:', hex(v1)
#            print 'QPLL_FBDIV:', hex(v2)
#            print 'QPLL_REFCLK_DIV:', hex(v3)


################################################################################################################

    # Update chan settings
    drp.getNode ("cpll_fbdiv").write(new_cpll_fbdiv);
    drp.getNode ("cpll_fbdiv_45").write(new_cpll_fbdiv_45);
    drp.getNode ("cpll_refclk_div").write(new_cpll_refclk_div);
    drp.getNode ("cpll_cfg_15to00").write(new_cpll_cfg & 0xFFFF);
    drp.getNode ("cpll_cfg_28to16").write((new_cpll_cfg >> 16) & 0x1FFF);
    
    # Update common settings
    drp.getNode ("pma_rsv_0").write(new_pma_rsv_0);
    drp.getNode ("pma_rsv_1").write(new_pma_rsv_1);
    drp.getNode ("txout_div").write(new_txout_div);
    drp.getNode ("rxout_div").write(new_rxout_div);
    drp.getNode ("rxcdr_cfg_0").write(new_rxcdr_cfg_0);
    drp.getNode ("rxcdr_cfg_1").write(new_rxcdr_cfg_1);
    drp.getNode ("rxcdr_cfg_2").write(new_rxcdr_cfg_2);
    drp.getNode ("rxcdr_cfg_3").write(new_rxcdr_cfg_3);
    drp.getNode ("rxcdr_cfg_4").write(new_rxcdr_cfg_4);
    drp.getNode ("rxcdr_cfg_5").write(new_rxcdr_cfg_5);





#        v1 = drp.getNode ("txout_div").read();
#        v2 = drp.getNode ("rxout_div").read();
#        drp.getClient().dispatch()        
#
#       # Channel-specific
#        print 'TXOUT_DIV:', hex(v1)
#        print 'RXOUT_DIV:', hex(v2)

    #print 'RXCDR_CFG:', hex(x.gt_drp_channel_read(quad, channel, RXCDR_CFG_5) << 80 | x.gt_drp_channel_read(quad, channel, RXCDR_CFG_4) << 64 | x.gt_drp_channel_read(quad, channel, RXCDR_CFG_3) << 48 | x.gt_drp_channel_read(quad, channel, RXCDR_CFG_2) << 32 | x.gt_drp_channel_read(quad, channel, RXCDR_CFG_1) << 16 | x.gt_drp_channel_read(quad, channel, RXCDR_CFG_0))
    #print 'PMA_RSV:', hex(x.gt_drp_channel_read(quad, channel, PMA_RSV_1) << 16 | x.gt_drp_channel_read(quad, channel, PMA_RSV_0))

    #mgt.getNode ("rw_regs.common.control.soft_reset").write(0x0);
    #mgt.getNode ("rw_regs.common.control.soft_reset").write(0x1);
    #mgt.getClient().dispatch()
    #mgt.getNode ("rw_regs.common.control.soft_reset").write(0x0);
    #mgt.getClient().dispatch()
    
    mgt.getNode ("rw_regs.ch1.control.tx_fsm_reset").write(0x1);
    mgt.getNode ("rw_regs.ch1.control.rx_fsm_reset").write(0x1);
    mgt.getClient().dispatch()
   

    mgt.getNode ("rw_regs.ch1.control.tx_fsm_reset").write(0x0);
    mgt.getClient().dispatch()
    mgt.getNode ("rw_regs.ch1.control.rx_fsm_reset").write(0x0);
    mgt.getClient().dispatch()

    #mgt.getNode ("rw_regs.ch1.control.tx_power_down").write(0x1);
    #mgt.getClient().dispatch()
    #mgt.getNode ("rw_regs.ch1.control.tx_power_down").write(0x0);
    #mgt.getClient().dispatch()
    #mgt.getNode ("rw_regs.ch1.control.rx_power_down").write(0x1);        
    #mgt.getClient().dispatch()
    #mgt.getNode ("rw_regs.ch1.control.rx_power_down").write(0x0);
    #mgt.getClient().dispatch()
    #time.sleep(1)
              
def ReadDrp(hw):
    ctrl      = hw.ctrl
    datapath       = hw.datapath

    hw.log.info('DRP Test')

    ctrl.getNode('csr.ctrl.quad_sel').write(0)
    ctrl.getClient().dispatch()
    v = ctrl.getNode('csr.ctrl.quad_sel').read()
    ctrl.getClient().dispatch()
    print ' quad_sel  :',v

    ctrl.getNode('csr.ctrl.chan_sel').write(0)
    ctrl.getClient().dispatch()
    v = ctrl.getNode('csr.ctrl.chan_sel').read()
    ctrl.getClient().dispatch()
    print ' chan_sel  :',v
    
    #reg = datapath.getNode ("drp").read();
    #datapath.getClient().dispatch()
    #print "reg = ", hex(reg)
    
    #reg = datapath.getNode ("drp.r000").read();
    #datapath.getClient().dispatch()
    #print "r000 = ", hex(reg)

    reg = datapath.getNode ("drp.es_horz_offset_etc").read();
    datapath.getClient().dispatch()
    print "es_horz_offset_etc = ", hex(reg)

    reg = datapath.getNode ("drp.es_control").read();
    datapath.getClient().dispatch()
    print "es_control = ", hex(reg)

    
    print ' '
    
    
########################################################

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
manager = uhal.ConnectionManager("file://${MP7_TESTS}/etc/mp7/connections-test.xml")
hw = manager.getDevice("DAQTEST")

# Grab device's id, or print it to screen
device_id = hw.id()
print hw
# Grab the device's URI
device_uri = hw.uri()

eyeScan

print "Obtain Eye Scan"
eyeScan(hw)


