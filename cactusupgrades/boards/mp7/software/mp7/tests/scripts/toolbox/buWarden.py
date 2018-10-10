#!/bin/env python

import argparse
import xdaqclient

desc = '''
Hacky script to enable/disable Builder Unit 
'''
parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter,description=desc)
parser.add_argument('mode', choices=['save','drop']) 
args = parser.parse_args()

# Trigger MiniDAQ host
host = 'bu-c2f13-39-01.cms'
port = 39100
lid = 51
infosp = 'urn:xdaq-application:evb::BU'
param = 'dropEventData'

url = 'http://%s:%d' % (host,port)
urn = 'urn:xdaq-application:lid=%d' % (lid,)

# XDAQ client
bu = xdaqclient.XDAQ(url, urn)

oldPar = bu.parameterGet(params={param:xdaqclient.Bool()},infospace=infosp)
bu.parameterSet(params={param:xdaqclient.Bool(args.mode == 'drop')},infospace=infosp)
newPar = bu.parameterGet(params={param:xdaqclient.Bool()},infospace=infosp)

# print 'BU parameter',param,'is set to',newPar[param],'(was',oldPar[param],')'
print "BU parameter '%s' now set to '%s' (was '%s')" % (param, newPar[param], oldPar[param])
