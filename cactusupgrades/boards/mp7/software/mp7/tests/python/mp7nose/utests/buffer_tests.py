# Core module
import mp7nose

# Settings
from mp7nose.settings.buffers import getSettings

# MP7 commands
import mp7.cmds.datapath as datapath
import mp7.cmds.infra as infra
import mp7.cmds.readout as readout
import mp7.orbit as orb
import mp7.tools.data as data

# Asserts from nose
from nose import tools


#---
def measureDatavalidLatency( vStart, capStart, pattStart, metric ):
    '''Measures latency between playback/pattern and capture based on data valid position'''

    vP = orb.Point(
        vStart/metric.clockRatio(),
        vStart%metric.clockRatio()
        )
    p0Tx = metric.add(vP,capStart)

    algoLatency = metric.distance(p0Tx,pattStart)

    return algoLatency

#---
def checkCapturedPattern( data, packet, chans, capStart, latency, metric):
    '''Check the goodness of a pattern-based packet, captured via buffers

    Packet data word: 0xooobbbcc

    Where:
     o: orbit number at source
     b: bunch number at source
     c: channel id (source)
    '''

    errors = []
    # Scan frames
    for k in xrange(packet[0],packet[1]+1):
        frame =  data.frame(k)

        # And channels within
        for i,ch in enumerate(chans):
            # get the channel entry
            e = frame[i]
            expCh = ch *2
            expBx = metric.addCycles(capStart, k-latency).bx

            chanOK = ( (e.data & 0xff) == expCh )
            bxOK = ( ((e.data >> 8 ) & 0xfff) ) == expBx
            
            if not ( chanOK and bxOK ):
                errors.append( (k,ch, e.data) )
                print 'ERROR: ',k,ch,e, hex(e.data), bxOK, chanOK
    return errors

# ---
def compareBufferData( original, new, rng ):
    '''
    '''

    errors = []

    tools.assert_equal(original.links(),new.links())
    tools.assert_equal(original.size(),new.size())

    for l in original.links():
        lOrig = original[l]
        lNew = new[l]

        for k in xrange(*rng):
            if lOrig[k] == lNew[k]:
                continue

            error = 'Channel %d, frame %d: orig %s, new %s' % (l,k,lOrig[k],lNew[k])
            errors.append(error)

    return errors





# Global default settings for buffer test cases
defaults = {}


def setup_module(module):
    print ("") # this is to get a newline after the dots
    print ("setup_module before anything in "+__name__)

    global defaults
    
    defaults = getSettings()

def teardown_module(module):
    print ("teardown_module after everything in "+__name__)

