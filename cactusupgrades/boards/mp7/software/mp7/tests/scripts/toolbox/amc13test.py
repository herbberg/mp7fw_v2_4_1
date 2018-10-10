#!/usr/bin/python
import logging
import time
import readline
import sys
import re

from mp7.tools.log_config import initLogging
# from p5.tcds import TCDSController
import mp7.cmds.infra as infra
import mp7.cmds.datapath as datapath
import mp7.cmds.readout as readout
import mp7.tools.helpers as helpers
import p5.tcds
# TCDS Interface


import uhal
import amc13
import mp7

import daq.stage1 as stage1

class DAQSimpleTester(object):
	def __init__(self, a13, mp7daq):
		self._amc13 = a13
		self._mp7 = mp7daq
		self._fakesize = 100

	def resetEverything( self ):

		a13 = self._amc13
		mp7daq = self._mp7
	
		# a13.getStatus().Report(1)
		# self.linkStatus('Pre-AMC13 Reset')
		#----------------------------------
		# KH: amc13->initialize();
		#----------------------------------
	
		a13.reset(a13.Board.T1);
	
		a13.reset(a13.Board.T2);
		
		a13.endRun();
	
		a13.sfpOutputEnable(0);
	
		a13.AMCInputEnable(0);
	
		# configure TTC commands
		a13.setOcrCommand(0x8);
	
		# a13.write(a13.Board.T1,'CONF.BCN_OFFSET',0xfff-23+1);
		a13.write(a13.Board.T1,'CONF.BCN_OFFSET',0xdec-24-1); # No idea whre -1 comes from...
	
		# Clear the TTS inputs mask
		a13.write(a13.Board.T1, 'CONF.AMC.TTS_DISABLE_MASK', 0x0);
		
		# enable local TTC signal generation (for loopback fibre)
		a13.localTtcSignalEnable(True)
		
		# activate TTC output to all AMCs
		a13.enableAllTTC();

		mp7daq.reset('external','external','external')
		# mp7daq.reset('internal','internal','internal')

		ro = mp7daq.getReadout()
		ro.getNode("csr.ctrl.amc13_link_rst").write(0x1);
  		ro.getClient().dispatch();
		ro.getNode("csr.ctrl.amc13_link_rst").write(0x0);
		ro.getClient().dispatch();

		mp7daq.getTTC().maskHistoryBC0L1a(True)

	def configMP7DAQ(self, fake = False, inject=None):

		mp7daq = self._mp7

		setup = readout.Setup()
		setup(mp7daq, fake, self._fakesize, internal=False, drain=None, bxoffset=1)

		if fake:
			return
		mgts = datapath.MGTs()
		mgts(mp7daq, orbittag=False, loopback=True, invpol=False, alignTo=None, alignMargin=3, config=True, align=True, check=True, forcepattern=None, threeg=False, dmx_delays=False)

		# Configure the buffers in stage1 demo mode
		s1demo = stage1.ConfigS1Demo()
		# add = 12 = 2bx * 6 to take into accout validation events
		s1demo(mp7daq, 'loop', 'full', 'events', 12, inject)
		# s1demo(mp7daq, 'algo', 'full', 'counts', 12)

		# Load the menu
		romenu = readout.LoadMenu()
		romenu(mp7daq, '${MP7_TESTS}/python/daq/stage2.py','menuDemux')

		# Send an internal resync because the AMC13 doesn't do it
		mp7daq.getTTC().forceBCmd(mp7.TTCBCommand.kResync)

	def configAMC13( self, toDAQ = False):
	
		logging.info('AMC13 DAQLink = %s', toDAQ)

		a13 = self._amc13
		slot = self._mp7.slot

		bitmask = (1 << (slot - 1));

		#self.linkStatus('Before enabling AMC13 inputs')
	
		a13.AMCInputEnable(bitmask);

		#----------------------------------
		# KH: amc13->configureLocalDAQ(mp7_slots)
		#----------------------------------
		# set FED ID and S-link ID
		# Stage1 FED
		# FED_ID = 1352    
	
		a13.setFEDid(1352); # notes this sets the CONF.ID.SOURCE_ID register
	
		# a13.write(a13.Board.T1, 'CONF.ID.FED_ID', FED_ID);
		
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
		a13.daqLinkEnable(toDAQ);
	
		# SFP 1 connected
		a13.sfpOutputEnable(1 if toDAQ else 0);
		
		#self.linkStatus('Before DAQ reset')
	
		# a13.resetDAQ();
		
		a13.resetCounters();
		
		#self.linkStatus('Before T1 Reset')

		# reset the T1
		a13.reset(a13.Board.T1)
	
		#self.linkStatus('AMC13 config completed')

	def configureL1AGeneration(self):
		pass

	def start(self):
        # must be in run mode to download data from AMC13'
		a13.startRun()

		a13.sendLocalEvnOrnReset(True, True)

if __name__=='__main__' :

	initLogging(logging.INFO)
	mp7.setLogThreshold(mp7.kInfo)
	uhal.setLogLevelTo(uhal.LogLevel.ERROR)

	# p5.tcds._log.setLevel(logging.INFO)

	# tcds = 'tcds-control-trig.cms:2110'

	# tcdstoken = tcds.split(':')
	# print tcdstoken
	# if len(tcdstoken) != 2 or not tcdstoken[1].isdigit():
	# 	logging.critical('Badly formatted tcds applcation address')
	# 	sys.exit(0)

	# tcdsHost,tcdsPort = tcdstoken[0],int(tcdstoken[1])
	# logging.info('TCDS host: %s:%d',tcdsHost, tcdsPort)

	# # Build TCDS controllers
	# pi = p5.tcds.TCDSController( tcdsHost,tcdsPort, 505 );
	# iCi = p5.tcds.TCDSController( tcdsHost,tcdsPort, 305 );
	connections = '${MP7_TESTS}/etc/mp7/connections-DAQ.xml'
	# sanitise the connection string
	conns = connections.split(';')
	for i,c in enumerate(conns):
		if re.match('^\w+://.*', c) is None:
			conns[i] = 'file://'+c

	# Build the AMC13
	cm = uhal.ConnectionManager(';'.join(conns))
	a13 = amc13.AMC13(cm.getDevice('T1'), cm.getDevice('T2'))
	logging.notice('AMC13 Version: %s',a13.GetVersion())

	mp7daq = mp7.MP7Controller(cm.getDevice('XE_AC'))
	mp7daq.identify()
	mp7daq.slot = 9

	a = DAQSimpleTester(a13,mp7daq)
	a.resetEverything()
	a.configMP7DAQ()
	a.configAMC13()
	a.start()
