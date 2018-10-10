import logging

class ns: pass

class AMCEvent(object):
    """docstring for UnpackedEvent"""
    def __init__(self, id):
        self.id = id
        self.branches = {}

    @property
    def errors(self):
        errs = []
        for k in sorted(self.branches):
            errs += [ (k,e) for e in self.branches[k].errors ]
        return errs

    def __getitem__(self,key):
        return self.branches[key]

    def __str__(self):
        s = 'AMCEvent id: %d\n' % self.id
        s += 'Branches: '+', '.join(self.branches.keys())+'\n'

        amcp = self.branches.get('amc.protocol', None)
        if amcp is not None:
            # Do something here?
            pass

        mp7p = self.branches.get('mp7.payload', None)
        if mp7p is not None:
            # print vars(mp7p)
            chans = []
            s +=  'MP7 Blocks: %d\n' % len(mp7p.blocks)

            for b in mp7p.blocks:
                hdr = b[0]
                bid = (hdr & 0xff000000) >> 24
                bsz = (hdr & 0x00ff0000) >> 16
                print 'hdr 0x%08x id %d, size %d' % (hdr, bid, bsz)
                print 
                for w in b[1:]:
                    print hex(w)

                print
                chans.append( (bid, bsz) )

            s += 'Available blocks (id, size): '+', '.join([str(c) for c in chans])
        return s
    

class Branch(object):
    """
    Empty class to collect umpacking results
    Called Branch because of lack of imagination"""
    def __init__(self):
        self.errors = []

# Helper functions
#---
def unpackROBEvent( rawEvent, event, fake=False ):
    mp7HdrLen = 2;
    mp7TrlLen = 1;

    logging.info('AMCEvent length %d', len(rawEvent))

    # Unpack MP7/AMC protcol layer
    unpackAMCProtocol(rawEvent, event)

    # payload = rawEvent[mp7HdrLen:len(rawEvent)-mp7TrlLen]
    payload = rawEvent[mp7HdrLen:-mp7TrlLen]

    logging.info('Payload length (64b words): %d', len(payload))

    if fake:
        unpackFakePayload(payload, event)
    else:
        unpackPayload(payload, event)

    return event


#---
def unpackAMCProtocol( rawAMCBlock, event ):
    branch = Branch()
    event.branches['amc.protocol'] = branch

    # branch.payload = [] #empty payload, can be filled later
    
    #---
    # Decode MP7 Header first
    #---
    #
    # First word: AMC protocl header 0
    branch.hdr0 = rawAMCBlock[0]
    branch.eventSize = branch.hdr0 & 0xfffff

    branch.bxId = (branch.hdr0 >> 20) & 0xfff;
    branch.l1AIdHdr = (branch.hdr0 >> 32) & 0xffffff;
    branch.amcNum = ((branch.hdr0 >> 56) & 0xf );


    logging.debug( "mp7   hdr0 | 0x%016x" % (branch.hdr0,) )
    logging.info( "mp7   hdr0 | bx: 0x%03x l1a: 0x%06x amcNum: 0x%01x size:0x%05x" % (branch.bxId, branch.l1AIdHdr, branch.amcNum, branch.eventSize) )

    # Some bits are reserved
    branch.hdrReserved = (branch.hdr0 >> 60) & 0xf

    # Second word: AMC protocl header 1
    branch.hdr1 = rawAMCBlock[1]

    branch.boardId = branch.hdr1 & 0xffff
    branch.orb = (branch.hdr1 >> 16) & 0xffff;
    branch.eventType = ( branch.hdr1 >> 32 ) & 0xff;

    logging.debug( "mp7   hdr1 | 0x%016x" % (branch.hdr1,) )
    logging.info( "mp7   hdr1 | boardId: 0x%04x orb: 0x%04x ev type: 0x%02x" % (branch.boardId, branch.orb, branch.eventType) )

    # Then move to the MP7 trailer
    branch.trl0 = rawAMCBlock[-1]
    branch.lengthCounter = branch.trl0 & 0xffffff;
    branch.crc = branch.trl0 >> 32;
    branch.l1AIdTrl = (branch.trl0 >> 24) & 0xff;
    logging.debug( "mp7   trl0 | 0x%016x" % (branch.trl0,) )
    logging.info( "mp7   trl0 | len: 0x%06x l1a: 0x%06x crc: 0x%08x" % (branch.lengthCounter, branch.l1AIdTrl,branch.crc) )


    # import pdb
    # pdb.set_trace()
    # Store result in the corresponding object
    if branch.eventSize != branch.lengthCounter:
        # returnEvent['ExitStatus'] = False
        # returnEvent['ExitMsg'] += 'Eventsize - LengthCounter mismatch \n' 
        branch.errors.append('Eventsize - LengthCounter mismatch')
        logging.error('Eventsize - LengthCounter mismatch')

    return event


