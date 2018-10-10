#!/usr/bin/python
import logging
import time
import readline
import sys
import re

from mp7.tools.log_config import initLogging
from mp7.tools.unpacker import unpackROBEvent, unpackAMC13Protocol
# from p5.tcds import TCDSController
import p5.tcds
# TCDS Interface


import uhal
import amc13
import mp7
import mp7.cmds.infra as infra
import mp7.cmds.datapath as datapath
import mp7.cmds.readout as readout
import mp7.tools.helpers as helpers

import daq.stage1 as stage1


class DAQSimpleTester(object):
    def __init__(self, a13, mp7daq, pi, ici):
        self._amc13 = a13
        self._mp7 = mp7daq
        self._pi = pi
        self._ici = ici
        self._args = args
        self._fakesize = 100

    @property
    def fakesize(self):
        return self._fakesize
    
    @fakesize.setter
    def fakesize(self,value):
        self._fakesize = value


    def linkStatus(self, msg = None ):

        mp7daq = self._mp7
        a13 = self._amc13

        if msg:
            logging.info('- %s ---' % msg)


        ro_stat = mp7.snapshot(mp7daq.getReadout().getNode('csr.stat'))
        tts_stat = mp7.snapshot(mp7daq.getReadout().getNode('tts_csr.stat'))


        # Final Summary
        # log = logging.notice if ro_stat['amc13_rdy'] else logging.warning
        # for k in ['amc13_rdy']:
        #     log('   %s = %s', k, ro_stat[k])


        logging.debug(' MP7 Side')       
        for k in sorted(ro_stat):
            logging.debug('   readout.csr.stat.%s = %s', k,ro_stat[k])
        
        for k in sorted(tts_stat):
            logging.debug('   readout.tts_csr.stat.%s = %s', k,tts_stat[k])
    
        logging.debug('-'*80)

        slot = mp7daq.slot

        logging.debug(' AMC13 Side')
        amc13ttsenc = {
            0: 'RDY',
            1: 'OFW',
            2: 'BSY',
            4: 'SYN',
            8: 'ERR',
            16: 'DIS',
        }
    
        amc13ttsraw = {
            0: 'DIS',
            1: 'OFW',
            2: 'SYN',
            4: 'BSY',
            8: 'RDY',
            16: 'DIS',
        }
    
        # AMC13 global variables
        regs = [
            'CONF.RUN',
            'STATUS.AMC_TTS_STATE',
            'STATUS.T1_TTS_STATE',
            # 'STATUS.SFP.TTS_SFP_ABSENT',
            # 'STATUS.SFP.TTS_LOS_LOL',
            # 'STATUS.SFP.TTS_TX_FAULT',
        ]