# ---
class TestAlgoPattern(mp7nose.TestUnit):
    '''
    Test data transmission from rx buffers to tx buffers through null algorithm block.

    '''

    def setup(self):

        print (self.__class__.__name__+".setup() before each test method")

        class config: pass



        # Preparing test
        self.board = self.context().mp7
        
        # Reset board
        infra.Reset.run(self.board, **defaults['reset'])


    def pattern_and_capture(self, cfg):

        # RX buffer in pattern mode
        datapath.XBuffers.run(self.board, 'rx', 'Pattern', cfg.chs, None, (cfg.pattStart,cfg.pattStop))

        # Tx buffers in capture mode
        datapath.XBuffers.run(self.board, 'tx', 'Capture', cfg.chs, None, (cfg.capStart, cfg.capStop))

        # Capture!
        return datapath.Capture.run(self.board, cfg.chs, cfg.chs, cfg.capPath)

    def test_pattern_latency(self):
        '''
        Checks the rx to rx buffers latency.

        A short packer is sent from rx buffers to tx buffers.
        The latency is measured by capturing the packet at tx buffers and 
        comparing the rising edge of data-valid with the time of transmission.

        * Rx buffers configured to produce the hardcoded pattern.
        * TX buffers in capture mode.

        '''
        
        cfg = mp7nose.TestConfig()
        
        cfg.chs = [1,2]
        cfg.pattStart = orb.Point(2)
        cfg.pattStop = orb.Point(5)
        cfg.capStart = orb.Point(1)
        cfg.capStop = None
        cfg.capPath = None
        cfg.nullAlgoLatency = 4

        rx,tx = self.pattern_and_capture(cfg)

        # Analyze capture

        # Break down the daptured data in packets
        packets = data.findAllPackets(tx)

        # When channels are aligned, there is only one train of packets
        tools.assert_equal(len(packets),1,'Expected 1 packet train in capture, found %d' % len(packets))

        # first and only packet, unpack
        pkts, chans =  packets[0]

        # extract the first packet
        firstPkt = pkts[0]

        m = self.board.getMetric()
        
        # Measure the latency based on data valid
        algoLatency = measureDatavalidLatency( firstPkt[0], cfg.capStart, cfg.pattStart, m )
        
        tools.assert_equal(algoLatency, cfg.nullAlgoLatency)

    def test_pattern_packet(self):

        cfg = mp7nose.TestConfig()
        
        cfg.chs = [1,2]
        cfg.pattStart = orb.Point(2)
        cfg.pattStop = orb.Point(5)
        cfg.capStart = orb.Point(1)
        cfg.capStop = None
        cfg.capPath = None
        cfg.nullAlgoLatency = 4

        rx,tx = self.pattern_and_capture(cfg)

        # Break down the daptured data in packets
        packets = data.findAllPackets(tx)

        # When channels are aligned, there is only one train of packets
        tools.assert_equal(len(packets),1,'Expected 1 packet train in capture, found %d' % len(packets))

        # first and only packet, unpack
        pkts, chans =  packets[0]

        tools.assert_equal(chans, cfg.chs)

        # extract the first packet
        firstPkt = pkts[0]

        m = self.board.getMetric()

        errors = checkCapturedPattern(tx, firstPkt, chans, cfg.capStart, cfg.nullAlgoLatency, m)

        tools.assert_equal(len(errors),0, 'Capture errors detected\n'+'\n'.join(errors))


    def test_pattern_full(self):

        cfg = mp7nose.TestConfig()
        
        cfg.chs = [1,2]
        cfg.nullAlgoLatency = 4
        cfg.pattStart = orb.Point(0)
        cfg.pattStop = None
        cfg.capStart = orb.Point(1,cfg.nullAlgoLatency)
        cfg.capStop = None
        cfg.capPath = 'nosecap'

        rx,tx = self.pattern_and_capture(cfg)

        # errors = checkCapturedPattern(tx, firstPkt, chans, cfg.capStart, cfg.nullAlgoLatency, m)

# ---
# 
# 
class TestAlgoPlayback(mp7nose.TestUnit):

    def setup(self):
        print (self.__class__.__name__+".setup() before each test method")

        # Preparing test
        self.board = self.context().mp7
        
        # Reset board
        infra.Reset.run(self.board, **defaults['reset'])


    def test_channel_playback(self):

        class config: pass

        cfg = config()
        
        cfg.chs = [1]
        cfg.nullAlgoLatency = 4
        cfg.playStart = orb.Point(0)
        cfg.playStop = orb.Point(2)
        cfg.playPayload = 'generate://pattern'
        cfg.capStart = orb.Point(0, cfg.nullAlgoLatency)
        cfg.capStop = orb.Point(2, cfg.nullAlgoLatency)
        cfg.capPath = None
        
        m = self.board.getMetric()

        d = m.distance(cfg.playStop, cfg.playStart)

        # RX buffer in pattern mode
        datapath.XBuffers.run(self.board, 'rx', 'PlayOnce', cfg.chs, cfg.playPayload, (cfg.playStart,cfg.playStop))

        # Tx buffers in capture mode
        datapath.XBuffers.run(self.board, 'tx', 'Capture', cfg.chs, None, (cfg.capStart, cfg.capStop))

        # Capture!
        rx,tx = datapath.Capture.run(self.board, cfg.chs, cfg.chs,  cfg.capPath)

        # Compare captures in the relevant range
        errors = compareBufferData(rx,tx, (0,d) )
        tools.assert_equal(len(errors),0)


