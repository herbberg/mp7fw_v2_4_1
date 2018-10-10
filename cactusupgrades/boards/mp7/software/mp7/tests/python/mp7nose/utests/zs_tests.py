# Core module
import mp7nose

# Settings
from mp7nose.settings.readout import getSettings

# MP7 commands
import mp7.cmds.infra as infra
import mp7.cmds.readout as readout
import mp7.cmds.datapath as datapath
import mp7.orbit as orbit
import daq.stage1 as stage1

# Asserts from nose
from nose import tools

import os.path

# Additional tools
import difflib
import copy

defaults = {}


def setup_module(module):
    print ("") # this is to get a newline after the dots
    print ("setup_module before anything in this file")
    
    global defaults
    defaults = getSettings()


class UnpackerBase(mp7nose.TestUnit):

    board = None

    roMenuFile = None
    roMenuName = None

    zsMenuFile = None
    zsMenuName = None

    nBlocksExpected = None

    config = None
    result = None

    @classmethod
    def setup_class(cls):
        '''Configure class for tests. Configure the board and capture.
        Store the event and the configuration locally 
        '''
        # Take a snapshot of this module's config
        
        #config = copy.deepcopy(defaults)
        config = defaults

        print "%s - loading menu '%s' from %s" % (cls.__name__,cls.roMenuName,cls.roMenuFile)

        # Preparing test
        cls.board = cls.context().mp7
        
        print 'Resetting board'
        infra.Reset.run(cls.board, **config['reset'])
        print 'Configure Rx to send patterns'
        datapath.XBuffers.run(cls.board, 'rx', 'Pattern', [0,1,2,3], None,(orbit.Point(0),None))
        print 'Configuing latency buffers'
        readout.EasyLatency.run(cls.board, **config['easylatency'])
        print 'Setting up readout'
        readout.Setup.run(cls.board, **config['setup'])
        print 'Configuring readout menu'
        readout.LoadMenu.run(cls.board, cls.roMenuFile, cls.roMenuName)
        print 'Configuring zerosuppression menu'
        readout.LoadZSMenu.run(cls.board, cls.zsMenuFile, cls.zsMenuName)

        # Additionally, set board id
        ctrl = cls.board.getCtrl()
        ctrl.getNode('board_id').write(0x1234)
        ctrl.getClient().dispatch()
        
        result = readout.CaptureEvents.run(cls.board, **config['capture'])

        # Stop if the capture was bugged
        tools.assert_not_equal(result, None, "There's no event in here. Is the FIFO empty? Maybe you didn't set up correctly.")

        # Append result to the class
        cls.result = result

    @classmethod
    def teardown_class(cls):
        # print ("teardown_class() after any methods in this class")
        cls.board = None

        cls.roMenuFile = None
        cls.roMenuName = None

        cls.zsMenuFile = None
        cls.zsMenuName = None

        cls.config = None
        cls.result = None


    def test_01_has_result(self):
        # Turn this into an exception
        tools.assert_equal(self.result.status, 0, 'Event capture failed. Stopping here')

    def test_02_number_events(self):
        # Number of events must match the requested
        tools.assert_equal(len(self.result.events), defaults["capture"]["nevents"], "Number of collected events doesn't match requested")

    def test_03_fw_revisions(self):

        fwRev = self.board.getCtrl().readFwRevision()
        alRev = self.board.getCtrl().readAlgoRevision()

        for ev in self.result.unpacked:
            tools.assert_equal(ev.branches['mp7.payload'].fwRev, fwRev)
            tools.assert_equal(ev.branches['mp7.payload'].algoRev, alRev)

    def test_04_l1A_ids_match(self):

        for i,ev in enumerate(self.result.unpacked):
            # tools.assert_equal(ev.branches['mp7.payload'].fwRev, fwRev)
            # tools.assert_equal(ev.branches['mp7.payload'].algoRev, alRev)
            tools.assert_equal( ev.branches['amc.protocol'].l1AIdHdr, i+1)
            tools.assert_equal( ev.branches['amc.protocol'].l1AIdHdr, ev.branches['amc.protocol'].l1AIdTrl)

    def test_05_blocks(self):

        # nexpected = len(defaults['easylatency']['rx'])+len(defaults['easylatency']['tx'])
        nexpected = self.nBlocksExpected
        for i,ev in enumerate(self.result.unpacked):
            # raise RuntimeError()
            # 
            print ev

            tools.assert_equal(len(ev.branches['mp7.payload'].blocks),nexpected, 'Number of blocks doesn\'t match requested %d vs %d' % (len(ev.branches['mp7.payload'].blocks),nexpected))
            # Check blocks
            # for b in ev.branches['mp7.payload'].blocks:
            
class TestUnpackerZSMenuA(UnpackerBase):

    roMenuFile = '${MP7_TESTS}/python/daq/simple.py'
    roMenuName = 'menuA'

    zsMenuFile = '${MP7_TESTS}/python/daq/simple.py'
    zsMenuName = 'zsMenuA'

    nBlocksExpected = 3

class TestUnpackerZSMenuA1(UnpackerBase):

    roMenuFile = '${MP7_TESTS}/python/daq/simple.py'
    roMenuName = 'menuA'

    zsMenuFile = '${MP7_TESTS}/python/daq/simple.py'
    zsMenuName = 'zsMenuA1'

    nBlocksExpected = 2