#        for r in regs:
#            logging.info('   %s : %d', r,a13.read(a13.Board.T1, r))
#        
#
#        for s in [slot]:
#            rdy = a13.read(a13.Board.T1,'STATUS.AMC%02d.AMC_LINK_READY_MASK' % s)
#            enc = a13.read(a13.Board.T1,'STATUS.AMC%02d.TTS_ENCODED' % s)
#            raw = a13.read(a13.Board.T1,'STATUS.AMC%02d.TTS_RAW' % s)
#    
#            logging.debug('   AMC%02d.AMC_LINK_READY_MASK : %d', s, rdy )
#            logging.debug('   AMC%02d.TTS_ENCODED : %d (%s)', s, enc, amc13ttsenc[enc] )
#            logging.debug('   AMC%02d.TTS_RAW : %d (%s)', s, raw, amc13ttsraw[raw] )
#            logging.debug('-'*80)
        
        return ro_stat['amc13_rdy']


    def resetEverything( self ):

        a13 = self._amc13
        mp7daq = self._mp7
    
        # a13.getStatus().Report(1)
        self.linkStatus('Pre-AMC13 Reset')
        #----------------------------------
        # KH: amc13->initialize();
        #----------------------------------
    
        a13.reset(a13.Board.T1);
    
        a13.reset(a13.Board.T2);
        
        a13.endRun();
    
        a13.sfpOutputEnable(0);
    
        a13.AMCInputEnable(0);
    
        # configure TTC commands
        a13.setOcrCommand(0x8);
    
        # a13.write(a13.Board.T1,'CONF.BCN_OFFSET',0xfff-23+1);
        a13.write(a13.Board.T1,'CONF.BCN_OFFSET',0xdec-24); # No idea whre -1 comes from...
    
        # Clear the TTS inputs mask
        a13.write(a13.Board.T1, 'CONF.AMC.TTS_DISABLE_MASK', 0x0);
        
        # enable local TTC signal generation (for loopback fibre)
        a13.localTtcSignalEnable(False)
    
        # a13.monBufBackPressEnable(False)

        # a13.configurePrescale(0,1)
        
        # activate TTC output to all AMCs
        a13.enableAllTTC();
    

        self.linkStatus('Post-AMC13 Reset')

        mp7daq.reset('external','external','external')
        # mp7daq.reset('internal','internal','internal')
        self.linkStatus('Post MP7 Reset')

    #---
    def configMP7DAQ(self, fake = True, inject=None):

        mp7daq = self._mp7

        setup = readout.Setup()
        setup(mp7daq, fake, self._fakesize, internal=False, drain=None, bxoffset=1)

        if fake:
            return
        mgts = datapath.MGTs()
        mgts(mp7daq, orbittag=False, loopback=True, invpol=False, alignTo=None, alignMargin=3, config=True, align=True, check=True, forcepattern=None, threeg=False, dmx_delays=False)

        # Configure the buffers in stage1 demo mode
        s1demo = stage1.ConfigS1Demo()
        # add = 12 = 2bx * 6 to take into accout validation events
        s1demo(mp7daq, 'loop', 'full', 'events', 12, inject)
        # s1demo(mp7daq, 'algo', 'full', 'counts', 12)

        # Load the menu
        romenu = readout.LoadMenu()
        romenu(mp7daq, '${MP7_TESTS}/python/daq/stage1.py','menu')


    def configAMC13( self, toDAQ = False):
    
        logging.info('AMC13 DAQLink = %s', toDAQ)

        a13 = self._amc13
        slot = self._mp7.slot

        bitmask = (1 << (slot - 1));

        self.linkStatus('Before enabling AMC13 inputs')
    
        a13.AMCInputEnable(bitmask);

        #----------------------------------
        # KH: amc13->configureLocalDAQ(mp7_slots)
        #----------------------------------
        # set FED ID and S-link ID
        # Stage1 FED
        # FED_ID = 1352    
    
        a13.setFEDid(1352); # notes this sets the CONF.ID.SOURCE_ID register
    
        # a13.write(a13.Board.T1, 'CONF.ID.FED_ID', FED_ID);
        
        # enable incoming DAQ link.
        # Note that an MP7 reset brings down the DAQ link, and it has to be
        # re-enabled with the following command on the AMC13 afterwards!
        # Note also that you must not enable channels here that we are not
        # expecting data from. Enaqbled but unconnected channels seem to prevent
        # the AMC13 from building events.
        # bit mask:  0x001 = slot  1
        #            0x002 = slot  2
        #            0x004 = slot  3
        #            ...
        #            0x800 = slot 12
    
        # enable outgoing DAQ link on the topmost SFP if readou via FEROL
        # note that if the daq link is enabled,
        # you cannot read events from the AMC13 monitoring buffer
        a13.daqLinkEnable(toDAQ);
    
        # SFP 1 connected
        a13.sfpOutputEnable(1 if toDAQ else 0);
        
        self.linkStatus('Before DAQ reset')
    
        # a13.resetDAQ();
        
        a13.resetCounters();
        
        self.linkStatus('Before T1 Reset')

        # reset the T1
        a13.reset(a13.Board.T1)
    
        self.linkStatus('AMC13 config completed')


    def testReset(self, fake=True):

        # self._amc13.getFlash().loadFlash()

        # for i in xrange(20):
            # logging.info('%d', i)
            # time.sleep(1)
        self.resetEverything()
        
        # self.configMP7AlgoPatt()

        self.configMP7DAQ(fake)

        # self.preConfigAMC13()

        self.configAMC13()

        ro = mp7daq.getReadout()
        # ro.getNode('tts_csr.ctrl.tts_force').write(0)
        # ro.getClient().dispatch()

        debug = ro.getNode('csr.stat.debug').read()
        ro.getClient().dispatch()


        decoded = {}
        decoded['0.    rx_reset_done'] = (debug >> 0) & 0x1
        decoded['1.    tx_reset_done'] = (debug >> 1) & 0x1
        decoded['2.    data_valid']    = (debug >> 2) & 0x1
        decoded['3.    rxrstdbg']      = (debug >> 3) & 0x1
        decoded['4.    cplllock']      = (debug >> 4) & 0x1
        decoded['6.    rxcharisk']     = (debug >> 6) & 0x1
        decoded['7.    rxcharisk']     = (debug >> 7) & 0x1
        decoded['8-23. rxdata']        = (debug >> 8) & 0xffff 

        for x in sorted(decoded):
            logging.info('%s: 0x%x', x, decoded[x])

        self._amc13.startRun()

        self.linkStatus('AMC13 started')

    def testTTS(self):

        self.resetEverything()
        
        self.configMP7DAQ()
    
        self.configAMC13()

        # AMC13 must go in Run Mode
        self._amc13.startRun()
    
        self.linkStatus('TTS check - initial')
    

        time.sleep(1)

        ttsStates = [
            ('Warning', 0x1),
            ('OOS', 0x2),
            ('Busy', 0x4),
            ('Ready', 0x8),
            ('Error', 0xc),
            ('Disconnected', 0xf),
        ]
    
        for state,code in ttsStates:
            logging.notice('TTS check:  Force %s', state)
            mp7daq.hw().getNode('readout.tts_csr.ctrl.tts_force').write(1)
            mp7daq.hw().getNode('readout.tts_csr.ctrl.tts').write(code)
            mp7daq.hw().dispatch()

            time.sleep(2)
    
            self.linkStatus('TTS check')


    def stressTTS(self):

        self.resetEverything()
        
        # self.preConfigAMC13()
    
        self.configAMC13()
    
        self.configMP7DAQ()
    
        # AMC13 must go in Run Mode
        self._amc13.startRun()
    
        self.linkStatus('TTS check - initial')
    
        ttsStates = [
            ('Warning', 0x1),
            ('OOS', 0x2),
            ('Busy', 0x4),
            ('Ready', 0x8),
            ('Error', 0xc),
            ('Disconnected', 0xf),
        ]

        mp7daq.hw().getNode('readout.tts_csr.ctrl.tts_force').write(1)
    
        for i in xrange(1000):
            mp7daq.hw().getNode('readout.tts_csr.ctrl.tts').write(0x4) # Busy
            mp7daq.hw().getNode('readout.tts_csr.ctrl.tts').write(0x8) # Ready
            
        mp7daq.hw().dispatch()
    
        self.linkStatus('TTS check - after burst')


    def miniDAQ(self, fake):
        iCi = self._ici
        pi  = self._pi
        a13 = self._amc13
        mp7daq = self._mp7

        logging.info('Standing by for Configuration')
        line = raw_input('Press enter to proceed')
        logging.info('Configuring')

        # move the files in ${MP7_TESTS}/etc/tcds/minidaq/
        iCi.loadHwCfg('${MP7_TESTS}/etc/tcds/minidaq/ici_from_lpm.txt')
        pi.loadHwCfg('${MP7_TESTS}/etc/tcds/common/pi_mp7bgos.txt')
        pi.fedEnableMask_ = '1352&3%'
        
        iCi.sendCmd('Halt')
        pi.sendCmd('Halt')
    
        time.sleep(1)
    
        pi.sendCmd('Configure')
    
        pi.lock()
    
        iCi.sendCmd('Configure')
    
        iCi.lock()
    
        time.sleep(2)

        self.resetEverything()
    
        # self.preConfigAMC13()
        
        # self.configMP7AlgoPatt()
    
        injectEvents = 'events/s1golden-clean-strobed'
        self.configMP7DAQ(fake, injectEvents)

        self.configAMC13( True )

        logging.info('Configured')

        logging.info('Standing by for Start')
        line = raw_input('Press enter to proceed')
        logging.info('Starting')

        # must be in run mode to download data from AMC13'
        a13.startRun()
        
        self.linkStatus('AMC13 Started')
        pi.sendCmd('Enable')
        iCi.sendCmd('Enable')

        logging.info('Running')
        logging.info('Monitoring system status - Press Ctrl-C to quit')

        while True:
            try:
                ttc = mp7daq.getTTC()
                ro = mp7daq.getReadout()

                ttcev = ttc.readEventCounter()
                fifoocc = ro.readFifoOccupancy()
                roev = ro.readEventCounter()
                ttsstat = ro.readTTSState()
                amc13rdy = ro.isAMC13LinkReady()


                logging.info('-'*20)
                logging.info('TTC ev %d - Readout events %d - occupancy %d', ttcev, roev, fifoocc)
                logging.info('TTS %d - AMC13 ready %d', ttsstat, amc13rdy)
            
                # AMC13 global variables
                regs = [
                    'CONF.RUN',
                    'STATUS.AMC_TTS_STATE',
                    'STATUS.T1_TTS_STATE',
                    'STATUS.GENERAL.L1A_COUNT_LO',
                    'STATUS.GENERAL.L1A_COUNT_HI',
                    'STATUS.EVB.OVERFLOW_WARNING',
                    'STATUS.EVB.SYNC_LOST',
                    # 'STATUS.SFP.TTS_SFP_ABSENT',
                    # 'STATUS.SFP.TTS_LOS_LOL',
                    # 'STATUS.SFP.TTS_TX_FAULT',
                    'STATUS.LSC.SFP0.LINK_FULL_N',
                ]
                for r in regs:
                    logging.info('amc13 - %s : %d', r,a13.read(a13.Board.T1, r))
                try:
                    e = a13.readEvent()
                    # for i,w in enumerate(e):
                    #     logging.warning( '%04d : 0x%016x', i, w)
                    decode(e, fake)
                except Exception, e:
                    logging.warning('ERROR while reading events from AMC13.')
                        
                time.sleep(5)
            except KeyboardInterrupt:
                print 'Bye'
                break



    def someEvents( self, nev, fake = False, cyclic=False, path=None ):
    
        iCi = self._ici
        pi  = self._pi
        a13 = self._amc13
        mp7daq = self._mp7

        if cyclic:
            iCi.loadHwCfg('${MP7_TESTS}/etc/tcds/local/ici_mp7bgos_cyclic.txt')
        else:
            iCi.loadHwCfg('${MP7_TESTS}/etc/tcds/local/ici_mp7bgos_software.txt')
        
        pi.loadHwCfg('${MP7_TESTS}/etc/tcds/common/pi_mp7bgos.txt')
    
        iCi.sendCmd('Halt')
        pi.sendCmd('Halt')
    
        time.sleep(1)
    
        pi.sendCmd('Configure')
    
        pi.lock()
    
        iCi.sendCmd('Configure')
    
        iCi.lock()
    
        time.sleep(2)
    
        try:
        
            self.resetEverything()
    
            self.configAMC13()
    
            self.configMP7DAQ(fake)
    
    
            mp7daq.getTTC().maskHistoryBC0L1a(True)
    
    
            self.linkStatus('Before starting the AMC13')
    
            # must be in run mode to download data from AMC13'
            a13.startRun()
    
            self.linkStatus('AMC13 Stared')
    
            logging.notice('Enabling TCDS OCR')
    
            # iCi.sendCmd('Enable')
            pi.sendCmd('Enable')
    
            time.sleep(1)

            # logging.notice('Sending Resync')

            # Resync
            iCi.sendCmd(5)

            logging.notice('Sending OCR')
    
            # OC0
            iCi.sendCmd(8)
    
            logging.notice('Sending Start')
    
            # EC0
            iCi.sendCmd(9)

            logging.notice('Sending ECR')
    
            # EC0
            iCi.sendCmd(7)
    
            logging.notice('Sending %d L1A', nev)
    
            self.linkStatus('Before triggers')

            # logging.notice('Sleep 20 sec')
            iCi.sendCmd('Enable')
    
            # logging.error('nev %d',nev)
    
            events = []
            if cyclic:
                lastEv = 1
                k = 0
                # for k in xrange(nev):
                while( lastEv <= nev):
                    ev = mp7daq.getTTC().readEventCounter()
                    logging.info('%d : mp7 ev %d', k,ev)
                    if ev > lastEv:
                        for j in xrange(ev-lastEv):
                            e = a13.readEvent()
                            events.append(e)
                            decode(e, fake)
                        lastEv = ev
                    time.sleep(0.1)
                    k += 1
            else:
                for i in xrange(nev):
                    print i
                    iCi.sendCmd('SendL1A')
                    time.sleep(0.01)
        
                    ev = mp7daq.getTTC().readEventCounter()
                    logging.info(' - mp7 ev %d', ev)
    
                    try:
                        e = a13.readEvent()
                        events.append(e)
                    except Exception, e:
                        logging.error('ERROR while reading events from AMC13.')
                        # ro = mp7daq.hw().getNode('readout')
                        # ro.readEvents()
                        raise e
    
    
    
                    decode(e, fake)


            history = mp7daq.getTTC().captureHistory()
    
            for i,e in enumerate(history):
                logging.info('%4d | orb:0x%06x bx:0x%03x ev:0x%06x l1a:%1d cmd:%02x', i, e.orbit, e.bx, e.event,e.l1a, e.cmd)
    

            self.linkStatus('After triggers')
            if path:
                logging.info('Saving events to %s', path)
                f = open(path,'w')
                for i,ev in enumerate(events):
                    hdr = 'Event %d' % (i+1)
                    f.write(hdr+'\n')
                    f.write('-'*len(hdr)+'\n')
                    f.write('\n')
                    for j,w in enumerate(ev):
                        f.write('%04d : 0x%08x\n' % (2*j, (w & 0xffffffff) ) )
                        f.write('%04d : 0x%08x\n' % (2*j+1, ((w>>32) & 0xffffffff) ) )
                    f.write('---\n')
                f.close()

        except RuntimeError as e:
            logging.critical('Runtime Error caught! %s ',e)
    
            self.linkStatus('Exception!!!')
        finally:
            logging.notice('Stopping Partition')
            
    
            try:
                iCi.sendCmd('Stop')
            except Exception:
                pass
            try:
                pi.sendCmd('Stop')
            except Exception:
                pass
    
    
            # logging.notice('Releasing TCDS Partition')
            # iCi.release()
            # pi.release()


    def spyEvents(self, fake):
        a13 = self._amc13

        while True:
            try:
                try:
                    e = a13.readEvent()
                    # for i,w in enumerate(e):
                    #     logging.warning( '%04d : 0x%016x', i, w)
                    decode(e, fake)
                except Exception, e:
                    logging.warning('ERROR while reading events from AMC13.')
                        
                time.sleep(5)
            except KeyboardInterrupt:
                print 'Bye'
                break