#---
def unpackFakePayload( rawFakeBlock, event ):

    branch = Branch()
    event.branch['mp7.fake'] = branch

    amcHdrLen = 2;

    error = 0
    for i,word in enumerate(rawFakeBlock):
        ctr = i+amcHdrLen
        expected = (branch.boardId << 48) + ((ctr*2+1) << 32) + (branch.boardId << 16) + (ctr*2)

        # special case, header
        if i == 0:
            expected &= (0xffffffff << 32)

        # special case, trailer?
        # 


        logging.debug('%04d | 0x%016x 0x%016x', i, word, expected)
        if word != expected:
            # returnEvent['ExitStatus'] = False
            # returnEvent['ExitMsg'] +=  "Payload not as expected \n"
            branch.errors.append('Word %d: expected = 0x%016x found = 0x%016x', i,expected, word)
            logging.error('Payload error: expected = 0x%016x found = 0x%016x', expected, word)
            error+=1

    # Add branch to results

    log = logging.notice if error == 0 else logging.error
    log('Fake Payload errors %d', error)  
            
    logging.info('-'*80)

    return event


#---
def countBits( word ):
    b = 0
    for i in xrange(8):
        b += (word & 0x1)
        word = (word >> 1)

    return b


#---
def unpackPayload( rawPayloadBlock, event ):

    branch = Branch()
    branch.blocks = []
    event.branches['mp7.payload'] = branch

    # Padding word
    paddingword = 0xffffffff

    hdrCnt = 0
    pldCnt = 0
    pldWrd = 0
    p = []
    for x in rawPayloadBlock:
        p.append( x & 0xffffffff )
        p.append( ( x >> 32 ) & 0xffffffff )

    nw = len(p)
    iw = 0
    # First header word
    logging.info('%04x : %08x | mp7 hdrA', iw, p[iw])
    branch.fwRev = p[iw]

    iw += 1
    logging.info('%04x : %08x | mp7 hdrB', iw, p[iw])
    branch.algoRev = p[iw]

    iw += 1
    while iw < nw :
        block = []
        w = p[iw]

        if w == paddingword:
            logging.debug('%04x : %08x | mp7 padding', iw, p[iw])
            iw += 1
            continue

        # expect a header first
        chid = (w >> 24)
        chsz = (w >> 16) & 0xff
        wmsk = (w >> 8 ) & 0xff

        # Crap masking on
        # chwd = (chsz/6)*(6-countBits(wmsk))
        # Full readout mode
        chwd = chsz

        logging.debug('%04x : %08x | hdr, id=%02d sz=%02d', iw, w, chid, chwd)
        block.append(w)

        iw += 1
        hdrCnt += 1

        if chsz == 0:
            continue
        pldCnt += 1
        isz = 0
        while (isz < chwd): # Look away, please

            if iw == nw:
                # returnEvent['ExitStatus'] = False
                # returnEvent['ExitMsg'] += 'Block truncated \n'
                branch.errors.append('End of payload found while readin block')
                logging.error('Block truncated')
                break
                
            w = p[iw]
            logging.debug('%04x : %08x | dat', iw, w)
            block.append(w)
            
            iw += 1
            isz += 1
            pldWrd += 1

        branch.blocks.append(block)  

    logging.info('Headers %d, payloads %d, payload words (32b) %d', hdrCnt, pldCnt, pldWrd )

