import logging
import os
import time

import mp7
from mp7.tools import buffers
import mp7.tools.helpers as hlp
from mp7.cli_core import defaultFmtStr, FunctorInterface

from mp7.tools.cli_utils import IntListAction, BxRangeTupleAction, HdrFormatterAction, ValidFormatterAction, BC0FormatterAction, OrbitPointAction

from argparse import ArgumentError

#    ___       ______          
#   / _ )__ __/ _/ _/__ _______
#  / _  / // / _/ _/ -_) __(_-<
# /____/\_,_/_//_/ \__/_/ /___/
#                             

#---
class Buffers(FunctorInterface):

    @staticmethod
    def addArgs(subp):
        subp.add_argument('mode', choices=buffers.Configurator.modes(), help='Buffer mode')
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)
        subp.add_argument('--inject', dest='data_uri', default='generate://empty', help='Source of data to be injected'+defaultFmtStr)
        subp.add_argument('--cap', dest='cap_bx',  default=(mp7.orbit.Point(0),None), action=BxRangeTupleAction, help='Capture range '+defaultFmtStr)
        subp.add_argument('--play',dest='play_bx', default=(mp7.orbit.Point(0),None), action=BxRangeTupleAction, help='Playback range'+defaultFmtStr)

    @staticmethod
    def run(board, mode, enablechans=None, data_uri='generate://empty', cap_bx=(mp7.orbit.Point(0),None), play_bx=(mp7.orbit.Point(0),None)):
        # board.getBuffer().setSize(depth)
        depth    = board.getBuffer().getBufferSize()

        logging.warn('playback=%s, capture=%s, depth=%s' % (play_bx, cap_bx, depth) )

        # Prepare the data to be loaded into the pp RAMs
        if data_uri is not None:
            data = mp7.BoardDataFactory.generate(data_uri, depth, True)
        else:
            data = None

        # Instantiate a buffer configurator.
        # bufferConfigurator = buffers.Configurator.withBXRange( board, mode, playbx=play_bx, capbx=cap_bx )
        bufferConfigurator = buffers.Configurator( mode, enablechans, play_bx, cap_bx )

        # Apply the selected configuration
        bufferConfigurator.configure(board)

        # Pre-fill the buffers according to the selected operation mode
        data_rx, data_tx = bufferConfigurator.assignRxTxData(data)

        # Forcefully clear buffers and load patters, if necessary
        buffers.loadBuffers(board, enablechans, data_rx, data_tx, clearall=True )


#    _  _____       ______          
#   | |/_/ _ )__ __/ _/ _/__ _______
#  _>  </ _  / // / _/ _/ -_) __(_-<
# /_/|_/____/\_,_/_//_/ \__/_/ /___/
#                                   

#---
class XBuffers(FunctorInterface):

    #TODO: retrieve  default argument values in framework from applying inspect.getargspec method to the call function ??
    @staticmethod
    def addArgs(subp):
        bufmodes = [str(m)[1:] for m  in mp7.PathConfigurator.Mode.names.iterkeys()]
        subp.add_argument('sel',choices=['rx','tx'], default=None, help='Buffer to configure')
        subp.add_argument('mode',choices=bufmodes)
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)
        subp.add_argument('--inject', dest='data_uri', default=None, help='Source of data to be injected'+defaultFmtStr)
        subp.add_argument('--bx-range', dest='bx_range',  default=(mp7.orbit.Point(0),None), action=BxRangeTupleAction, help='Bx range '+defaultFmtStr)


    @staticmethod
    def run(board, sel, mode, enablechans=None, data_uri=None, bx_range=(mp7.orbit.Point(0),None)):
        depth    = board.getBuffer().getBufferSize()

        idmap = {
            'rx': mp7.RxTxSelector.kRx,
            'tx': mp7.RxTxSelector.kTx,
            }

        m = board.getMetric()

        # Prepare the data to be loaded into the RAMs
        if data_uri is not None:
            data = mp7.BoardDataFactory.generate(data_uri, depth, True)
        else:
            data = None

        bkind = idmap[sel]
        bmode = mp7.PathConfigurator.Mode.names['k'+mode]

        # Build the bx range
        start_p, stop_p = bx_range
        logging.info('Configuring with bx range %s', bx_range)

        if not (stop_p is None or isinstance(stop_p,mp7.orbit.Point)):
            raise ArgumentError('Stop point is not an instance of mp7.orbit.Point')


        if stop_p is None:
            pc = mp7.TestPathConfigurator(bmode, start_p, m)
        else:
            pc = mp7.TestPathConfigurator(bmode, start_p, stop_p, m)

        cm = hlp.channelMgr(board,enablechans)

        logging.info('Configuring %s buffers %s in %s mode', sel, cm.getDescriptor().pickAllIDs().channels(), mode)
        cm.configureBuffers(bkind, pc)

        if data:
            logging.info('Loading data from %s ', data_uri)
            # if a pattern is supposed to be loaded, clear first
            cm.clearBuffers(bkind)
            cm.loadPatterns(bkind, data)
        else:
            # otherwise clear only buffers configured in capture mode
            cm.clearBuffers(bkind, mp7.ChanBufferNode.kCapture)