# def unpackAMC13Protocol( event ):

#     iw = 0
#     nw = len(event)

#     amc13ev = readout.ns()
#     amc13ev.amcBlocks = {}
#     amc13ev.amcHdrs = {}

#     amc13ev.cdfhdr = event[iw]
#     iw += 1

#     # check that amc13ev.cdfhdr[63] is 
#     assert( (amc13ev.cdfhdr >> 60) == 0x5 )
#     amc13ev.event_type = amc13ev.cdfhdr >> 56
#     amc13ev.l1A = (amc13ev.cdfhdr >> 32) & 0xffffff
#     amc13ev.bxId = (amc13ev.cdfhdr >> 20 ) & 0xfff
#     amc13.srcId = (amc13ev.cdfhdr >> 8 ) & 0xfff

#     logging.debug( 'amc13 cdfhdr | 0x%16x' % (amc13ev.cdfhdr,) )
#     logging.info( 'amc13 cdfhdr | bx: 0x%03x l1a: 0x%06x evType: %01x srcId: 0x%03x' % (amc13ev.bxId, amc13ev.l1A, amc13ev.event_type, amc13.srcId) )

#     amc13ev.hdr = event[iw]
#     iw += 1

#     amc13ev.orb = (amc13ev.hdr>>4) & 0xffffffff
#     amc13ev.nAmcs = (amc13ev.hdr>>52) & 0xf
#     logging.debug( 'amc13 hdr    | 0x%016x', amc13ev.hdr )
#     logging.info( 'amc13 hdr    | namcs: 0x%01x orb: 0x%06x', amc13ev.nAmcs, amc13ev.orb )

