#
#
#

import mp7
import logging

#---
def findPackets( buffer ):
    '''
    Searches a data link dumpo for packets identified by data valid high

    Return a tuple of two-ples, python-style range i.e.

    '''
    ranges = []

    v = False
    begin = end = None

    for i,x in enumerate(buffer):
        if not v:
            if x.valid:
                v = True
                begin = i
            continue
        # print v,x
        else:
            if not x.valid:
                v = False
                end = i-1
                # end = i
                ranges.append( (begin,end) )
            continue
    if v and (begin is not None):
        end = len(buffer)-1
        # end = len(buf)
        ranges.append( (begin,end) )
    return tuple(ranges)

#---
def findAllPackets( bData ):

    '''
    Returns a map of packets ranges vs channels.

    Keys: tuple of bx-ranges, ((3,10),(14,23),...)
    Values: List of channels
    '''

    pktMap = {}

    # Loop over links
    for l in bData.links():

        # Calc the package structure for each one
        pkts = findPackets(bData[l])

        # Store the information in the dict
        if pkts in pktMap:
            pktMap[pkts].append(l)
        else:
            pktMap[pkts] = [l]

    return list( pktMap.iteritems() )

#---
def overrideDataValidPattern(bData, replaceChs, masterCh):
    '''
    Returns copy of board data with data valid pattern of several channels updated
    to match the data valid pattern of a master channel. Arguments:
       - bData : Input board data object
       - replaceChs : List of IDs of channels whose data valid bits will be updated
       - masterCh : ID of channel whose data valid pattern will be used.
    '''
    assert( isinstance(bData, mp7.BoardData) )
    assert( isinstance(replaceChs, list) )
    assert( isinstance(masterCh, int) )

    indata = bData

    logging.notice('Master is %d', masterCh)
    master = indata[masterCh]
    valids = [ (f.data>>32) for f in master ]

    fakedata = mp7.LinkData()

    for m in master:
        f = mp7.Frame()
        f.valid = m.valid
        fakedata.append(f)

    # if args.offset == 0:
    #     pass
    # elif args.offset < 0:
    #     fakedata = fakedata[-args.offset:] + [0]*-args.offset
    # elif args.offset > 0:
    #     fakedata = [0]*args.offset + fakedata[:-args.offset]

    # print 'len',len(valids),len(fakedata)

    # for v,f in zip(valids,fakedata):
    #     print v,hex(f)

    # for i,v in enumerate(valids):
    #     print i,v

    outdata = mp7.BoardData(indata.name())

    for l in indata:

        if not l.first in replaceChs:
            outdata.add(l.first, l.second)
            continue

        outdata.add(l.first,fakedata)

    return outdata

