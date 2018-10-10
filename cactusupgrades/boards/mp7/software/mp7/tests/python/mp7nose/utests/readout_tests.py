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


# -----------------------------------------------------------------------------
def setup_module(module):
    print ("") # this is to get a newline after the dots
    print ("setup_module before anything in this file")
    
    global defaults
    defaults = getSettings()
# -----------------------------------------------------------------------------

# def teardown_module(module):
#     print ("teardown_module after everything in this file")


# -----------------------------------------------------------------------------
class TestReadWriteMenu(mp7nose.TestUnit):
    '''
    Readout menu loading and read back
    '''

    # -------------------------------------------------------------------------
    def setup(self):
        print (self.__class__.__name__+".setup() before each test method")

        # Preparing test
        self.board = self.context().mp7
        
        # Reset board        
        infra.Reset.run(self.board, **defaults['reset'])
    # -------------------------------------------------------------------------


    # -------------------------------------------------------------------------
    def teardown(self):
        print (self.__class__.__name__+".teardown() after each test method")
    # -------------------------------------------------------------------------


    # -------------------------------------------------------------------------
    def test_01_configure(self):

        print ""
        print "Writing Menu" 


        path = "${MP7_TESTS}/python/daq/simple.py"
        menu = "menuA"        

        readout.LoadMenu.run(self.board, path, menu)

        print "Reading Menu"

        ro = self.board.getReadout().getControl()
        rmenu = ro.readMenu()

        variables = {}
        execfile(os.path.expandvars(path), variables)

        wmenu = variables[menu]

        evszs = self.board.computeEventSizes(wmenu)
        for i,s in evszs.iteritems():
            wmenu.mode(i).eventSize = s

        # Find differences between written and read menus
        str1 = str.rstrip(str(wmenu)).split("\n")
        str2 = str.rstrip(str(rmenu)).split("\n")

        for line in difflib.unified_diff(str1, str2):
            print line

        eq = tools.assert_equal(str(wmenu), str(rmenu),
                                        "Menu written : \n"
                                        + str(wmenu) + "\n"
                                        + "Menu read : \n"
                                        + str(rmenu))
    # -------------------------------------------------------------------------
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
class TestMenuPatternExample(mp7nose.TestUnit): 
    '''
    Base class for Event readout tests

    test parameters:

        menu: path, name
        channels setu:
    '''

        
    # -------------------------------------------------------------------------
    def setup(self):

        print (self.__class__.__name__+".setup() before each test method")

        # Preparing test
        self.board = self.context().mp7

        print '-> Reset'
        infra.Reset.run(self.board, **defaults['reset'])

        print '-> Rx in playback'
        # Playback on the same rx channels as configured for 
        datapath.XBuffers.run(self.board, 'rx', 'Pattern', defaults['easylatency']['tx'], None)

        print '-> Tx in EasyLatency'
        readout.EasyLatency.run(self.board, **defaults['easylatency'])
        # print '->Latency buffers cfg'
        # stage1.ConfigS1Demo.run(self.board, **defaults['s1demo'])
        print '->Readout setup'
        readout.Setup.run(self.board, **defaults['setup'])
        # Take menu from child class
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    def test_01_menuA_captureEvents(self):

        print "->Loading Menu"
        readout.LoadMenu.run(self.board, "${MP7_TESTS}/python/daq/simple.py", "menuA")

        print "->Capturing events"

        cfg = defaults["capture"]
        
        ret = readout.CaptureEvents.run(self.board, **cfg)

        tools.assert_not_equal(ret, None, "There's no event in here. Is the FIFO empty? Maybe you didn't set up correctly.")

        # Turn this into an exception
        tools.assert_equal(ret.status, 0, 'Event capture failed. Stopping here')

        # Number of events must match the requested
        tools.assert_equal(len(ret.events), cfg["nevents"], "Number of collected events doesn't match requested")
        



        # Check the payload looks ok
        for i,dec in enumerate(ret.unpacked):
            
            # Take first 3 bytes form orbit number in the payload
            orb = (dec.branches["amc.protocol"].orb & 0xfff)
            bx  = dec.branches["amc.protocol"].bxId
            blocks = dec.branches["mp7.payload"].blocks
            print dec.errors
            tools.assert_equal(len(dec.errors), 0, "Unpacker reported errors: "+"\n".join( [ "%   s: %s" % err for err in dec.errors] ) )

            orb_errs = []
            bx_errs = []
            blk_errs = []
            for block in blocks:
                hdr = block[0]
                length = (hdr >> 16) & 0x00ff #length of data picked from header
                blkId = (hdr >> 24) & 0xff
                block.pop(0) #remove header
                for word in block:
                    frm_orb = (word >> 20)
                    frm_bx = (word >> 8) & 0xfff
                    frm_ch = (word) & 0xff
                    print orb, frm_orb
                    if ( orb != frm_orb):
                        orb_errs.append(
                                        "Orbit counter and packet not aligned:"
                                        + " Channel hdr=" + hex(hdr)
                                        + ", Orbit=" + hex(orb)
                                        + ", Payload orbit=" + hex(frm_orb)
                                        )
                    if ( bx != frm_bx):
                        bx_errs.append("Bx counter and packet not aligned:"
                                        + " Channel hdr=" + hex(hdr)
                                        + ", Bx=" + hex(bx)
                                        + ", Payload bx=" + hex(frm_bx)
                                        )

                    if ( blkId-1 != frm_ch):

                        blk_errs.append("Block id and channel id mismatch:"
                                        + " Channel hdr= " + hex(hdr)
                                        + ", Block Id= " + hex(blkId)
                                        + ", Chan Id= " + hex(frm_ch)
                                        )
            
            tools.assert_equal(len(orb_errs), 0, 'Orbit number mismatches detected\n'+'\n'.join(orb_errs))
            tools.assert_equal(len(bx_errs), 0, 'BX number mismatches detected\n'+'\n'.join(bx_errs))
            tools.assert_equal(len(blk_errs), 0, 'Block ID mismatches detected\n'+'\n'.join(blk_errs))
    # -------------------------------------------------------------------------
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
class UnpackerBase(mp7nose.TestUnit):

    board = None

    menuFile = None
    menuName = None

    config = None
    result = None

    patternchans = [1]

    # -------------------------------------------------------------------------
    @classmethod
    def setup_class(cls):
        '''Configure class for tests. Configure the board and capture.
        Store the event and the configuration locally 
        '''
        # Take a snapshot of this module's config
        
        #config = copy.deepcopy(defaults)
        config = defaults

        print "%s - loading menu '%s' from %s" % (cls.__name__,cls.menuName,cls.menuFile)

        # Preparing test
        cls.board = cls.context().mp7
        
        print 'Resetting board'
        infra.Reset.run(cls.board, **config['reset'])
        print 'Configure Tx to send patterns'
        datapath.XBuffers.run(cls.board, 'rx', 'Zeroes', None, None,(orbit.Point(0),None))
        datapath.XBuffers.run(cls.board, 'tx', 'Zeroes', None, None,(orbit.Point(0),None))
        datapath.XBuffers.run(cls.board, 'rx', 'Pattern', cls.patternchans, None,(orbit.Point(0),None))
        print 'Configuing latency buffers'
        readout.EasyLatency.run(cls.board, **config['easylatency'])
        print 'Setting up readout'
        readout.Setup.run(cls.board, **config['setup'])
        print 'Configuring out menu'
        readout.LoadMenu.run(cls.board, cls.menuFile, cls.menuName)
        # Additionally, set board id
        ctrl = cls.board.getCtrl()
        ctrl.getNode('board_id').write(0x1234)
        ctrl.getClient().dispatch()
        
        result = readout.CaptureEvents.run(cls.board, **config['capture'])

        # Stop if the capture was bugged
        tools.assert_not_equal(result, None, "There's no event in here. Is the FIFO empty? Maybe you didn't set up correctly.")

        # Append result to the class
        cls.result = result
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    @classmethod
    def teardown_class(cls):
        # print ("teardown_class() after any methods in this class")
        cls.board = None

        cls.menuFile = None
        cls.menuName = None

        cls.config = None
        cls.result = None
    # -------------------------------------------------------------------------

    
    # -------------------------------------------------------------------------
    def test_01_has_result(self):
        # Turn this into an exception
        tools.assert_equal(self.result.status, 0, 'Event capture failed. Stopping here')
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    def test_02_number_events(self):
        # Number of events must match the requested
        tools.assert_equal(len(self.result.events), defaults["capture"]["nevents"], "Number of collected events doesn't match requested")
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    def test_03_fw_revisions(self):

        fwRev = self.board.getCtrl().readFwRevision()
        alRev = self.board.getCtrl().readAlgoRevision()

        for ev in self.result.unpacked:
            tools.assert_equal(ev.branches['mp7.payload'].fwRev, fwRev)
            tools.assert_equal(ev.branches['mp7.payload'].algoRev, alRev)
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    def test_04_l1A_ids_match(self):

        for i,ev in enumerate(self.result.unpacked):
            # tools.assert_equal(ev.branches['mp7.payload'].fwRev, fwRev)
            # tools.assert_equal(ev.branches['mp7.payload'].algoRev, alRev)
            tools.assert_equal( ev.branches['amc.protocol'].l1AIdHdr, i+1)
            tools.assert_equal( ev.branches['amc.protocol'].l1AIdHdr, ev.branches['amc.protocol'].l1AIdTrl)
    # -------------------------------------------------------------------------

    # -------------------------------------------------------------------------
    def test_05_blocks(self):

        nexpected = len(defaults['easylatency']['rx'])+len(defaults['easylatency']['tx'])

        for i,ev in enumerate(self.result.unpacked):
            # raise RuntimeError()

            tools.assert_equal(len(ev.branches['mp7.payload'].blocks),nexpected, 'Number of blocks doesn\'t match requested %d vs %d' % (len(ev.branches['mp7.payload'].blocks),nexpected))
            # Check blocks
            # for b in ev.branches['mp7.payload'].blocks:
    # -------------------------------------------------------------------------
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
class TestUnpackerMenuA(UnpackerBase):

    menuFile = "${MP7_TESTS}/python/daq/simple.py"
    menuName = "menuA"

    def test_06_payload(self):

        # Extract the first bx from the configuration
        l1bx = defaults['capture']['bxs'][0]


        for i,ev in enumerate(self.result.unpacked):
            blocks = self.result.unpacked[0].branches['mp7.payload'].blocks
            # Calculate the tx channel to block map
            hdrmap = {((b[0] >> 24)-1)/2:i for i,b in enumerate(blocks)}
            
            for c in self.patternchans:
                block = blocks[hdrmap[c]]

                singlewords = set(block[1:])
                tools.assert_equal(len(singlewords), 1)

                word =  next(iter(singlewords))

                src_cid = (word & 0xff)/2
                src_bx = ((word >> 8) & 0xff)

                tools.assert_equal(src_cid, c)
                tools.assert_equal(src_bx, l1bx)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# class TestUnpackerMenuAprime(UnpackerBase):
#     __test__ = True

#     menuFile = "${MP7_TESTS}/python/daq/simple.py"
#     menuName = "menuAprime"

# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
class TestUnpackerMenuB(UnpackerBase):

    menuFile = "${MP7_TESTS}/python/daq/simple.py"
    menuName = "menuB"
# -----------------------------------------------------------------------------