#     while iw < nw:
#         # print iw,nw
        
#         if len(amc13ev.amcHdrs) == amc13ev.nAmcs:
#             # AMC section completed
#             break

#         w = event[iw]

#         iw += 1
#         amchdr = w
#         amcId = ( amchdr ) & 0xffff 
#         amcNo = ( amchdr >> 16 ) & 0xf
#         amcBlkNo = ( amchdr >> 20 ) & 0xff
#         amcSize = ( amchdr >> 32 ) & 0xffffff
#         flags = ( amchdr >> 56 ) & 0x7f 

#         if amcId in amc13ev.amcBlocks:
#             raise RuntimeError('Duplicated amc no %d' % amcNo)

#         logging.debug( 'amc hdr      | 0x%16x' % (amchdr,) )
#         logging.info( 'amc hdr      | id: 0x%04x no: 0x%01x blkno: 0x%02x size: 0x%06x flags: 0x%02x' % (amcId,amcNo, amcBlkNo, amcSize, flags) )

#         amc13ev.amcHdrs[amcNo] = amchdr

#         amc13ev.amcBlocks[amcNo] = event[ iw : iw+amcSize ]
#         iw += amcSize

#     amc13ev.trl = event[iw]
#     iw += 1
#     amc13ev.trlBx = (amc13ev.trl >> 0) & 0xfff
#     amc13ev.trlL1a = (amc13ev.trl >> 12) & 0xff
#     amc13ev.trlBlkNo = (amc13ev.trl >> 20) & 0xff
#     amc13ev.crc = (amc13ev.trl >> 32) & 0xffffffff
#     logging.debug( 'amc13 trl    | 0x%16x', amc13ev.trl )
#     logging.info( 'amc13 trl    | bx: 0x%03x l1a: 0x%02x blkno: 0x%02x, crc: 0x%08x', amc13ev.trlBx, amc13ev.trlL1a, amc13ev.trlBlkNo, amc13ev.crc )




