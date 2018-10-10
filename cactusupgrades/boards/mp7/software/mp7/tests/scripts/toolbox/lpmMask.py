#!/bin/env python

import argparse
import os
import uhal


if 'XDAQ_ROOT' not in os.environ:
    os.environ['XDAQ_ROOT'] = '/opt/xdaq'

desc = '''
Hacky script to apply a bunch mask range to the LPM
'''
parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter,description=desc)
parser.add_argument('startBx', type=int) 
parser.add_argument('endBx', type=int) 

args = parser.parse_args()




if ( args.startBx < 1 or args.startBx > 3564 ):
    parser.error('startBx out of allowed bx range 1-3564: %d' % args.startBx)

if ( args.endBx < 1 or args.endBx > 3564 ) :
    parser.error('stopBx out of allowed bx range 1-3564: %d' % args.stopBx)

if args.startBx > args.endBx:
    parser.error('startBx %d > endBx %d', args.startBx, args.stopBx)

print 'Building lpm interface'

uhal.setLogLevelTo(uhal.LogLevel.ERROR)
cm = uhal.ConnectionManager('file:///opt/xdaq/share/tcdsp5/etc/tcds_connections.xml')

lpm = cm.getDevice('lpm-trig')

print 'Enabling triggers in range %d-%d' % (args.startBx, args.endBx)
for bx in xrange(1,0xdec+1):
    reg = 'ipm.bunch_mask.bx%d' % bx
    mask = 2 if ( bx < args.startBx or bx > args.endBx ) else 0
    lpm.getNode( reg ).write( mask )
lpm.dispatch()

lpm.getNode('ipm.main.inselect.bunch_mask_veto_enable').write(0x1)

lpm.dispatch()
