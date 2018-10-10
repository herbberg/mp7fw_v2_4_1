#!/bin/env python

import os
import time
import fcntl
import subprocess


class IPopen(subprocess.Popen):

    POLL_INTERVAL = 0.1
    def __init__(self, *args, **kwargs):
        """Construct interactive Popen."""
        keyword_args = {
            'stdin': subprocess.PIPE,
            'stdout': subprocess.PIPE,
            'stderr': subprocess.PIPE,
            'prompt': '>',
            'verbose': False
        }
        keyword_args.update(kwargs)
        self.prompt = keyword_args.get('prompt')
        del keyword_args['prompt']
        self.verbose = keyword_args.get('verbose')
        del keyword_args['verbose']
        subprocess.Popen.__init__(self, *args, **keyword_args)
        # Make stderr and stdout non-blocking.
        for outfile in (self.stdout, self.stderr):
            if outfile is not None:
                fd = outfile.fileno()
                fl = fcntl.fcntl(fd, fcntl.F_GETFL)
                fcntl.fcntl(fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)

    def correspond(self, text, sleep=0.1):
        """Communicate with the child process without closing stdin."""
        if text:
            if text[-1] != '\n': text += '\n'
        else:
            text='\n'
        self.stdin.write(text)
        self.stdin.flush()
        str_buffer = ''
        while not str_buffer.endswith(self.prompt):
            try:
                tmp = self.stdout.read()
                if self.verbose: print tmp
                str_buffer += tmp 
            except IOError:
                time.sleep(sleep)

        return str_buffer


class Impact:
    def __init__(self):
        cmd = 'impact -batch'
        self._me = IPopen(cmd.split())

    def __del__(self):
        self._me.communicate()


    def verbose(self, value):
        self._me.verbose = value

    def execute(self, script):
        output_buffer=''
        for l in script.split('\n'):
            # print 'cmd:',l
            if not l.strip(): continue
            print "[exec] "+l
            output_buffer += self._me.correspond(l)
        return output_buffer

    def listcables(self):
        output = self._me.correspond('listusbcables')

        import re
        prog = re.compile('^port=([^,]*), esn=(.*)')
    
        # print output
        lines = output.split('\n')
    
        i = lines.index('List of available USB cables')
        b =  [ j for j,l in enumerate(lines[i:]) if l == '==============================' ]
        # print b,i
        cables = dict([prog.match(l).groups() for l in lines[i+b[0]+1:i+b[1]]])

        return cables

    def identify(self, usbcable):

        script = '''
setMode -bscan
setCable -p %s
''' % usbcable

        self.execute(script)

        output = self.execute('identify')
        # print output
        return self.devices()

    def devices(self):
        output = self.execute('info')

        output = output.split('\n')

        # isolate the section corresponding to the boundary scan
        i = output.index('Mode BS')+2
        j = i+output[i:].index('-'*70)
        
        # build a dictionary with the correct infos
        devices = {}
        
        devstr = output[i:j]
        # print devstr
        header = devstr[0].split()
        # print header
        for l in devstr[1:]:
            # TOFIX: improve the splitting
            cells = l.split()

            devices[cells[0]] = dict(zip(header,cells))
        return devices

    def deletedevices(self,ids=None):
        if not ids:
            self._me.correspond('deletedevices -all')

        for i in ids:
            self._me.correspond('deletedevices -p %s' % id)


    def program(self, usbcable, bitfile):

        script = '''
setMode -bscan
setCable -p %s -b 12000000
addDevice -p 1 -file %s
program -p 1
''' % (usbcable,bitfile)

        self.execute(script)
        # for l in script.split('\n'):
        #     if not l: pass
        #     print "Executing '"+l+"'"
        #     self._me.correspond(l)

def parseArguments():

    import argparse
    dftstr=' (default: \'%(default)s\')'
    
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    subparsers = parser.add_subparsers(dest = 'cmd')
    subp = subparsers.add_parser('show', help='Show the list of known cables')

    subp = subparsers.add_parser('program', help='Program bitfile')
    subp.add_argument('cable', help='Usb cable to use')
    subp.add_argument('bitfile', help='Bitfile to load')

    subp = subparsers.add_parser('identify', help='Identify board on a cable')
    subp.add_argument('cable', help='Usb cable to use')

    ns = parser.parse_args()

    return ns

args = parseArguments()



if args.cmd == 'show':
    impact = Impact()
    cables = impact.listcables()
    print 'Found usb cables:'

    for usb,esn in cables.iteritems():
        print '  cable=%s, esn=%s' % (usb,esn)

elif args.cmd == 'program':
    if not os.path.exists(args.bitfile):
        raise ValueError('%s bitfile doesn\'t exist' % args.bitfile )

    impact = Impact()
    
    cables = impact.listcables()
    if args.cable not in cables:
        raise ValueError('Cable %s does not exist' % args.cable)

    print 'Programming',args.bitfile,'into',args.cable
    impact.verbose(True)
    impact.program(args.cable,args.bitfile)

elif args.cmd == 'identify':
    impact = Impact()

    cables = impact.listcables()
    if args.cable not in cables:
        raise ValueError('Cable %s does not exist' % args.cable)

    # impact.verbose(True)

    print impact.identify(args.cable)