#     amc13ev.cdftrl = event[iw]
#     iw += 1
#     assert( (amc13ev.cdftrl >> 60) == 0xa )

#     amc13ev.cdfCrc = (amc13ev.cdftrl >> 16) & 0xffff
#     amc13ev.tts = (amc13ev.cdftrl >> 4) & 0xf
#     logging.debug( 'amc13 cdftrl | 0x%16x', amc13ev.cdftrl )
#     logging.info( 'amc13 cdftrl | crc: 0x%06x tts: 0x%01x', amc13ev.crc,amc13ev.tts )

#     return amc13ev


def decode( event, fake=False ):
    
    # print 'Event size: ', len(event)
    # AMC13 data format parameters
    amc13HdrLen = 3;
    amc13TrlLen = 2;
    mp7HdrLen = 2;
    mp7TrlLen = 1;
    # mp7EventSize64bit = 131; # not sure for actual DAQ bus

    for i,w in enumerate(event):
        logging.debug('%04d : %016x', i, w)

    amc13ev = unpackAMC13Protocol(event)

    # amcblock = event[amc13HdrLen:len(event)-amc13TrlLen]
    for i in sorted(amc13ev.amcBlocks):
        amcblock = amc13ev.amcBlocks[i]
        mp7ev = readout.unpackMP7Protocol(amcblock)

        if len(amcblock) != mp7ev.lengthCounter:
            logging.error('Trailer event size error : expected %d, block length %d',mp7ev.lengthCounter, len(amcblock))

        payload = event[amc13HdrLen+mp7HdrLen:len(event)-mp7TrlLen-amc13TrlLen]


        if fake:
            readout.unpackFakePayload(payload, mp7ev)
        else:
            readout.unpackPayload(payload, mp7ev)



