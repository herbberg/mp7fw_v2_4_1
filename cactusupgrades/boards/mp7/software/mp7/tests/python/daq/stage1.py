import logging
import time
import sys

import mp7
import mp7.tools.helpers as hlp
from mp7.cli_core import defaultFmtStr, FunctorInterface

def _remakeMenu():

    baseMode = mp7.ReadoutMenu.Mode(4)

    # Common parameters
    # -----------------

    # Even, bank id 1, +0bx
    c = baseMode[0]
    c.enable = True
    c.bankId = 1
    c.id = 0

    # Odd, bank id 2, +0bx
    c = baseMode[1]
    c.enable = True
    c.bankId = 2
    c.id = 0

    # Odd, bank id 2, +9bx
    c = baseMode[2]
    c.enable = True
    c.bankId = 2
    c.id = 1

    # Outs, bank id 2, +0bx
    c = baseMode[3]
    c.enable = True
    c.bankId = 3
    c.id = 2

    s1Menu = mp7.ReadoutMenu(4,2,4)

    # Even inputs, 6 w per bx
    s1Menu.bank(1).wordsPerBx = 6
    # Odd inputs, 6 w per bx
    s1Menu.bank(2).wordsPerBx = 6
    # Outputs, 2 w per bx
    s1Menu.bank(3).wordsPerBx = 2

    s1Menu.setMode(0,baseMode)
    s1Menu.setMode(1,baseMode)

    # First trigger mode, Validation events
    # -------------------------------------

    m = s1Menu.mode(0)
    m.eventSize = 0
    m.eventToTrigger = 107
    m.eventType = 0x1
    m.tokenDelay = 70

    # Even, bank id 1, +0bx
    c = s1Menu.capture(0,0)
    c.delay = 0
    c.length = 5
    c.readoutLength = 30

    # Odd, bank id 2, +0bx
    c = s1Menu.capture(0,1)
    c.delay = 0
    c.length = 5
    c.readoutLength = 30

    # Odd, bank id 2, +9bx
    c = s1Menu.capture(0,2)
    c.delay = 9
    c.length = 5
    c.readoutLength = 30

    # Outs, bank id 2, +0bx
    c = s1Menu.capture(0,3)
    c.delay = 0
    c.length = 5
    c.readoutLength = 10


    # Second trigger mode, standard events
    # ------------------------------------

    m = s1Menu.mode(1)
    m.eventSize = 0
    m.eventToTrigger = 1
    m.eventType = 0x0
    m.tokenDelay = 70

    # Even, bank id 1, +0bx
    c = s1Menu.capture(1,0)
    c.delay = 2 # 0+2 bx
    c.length = 1
    c.readoutLength = 6

    # Odd, bank id 2, +0bx
    c = s1Menu.capture(1,1)
    c.delay = 2 # 0+2bx
    c.length = 1
    c.readoutLength = 6

    # Odd, bank id 2, +9bx
    c = s1Menu.capture(1,2)
    c.delay = 11 # 9+2bx
    c.length = 1
    c.readoutLength = 6

    # Outs, bank id 2, +0bx
    c = s1Menu.capture(1,3)
    c.delay = 0
    c.length = 5
    c.readoutLength = 10

    return s1Menu

menu = _remakeMenu()


