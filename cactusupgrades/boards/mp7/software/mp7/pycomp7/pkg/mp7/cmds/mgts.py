import logging
import os
import time
from datetime import datetime

import mp7
import mp7.tools.helpers as hlp
from mp7.cli_core import defaultFmtStr, FunctorInterface
from mp7.tools.cli_utils import IntListAction, BxRangeTupleAction, HdrFormatterAction, ValidFormatterAction, BC0FormatterAction, OrbitPointAction


class RxMGTs(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)
        subp.add_argument('--polarity', dest='polarity',  default='std', choices=['std','inv'],  help='Polarity \'std\': standard, \'inv\': inverted'+defaultFmtStr)
        subp.add_argument('--orbittag', dest='orbittag',  default=False, action='store_true',  help='Align to the orbit tag'+defaultFmtStr)

    @staticmethod
    def run(board, enablechans=None, orbittag=False, polarity='std'): #, alignTo=None, alignMargin=3): #, config=True, align=True, check=True, forcepattern=None, threeg=False, dmx_delays=False):
        
        cm = hlp.channelMgr(board,enablechans)

        cm.configureRxMGTs(orbittag, polarity=='std')
    

class TxMGTs(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)
        subp.add_argument('--polarity', dest='polarity',  default='std', choices=['std','inv'],  help='Polarity \'std\': standard, \'inv\': inverted'+defaultFmtStr)
        subp.add_argument('--loopback', dest='loopback',  default=False, action='store_true',  help='Activate MGT loopback'+defaultFmtStr)
        subp.add_argument('--pattern', dest='pattern',  default='none', choices=['none','std','3g','orbittag'],  help='Select loopback pattern'+defaultFmtStr)


    @staticmethod
    def run(board, enablechans=None, polarity='std', loopback=False, pattern=None):
        
        cm = hlp.channelMgr(board,enablechans)

        cm.configureTxMGTs(loopback, polarity=='std')

        if pattern == 'std':
            cm.setupTx2RxPattern()
        elif pattern == '3g':
            cm.setupTx2Rx3GPattern()
        elif pattern =='orbittag':
            cm.setupTx2RxOrbitPattern()
        elif pattern == 'none':
            logging.debug('Loopback pattern generation disabled')


class RxAlign(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)   
        subp.add_argument('--to-bx', dest='alignTo', default=None, action=OrbitPointAction, help='Align links to (bx,cycle)'+defaultFmtStr)
        subp.add_argument('--margin', dest='alignMargin', default=3, type=int, help='Alignment margin (Only used when minimising latency)'+defaultFmtStr)
        subp.add_argument('--freeze', dest='alignFreeze', default=False, action='store_true', help='Freeze alignment point after aligning'+defaultFmtStr)
        subp.add_argument('--dmx-delays', dest='dmx_delays',  default=False, action='store_true',  help='Add additional delay for L2 Demux'+defaultFmtStr)

    @staticmethod
    def run(board, enablechans=None, alignTo=None, alignMargin=3, alignFreeze=False, dmx_delays=False):

        cm = hlp.channelMgr(board,enablechans)

        logging.notice('Aligning links')

        delays = None
        
        if dmx_delays:
            
            #delays = {}
            
            #nMaxMps = 12
            #clockRatio = 6
            #nMpOutputs = 6
            #for mp in xrange(nMaxMps):
            #    for c in xrange(nMpOutputs):
            #        delays[c*nMaxMps+mp] = mp*clockRatio
      

            delays = {}
            
            nMaxMps = 6
            nMaxMps_2 = 12

            clockRatio = 6
            nMpOutputs = 6
            nMpOutputs_2 =12
            
            for mp in xrange(nMaxMps-1):
                for c in xrange(nMpOutputs):
                    delays[c*nMaxMps+mp] = mp*clockRatio
        
            for mp in xrange(nMaxMps,nMaxMps_2):
                for c in xrange(nMpOutputs,nMpOutputs_2):
                    delays[c*nMaxMps+mp-6] = mp*clockRatio - 6

                    
        if alignTo:
            p = mp7.orbit.Point( alignTo[0], alignTo[1])
            args = (p,) if delays == None else (p, delays)

            cm.align(*args)
         
        else:
            args = (alignMargin,) if delays == None else (delays, alignMargin)

            cm.minimizeAndAlign(*args);

        if alignFreeze:
            cm.freezeAlignment()