#    __        __                   
#   / /  ___ _/ /____ ___  ______ __
#  / /__/ _ `/ __/ -_) _ \/ __/ // /
# /____/\_,_/\__/\__/_//_/\__/\_, / 
#                            /___/  
class LatencyBuffers(FunctorInterface):

    @staticmethod
    def addArgs(subp):
        subp.add_argument('group',choices=['rx','tx'], help='Buffer to configure')
        subp.add_argument('bankId', type=int, help='Bank id to assign to latency buffer')
        subp.add_argument('depth', type=int, help='Latency buffer depth (latency)')
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)

    @staticmethod
    def run(board, group, bankId, depth, enablechans=None):

        idmap = {
            'rx': mp7.RxTxSelector.kRx,
            'tx': mp7.RxTxSelector.kTx,
        }

        bkind = idmap[group]

        cm = hlp.channelMgr(board,enablechans)

        pc = mp7.LatencyPathConfigurator(bankId, depth)
        logging.info('Configuring buffers in latency mode: bank id = %d, latency = %d', bankId, depth )
        cm.configureBuffers(bkind, pc)



#    ____                    __  __            
#   / __/__  ______ _  ___ _/ /_/ /____ _______
#  / _// _ \/ __/  ' \/ _ `/ __/ __/ -_) __(_-<
# /_/  \___/_/ /_/_/_/\_,_/\__/\__/\__/_/ /___/
#                                              

#---
class Formatters(FunctorInterface):
    # run = staticmethod(configureFormatters)

    @staticmethod
    def addArgs(subp):
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)
        subp.add_argument('--tdrfmt', dest='tdr_fmt', default=None, action=HdrFormatterAction, help='Header formatter configuration (<strip>,<insert>)'+defaultFmtStr)
        subp.add_argument('--dmx-hdrfmt', dest='dmx_hdrfmt', default=None, action=HdrFormatterAction, help='Demux - Header formatter configuration (<strip>,<insert>)'+defaultFmtStr)
        subp.add_argument('--dmx-validfmt', dest='dmx_valfmt', default=None, action=ValidFormatterAction, help='Demux - Force data valid range (start_bx,start_cycle:stop_bx,stop_cycle)'+defaultFmtStr)
        # subp.add_argument('--s1-bc0fmt', dest='s1_bc0fmt', default=None, action=BC0FormatterAction, help='Stage 1 - Bx at which insert the BC0 tag '+defaultFmtStr)

    @staticmethod
    def run(board, enablechans=None, tdr_fmt=None, dmx_hdrfmt=None, dmx_valfmt=None, s1_bc0fmt=None):
        '''
        Configures the MP7 formatter. Arguments:
             * board - The MP7Controller FunctorInterface for that board
             * tdr_fmt - TDR header formatter options. Valid values: None , or map with keys 'strip' and 'insert', each value True or False
             * dmx_hdrfmt - Demux header formatter options. Valid values: same as tdr_fmt
             * dmx_valfmt - Demux datavalid-override formatter options. Valid values: None, 'disable', or map with keys 'start' and 'stop', each value a 2-tuple of ints (i.e. (bx, clock_cycle))
             * s1_bc0fmt  - Stage-1 formatter options. Valid values: None, 'disable', or int (the bx number)
        '''
        logging.notice("Configuring formatters")
    
        cm = hlp.channelMgr(board,enablechans)

        fmt = board.getFormatter()
        ctrl = board.getCtrl()
        datapath = board.getDatapath()
   

        if ( not any([tdr_fmt, dmx_hdrfmt, dmx_valfmt, s1_bc0fmt]) ):
            logging.warn('Nothing to do')
            return

        if tdr_fmt is not None:
            cm.configureHdrFormatters(mp7.FormatterKind.kTDRFormatter, tdr_fmt['strip'], tdr_fmt['insert'])

        if dmx_hdrfmt is not None :
            cm.configureHdrFormatters(mp7.FormatterKind.kDemuxFormatter, dmx_hdrfmt['strip'], dmx_hdrfmt['insert'])
        
        if dmx_valfmt is not None:
            # print mp7.orbit.Point(*dmx_valfmt['start']),mp7.orbit.Point(*dmx_valfmt['stop'])
            if dmx_valfmt == 'disable':
                cm.disableDVFormatters()
            else:
                cm.configureDVFormatters(mp7.orbit.Point(*dmx_valfmt['start']),mp7.orbit.Point(*dmx_valfmt['stop']))
    

