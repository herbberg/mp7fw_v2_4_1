import uhal
from _pycomp7 import *

##################################################
# Pythonic additions to uhal::exception API

def _exception_to_string(self):
  # what returns the exception string with one \n too many
  return self.what

exception.__str__ = _exception_to_string

##########################################################
# Utility function to take a snapshot of all the registers
def snapshot(self, aRegex = '' ):
  if aRegex :
    nodes = self.getNodes(aRegex)
  else:
    nodes = self.getNodes()

  vwords = [ (node,self.getNode(node).read()) for node in nodes ]
  self.getClient().dispatch()
  return dict( [ (n,v.value()) for n,v in vwords ] )


_classes = [
  AlignMonNode,
  ChanBufferNode,
  ClockingR1Node,
  ClockingXENode,
  CtrlNode,
  DatapathNode,
  FormatterNode,
  MGTRegionNode,
  SI5326Node,
  SI570Node,
  TTCNode,
  ReadoutNode,

  PPRamNode,

  MiniPODMasterNode,
  MmcPipeInterface,
  Firmware,
  XilinxBitStream,
  XilinxBitFile,
  XilinxBinFile,
  ]

for cl in _classes:
  setattr(cl,'snapshot',snapshot)

for name,enum in ChanBufferNode.DataSrc.names.iteritems():
  setattr(ChanBufferNode,name,enum)

for name,enum in ChanBufferNode.BufMode.names.iteritems():
  setattr(ChanBufferNode,name,enum)

for name,enum in TTCNode.FreqClockChannel.names.iteritems():
  setattr(TTCNode,name,enum)

for name,enum in ReadoutNode.EventSource.names.iteritems():
  setattr(ReadoutNode,name,enum)