#---
def unpackAMC13Event( rawAMC13Block ):

    iw = 0
    nw = len(rawAMC13Block)

    amc13ev = ns()
    amc13ev.amcBlocks = {}
    amc13ev.amcHdrs = {}

    amc13ev.cdfhdr = rawAMC13Block[iw]
    iw += 1

    # check that amc13ev.cdfhdr[63] is 
    assert( (amc13ev.cdfhdr >> 60) == 0x5 )
    amc13ev.event_type = amc13ev.cdfhdr >> 56
    amc13ev.l1A = (amc13ev.cdfhdr >> 32) & 0xffffff
    amc13ev.bxId = (amc13ev.cdfhdr >> 20 ) & 0xfff
    amc13ev.srcId = (amc13ev.cdfhdr >> 8 ) & 0xfff

    logging.debug( 'amc13 cdfhdr | 0x%16x' % (amc13ev.cdfhdr,) )
    logging.info( 'amc13 cdfhdr | bx: 0x%03x l1a: 0x%06x evType: %01x srcId: 0x%03x' % (amc13ev.bxId, amc13ev.l1A, amc13ev.event_type, amc13ev.srcId) )

    amc13ev.hdr = rawAMC13Block[iw]
    iw += 1

    amc13ev.orb = (amc13ev.hdr>>4) & 0xffffffff
    amc13ev.nAmcs = (amc13ev.hdr>>52) & 0xf
    logging.debug( 'amc13 hdr    | 0x%016x', amc13ev.hdr )
    logging.info( 'amc13 hdr    | namcs: 0x%01x orb: 0x%06x', amc13ev.nAmcs, amc13ev.orb )

    iBlockStart = iw+amc13ev.nAmcs

    # loop over the headers
    for ih in xrange(amc13ev.nAmcs):

        w = rawAMC13Block[iw+ih]
        amchdr = w
        amcId = ( amchdr ) & 0xffff 
        amcNo = ( amchdr >> 16 ) & 0xf
        amcBlkNo = ( amchdr >> 20 ) & 0xff
        amcSize = ( amchdr >> 32 ) & 0xffffff
        flags = ( amchdr >> 56 ) & 0x7f 

        if amcNo in amc13ev.amcBlocks:
            raise RuntimeError('Duplicated amc no %d' % amcNo)
        
        logging.debug( 'amc hdr      | 0x%16x' % (amchdr,) )
        logging.info( 'amc hdr      | id: 0x%04x no: 0x%01x blkno: 0x%02x size: 0x%06x flags: 0x%02x' % (amcId,amcNo, amcBlkNo, amcSize, flags) )

        amc13ev.amcHdrs[amcNo] = amchdr

        iLast = iBlockStart+amcSize
        # print iBlockStart, iLast
        amc13ev.amcBlocks[amcNo] = rawAMC13Block[ iBlockStart : iLast ]

        iBlockStart = iLast

        # return

    iw = iLast

    amc13ev.trl = rawAMC13Block[iw]
    iw += 1
    amc13ev.trlBx = (amc13ev.trl >> 0) & 0xfff
    amc13ev.trlL1a = (amc13ev.trl >> 12) & 0xff
    amc13ev.trlBlkNo = (amc13ev.trl >> 20) & 0xff
    amc13ev.crc = (amc13ev.trl >> 32) & 0xffffffff
    logging.debug( 'amc13 trl    | 0x%16x', amc13ev.trl )
    logging.info( 'amc13 trl    | bx: 0x%03x l1a: 0x%02x blkno: 0x%02x, crc: 0x%08x', amc13ev.trlBx, amc13ev.trlL1a, amc13ev.trlBlkNo, amc13ev.crc )




    amc13ev.cdftrl = rawAMC13Block[iw]
    iw += 1
    assert( (amc13ev.cdftrl >> 60) == 0xa )

    amc13ev.cdfCrc = (amc13ev.cdftrl >> 16) & 0xffff
    amc13ev.tts = (amc13ev.cdftrl >> 4) & 0xf
    logging.debug( 'amc13 cdftrl | 0x%16x', amc13ev.cdftrl )
    logging.info( 'amc13 cdftrl | crc: 0x%06x tts: 0x%01x', amc13ev.crc,amc13ev.tts )

    return amc13ev
