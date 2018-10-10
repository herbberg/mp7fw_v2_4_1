#!/bin/env python
import uhal
from daq.dtm import DTManager

uhal.setLogLevelTo(uhal.LogLevel.WARNING)
# cm = uhal.ConnectionManager('file:///nfshome0/thea/trg/amc13/c_ugmt.xml')
connection = 'file:///nfshome0/thea/trg/amc13/c_ugmt.xml'
fedId = 1402
connection = 'file:///nfshome0/thea/trg/amc13/c_demux.xml'
fedId = 1366


print 'Using file',connection
print 'fedID',fedId
cm = uhal.ConnectionManager(connection)

amc13T1 = cm.getDevice('T1')
amc13T2 = cm.getDevice('T2')

amc13 = DTManager(amc13T1, amc13T2)

amc13.reset()

amc13.configure( [1,2,3] , fedId, True, False, True)
amc13.start()