import argparse

if __name__ == '__main__':


    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-v', '--verbose', action='count', default=0)
    parser.add_argument('-c', '--connections', default='file:///nfshome0/thea/l1t/mp7/software/mp7-bridge/mp7/tests/etc/mp7/connections-DAQ.xml')
    parser.add_argument('--tcds', default='tcds-control-trig.cms:2110')
    parser.add_argument('--gdb', action='store_true', default=False) 

    subparsers = parser.add_subparsers(dest = 'cmd')
    subp = subparsers.add_parser('testtts', help='')
    subp = subparsers.add_parser('stresstts', help='')
    subp = subparsers.add_parser('linkstatus', help='')
    subp = subparsers.add_parser('reset', help='')
    subp = subparsers.add_parser('resetinv', help='')
    subp = subparsers.add_parser('s1loopback', help='')


    subp = subparsers.add_parser('some', help='')
    subp.add_argument('nevents', type=int,  help='')
    subp.add_argument('--fake', dest='fake',  default=False, action='store_true',  help='')
    subp.add_argument('--cyclic', dest='cyclic',  default=False, action='store_true',  help='')
    subp.add_argument('--output', default=None, help='Write events to file <output>')

    subp = subparsers.add_parser('minidaq', help='')
    subp.add_argument('--fake', dest='fake',  default=False, action='store_true',  help='')
    subp.add_argument('--fakesize', dest='fakesize',  type=int, default=100, help='')

    subp = subparsers.add_parser('spy', help='')
    subp.add_argument('--fake', dest='fake',  default=False, action='store_true',  help='')

    args = parser.parse_args()

    initLogging(logging.INFO if args.verbose == 0 else logging.DEBUG)
    mp7.setLogThreshold(mp7.kInfo if args.verbose == 0 else mp7.kDebug1)
    uhal.setLogLevelTo(uhal.LogLevel.ERROR)

    p5.tcds._log.setLevel(logging.INFO)

    if args.gdb:
        helpers.hookDebugger()

    tcdstoken = args.tcds.split(':')
    print tcdstoken
    if len(tcdstoken) != 2 or not tcdstoken[1].isdigit():
        logging.critical('Badly formatted tcds applcation address')
        sys.exit(0)

    tcdsHost,tcdsPort = tcdstoken[0],int(tcdstoken[1])
    logging.info('TCDS host: %s:%d',tcdsHost, tcdsPort)

    # Build TCDS controllers
    pi = p5.tcds.TCDSController( tcdsHost,tcdsPort, 505 );
    iCi = p5.tcds.TCDSController( tcdsHost,tcdsPort, 305 );
    # pi = TCDSController( tcdsHost,tcdsPort, 506 );
    # iCi = TCDSController( tcdsHost,tcdsPort, 306 );

    pi.fedEnableMask_ = '0&0%'

    # sanitise the connection string
    conns = args.connections.split(';')
    for i,c in enumerate(conns):
        if re.match('^\w+://.*', c) is None:
            conns[i] = 'file://'+c

    print conns
    cm = uhal.ConnectionManager(';'.join(conns))

    # Build the AMC13
    a13 = amc13.AMC13(cm.getDevice('T1'), cm.getDevice('T2'))
    logging.notice('AMC13 Version: %s',a13.GetVersion())

    # and then the MP7
    mp7daq = mp7.MP7Controller(cm.getDevice('XE_SL9'))
    mp7daq.identify()
    mp7daq.slot = 9


    t = DAQSimpleTester(a13,mp7daq,pi,iCi)

    if args.cmd == 'testtts': 
        t.testTTS()
    elif args.cmd == 'stresstts': 
        t.stressTTS()
    elif args.cmd == 'linkstatus':
        t.linkStatus()
    elif args.cmd == 'reset':
        t.testReset()
    elif args.cmd == 'some':
        t.someEvents(args.nevents, args.fake, args.cyclic, args.output)
    elif args.cmd == 'minidaq':
        t.fakesize = args.fakesize
        t.miniDAQ(args.fake)
    elif args.cmd == 'spy':
        t.spyEvents(args.fake)
    elif args.cmd == 's1loopback':
        stage1.configureStage1LatencyLoopback(mp7daq)
    else:
        parser.print_help()
    