class ConfigS1Demo(FunctorInterface):

    @staticmethod
    def addArgs(subp):

        subp.add_argument('mode', default=None, choices=['algo','loop'], help='Configure buffers in stage1 demo mode')
        subp.add_argument('chset', default=None, choices=['test','testsim','testsimB','full'], help='Configure buffers in stage1 demo mode')
        subp.add_argument('src', default=None, choices=['counts','events'], help='Configure buffers in stage1 demo mode')
        subp.add_argument('--add', default=0, type=int, help='Add latency if necessary')
        subp.add_argument('--inject', default=None, help='Add latency if necessary')

    @staticmethod
    def run(board, mode, chset, src, add, inject=None):

        cm = hlp.channelMgr(board)

        # Set Stage1 Board ID
        ctrl = board.getCtrl()

        ctrl.getNode('board_id').write(0x2300)
        ctrl.getClient().dispatch()

        logging.debug('Applying default buffer config')
        rxlatency = mp7.LatencyPathConfigurator(0, 1)
        cm.configureBuffers(mp7.kRx, rxlatency)
        txlatency = mp7.LatencyPathConfigurator(0, 1)
        cm.configureBuffers(mp7.kTx, txlatency)

        # Stage 1 fibre mapping
        # Even channels, 

        if chset == 'test':
            lInsEven  = [0]
            lInsOdd  = [1] 
            lOuts  = [38]
        elif chset == 'testsim':
            lInsEven  = [0] #[ 2*i for i in xrange(18) ] # captures right away
            lInsOdd  = [1] #[ 2*i+1 for i in xrange(18) ] # captured after 1 bx
            lOuts  = [4] #range(38,54) # outputs right away 
        elif chset == 'testsimB':
            lInsEven  = [4] #[ 2*i for i in xrange(18) ] # captures right away
            lInsOdd  = [5] #[ 2*i+1 for i in xrange(18) ] # captured after 1 bx
            lOuts  = [8] #range(38,54) # outputs right away 
        elif chset == 'full':
            lInsEven = range(0,36,2) # [ 2*i for i in xrange(18) ] # captures right away
            lInsOdd  = range(1,36,2) #[ 2*i+1 for i in xrange(18) ] # captured twice
            lOuts    = range(38,54) # outputs right away 
        elif chset == 'debug':
            lInsEven = range(0,36)
            lInsOdd  = []
            lOuts    = [] 

        else:
            raise ArgumentError('chset can either be test or full')

        #
        latPropagationCyc = 32

        # tx->mgt->rx
        latTx2Rx = 39

        # for rx->algo->tx
        latRx2Tx = 4 
        # inBaseLatency = latPropagationCyc-latRx2Tx
        # outBaseLatency = latPropagationCyc-latRx2Tx

        lIns = lInsEven+lInsOdd


        # mode = 'algo'
        if mode == 'algo':

            # Data sources
            inSrc   = mp7.kRx
            outSrc  = mp7.kRx

            # Data destination
            inDest  = mp7.kTx
            outDest = mp7.kTx

            inBaseLatency = latPropagationCyc-latRx2Tx
            outBaseLatency = latPropagationCyc-latRx2Tx

        elif mode == 'loop':
            # Data sources
            inSrc   = mp7.kTx
            outSrc  = mp7.kRx

            # Data destination
            inDest  = mp7.kRx
            outDest = mp7.kTx

            inBaseLatency = latPropagationCyc-latTx2Rx
            outBaseLatency = latPropagationCyc-latRx2Tx

            print 'inBaseLatency', inBaseLatency
            print 'outBaseLatency', outBaseLatency
        else:
            raise ArgumentError('Unknown mode '+mode)

        if src == 'counts':
            # Data source
            logging.debug('Configuring pattern generation on tx %s (inputs)', sorted(lIns))
            patt = mp7.TestPathConfigurator(mp7.PathConfigurator.kPattern, mp7.orbit.Point(0), board.getMetric());
            hlp.channelMgr(board,lIns).configureBuffers(inSrc, patt)

            # Outputs
            logging.debug('Configuring pattern generation on rx %s (outputs)', sorted(lOuts))
            patt = mp7.TestPathConfigurator(mp7.PathConfigurator.kPattern3G, mp7.orbit.Point(0), board.getMetric());
            hlp.channelMgr(board,lOuts).configureBuffers(outSrc, patt)

        elif src == 'events':
            # Data source, tx buffers of input channels
            logging.debug('Configuring playback generation on %s %s (inputs)', inSrc, sorted(lIns))
            play = mp7.TestPathConfigurator(mp7.PathConfigurator.kPlayOnce, mp7.orbit.Point(0), board.getMetric());
            hlp.channelMgr(board,lIns).configureBuffers(inSrc, play)

            logging.debug('Configuring strobed playback on %s %s (outputs)', outSrc, sorted(lOuts))
            play = mp7.TestPathConfigurator(mp7.PathConfigurator.kPlayOnce3G, mp7.orbit.Point(0), board.getMetric());
            hlp.channelMgr(board,lOuts).configureBuffers(outSrc, play)

            # Loading events from file
            # Input events first
            # rxevents = mp7.BoardDataFactory.readFromFile('events/s1golden-clean-strobed/rx_summary.txt')
            # txevents = mp7.BoardDataFactory.readFromFile('events/s1golden-clean-strobed/tx_summary.txt')

            if inject is None:
                rxevents = mp7.BoardDataFactory.generate('generate://pattern')
                txevents = mp7.BoardDataFactory.generate('generate://3gpattern')
            else:
                logging.info('Injecting events from %s', inject)
                rxevents = mp7.BoardDataFactory.generate('file://'+inject+'/rx_summary.txt')
                txevents = mp7.BoardDataFactory.generate('file://'+inject+'/tx_summary.txt')

            hlp.channelMgr(board,lIns).loadPatterns(inSrc, rxevents)

            hlp.channelMgr(board,lOuts).loadPatterns(outSrc, txevents)
        else:
            raise ArgumentError('WTF!?!?')




        # Real latency buffer configuration
        # Increase the latency to capture 2 bx ahead
        inLatency = inBaseLatency+add
        logging.debug('Configuring latency buffers even=%s, odd=%s, latency=%d', lInsEven, lInsOdd, inLatency)
        # Dummy inout channels
        txlatency = mp7.LatencyPathConfigurator(1, inLatency)
        hlp.channelMgr(board,lInsEven).configureBuffers(inDest, txlatency)

        txlatency = mp7.LatencyPathConfigurator(2, inLatency)
        hlp.channelMgr(board,lInsOdd).configureBuffers(inDest, txlatency)

        # Increase the latency to capture 2 bx ahead
        outLatency = outBaseLatency+add
        logging.debug('Configuring latency buffers outs=%s, latency=%d', lOuts, outLatency)
        # Dummy output channels
        txlatency = mp7.LatencyPathConfigurator(3, outLatency)
        hlp.channelMgr(board,lOuts).configureBuffers(outDest, txlatency)
        