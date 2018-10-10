# Python Modules
import logging
import time
import os.path

# MP7 Modules
import mp7

from mp7.cli_core import defaultFmtStr,FunctorInterface
from mp7.tools.cli_utils import IntListAction, IntPairAction
import mp7.tools.helpers as hlp
import mp7.tools.unpacker as unpacker



class TMTReadoutSetup(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        subp.add_argument('period', default=0, type=int, help='TMT Period'+defaultFmtStr )
        subp.add_argument('rophase', default=0, type=int, help='Readout phase'+defaultFmtStr )
        subp.add_argument('tmtId', default=0, type=int, help='TMT Board ID'+defaultFmtStr )

    #TODO: Move this function to helpers if might be used elsewhere ???
    @staticmethod
    def run(board, period, rophase, tmtId):

        if period < 0x0 or period > 0xf:
            raise ValueError('Period outside supported range 0x0 < period < 0xf')
        if rophase < -period-1 or rophase > period-1:
            raise ValueError('Readout phase outside valid range (period-1) < phase < (period-1)')
        if tmtId < 0x0 or tmtId >= period:
            raise ValueError('Period outside valid range 0x0 < P < 0x%x' % (period-1,))
        

        print 'Period',period

        max_phase = period-1
        phase = (period-1+rophase)%period
        l1a_offset = tmtId

        logging.info('max_phase = 0x%x', max_phase)
        logging.info('phase = 0x%x', phase)
        logging.info('l1a_offset = 0x%x', l1a_offset)

        ttc = board.getTTC()

        ttc.getNode('tmt.max_phase').write(max_phase)
        ttc.getNode('tmt.phase').write(phase)
        ttc.getNode('tmt.l1a_offset').write(l1a_offset)
        ttc.getNode('tmt.pkt_offset').write(0x0)

        ttc.getClient().dispatch()





#  ________________  __ ___     __                  _____          __              
# /_  __/_  __/ __/ / // (_)__ / /____  ______ __  / ___/__ ____  / /___ _________ 
#  / /   / / _\ \  / _  / (_-</ __/ _ \/ __/ // / / /__/ _ `/ _ \/ __/ // / __/ -_)
# /_/   /_/ /___/ /_//_/_/___/\__/\___/_/  \_, /  \___/\_,_/ .__/\__/\_,_/_/  \__/ 
#                                         /___/           /_/                      
class TTSCapture(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        subp.add_argument('--clear', default=False, action='store_true', help='Clear history before capturing'+defaultFmtStr )

    #TODO: Move this function to helpers if might be used elsewhere ???
    @staticmethod
    def run(board, clear):

        ttsHist = board.getReadout().getNode('tts_hist')

        if clear:
            ttsHist.clear()

        history = ttsHist.capture()

        for i,e in enumerate(history):
            # print('%4d | V:%1d L1A:%1d orb:0x%06x bx:0x%03x cmd:%02x' % (i,valid, isL1A, orbit, bx, cmd))
            logging.info('%4d | orb:0x%06x bx:0x%03x ev:0x%06x state: 0x%0x', i, e.orbit, e.bx, e.event, e.data)


#    ___              __          __    __ ___     __                  _____          __              
#   / _ \___ ___ ____/ /__  __ __/ /_  / // (_)__ / /____  ______ __  / ___/__ ____  / /___ _________ 
#  / , _/ -_) _ `/ _  / _ \/ // / __/ / _  / (_-</ __/ _ \/ __/ // / / /__/ _ `/ _ \/ __/ // / __/ -_)
# /_/|_|\__/\_,_/\_,_/\___/\_,_/\__/ /_//_/_/___/\__/\___/_/  \_, /  \___/\_,_/ .__/\__/\_,_/_/  \__/ 
#                                                            /___/           /_/                      
class HistoryCapture(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        subp.add_argument('--clear', default=False, action='store_true', help='Clear history before capturing'+defaultFmtStr )
        subp.add_argument('--maxlen', default=10, type=int, help='Change max length of history readout'+defaultFmtStr )

    #TODO: Move this function to helpers if might be used elsewhere ???
    @staticmethod
    def run(board, clear, maxlen):

        hist = board.getReadout().getNode('hist')

        if clear:
            hist.clear()

        history =  hist.capture()

        h = history[-maxlen:] if maxlen else history
        if maxlen:
            logging.info('Printing last %d entries', maxlen)

        for i,e in enumerate(h):
            logging.info('%4d | orb:0x%06x bx:0x%03x ev:0x%06x state: %s', i, e.orbit, e.bx, e.event, "{0:012b}".format(e.data))

#    ___              __          __    ____    __          
#   / _ \___ ___ ____/ /__  __ __/ /_  / __/__ / /___ _____ 
#  / , _/ -_) _ `/ _  / _ \/ // / __/ _\ \/ -_) __/ // / _ \
# /_/|_|\__/\_,_/\_,_/\___/\_,_/\__/ /___/\__/\__/\_,_/ .__/
#                                                    /_/    

class Setup(FunctorInterface):
    
    """docstring for ReadoutTest"""

    @staticmethod
    def addArgs(subp):
        subp.add_argument('--internal', default=False, action='store_true', help='Select internal/external mode'+defaultFmtStr)
        subp.add_argument('--fake', default=False, action='store_true', help='Generate Fake events')
        subp.add_argument('--fakesize', default=100, type=int, help='Fake event size'+defaultFmtStr)
        subp.add_argument('--drain', default=None, type=int, help='Fifo drain rate'+defaultFmtStr)
        subp.add_argument('--bxoffset', default=1, type=int, help='TTC to header offset'+defaultFmtStr)
        subp.add_argument('--watermarks', default=(32,16), action=IntPairAction, help='High and low watermarks'+defaultFmtStr)

    @staticmethod
    def run(board, fake, fakesize, internal, drain, bxoffset, watermarks):

        ctrl = board.getCtrl()
        ttc = board.getTTC()
        ro = board.getReadout()
        rc = ro.getNode('readout_control')

        # Turn on rules only if in internal mode
        logging.info('L1A Trigger rules : %s' % ('enabled' if internal else 'disabled'))
        ttc.enableL1ATrgRules( internal )

        logging.info('L1A Trigger throttling : %s' % ('enabled' if internal else 'disabled'))
        # Turn throttling on if in internal mode
        ttc.enableL1AThrottling( internal )

        # Set the readout counter offset
        ro.setBxOffset(bxoffset)

        #  set TTS status by hand.
        #  1 = warningt
        #  2 = out of sync
        #  4 = busy
        #  8 = ready
        #  12 = error
        #  0 or 15 = disconnected
        # ro.getNode('tts_csr.ctrl.tts_force').write(0)
        # ro.getClient().dispatch()
        ro.forceTTSState(False)

        # To drain or not to drain in internal mode?
        if drain is None: 
            logging.info('Autodrain : disabled')
            ro.enableAutoDrain(False)
        else:
            logging.info('Autodrain rate : 0x%x', drain)
            ro.enableAutoDrain(True, drain)

        # Configure big fifo's watermarks
        # Maximum: 64x
        # High water mark : 32 - 50%
        # Low water mark : 16 - 25%
        # hWM = 32
        # lWM = 26
        hWM, lWM = watermarks
        # Compare watermarsk with readout buffer size
        roSize = board.getGenerics().roChunks * 2
        if lWM >= roSize or hWM >= roSize:
            logging.warn('RO buffer Watermarks higher than its size : lwm = %d, hwm - %d, rosize = %d', lWM, hWM, roSize)

        ro.setFifoWaterMarks(lWM, hWM)

        # And the derandomisers
        # Maximum: 512
        # 
        rc.setDerandWaterMarks(64,128)

        #enable dr error handling
        #rc.getNode('csr.dr_ctrl.dr_err_en').write(1)
        #rc.getClient().dispatch()
    
        if fake:
            logging.info('Fake event source selected, event size : 0x%x', fakesize)
            ro.selectEventSource( ro.kFakeEventSource )
            ro.configureFakeEventSize(fakesize)
        else:
            logging.info('ReadoutControl event source selected')
            ro.selectEventSource( ro.kReadoutEventSource )


        # declare the board ready for readout        
        ro.start()

        # Local mode, amc13 link disabled
        logging.info('AMC13 output : %s' % ('enabled' if not internal else 'disabled'))
        ro.enableAMC13Output(not internal)


#    ___       __        ______        __ 
#   / _ \___ _/ /____   /_  __/__ ___ / /_
#  / , _/ _ `/ __/ -_)   / / / -_|_-</ __/
# /_/|_|\_,_/\__/\__/   /_/  \__/___/\__/ 
                                        
class RateTest(FunctorInterface):
    '''ReadoutRateTest docstring'''

    @staticmethod
    def addArgs(subp):
        subp.add_argument('--rate', default=100., type=float, help='Random trigger rate'+defaultFmtStr)
        subp.add_argument('--secs', default=1, type=int, help='Integration interval'+defaultFmtStr)

    @staticmethod
    def run(board, rate, secs):

        logging.notice('Input rate %f Hz', rate)
        ttc = board.getTTC()
        ro = board.getReadout()

        # Reset the orbit counter
        ttc.forceBCmd(mp7.TTCBCommand.kResync)
        # Reset the readout block counter
        ttc.forceBCmd(mp7.TTCBCommand.kOC0)
        # Reset the event counter
        ttc.forceBCmd(mp7.TTCBCommand.kEC0)

        # Print the status before starting 
        logging.info('Before enabling triggers')

        ttcev = ttc.readEventCounter()
        roev = ro.readEventCounter()
        logging.info('ttc l1As    : %d', ttcev)
        logging.info('ro events  : %d', roev)


        src_err = ro.getNode('csr.stat.src_err').read()
        rob_err = ro.getNode('csr.stat.rob_err').read()
        ro.getClient().dispatch()

        logging.info('Source error : %d', src_err)
        logging.info('ROB error : %d', rob_err)

        ttc.generateRandomL1As(rate)

        logging.info('Take a nap for %d secs', secs)

        for i in xrange(secs/10):
            time.sleep(10)
            logging.info('%ds...', (i+1)*10)

        time.sleep(secs % 10)
        logging.info('Wake up!')

        # Disable triggers
        ttc.generateRandomL1As(0)


        ttcev = ttc.readEventCounter()
        roev = ro.readEventCounter()
        # Print the status before starting 
        logging.info('ttc l1As    : %d', ttcev)
        logging.info('ro events  : %d', roev)

        src_err = ro.getNode('csr.stat.src_err').read()
        rob_err = ro.getNode('csr.stat.rob_err').read()
        ro.getClient().dispatch()

        logging.info('Source error : %d', src_err)
        logging.info('ROB error : %d', rob_err)


        tts = ro.readTTSState()

        flags = mp7.snapshot(ro.getNode('buffer.fifo_flags'))

        # print(i,flags)
        logging.info('TTS: 0x%x | Fifo valid: %d, warn: %d, full: %d, empty %d: cnt: %d', tts, flags['fifo_valid'], flags['fifo_warn'], flags['fifo_full'], flags['fifo_empty'], flags['fifo_cnt'])

        # Return ttc events, ro events, time
        return (ttcev,roev,tts)

#    ___       __        ____            
#   / _ \___ _/ /____   / __/______ ____ 
#  / , _/ _ `/ __/ -_) _\ \/ __/ _ `/ _ \
# /_/|_|\_,_/\__/\__/ /___/\__/\_,_/_//_/
                                       
class RateScan(FunctorInterface):

    @staticmethod
    def addArgs(subp): 
        subp.add_argument('fmin', default=1, type=int)
        subp.add_argument('fmax', default=1000000, type=int)
        subp.add_argument('steps', default=10, type=int)
        subp.add_argument('--secs', default=1, type=int, help='Integration interval'+defaultFmtStr)
        subp.add_argument('--plot', default=False, action='store_true', help='Save rate plot to file'+defaultFmtStr)

    @staticmethod
    def run(board, fmin, fmax, steps, secs, plot):

        rates = []
        for f in xrange(fmin, fmax, (fmax-fmin)/steps):
            ttcev,roev,tts = RateTest.run(board, f, secs)

            rates += [(f,ttcev,roev,tts)] 

        data = (
            [ x[0] for x in rates],
            [ x[1] for x in rates],
            [ x[2] for x in rates],
            [ x[3] for x in rates]
            )

        if plot:
            hlp.initPlotting()

            import matplotlib.pyplot as plt
            fig = plotRulesThrottling( data )
            fig.savefig('l1A_ttc_vs_roctr.pdf')
            plt.close(fig)


        return data


#   _____          __               ____              __    
#  / ___/__ ____  / /___ _________ / __/  _____ ___  / /____
# / /__/ _ `/ _ \/ __/ // / __/ -_) _/| |/ / -_) _ \/ __(_-<
# \___/\_,_/ .__/\__/\_,_/_/  \__/___/|___/\__/_//_/\__/___/
#         /_/                                               

class CaptureResult(object):
    """docstring for CaptureResult"""
    def __init__(self):
        self.ttcHistory = None
        self.status = 0
        self.msg = ''
        self.events = []
        self.unpacked = []

    def rawsize(self):
        return len(self.events)

    def size(self):
        return len(self.unpacked)


class CaptureEvents(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        subp.add_argument('nevents', default=1, type=int, help='Number of events'+defaultFmtStr)
        subp.add_argument('--bxs', default=None, action=IntListAction, help='Fire on Bx'+defaultFmtStr)
        subp.add_argument('--outputpath', default=None, help='Write events to file <path>'+defaultFmtStr)

    @staticmethod
    def run(board, nevents, outputpath, bxs):

        r = CaptureResult()

        ttc = board.getTTC()
        ro = board.getReadout()


        # print ro.readFifoOccupancy()
        logging.info('TTS: 0x%x', ro.readTTSState())

        ttc.maskHistoryBC0L1a(True)

        # Reset the orbit counter
        ttc.forceBCmd(mp7.TTCBCommand.kOC0)
        # Reset the event counter
        ttc.forceBCmd(mp7.TTCBCommand.kEC0)
        # Reset the readout block counter
        ttc.forceBCmd(mp7.TTCBCommand.kResync)

        # Don't drain!
        ro.enableAutoDrain(False)

        logging.info('TTS: 0x%x', ro.readTTSState())

        # ro.enableAutoDrain(True)
        ro.enableAutoDrain(False)

        logging.info('TTS: 0x%x', ro.readTTSState())


        logging.notice('Injecting L1As')
        
        from itertools import cycle
        
        bxPool = cycle(bxs) if bxs is not None else None

        # Inject L1As
        for i in xrange(nevents):
            if bxPool is None:
                ttc.forceL1A()
            else:
                bx = next(bxPool)
                logging.info('Firing l1A on bx %d', bx)

                ttc.forceL1AOnBx(bx)

            if board.kind() == mp7.kMP7Sim:
                logging.debug('Sleep 10 secs because simulation is slow')
                time.sleep(10)

            # Check fifo level
            # fifo_cnt = ro.getNode('buffer.fifo_flags.fifo_cnt').read()
            tts = ro.readTTSState()
    
            flags = mp7.snapshot(ro.getNode('buffer.fifo_flags'))

            # print(i,flags)
            logging.info('%02d - TTS: 0x%x | Fifo valid: %d, warn: %d, full: %d, empty %d: cnt: %d', i, tts, flags['fifo_valid'], flags['fifo_warn'], flags['fifo_full'], flags['fifo_empty'], flags['fifo_cnt'])
        


        logging.debug('Now there should be an event')
        empty = ro.isFifoEmpty()
        logging.debug('Is fifo empty? %s', empty)

         # Print the TTC history
        logging.info('TTC History')
        history = ttc.captureHistory()
        # Save it in the result
        r.history =  history
    
        for i,e in enumerate(history):
            logging.info('%4d | orb:0x%06x bx:0x%03x ev:0x%06x l1a:%1d cmd:%02x', i, e.orbit, e.bx, e.event, e.l1a, e.cmd)

        if ( empty ):
            # Throw an exception here
            logging.warn('The fifo is empty, something is not quite right')
            r.status = -1
            r.msg = "The fifo is empty, something is not quite right. No event was captured"
            return 

        logging.notice('Reading events back')

        # Read events back
        events = []
        for i in xrange(nevents):
            tts = ro.getNode('tts_csr.stat').read()
            flags = mp7.snapshot(ro.getNode('buffer.fifo_flags'))

            logging.info('%02d - TTS: 0x%x | Fifo valid: %d, warn: %d, full: %d, empty %d: cnt: %d', i, tts, flags['fifo_valid'], flags['fifo_warn'], flags['fifo_full'], flags['fifo_empty'], flags['fifo_cnt'])

            e = ro.readEvent()
            events.append( e )

        logging.info('%d events read', len(events) )

        # Copy events into result object
        r.events.extend( events )

        src = ro.getNode('csr.ctrl.src_sel').read()
        ro.getClient().dispatch()
        fake = (src == ro.kFakeEventSource)
        logging.info('Fake? %s', fake)

        upEv = []
        # Unpack events
        for i,ev in enumerate(events):
            logging.info('## Decoding event %d ##',i+1)
            # Create an unpacker result
            upEv.append( unpacker.unpackROBEvent(ev, unpacker.AMCEvent(i), fake ) )

        # returnEvent['Event'] = upEv
        r.unpacked.extend( upEv )

        if outputpath:
            dn = os.path.dirname(outputpath)
            if dn:
                os.system('mkdir -p '+dn)

            with open(outputpath,'w') as f:
                for i,ev in enumerate(events):

                    ttcentry = filter( lambda x: x.l1a==True and x.event==(i+1), history)[0]
                    # print ttcentry, ttcentry.bx

                    hdr = 'Event %d' % (i+1)
                    f.write(hdr+'\n')
                    f.write('-'*len(hdr)+'\n')
                    f.write('ttc | orb: 0x%06x bx: 0x%03x\n' % (ttcentry.orbit,ttcentry.bx) )
                    f.write('-'*20+'\n')
                    for j,w in enumerate(ev):
                        f.write('%04d : 0x%08x\n' % (2*j, (w & 0xffffffff) ) )
                        f.write('%04d : 0x%08x\n' % (2*j+1, ((w>>32) & 0xffffffff) ) )
                    f.write('-'*20+'\n\n')

            logging.info('Events saved to %s', dn)

        # return returnEvent
        return r


#    __                __  __  ___             
#   / /  ___  ___ ____/ / /  |/  /__ ___  __ __
#  / /__/ _ \/ _ `/ _  / / /|_/ / -_) _ \/ // /
# /____/\___/\_,_/\_,_/ /_/  /_/\__/_//_/\_,_/ 
                                             
class LoadMenu(FunctorInterface):

    @staticmethod
    def addArgs(subp):
        subp.add_argument('path', help='Menu file'+defaultFmtStr)
        subp.add_argument('name', help='Menu name'+defaultFmtStr)

    @staticmethod
    def run(board, path, name):

        path = os.path.expandvars(path)
        path = os.path.expanduser(path)

        if not os.path.exists(path):
            raise RuntimeError('File '+path+' not found')

        vs = {}
        execfile(path,vs)

        if name not in vs:
            raise RuntimeError('Menu '+name+' not found in '+path)

        menu = vs[name]

        logging.notice('Updating event sizes')
        evszs = board.computeEventSizes(menu)
        for i,s in evszs.iteritems():
            logging.info('mode %d: %d', i,s)
            menu.mode(i).eventSize = s

        for l in str(menu).split('\n'):
            logging.debug('%s',l)

        rc = board.getReadout().getNode('readout_control')
        rc.configureMenu(menu)


#    ____              __        __                   
#   / __/__ ____ __ __/ /  ___ _/ /____ ___  ______ __
#  / _// _ `(_-</ // / /__/ _ `/ __/ -_) _ \/ __/ // /
# /___/\_,_/___/\_, /____/\_,_/\__/\__/_//_/\__/\_, / 
#              /___/                           /___/  

class EasyLatency(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        subp.add_argument('--rx', action=IntListAction, default=None, help='Rx channels to configure'+defaultFmtStr)
        subp.add_argument('--tx', action=IntListAction, default=None, help='Tx channels to configure'+defaultFmtStr)
        subp.add_argument('--rxBank', type=int, default=1, help='Rx channels bank id'+defaultFmtStr)
        subp.add_argument('--txBank', type=int, default=1, help='Tx channels bank id'+defaultFmtStr)
        subp.add_argument('--algoLatency', default=0, type=int, help='Algorithm latency'+defaultFmtStr)
        subp.add_argument('--masterLatency', default=0, type=int, help='Master latency'+defaultFmtStr)
        subp.add_argument('--rxExtraFrames', default=0, type=int, help='Rx extra readout frames'+defaultFmtStr)
        subp.add_argument('--txExtraFrames', default=0, type=int, help='Tx extra readout frames'+defaultFmtStr)


    @staticmethod
    def run(board, rx=None, tx=None, rxBank=1, txBank=1, algoLatency=0, masterLatency=0, rxExtraFrames=0, txExtraFrames=0):
        # logging.info('Masking all buffers')
        # cm = hlp.channelMgr(board, enablechans)
        # cm = hlp.channelMgr(board)

        # rxCfg = mp7.LatencyPathConfigurator(0, 1)
        # cm.configureBuffers(mp7.kRx, rxCfg)
        # txCfg = mp7.LatencyPathConfigurator(0, 1)
        # cm.configureBuffers(mp7.kTx, txCfg)

        internalLatency = 32  # 240 Mhz clock cycles
        logging.info('Internal L1A latency (%s cycles) added to rx and tx latency', internalLatency)
        rxLatency = masterLatency+internalLatency+rxExtraFrames
        txLatency = masterLatency+internalLatency+txExtraFrames-algoLatency

        if rx is not None:
            logging.info('Configuring rx buffers %s to bank %d, latency %d', rx, rxBank, rxLatency)
            cm = board.channelMgr(rx)
            rxCfg = mp7.LatencyPathConfigurator(rxBank, rxLatency)
            cm.configureBuffers(mp7.kRx, rxCfg)

        if tx is not None:
            logging.info('Configuring tx buffers %s to bank %d, latency %d', tx, txBank, txLatency)
            cm = board.channelMgr(tx)
            txCfg = mp7.LatencyPathConfigurator(txBank, txLatency)
            cm.configureBuffers(mp7.kTx, txCfg)


#    ___  _                         __  _    
#   / _ \(_)__ ____ ____  ___  ___ / /_(_)___
#  / // / / _ `/ _ `/ _ \/ _ \(_-</ __/ / __/
# /____/_/\_,_/\_, /_//_/\___/___/\__/_/\__/ 
#             /___/                          

def dynLog( ok, *args ):
    log = logging.info if ok else logging.warn
    log(*args)


#----
class Diagnostic(FunctorInterface):

    @staticmethod
    def addArgs(subp):
        subp.add_argument('--histlen', default=10, type=int, help='Readout history size'+defaultFmtStr)
        subp.add_argument('--capall', default=False, action='store_true', help='Print all capture modes'+defaultFmtStr)

    @staticmethod
    def run(board, histlen, capall):

        ctrl = board.getCtrl()
        ttc = board.getTTC()
        ro = board.getReadout()
        rc = ro.getControl()


        logging.notice('Firmware information')
        # logging.info('Revision')
        # logging.info('   Infra 0x%06x', ctrl.readFwRevision())
        # logging.info('   Algo  0x%08x', ctrl.readAlgoRevision())

        gens = mp7.snapshot(ctrl.getNode('id'))
        for r in sorted(gens):
            logging.info('   %s : 0x%x', r, gens[r])

        logging.notice('TTC status')
        ttcstat = mp7.snapshot(ttc.getNode('csr'))

        logging.info('Event counter : %d', ttcstat['stat1.evt_ctr'])
        logging.info('BC0 Lock      : %d', ttcstat['stat0.bc0_lock'])
        logging.info('TTC phase     : %d', ttcstat['stat0.ttc_phase_ok'])
        logging.info('TTC SBE       : %d', ttcstat['stat3.double_biterr_ctr'])
        logging.info('TTC DBE       : %d', ttcstat['stat3.single_biterr_ctr'])
        
        evt_chk = ro.getNode('evt_check.evt_err').read()
        ro.getClient().dispatch()
        
        logging.info('Event order errors: %d', evt_chk)
        if evt_chk != 0 :
            logging.error('Event order looks to be wrong')
        
        logging.info('TTC counters')
        ttcctrs = mp7.snapshot(ttc.getNode('cmd_ctrs'))
        for k in sorted(ttcctrs):
            logging.info('   %s : %d', k, ttcctrs[k])

        # Print the TTC history
        # Useless until Maxime masks BC0s in configurations

        logging.info('TTC History')
        history = ttc.captureHistory()
    
        for i,e in enumerate(history):
            logging.info('%4d | orb:0x%06x bx:0x%03x ev:0x%06x l1a:%1d cmd:%02x', i, e.orbit, e.bx, e.event, e.l1a, e.cmd)


        logging.notice('Readout status')
        rostat = mp7.snapshot(ro.getNode('csr'))

        dynLog(rostat['stat.src_err'] == 0, 'Event source error : %d', rostat['stat.src_err'])
        dynLog(rostat['stat.rob_err'] == 0, 'Readout error      : %d', rostat['stat.rob_err'])
        logging.info('Debug              : 0x%06x', rostat['stat.debug'])
        logging.info('Event counter      : %d', rostat['evt_count'])

        #
        # TTS State section
        #
        logging.notice('TTS status')
        ttsstat = mp7.snapshot(ro.getNode('tts_csr.stat'))

        # log = logging.info if ttsstat['tts_stat'] == 0x8 else logging.warn
        dynLog(ttsstat['tts_stat'] == 0x8, 'Status        : %d', ttsstat['tts_stat'])

        logging.notice('TTS history')

        TTSCapture.run(board, False)

        logging.notice('RO history')

        HistoryCapture.run(board, False, histlen)


        logging.notice('Fifo status')
        robstat = mp7.snapshot(ro.getNode('buffer.fifo_flags'))

        for f in sorted(robstat):
            logging.info('%s : %d', f, robstat[f])


        #
        # Readout Control section
        #
        logging.notice('Readout Control & ZS')
        rcstat = mp7.snapshot(rc.getNode('csr.stat'))

        nBanks = rcstat['n_banks']
        nModes = rcstat['n_modes']
        nCaps = rcstat['n_caps']

        logging.info('Banks %d, Modes %d, Captures %d', 
            nBanks,
            nModes,
            nCaps)

        # A. Print existing menu
        menu = rc.readMenu()

        logging.debug('Readout menu (on-board)')
        for l in str(menu).split('\n'):
            logging.debug('%s',l)

        try:
            if len(ro.getNodes('readout_zs')) == 0:
                raise RuntimeError('ZS node not found')

            zs = ro.getNode('readout_zs')
            logging.info('Zero Suppression is %s', 'ON' if zs.isEnabled() else 'OFF');
            logging.info('ZS FSMs')
            logging.info(' - Main          : %s', zs.readMainState())
            logging.info(' - Fifo Transfer : %s', zs.readFifoTransferState())
            logging.info(' - Output        : %s', zs.readOutputState())

            menu = zs.readMenu()
            logging.debug('ZS menu (on-board)')
            for l in str(menu).split('\n'):
                logging.debug('%s',l)
        except (mp7.ZeroSuppressionNotAvailable, RuntimeError):
            logging.info('ZeroSuppression block not instantiated')


        logging.notice('Bank occupancy')

        for iB in xrange(nBanks):
            rc.selectBank(iB)
            dr_occ = rc.getNode('bank_csr.stat.dr_occupancy').read()
            rc.getClient().dispatch()

            logging.info('%d : %d', iB, dr_occ)

        logging.notice('Readout Modes and Captures')

        for iM in xrange(nModes):
            logging.info('Mode %d', iM)

            rc.selectMode(iM)
            mctrl =  mp7.snapshot(rc.getNode('mode_csr.ctrl'))
            mstat =  mp7.snapshot(rc.getNode('mode_csr.stat'))
            for r in sorted(mstat):
                logging.info('- %s : %d', r, mstat[r])

            nCapEn = 0
            for iC in xrange(nCaps):
                rc.selectCapture(iC)
                cctrl = mp7.snapshot(rc.getNode('cap_csr.ctrl'))
                if not ( cctrl['cap_en'] or capall ) : continue
                nCapEn += 1
                logging.info('   Capture %d', iC)
                cstat = mp7.snapshot(rc.getNode('cap_csr.stat'))
                for r in sorted(cstat):
                    logging.info('   - %s : %d', r, cstat[r])
            if not nCapEn:
                logging.info('No captures enabled for mode %d', iM)




        #
        # Trigger anf Capture mode section
        #
        # trigger_mode_hist(0) <= '1' WHEN ro_state = ST_IDLE ELSE '0';
        # trigger_mode_hist(1) <= '1' WHEN ro_state = ST_READ ELSE '0';
        # trigger_mode_hist(2) <= '1' WHEN state = ST_IDLE ELSE '0';
        # trigger_mode_hist(3) <= '1' WHEN state = ST_TOK_DEL ELSE '0';
        # trigger_mode_hist(4) <= '1' WHEN state = ST_HDR ELSE '0';
        # trigger_mode_hist(5) <= '1' WHEN state = ST_DATA ELSE '0';
        # trigger_mode_hist(6) <= ctrs_fifo_full;
        # 
        # cap_mode_hist(0) <= '1' WHEN ro_state = ST_IDLE ELSE '0';
        # cap_mode_hist(1) <= '1' WHEN ro_state = ST_INIT ELSE '0';
        # cap_mode_hist(2) <= '1' WHEN ro_state = ST_READ ELSE '0';
        # cap_mode_hist(3) <= '1' WHEN ro_state = ST_PREP ELSE '0';
        # cap_mode_hist(4) <= '1' WHEN cap_state = ST_CAP ELSE '0';
        # 
        # hist_state <= trigger_mode_hist & cap_mode_hist

        rchist = rc.getNode('hist')

        def getBit(w,i):
            return (w>>i) & 1

        def printBit(on,off,w,i):
            return on if getBit(w,i) else off

        def printMod(w):
            return (
                printBit('I','_',w,0)+
                printBit('R','_',w,1)+
                printBit('I','_',w,2)+
                printBit('T','_',w,3)+
                printBit('H','_',w,4)+
                printBit('D','_',w,5)+
                printBit('F','_',w,6)
                )

        def printCap(w):
            return (
                printBit('I','_',w,0)+
                printBit('S','_',w,1)+
                printBit('R','_',w,2)+
                printBit('P','_',w,3)+
                printBit('C','_',w,4)
                )

        logging.notice('Readout Modes and Captures history')
        for iM in xrange(nModes):
            logging.info('Mode %d', iM)

            rc.selectMode(iM)

            for iC in xrange(nCaps):
                rc.selectCapture(iC)
                cctrl = mp7.snapshot(rc.getNode('cap_csr.ctrl'))
                if not ( cctrl['cap_en'] or capall ) : continue
                logging.info('   Capture %d', iC)

                history =  rchist.capture()
        
                h = history[-histlen:] if histlen else history
                if histlen:
                    logging.info('Printing last %d entries', histlen)

                for i in xrange(len(h)):
                    e = h[i]
                    if i:
                        em1 = h[i-1]
                        gap = '%4d' % (e.bx-em1.bx)
                    else:
                        gap = ' NA '
                    # Capture state, lower 5bits
                    capstate = (e.data & 0x1f)
                    # Trigger Mode state, following 7 bits
                    modstate = ((e.data >> 5 ) & 0x7f)

                    # print printMod(modstate), printCap(capstate)
                    # logging.debug('%4d | orb:0x%06x bx:0x%03x ev:0x%06x gap: %s, mod: %s cap: %s', i, e.orbit, e.bx, e.event, gap, '{0:07b}'.format(modstate), '{0:05b}'.format(capstate))
                    logging.info('%4d | orb:0x%06x bx:0x%03x cyc:0x%03x ev:0x%06x gap: %s, mod: %s cap: %s', i, e.orbit, e.bx, e.cyc, e.event, gap, printMod(modstate), printCap(capstate))


#    __                ______  ______  ___             
#   / /  ___  ___ ____/ /_  / / __/  |/  /__ ___  __ __
#  / /__/ _ \/ _ `/ _  / / /__\ \/ /|_/ / -_) _ \/ // /
# /____/\___/\_,_/\_,_/ /___/___/_/  /_/\__/_//_/\_,_/ 
#                                                                                                  

class LoadZSMenu(FunctorInterface):

    @staticmethod
    def addArgs(subp):
        subp.add_argument('path', help='Menu file'+defaultFmtStr)
        subp.add_argument('name', help='Menu name'+defaultFmtStr)

    @staticmethod
    def run(board, path, name):

        path = os.path.expandvars(path)
        path = os.path.expanduser(path)

        if not os.path.exists(path):
            raise RuntimeError('File '+path+' not found')

        vs = {}
        execfile(path,vs)

        if name not in vs:
            raise RuntimeError('Menu '+name+' not found in '+path)

        menu = vs[name]

        for l in str(menu).split('\n'):
            logging.debug('%s',l)

        zs = board.getReadout().getNode('readout_zs')
        zs.configureMenu(menu)
        
        # Enable zero suppression
        zs.enable()



#    ___  __     __  __  _          
#   / _ \/ /__  / /_/ /_(_)__  ___ _
#  / ___/ / _ \/ __/ __/ / _ \/ _ `/
# /_/  /_/\___/\__/\__/_/_//_/\_, / 
#                            /___/  
#                            

#---
def plotRulesThrottling( data ):

    # Local imports    
    import matplotlib.pyplot as plt

    l1AFreq,ttcL1As,roEvCounts,tts = data
    
    ftsz = 10
    fig = plt.figure(figsize=(12,5), dpi=80)
    ax = fig.add_subplot(121)
    ax.set_title('Post-rules rate vs Pre-rules rate', fontsize=ftsz)
    ax.set_xlabel('Pre-throttling rate [Hz]', fontsize=ftsz)
    ax.set_ylabel('Post-throttling rate [Hz]', fontsize=ftsz)
    ax.plot(l1AFreq,ttcL1As, '-o', ms=8, lw=3, alpha=0.7, label='ttc l1a count')
    ax.plot(l1AFreq,roEvCounts, '-yo', ms=8, lw=3, alpha=0.7, label='ro ev count')
    ax.legend(loc='upper left')
    
    ax2 = fig.add_subplot(122)
    ax2.set_title('Post-rules rate vs Pre-rules rate', fontsize=ftsz)
    ax2.set_xlabel('Pre-throttling rate [Hz]', fontsize=ftsz)
    ax2.set_ylabel('TTS state', fontsize=ftsz)
    ax2.set_ylim([0,0xf])
    ax2.plot(l1AFreq,tts, '-^', ms=8, lw=3, alpha=0.7, label='ro ev count')
    return fig


#---
def plotThrottledRateDrainRate( data ):

    # Local imports    
    import matplotlib.pyplot as plt

    figs = {}

    ftsz = 10
    drset = set([ tuple(sorted(v.keys())) for fs,v in data.iteritems()])
    
    if len(drset) != 1: raise ValueError('Aaaarg')
    drs = drset.pop()
    
    for i,dr in enumerate(drs):
        fig = plt.figure(figsize=(13,5), dpi=80)
        ax = fig.add_subplot(1,2,1)
        ax.set_title('Effect of throttling (Drain rate %dGb/s)' % (dr+1), fontsize=ftsz)
        ax.set_xlabel('Pre-throttling rate [Hz]', fontsize=ftsz)
        ax.set_ylabel('Post-throttling rate [Hz]', fontsize=ftsz)
        for fs in sorted(data):
           d = data[fs][dr]
           ax.plot(d[0],d[1], '-o', ms=5, lw=2, alpha=0.7)#, label='Fk ev size %d' % fs) 
        #ax.legend(loc='upper left')
        
        ax2 = fig.add_subplot(1,2,2)
        ax2.set_title('Final TTS state (Drain rate %dGb/s)' % (dr+1), fontsize=ftsz)
        ax2.set_xlabel('Pre-throttling rate [Hz]', fontsize=ftsz)
        ax2.set_ylabel('TTS code', fontsize=ftsz)
        for fs in sorted(data):
            d = data[fs][dr]
            ax2.plot(d[0],d[3], '-o', ms=5, lw=2, alpha=0.7)#, label='Fk ev size %d' % fs)
        #ax2.legend(loc='upper left')
        figs[dr] = fig

    return figs

#---
def plotThrottledRateEvSize( data ):

    # Local imports    
    import matplotlib.pyplot as plt

    # Plots of pre-post throttling rates at at different drain rates, for different event sizes
    figs = {}
    
    ftsz = 15
    
    for i,fs in enumerate(sorted(data)):
        fig = plt.figure(figsize=(13,5), dpi=80)
        ax = fig.add_subplot(1,2,1)
        ax.set_title('Effect of throttling')# (Fk ev size %d)' % fs, fontsize=ftsz)
        ax.set_xlabel('Pre-throttling rate [Hz]', fontsize=ftsz)
        ax.set_ylabel('Post-throttling rate [Hz]', fontsize=ftsz)
        for dr,d in data[fs].iteritems():
            ax.plot(d[0],d[1], '-o', ms=5, lw=2, alpha=0.7, label='Drain rate %d' % dr)#
        #ax.legend(loc='upper left')
        
        ax2 = fig.add_subplot(1,2,2)
        ax2.set_title('Final TTS state)')# (Fk ev size %d)' % fs, fontsize=ftsz)
        ax2.set_xlabel('Pre-throttling rate [Hz]', fontsize=ftsz)
        ax2.set_ylabel('TTS code', fontsize=ftsz)
        for dr,d in data[fs].iteritems():
            ax2.plot(d[0],d[3], '-o', ms=5, lw=2, alpha=0.7, label='Drain rate %d' % dr)
        #ax2.legend(loc='upper left')
        figs[fs] = fig
    
    return figs
    
