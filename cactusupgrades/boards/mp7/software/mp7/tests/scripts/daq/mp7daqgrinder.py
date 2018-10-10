#!/bin/env python

'''
MP7 butler
Title: mp7butler
Author: Alessandro Thea and Tom Williams

Example usage ...

mp7butler.py show
mp7butler.py reset MY_BOARD --clksrc=internal
mp7butler.py ...

'''





import logging
import mp7
from mp7.cli_core import defaultFmtStr
from mp7.tools.helpers import testAccess

from mp7.cli_core import CLIEngine

from mp7.cli_core import defaultFmtStr, Command, DevicePlugin

# from mp7.butler_cmds import COMMANDS as cmds
# from daq.readouttest import FifoThrottleTest, FifoThrottleScan, FifoFullEmptyTest
# from daq.readouttest import CountersCapture
# from daq.stage1 import ConfigS1Demo, ConfigS1DemoB, ConfigS1Demo
from daq.stage1 import ConfigS1Demo

cmds = []


cmds += [ MP7Plugin('s1demo','Configure buffers to mimic stage1 setup', ConfigS1Demo()) ]



if __name__ == '__main__':
    cli = CLIEngine()

    for cmd in cmds:
        cli.addCommand(cmd)

    try:
        global result
        result = cli.run()
    except mp7.exception as e:
        logging.critical("%s",e)
    except RuntimeError as re:
        logging.critical("%s",re)
