import logging

import mp7

from mp7.cli_core import defaultFmtStr, FunctorInterface
import mp7.tools.helpers as hlp
from mp7.tools.cli_utils import IntListAction

###############################################
#  >>>  Clock- and TTC-related commands  <<<  #
###############################################

class Reset(FunctorInterface):

    @staticmethod
    def addArgs(subp):
        clksrcs = ['internal', 'external']
        subp.add_argument('--clksrc', choices=clksrcs, default='external', help='Clock source selection'+defaultFmtStr)
        subp.add_argument('--clkcfg', default=None, help='MP7 Clocking configuration'+defaultFmtStr)
        subp.add_argument('--ttccfg', default=None, help='MP7 TTC configuration'+defaultFmtStr) 
        subp.add_argument('--no-check', dest='check', default=True, action='store_false', help='MP7 TTC configuration'+defaultFmtStr) #

    @staticmethod
    def run(board, clksrc='external', clkcfg=None, ttccfg=None, check=True):
        logging.info('Board master reset')
        
        board.reset(clksrc, clkcfg if clkcfg else clksrc, ttccfg if ttccfg else clksrc)
        #TODO : Replace this with reset function based on clock & TTC config ??

        if board.kind() != mp7.MP7Kind.kMP7Sim and check:
            logging.info('Clock 40 frequency measurement. Hold on for a sec...')
            board.getTTC().measureClockFreq(mp7.TTCNode.kClock40)
            board.checkTTC()


        logging.info('MGTs master reset')
        board.channelMgr().resetMGTs()


        logging.info('AMC13 reset')
        board.getReadout().resetAMC13Block();

        # Add algo reset here
        logging.info('Algorithm reset')
        board.resetPayload()


class MeasureClocks(FunctorInterface):

    @staticmethod
    def addArgs(subp):
        dftstr = mp7.cmds.defaultFmtStr
        subp.add_argument('-e','--enablechans', action=IntListAction, default=None, help='Channels to control'+dftstr)

    @staticmethod
    def run(board, enablechans):
        board.checkTTC()
        logging.info('Measuring clocks')
        cm = hlp.channelMgr(board, enablechans)

        clkInfoMap = cm.refClkReport()
        for i in cm.pickMGTIDs().channels():
            id = "[{0:02d}]".format(i)
            logging.info('-> Channel '+id)
            logging.info('    RefClk = %s', clkInfoMap['RefClk'+id])
            logging.info('    RxClk  = %s', clkInfoMap['RxClk'+id])
            logging.info('    TxClk  = %s', clkInfoMap['TxClk'+id])


class TTCCapture(FunctorInterface):
    
    @staticmethod
    def addArgs(subp):
        subp.add_argument('--maskbc0', default=None, choices=['yes','no'], help='Skip BC0s'+defaultFmtStr )
        subp.add_argument('--clear', default=False, action='store_true', help='Clear history before capturing'+defaultFmtStr )

    #TODO: Move this function to helpers if might be used elsewhere ???
    @staticmethod
    def run(board, clear, maskbc0):
        if clear:
            board.getTTC().clear()

        if maskbc0 != None:
            # 0 = BC0 masked
            # 1 = L1A masked
            board.getTTC().maskHistoryBC0L1a( maskbc0 == 'yes' )

        history =  board.getTTC().captureHistory()

        for i,e in enumerate(history):
            # print('%4d | V:%1d L1A:%1d orb:0x%06x bx:0x%03x cmd:%02x' % (i,valid, isL1A, orbit, bx, cmd))
            logging.info('%4d | orb:0x%06x bx:0x%03x ev:0x%06x l1a:%1d cmd:%02x', i, e.orbit, e.bx, e.event,e.l1a, e.cmd)
