#!/bin/env python

''' 
Creates eye scan plots from data outputted using the mp7butler eyescan tool
'''

import os
import argparse
import logging

parser = argparse.ArgumentParser(description="Let's plot some eyescans")
parser.add_argument('data_uri', default='', help='Source of eyescan data')
parser.add_argument('--nw', dest='nw', default=False, action='store_true',help="Don't display the graph")

args = parser.parse_args()

class EyePlot:

    @staticmethod
    def run(data_uri, nw):
        
        try:
            import numpy as np
            import matplotlib as mpl
            mpl.use('Agg')
            import matplotlib.pyplot as plt
            from matplotlib.backends.backend_pdf import PdfPages
            data = np.genfromtxt(data_uri, delimiter=',')

            x = np.unique(data[:,0])
            y = np.unique(data[:,1])
            z = np.log(data[:,2])
        
            Y,X = np.meshgrid(y,x)
            # Z=z.reshape(len(y),len(x))
            Z=z.reshape(len(x), len(y)) #translate the hell out of this
            
            c0 = plt.contourf(X, Y, Z)
            
            plt.colorbar(c0)
            
            path = data_uri.replace('.txt', '') + '.pdf'
            
            pp = PdfPages(path)
            try:
                plt.savefig(pp, format='pdf')
                print "Wrote file: " , path
            except:
                print "Couldn't write file: ", path
            if nw == False:
                try:
                    os.environ['DISPLAY']
                    plt.show()
                except:
                    logging.warning('No display set. No window, no cry.')
            pp.close()

        except ImportError:
            plot_enable = False
            logging.warning('No numpy/matplotlib, no graphs!')

        
if __name__ == '__main__':

    EyePlot.run(args.data_uri, args.nw)
