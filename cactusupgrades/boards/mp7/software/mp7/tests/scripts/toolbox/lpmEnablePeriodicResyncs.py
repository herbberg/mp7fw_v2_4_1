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
parser.add_argument('enable', choices=['yes','no']) 

args = parser.parse_args()

uhal.setLogLevelTo(uhal.LogLevel.WARNING)
cm = uhal.ConnectionManager('file:///opt/xdaq/share/tcdsp5/etc/tcds_connections.xml')

lpm = cm.getDevice('lpm-trig')

# Generator 4: Periodic resyncs
generatorId = 4

lpm.getNode('ipm.cyclic_generator%d.configuration.enabled' % generatorId).write(args.enable == 'yes')
lpm.dispatch()