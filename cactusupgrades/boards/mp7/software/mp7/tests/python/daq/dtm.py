# DAQ and Trigger Manager (a.k.a AMC13) support

# Parameters
# 
# OC0 command
# BCN_OFFSET
# FED_ID
# Slots?
# Slinl?

import amc13
import logging
import time
from mp7 import TTCBCommand
import mp7.tools.unpacker as unpacker

class DTManager ( object ) :

    # ---
    def __init__(self, t1, t2, **kwargs):

        self._amc13 = amc13.AMC13(t1, t2)
        self._cfg = kwargs


    # ---
    def reset(self, oC0Cmd = TTCBCommand.kOC0, resyncCmd = TTCBCommand.kResync):
        # Default BCN offset = 0xdec-25
        # Default OC0 cmd = 0x8


        # Add bunch counter offset

        board = self._amc13
        cfg = self._cfg;

        # board.getStatus().Report(1)
        # self.linkStatus('Pre-AMC13 Reset')
    
        board.reset(board.Board.T1);
    
        board.reset(board.Board.T2);
        
        board.endRun();
    
        # Disable DAQ link
        board.daqLinkEnable(0x0);

        # Disabling the sfp is dangerous
        board.sfpOutputEnable(0x0);
    
        board.AMCInputEnable(0x0);
    
        # configure TTC commands
        # Typo in 1.1.6. Fix when 1.1.7 comes out
        # board.setOcrCommand(oC0Cmd);
        board.write(board.Board.T1,'CONF.TTC.OCR_COMMAND',oC0Cmd);
        board.write(board.Board.T1,'CONF.TTC.OCR_MASK',0x0); 

        # Replace with python bindings when they come out...
        board.write(board.Board.T1,'CONF.TTC.RESYNC.COMMAND',resyncCmd); 
        board.write(board.Board.T1,'CONF.TTC.RESYNC.MASK',0x0); 
    
        # Clear the TTS inputs mask
        # Replace it with proper python binding when 1.1.5 comes out
        board.write(board.Board.T1, 'CONF.AMC.TTS_DISABLE_MASK', 0x0);
        
        # enable local TTC signal generation (for loopback fibre)
        board.localTtcSignalEnable( False )

        board.monBufBackPressEnable( False )

        # Disable fake data generator
        board.fakeDataEnable( False );
        # board.configurePrescale(0,1)
        
        # activate TTC output to all AMCs
        board.enableAllTTC();


    def configureTTC(oC0Cmd = TTCBCommand.kOC0, resyncCmd = TTCBCommand.kResync):
        board = self._amc13

        # configure TTC commands
        board.setOcrCommand(oC0Cmd);
        board.write(board.Board.T1,'CONF.TTC.OCR_MASK',0x0); 

        # Replace with python bindings when they come out...
        board.write(board.Board.T1,'CONF.TTC.RESYNC.COMMAND',resyncCmd); 
        board.write(board.Board.T1,'CONF.TTC.RESYNC.MASK',0x0); 
    
        board.enableAllTTC();


    # ---
    def configure(self, slots, fedId, slink, localTtc=False, fakeData=False, bcnOffset = (0xdec-24) ):

        # logging.warning('Local TTC %s', localTtc)

        board = self._amc13

        bitmask = 0
        for s in slots:
            bitmask |= (1 << (s - 1));

        # self.linkStatus('Before enabling AMC13 inputs')
    
        board.AMCInputEnable(bitmask);

        #----------------------------------
        # KH: amc13->configureLocalDAQ(mp7_slots)
        #----------------------------------
        # set FED ID and S-link ID
        # Stage1 FED
        # FED_ID = 1352    
    
        board.setFEDid(fedId); # notes this sets the CONF.ID.SOURCE_ID register
    
        # board.write(board.Board.T1, 'CONF.ID.FED_ID', fedId);
            
        # Replace it with proper python binding when 1.1.5 comes out
        board.write(board.Board.T1,'CONF.BCN_OFFSET',bcnOffset); # No idea whre -1 comes from...

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
        board.daqLinkEnable(slink);
    
        # SFP 1 connected
        board.sfpOutputEnable(1 if slink else 0);
        
        # self.linkStatus('Before DAQ reset')
    
        # board.resetDAQ();
        
        board.resetCounters();
        
        # self.linkStatus('Before T1 Reset')

        # reset the T1
        board.reset(board.Board.T1)
    
        # self.linkStatus('AMC13 config completed')
        if localTtc:
            board.localTtcSignalEnable(True);
            # Already done in localTtcSignalEnable
            # board.write(board.Board.T1, 'CONF.DIAG.FAKE_TTC_ENABLE', 0x1);
        
        if fakeData:
            board.fakeDataEnable( True );

    # ---
    def start(self):
        board = self._amc13

        board.startRun()

    # ---
    def stop(self):
        board.stopRun()

    # ---
    def spy(self):
        '''aaaa'''
        board = self._amc13

        while True:
            try:
                self.status()
                try:
                    ev = board.readEvent()
                    # for i,w in enumerate(e):
                    #     logging.warning( '%04d : 0x%016x', i, w)
                except Exception, e:
                    logging.warning('ERROR while reading events from AMC13.')
                    ev = []

                if ev:
                    self.decode(ev)
                else:
                    logging.info('Empty amc13 event')

                        
                time.sleep(0.5)
            except KeyboardInterrupt:
                print 'Hasta la vista, Gringo!'
                break

    # ---
    def status(self):
        board = self._amc13




    # ---
    def decode( self, event, fake=False ):
    
        # print 'Event size: ', len(event)
        # AMC13 data format parameters
        amc13HdrLen = 3;
        amc13TrlLen = 2;
        mp7HdrLen = 2;
        mp7TrlLen = 1;
        # mp7EventSize64bit = 131; # not sure for actual DAQ bus

        for i,w in enumerate(event):
            logging.debug('%04d : %016x', i, w)

        amc13ev = unpacker.unpackAMC13Event(event)

        # amcblock = event[amc13HdrLen:len(event)-amc13TrlLen]
        # print amc13ev.amcBlocks.keys()
        for i in sorted(amc13ev.amcBlocks):
            amcblock = amc13ev.amcBlocks[i]
            mp7ev = unpacker.Event(i)
            mp7ev = unpacker.unpackAMCProtocol(amcblock, mp7ev)

            if len(amcblock) != mp7ev['amc.protocol'].lengthCounter:
                logging.error('Trailer event size error : expected %d, block length %d',mp7ev.lengthCounter, len(amcblock))

            if mp7ev['amc.protocol'].l1AIdHdr != amc13ev.l1A:
                logging.error('AMC13 - MP7 event id mismatch : amc13 %d, mp7 %d',amc13ev.l1A, mp7ev['amc.protocol'].l1AIdHdr)

            # payload = event[amc13HdrLen+mp7HdrLen:len(event)-mp7TrlLen-amc13TrlLen]
            payload = amcblock[mp7HdrLen:-mp7TrlLen]


            if fake:
                unpacker.unpackFakePayload(payload, mp7ev)
            else:
                unpacker.unpackPayload(payload, mp7ev)