#    __  ___          _ __             __   _      __      
#   /  |/  /__  ___  (_) /____  ____  / /  (_)__  / /__ ___
#  / /|_/ / _ \/ _ \/ / __/ _ \/ __/ / /__/ / _ \/  '_/(_-<
# /_/  /_/\___/_//_/_/\__/\___/_/   /____/_/_//_/_/\_\/___/
#                                                         

class RxMGTsCheck:
    @staticmethod
    def addArgs(subp):
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)   
        subp.add_argument('repeat', nargs='?', default=1, type=int, help='number of repetitions')
        subp.add_argument('--wait', default=5, type=int, help='pause between checks'+defaultFmtStr)
        subp.add_argument('--clear', dest='clear',  default=False, action='store_true',  help='Clear counters at the end'+defaultFmtStr)

    @staticmethod
    def run(board, enablechans=None, repeat=1, wait=5, clear=False):        

        cm = hlp.channelMgr(board,enablechans)

        errcntr = 0
        errtime = []
        for i in xrange(repeat):
            if i is not 0:
                time.sleep(wait)
            try:
                logging.info('==> Running check %d',i)
                cm.checkMGTs()
            except mp7.exception as e:
                errcntr += 1
                errtime.append(datetime.now())
                logging.error(e)
            if clear:
                board.channelMgr().clearLinkCounters()

        elog = logging.info if errcntr==0 else logging.error
        elog('Summary: %d checks failed',errcntr)
        for i,t in enumerate(errtime):
            elog( ' -> Fail #%i timestamp: %s', i, str(t) )


class RxAlignCheck:
    @staticmethod
    def addArgs(subp):
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)   

    @staticmethod
    def run(board, enablechans=None):        

        cm = hlp.channelMgr(board,enablechans)

        aligns = cm.readAlignmentStatus()

        for ch in sorted(aligns):
            status = aligns[ch]

            log = logging.info if ( status.marker and status.errors == 0 ) else logging.error
            logging.info( 'id %02d: marker %s, pos %s, frozen %s, errors %d' % (
                ch,
                'OK' if (status.marker == True) else 'Missing',
                status.position,
                'Yes'  if (status.frozen == True) else 'No',
                status.errors) 
            )