#   _____          __              
#  / ___/__ ____  / /___ _________ 
# / /__/ _ `/ _ \/ __/ // / __/ -_)
# \___/\_,_/ .__/\__/\_,_/_/  \__/ 
#         /_/                      
# 

class Capture(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        # subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)
        subp.add_argument('-o','--out','--outputpath', default='data', help='Output path'+defaultFmtStr)
        subp.add_argument('--tx', action=IntListAction, default=None, help='Tx channels to capture'+defaultFmtStr)
        subp.add_argument('--rx', action=IntListAction, default=None, help='Rx channels to capture'+defaultFmtStr)
    @staticmethod
    def run(board, tx=None, rx=None, out=None):
        # Local references
        ctrl = board.getCtrl()
        ttc = board.getTTC()
        buf = board.getBuffer()

        cm = board.channelMgr()

        txCm = hlp.channelMgr(board,tx)
        rxCm = hlp.channelMgr(board,rx)

        logging.info('Capturing data stream')
        
        # Capture the buffers
        ttc.forceBTest()

        if isinstance(board,mp7.MP7Controller) and board.kind() == mp7.kMP7Sim:
            logging.debug('Sleep 10 secs because simulation is slow')
            time.sleep(10)
        # And check it's done
        cm.waitCaptureDone()
        logging.info('Capture completed')
    
        rxData = rxCm.readBuffers(mp7.RxTxSelector.kRx)
        txData = txCm.readBuffers(mp7.RxTxSelector.kTx)
        
        # Dump
        if out:
            os.system('mkdir -p '+out)
    
            mp7.BoardDataFactory.saveToFile(rxData, os.path.join(out, 'rx_summary.txt'))
            mp7.BoardDataFactory.saveToFile(txData, os.path.join(out, 'tx_summary.txt'))
    
        return rxData, txData

#    ___                
#   / _ \__ ____ _  ___ 
#  / // / // /  ' \/ _ \
# /____/\_,_/_/_/_/ .__/
#                /_/    

#TODO: Move to helpers ???
class Dump(FunctorInterface):
    @staticmethod
    def addArgs(subp):
        # subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+defaultFmtStr)
        subp.add_argument('-o', '--out', '--outputpath', default='data', help='Output path'+defaultFmtStr)
        subp.add_argument('--tx', action=IntListAction, default=None, help='Tx channels to capture'+defaultFmtStr)
        subp.add_argument('--rx', action=IntListAction, default=None, help='Rx channels to capture'+defaultFmtStr)

    @staticmethod
    def run(board, tx=None, rx=None, out='data'):

        # Local references
        ctrl = board.getCtrl()
        txCm = hlp.channelMgr(board,tx)
        rxCm = hlp.channelMgr(board,rx)
        
        rxData = rxCm.readBuffers(mp7.RxTxSelector.kRx)
        txData = txCm.readBuffers(mp7.RxTxSelector.kTx)
    
        os.system('mkdir -p '+out)
    
        mp7.BoardDataFactory.saveToFile(rxData, os.path.join(out, 'rx_summary.txt'))
        mp7.BoardDataFactory.saveToFile(txData, os.path.join(out, 'tx_summary.txt'))
    
        return rxData, txData


