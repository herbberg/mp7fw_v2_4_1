#!/bin/env python

import mp7
import uhal

import mp7.cmds.infra as infra
import mp7.cmds.readout as readout
import mp7.cmds.datapath as datapath

import mp7.orbit as orbit

# Settings
from mp7nose.settings.readout import getSettings

# Development area
# 
# 

# class ZeroSuppressionMenu(object):
#     """ZeroSuppressionMenu

#     Contains a capture-to-mask map

#     Constraints: 
#         len(mask) == 6
#         capture id < 16 (12)
#     """
#     def __init__(self, ncaps):
#         super(ZeroSuppressionMenu, self).__init__()
#         self._ncaps = ncaps
#         self._masks = {}

#     def captureIds(self):
#         return self._masks.keys()

#     def setMask(self, id, mask):

#         if len(mask) != 6: 
#             raise RuntimeError('Forbidden mask size: found %d expected 6' % len(mask))

#         if id < 0 or id > self._ncaps-1:
#             raise RuntimeError('Capture id=%d outside valid range (0,%d)' % (id,self._ncaps-1) )

#         self._masks[id] = mask

#     def getMask(self, id):
#         try:
#             return self._masks[id]
#         except:
#             raise RuntimeError('Mask for capture mode %d not found' % id)

#     def removeMask(self, id):
#         try:
#             del self._masks[id]
#         except KeyError as e:
#             raise RuntimeError('Mask for capture mode %d not found' % id)


# def testZsMenu():

#     x = ZeroSuppressionMenu(12)

#     x.setMask(1,[0xff]*6)
#     print x.captureIds()
#     print x.getMask(1)

#     import daq.simple
#     import daq.stage1

#     menu = daq.stage1.menu
#     # menu = daq.simple.menuA
#     print menu

#     # bankCapIdMap = {}

#     yM = {}

#     for m in xrange(menu.numModes()):
#         # add an entry for this capture mode
#         yC = {}

#         for c in xrange(menu.numCaptures()):
#             # print m,c
#             cap = menu.capture(m,c)
#             # Ignore disabled cap ids
#             if not cap.enable:
#                 continue
#             # if cap.bankId not in bankCapIdMap:
#                 # bankCapIdMap[cap.bankId] = set()
#             # bankCapIdMap[cap.bankId].add(cap.id)

#             print cap.id, menu.bank(cap.bankId).wordsPerBx
#             if cap.id not in yC:
#                 yC[cap.id] = set()

#             yC[cap.id].add(cap.bankId)

#         yM[m] = yC

#     # print bankCapIdMap

#     # banks = bankCapIdMap.keys()
#     # for i in xrange(len(banks)):
#         # for j in xrange(i+1, len(banks)):
#             # print i,j,bankCapIdMap[banks[i]].intersection(bankCapIdMap[banks[j]])

#     # print [ menu.capture(m,0).id for m in xrange(menu.numModes()) ]
#     print yM


#     import sys
#     sys.exit(0)
        

# Test script
# 
# 
# 
uhal.setLogLevelTo(uhal.LogLevel.WARNING)
cm = uhal.ConnectionManager('file://p5.xml')
dev = cm.getDevice('XE_221_B9')

# cm = uhal.ConnectionManager('file://${MP7_TESTS}/etc/mp7/connections-test.xml')
# dev = cm.getDevice('SIM_DAQ')
# dev.setTimeoutPeriod(10000)
# import sys
# sys.exit(0)
 
board = mp7.MP7Controller(dev)

config = getSettings()

# Reset board        
infra.Reset.run(board, **config['reset'])

zs = board.hw().getNode('readout.readout_zs')

zs_csr = board.hw().getNode('readout.readout_zs.csr')
# zs_ram = board.hw().getNode('readout.readout_zs.ram')

info = mp7.snapshot(zs_csr.getNode('info'))


print 'ZS block detected: ', 'Yes' if info['zs_enabled'] else 'No'
print info
ncap = info['mask_ram_depth']/6

print 'Supported capture modes: 0',ncap-1

zs.enable()

menuFile = "${MP7_TESTS}/python/daq/simple.py"
menuName = "menuA"
zsMenuName = "zsMenuA"        

# print 'Resetting board'
# infra.Reset.run(board, **config['reset'])
print 'Configure Rx to send patterns'
# datapath.XBuffers.run(board, 'rx', 'PlayOnce', [0,1,2,3], 'generate://pattern',(orbit.Point(0),None))
datapath.XBuffers.run(board, 'rx', 'Pattern', [0,1,2,3], None,(orbit.Point(0),None))
print 'Configuing latency buffers'
readout.EasyLatency.run(board, **config['easylatency'])
print 'Setting up readout'
readout.Setup.run(board, **config['setup'])
print 'Configuring readout menu'
readout.LoadMenu.run(board, menuFile, menuName)
print 'Configuring zs menu'
readout.LoadZSMenu.run(board, menuFile, zsMenuName)
# Additionally, set board id
ctrl = board.getCtrl()
ctrl.getNode('board_id').write(0x1234)
ctrl.getClient().dispatch()

result = readout.CaptureEvents.run(board, **config['capture'])

print result.rawsize()

print result.unpacked[0]