# ---
#
#
class TestBufferBxCaptures(mp7nose.TestUnit):
    '''
    Captures data from the buffers at different bx ranges
    '''

    def setup(self):
        print (self.__class__.__name__+".setup() before each test method")

        # Preparing test
        self.board = self.context().mp7
        
        # Reset board
        infra.Reset.run(self.board, **defaults['reset'])

    def test_cap_greater_than_pattern(self):
        
        class config(): pass

        cfg = config()
        
        # Use one channel only
        cfg.chs = [3]
        
        # 1 BX long data valid
        cfg.pattStart = orb.Point(1,0)       
        cfg.pattStop = orb.Point(2,0)
        
        # Capture for 3 Bxs, starting at 1
        cfg.capStart = orb.Point(1,0)
        cfg.capStop = orb.Point(4,0)     
        
        # TX in pattern mode
        datapath.XBuffers.run(self.board, 'rx', 'Pattern', cfg.chs, None, (cfg.pattStart,cfg.pattStop))
        # RX in capture mode
        datapath.XBuffers.run(self.board, 'tx', 'Capture', cfg.chs, None, (cfg.capStart, cfg.capStop))
        # Capture
        rx, tx = datapath.Capture.run(self.board, cfg.chs, cfg.chs)


        # Break down the daptured data in packets
        pktTrains = data.findAllPackets(tx)
        tools.assert_equal(len(pktTrains),1,'Expected 1 packet train in capture, found %d' % len(pktTrains))

        pktTrain, chans = pktTrains[0]
        tools.assert_equal(len(pktTrain),1,'Expected 1 packet, found %d - %s' % (len(pktTrain),pktTrain))

        first,last = pktTrain[0]
        pktLen = last-first+1


        # cnt = self.countValidFrames(tx)
        print 'Packet length: ',pktLen

        m = self.board.getMetric()
        
        # Compare measured datavalid with expectations
        # Pattern range is shorter than capture's. The packet length is expected to match the pattern range.
        tools.assert_equal(pktLen, m.distance(cfg.pattStop, cfg.pattStart) )
        
    def test_cap_less_than_pattern(self):
        
        class config(): pass
        
        cfg = config()
        
        # Use one channel only
        cfg.chs = [2]
        cfg.pattStart = orb.Point(1,0)
        cfg.pattStop = orb.Point(4,0)

        # 1 BX long data valid
        cfg.capStart = orb.Point(2,0)
        cfg.capStop = orb.Point(4,0)      
        
        # TX in pattern mode
        datapath.XBuffers.run(self.board, 'rx', 'Pattern', cfg.chs, None, (cfg.pattStart,cfg.pattStop))
        # RX in capture mode
        datapath.XBuffers.run(self.board, 'tx', 'Capture', cfg.chs, None, (cfg.capStart, cfg.capStop))
        # Capture
        rx, tx = datapath.Capture.run(self.board, cfg.chs, cfg.chs)

        # Break down the daptured data in packets
        pktTrains = data.findAllPackets(tx)
        tools.assert_equal(len(pktTrains),1,'Expected 1 packet train in capture, found %d' % len(pktTrains))

        pktTrain, chans = pktTrains[0]
        tools.assert_equal(len(pktTrain),1,'Expected 1 packet, found %d - %s' % (len(pktTrain),pktTrain))

        first,last = pktTrain[0]
        pktLen = last-first+1

        m = self.board.getMetric()

        # Compare measured datavalid with expectations
        # Capture range is shorter than pattern's. The packet length is expected to match the capture range.
        tools.assert_equal(pktLen, m.distance(cfg.capStop, cfg.capStart) )    
        


        
        
        
        
