#!/bin/env python

'''
MP7 Jeeves (v0.1)
Title: mp7jeeves

'''

import sys

import nose
import nose.plugins.builtin

from mp7nose.plugins.mp7loader import MP7Loader
from mp7nose.plugins.logcapture import LogCapture
from mp7nose.plugins.nose_html_reporting import HtmlReport

if __name__ == '__main__':
    
    defaultplugins = [plug() for plug in nose.plugins.builtin.plugins]
    nose.main(plugins=defaultplugins + [MP7Loader(), LogCapture(), HtmlReport()])
