#!/bin/env python

'''
MP7 Mini butler (version 2)
Title: mp7minibutler
Author: Alessandro Thea and Tom Williams

Example usage ...

mp7minibutler.py show
mp7minibutler.py reset MY_BOARD --clksrc=internal
mp7minibutler.py ...

'''


import logging
import mp7

from mp7.cli_core import CLIEngine
from mp7.cmds import Factory

if __name__ == '__main__':
    cli = CLIEngine()
    cli.setDefaultConnectionFiles(['file://${MP7_TESTS}/etc/mp7/connections-'+x+'.xml' for x in ['test', 'RAL', 'TDR']])

    for cmd in Factory.makeMP7Mini():
        cli.addCommand(cmd)

    try:
        global result
        result = cli.run()
    except mp7.exception as e:
        logging.critical("%s",e)
    except RuntimeError as re:
        logging.critical("%s",re)
