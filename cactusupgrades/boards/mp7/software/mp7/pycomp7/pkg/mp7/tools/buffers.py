import mp7
import logging
import mp7.tools.helpers as hlp

_mode = mp7.PathConfigurator.Mode
# import the enumerator for brevity
_BufMode = mp7.ChanBufferNode.BufMode
_DataSrc = mp7.ChanBufferNode.DataSrc
#----------------------------


def loadBuffers( controller, enablechans=None, data_rx = None, data_tx = None, clearall=False ):
    ctrl = controller.getCtrl()
    cm = controller.channelMgr(enablechans) if enablechans is not None else controller.channelMgr()
    if data_rx:
        # if a pattern is supposed to be loaded, clear first
        cm.clearBuffers(mp7.kRx)
        cm.loadPatterns(mp7.kRx, data_rx)
    else:
        # otherwise clear only buffers configured in capture mode 
        cm.clearBuffers(mp7.kRx, mp7.ChanBufferNode.kCapture)

    if data_tx:
        # if a pattern is supposed to be loaded, clear first
        cm.clearBuffers(mp7.kTx)
        cm.loadPatterns(mp7.kTx, data_tx)
    else:
        # otherwise clear only buffers configured in capture mode 
        cm.clearBuffers(mp7.kTx, mp7.ChanBufferNode.kCapture)


class Configurator:
    '''Helper class to easily configure Rx and Tx buffers to run different tests 
    '''
    _log = logging.getLogger('Configurator')
    
    _modes = {
        'zeroes':         (_mode.kZeroes,         _mode.kZeroes), # L1 capture
        'captureRx':      (_mode.kCapture,        _mode.kLatency), #
        'captureTx':      (_mode.kLatency,        _mode.kCapture), #
        'captureRxTx':    (_mode.kCapture,        _mode.kCapture), #
        'algoPlay':       (_mode.kPlayOnce,       _mode.kCapture),
        'algoPatt':       (_mode.kPattern,        _mode.kCapture),
        'loopPlay':       (_mode.kCapture,        _mode.kPlayOnce),
        'loopPatt':       (_mode.kCapture,        _mode.kPattern),
        'captureRxStb':   (_mode.kCaptureStrobe,  _mode.kLatency), #
        'captureTxStb':   (_mode.kLatency,        _mode.kCaptureStrobe), #
        'captureRxTxStb': (_mode.kCaptureStrobe,  _mode.kCaptureStrobe), #
        'algoPatt3G':     (_mode.kPattern3G,      _mode.kCaptureStrobe),
        'algoPlayStb':    (_mode.kPlayOnceStrobe, _mode.kCaptureStrobe),
        'algoPlay3G':     (_mode.kPlayOnce3G,     _mode.kCaptureStrobe),
        'loopPlayStb':    (_mode.kCaptureStrobe,  _mode.kPlayOnceStrobe),
        'loopPatt3G':     (_mode.kCaptureStrobe,  _mode.kPattern3G),
        'strobeTest':     (_mode.kCaptureStrobe,  _mode.kCaptureStrobe),
    }

    @classmethod
    def modes(cls):
        return cls._modes.keys()

    @property
    def pathmodes(self):
        return self._modes[self._mode]

    _pattModes = [_mode.kPattern,_mode.kPattern3G,_mode.kPlayOnceStrobe]
    _playModes = [_mode.kPlayOnce,_mode.kPlayLoop,_mode.kPlayOnceStrobe,_mode.kPlayOnce3G]
    _capModes = [_mode.kCapture, _mode.kCaptureStrobe]
    _otherModes = [_mode.kLatency, _mode.kZeroes]

    def __init__(self, mode, enablechans=None, play=(0x0,None), cap=(0x0,None)):
        # Data members definition
        # 
        self._mode = mode
        self._enable = enablechans

        self._playRng = play
        self._capRng  = cap

    #---
    def getRxTxModes(self):
        return self._modes[self._mode]


    #---
    def assignRxTxData(self, data):
        '''Assigns data to the buffers configured in playback
        '''
        mode_rx,mode_tx = self.getRxTxModes()
        data_rx = data if mode_rx in self._playModes else None
        data_tx = data if mode_tx in self._playModes else None

        return data_rx, data_tx


    #---
    def _makeCfgtr(self, controller, bMode):

        # If latency or Zeroes, just a plain configurator 
        if bMode in self._otherModes:
            return mp7.TestPathConfigurator(bMode, mp7.orbit.Point(0), controller.getMetric())


        # Plyback?
        if bMode in self._playModes or bMode in self._pattModes:
            first, last = self._playRng
        # in capture, the capture range
        elif bMode in self._capModes:
            first, last = self._capRng
        # Nor play neither cap. Something's wrong
        else:
            raise ValueError('Mode %s not known (to me)' % bMode)

        # Do the real thing, then
        m = controller.getMetric()  
        if last is None:
            return mp7.TestPathConfigurator(bMode, first, m)

        return mp7.TestPathConfigurator(bMode, first, last, m)


    #---
    def configure(self, controller):
        '''Applies the requested configuration to the buffers

        Args:

        '''
        m = controller.getMetric()
        cm = hlp.channelMgr(controller,self._enable)

        # Search for the requested config
        self._log.debug('%s play: %s cap: %s', self._mode, self._playRng, self._capRng )

        # Find what mode rx and tx buffers must be configured with
        rxMode,txMode = self.getRxTxModes()

        rxConfig = self._makeCfgtr(controller, rxMode)
        # And apply it
        cm.configureBuffers(mp7.kRx, rxConfig);

        txConfig = self._makeCfgtr(controller, txMode)
        # And apply it
        cm.configureBuffers(mp7.kTx, txConfig);
