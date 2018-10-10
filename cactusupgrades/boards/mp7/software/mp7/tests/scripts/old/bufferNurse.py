#!/bin/env python


import argparse
import logging
from mp7 import BoardDataFactory
from mp7.tools.log_config import initLogging
from mp7.tools.helpers import overrideDataValidPattern



class IntListAction(argparse.Action):
    def __init__(self, *args, **kwargs):
        super(IntListAction, self).__init__(*args, **kwargs)
        # self._var  = var
        # self._sep  = sep
        # self._dash = dash
        self._sep  = ','
        self._dash = '-'

    def __call__(self, parser, namespace, values, option_string=None):

        numbers=[]
        items = values.split(self._sep)
        for item in items:
            nums = item.split(self._dash)
            if len(nums) == 1:
                # single number
                numbers.append(int(item))
            elif len(nums) == 2:
                i = int(nums[0])
                j = int(nums[1])
                if i > j:
                    parser.error('Invalid interval '+item)
                numbers.extend(range(i,j+1))
            else:
               parser.error('Malformed option (comma separated list expected): %s' % values)

        setattr(namespace, self.dest, numbers)

def parseArgs():

    dftstr=' (default: \'%(default)s\')'

    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('source')
    parser.add_argument('dest')
    parser.add_argument('--replacechans', action=IntListAction, default=[], help='Links to control'+dftstr)
    parser.add_argument('--master', default=0, type=int, help='Master link'+dftstr)
    parser.add_argument('--offset', default=0, type=int, help='Datavalid offset'+dftstr)
    args = parser.parse_args()
    return args


# logging initialization
initLogging( logging.DEBUG )

args = parseArgs()



input_data = BoardDataFactory.generate(args.source)

outdata = overrideDataValidPattern(input_data, args.replacechans, args.master)

BoardDataFactory.saveToFile(outdata, args.dest)

