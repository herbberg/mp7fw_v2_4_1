#!/bin/env python
import uhal
import logging
import re
import argparse
from daq.dtm import DTManager

uhal.setLogLevelTo(uhal.LogLevel.WARNING)
from mp7.tools.log_config import initLogging
initLogging( logging.DEBUG)
desc = '''
Hacky script to spy onto an AMC13 connected to MP7s
'''
parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter,description=desc)
parser.add_argument('connections') 

args = parser.parse_args()


# Sanitise the connection string
conns = args.connections.split(';')
for i,c in enumerate(conns):
    if re.match('^\w+://.*', c) is None:
        conns[i] = 'file://'+c


print 'Using file',conns
cm = uhal.ConnectionManager(';'.join(conns))

amc13T1 = cm.getDevice('T1')
amc13T2 = cm.getDevice('T2')

amc13 = DTManager(amc13T1, amc13T2)

amc13.spy()