#    ____         ____            
#   / __/_ _____ / __/______ ____ 
#  / _// // / -_)\ \/ __/ _ `/ _ \
# /___/\_, /\__/___/\__/\_,_/_//_/
#     /___/                       
class EyeScan:
    @staticmethod
    def addArgs(subp):
        subp.add_argument('-c','--chan', dest='chan', default=0, type=int, help='Link to perform eyescan on.'+defaultFmtStr)
        subp.add_argument('-o','--out','--outputpath', default='eye_data', help='Output path'+defaultFmtStr)
        subp.add_argument('--xmax', default=32, type=int, help='X maximum'+defaultFmtStr)
        subp.add_argument('--ymax', default=127, type=int, help='Y maximum'+defaultFmtStr)
        subp.add_argument('--xstep', default=2, type=int, help='Steps in X'+defaultFmtStr)
        subp.add_argument('--ystep', default=3, type=int, help='Steps in Y'+defaultFmtStr)

    @staticmethod
    def run(board, chan, out, xmax, ymax, xstep, ystep):

        chanType = board.channelMgr().getDescriptor().getRegionInfoByChannel(chan).mgtOut
        if chanType != mp7.kGth10gStdLat:
            logging.error("Channel type mismatch: channel %d type is '%s', expecting 'kGth10gStdLat'", chan, chanType)
            return
        
        logging.warning('Advised user runs a reset before using this command, ye have been warned')

        allChans = range(0,72)
        # TxMGTs.run(board, enablechans=list(range(0,72)), loopback=True, pattern='std')
        RxMGTs.run(board, enablechans=allChans)

        logging.notice('Selecting channel %d', chan)
        board.getDatapath().selectLink(chan)

        drp = board.hw().getNode('datapath.region.drp')
        mgt = board.hw().getNode('datapath.region.mgt')

        prescale_max = 8

        #mgt.getNode ('rw_regs.ch0.control.prbs_enable').write(0x1);

        # Qual mask
        drp.getNode ('es_qual_mask_15to00').write(0xFFFF);
        drp.getNode ('es_qual_mask_31to16').write(0xFFFF);
        drp.getNode ('es_qual_mask_47to32').write(0xFFFF);
        drp.getNode ('es_qual_mask_63to48').write(0xFFFF);
        drp.getNode ('es_qual_mask_79to64').write(0xFFFF);

        # Sdata mask
        drp.getNode ('es_sdata_mask_15to00').write(0);
        drp.getNode ('es_sdata_mask_31to16').write(0);
        drp.getNode ('es_sdata_mask_47to32').write(0xFF00);
        drp.getNode ('es_sdata_mask_63to48').write(0xFFFF);
        drp.getNode ('es_sdata_mask_79to64').write(0xFFFF);
        drp.getClient().dispatch()

        x_ = list(range(-xmax,xmax+1, xstep)) #was step of 1
        y_ = list(range(-ymax,ymax+1, ystep)) #was step of 1
        
        z_ = []
        
        #if not os.path.exists(os.path.dirname('eye_data')):
        #    os.makedirs(os.path.dirname('eye_data'))
        if not os.path.exists(out):
            os.makedirs(out)

        filename = 'eyescan_%02d_%d_%d_%d_%d_%s.txt' % (chan, xmax, ymax, xstep, ystep, time.strftime("%Y%m%d_%H%M%S"))
        filepath = os.path.join(out,filename)
        with open(filepath, 'w') as f:
        
            for i in x_:#2  # Was step of 1

                logging.info('Measuring %s / %s' , i, max(x_)) 
                tmp = []
                for j in y_:#2  # Was step of 1
                
                    for p in range(0, prescale_max+1):

                        y = eyeMeasure(board.hw(), i, j, p)
                        logging.debug('%s',y)

                        # Keep going up in prescale until error count is > 0
                        # or we reach the maximum acceptable prescale
                        if y[1] == 0 and p != prescale_max:
                            continue

                        # Count must be greater than zero for a prescale of 2
                        if y[1] == 0:
                            # 95% confidence minimum, count must be 65535
                            ret = 1.0 / (float(y[0]) * float(3 * (2 ** (p+1))))
                        elif y[0] != 0:
                            ret = float(y[1]) / (float(y[0]) * float(2 ** (p+1)) )
                        else:
                            ret = 0
                        
                        z_.append(ret)
                        f.write(str(i)+','+str(j)+','+str(ret)+'\n')
                        break
        logging.info('Eyescan data for channel %d saved to %s', chan, filepath)

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

    drp.getNode ('es_horz_offset').write(horizontal);

    # Ignore DFE
    v = 0
    if vertical < 0:
        # v = 1 << 7.  Bug?  Value 'v' overwritten by next line.
        v = -vertical
    else:
        v = vertical

    # Vertical
    drp.getNode ('es_vert_offset').write(v);
    # Prescale
    drp.getNode ('es_prescale').write(prescale);

    # Trigger ES control
    drp.getNode ('es_control.run').write(0);
    drp.getNode ('es_control.run').write(1);
    drp.getClient().dispatch()

    while True:
        done = drp.getNode ('es_control_status.done').read();
        drp.getClient().dispatch()
        if done:
            break

    sample_cnt = done = drp.getNode ('es_sample_count').read();
    error_cnt = done = drp.getNode ('es_error_count').read();
    drp.getClient().dispatch()

    return [sample_cnt.value(), error_cnt.value()]
