#
#
#

import logging
import os
from os.path import join
import random
import sys
import xml.etree.ElementTree as ET

# MP7 modules
import cli_utils
import log_config
import mp7


# models = {'r1':'MP7R1Controller', 'xe':'MP7XEController' }

class Tee(object):
    def __init__(self, name, mode='w'):
        self.file = open(name, mode)
        self.stdout = sys.stdout
        sys.stdout = self

    def __del__(self):
        self.file.close()
        del self.stdout

    def write(self, data):
        self.file.write(data)
        self.stdout.write(data)

    def flush(self):
        self.file.flush()
        self.stdout.flush()

#---
def initPlotting():
    if 'DISPLAY' not in os.environ:
        import matplotlib as mpl
        mpl.use('Agg')

#---
def logo():
    print '       __ __  ____      _____   ______    _________  '
    print '      / // //     |    /  _  | |   _  \  |_____   /  '
    print '     / // //  /|  |   /  /|  | |  | \  |      /  /   '
    print '    / // //  / |  |  /  / |  | |  |_/  |  ___/  /__  '
    print '   / // //  /  |  | /  /  |  | |   __ /  |__  ____/  '
    print '  / // //  /   |  |/  /   |  | |  |       /  /       '
    print ' /_//_//__/    |_____/    |__| |__|      /__/        '
    print '-'*80
    print ' mp7butler: One script to rule them all'
    print '-'*80

def testAccess(board):

    v = board.getNode('ctrl.id').read()
    try:
        board.dispatch()
    except:
        import sys
        # print something here when if times out
        raise RuntimeError('MP7 access failed (name: %s uri: %s)',board.id(),board.uri())
    
    logging.info('%s access successful (%s)', board.id(),hex(v))
    logging.debug(' uri : %s',board.uri())

def getLogLevel():
    import uhal
    levels = uhal.LogLevel.values
    for l in sorted(levels.keys()):
        if uhal.LoggingIncludes(levels[l]):
            return levels[l]

def snapshot( node ):
    '''snapshot( node ) -> { subnode:value }'''
    import uhal
    vals = {}
    for n in node.getNodes():
        vals[n] = node.getNode(n).read()
    node.getClient().dispatch()

    return dict( [ (k,v.value()) for k,v in vals.iteritems() ] )

def channelMgr(board, enable=None):
    return board.channelMgr(enable) if enable is not None else board.channelMgr()


# Make a logging Tee, to add the print to the logging, with below-warning
# priority :D

def hookDebugger(debugger='gdb'):
    '''debugging helper, hooks debugger to running interpreter process'''

    import os
    pid = os.spawnvp(os.P_NOWAIT,
                     debugger, [debugger, '-q', 'python', str(os.getpid())])

    # give debugger some time to attach to the python process
    import time
    time.sleep( 1 )

    # verify the process' existence (will raise OSError if failed)
    os.waitpid( pid, os.WNOHANG )
    os.kill( pid, 0 )
    return

#---
def run_from_ipython():
    try:
        __IPYTHON__   #pylint: disable=undefined-variable 
        return True
    except NameError:
        return False

#---
class list_maker:
  def __init__(self, var, sep=',', type=None ):
    self._type= type
    self._var = var
    self._sep = sep

  def __call__(self,option, opt_str, value, parser):
    if not hasattr(parser.values,self._var):
      setattr(parser.values,self._var,[])

    try:
      array = value.split(self._sep)
      if self._type:
        array = [ self._type(e) for e in array ]
      setattr(parser.values, self._var, array)

    except:
      print 'Malformed option (comma separated list expected):',value

#---
class intlist_maker:
  def __init__(self, var, sep=',', dash='-'):
    self._var  = var
    self._sep  = sep
    self._dash = dash

  def __call__(self,option, opt_str, value, parser):
    if not hasattr(parser.values,self._var):
      setattr(parser.values,self._var,[])

    numbers=[]
    items = value.split(self._sep)
    for item in items:
        nums = item.split(self._dash)
        if len(nums) == 1:
            # single number
            numbers.append(int(item))
        elif len(nums) == 2:
            i = int(nums[0])
            j = int(nums[1])
            if i > j:
                raise ValueError('Invalid interval '+item)
            numbers.extend(range(i,j+1))
        else:
           print 'Malformed option (comma separated list expected):',value
    setattr(parser.values, self._var, numbers)

#---
def intlist2str( items ):
    if not items:
        return '[]'
    
    if len(items) == 1:
        return str(items)

    sitems = sorted(items)

    ranges = []
    begin = sitems[0]
    end = sitems[0]
    # print '--'
    for c in sitems[1:]:
        # print c,begin,end
        if c == end+1:
            end = c
            continue

        if begin == end:
            ranges.append( '%s' % begin )
        else:
            ranges.append( '%s-%s' % (begin,end) )

        begin=c
        end=c

    # wrap the end elements up 
    if begin == end:
        ranges.append( '%s' % begin )
    else:
        ranges.append( '%s-%s' % (begin,end) )

    return '['+','.join(ranges)+']'

#---
def bin(x,fill=0):
    """
    bin(number) -> string

    Stringifies an int or long in base 2.
    """
    if x < 0:
        return '-' + bin(-x)
    out = []
    if x == 0:
        out.append('0')
    while x > 0:
        out.append('01'[x & 1])
        x >>= 1
        pass
    if fill != 0 and fill>len(out):
        out+='0'*(fill-len(out))
    try:
        return '0b' + ''.join(reversed(out))
    except NameError, ne2:
        out.reverse()
    return '0b' + ''.join(out)



#---
def validatePath( parser, opts ):
    if opts.path:
        # some local imports
        from os.path import exists,basename,join,splitext

        # sanitaise the inputs
        if opts.path[-1] != '/': opts.path += '/'

        if not os.path.exists(opts.path):
            os.system('mkdir -p '+opts.path)

        #
        opts.logfile = join(opts.path,basename(splitext(parser.get_prog_name())[0]+'.log') )
    else:
        opts.logfile=None


# #---
# def listFilesOnSD(controller):
#     logging.info("Scanning MicroSD card ...")
#     for filename in controller.filesOnSD():
#         logging.info("    > %s", filename)


#---
def qdrTest(controller):
    rams = []
    rams.append(controller.hw().getNode('qdr.ram0'))
    rams.append(controller.hw().getNode('qdr.ram1'))

    # The data is written into the RAM in 72bit words.  The QDR <-> IPBus interface
    # therefore expects read & writes to come in pairs.  
    # When writing the 36bit ipbus word-0 (add LSB=0) is buffered until ipbus word-1 (add LSB=1) arrives.
    # When reading the RAM the situation is reveresed and read word-0 is immediately transmitted 
    # while read word-1 (add LSB=1) is buffered until the next read.
    # This mechanism blocks the use of automatic breaking of big reads / writes into smaller packets.
    # (i.e block reads / writes must occur in even size packets)
        
    NMAX=2**21 # Size of RAM in 32bit words (i.e. 2**21 for 72Mb).  Set to less when debugging, but > N. 
    N=2**8 # Size of data block writen to RAM.  Above 8 packet chunking will occur and errors will occur.
    NBLOCKS=NMAX/N # Number of data blocks that need to be written to fill RAM
    NPRINT=8 # Prints out the first few RAM addresses if DEBUG true.
    DEBUG=False

    logging.warn("Be patient.  Testing the RAMs is not particularly quick.")

    for ram in rams:

        logging.info(" ")
        logging.info("RAM=%s", ram.getPath())
   
        logging.info("Build set of random numbers")
        ram_data = [random.randint(0,2**32-1) for r in range(NMAX)]
                 
        logging.info("Write data")
        for i in range(0, NBLOCKS):
            ram.writeBlockOffset(ram_data[i*N:(i+1)*N], i*N)
            ram.getClient().dispatch()
            i+=1

        logging.info("Read & check data.")
        err = 0
        MAX_ERR = 2
        for i in range(0, NBLOCKS):
            mem = ram.readBlockOffset(N, i*N)
            ram.getClient().dispatch()
            # Check data on the fly to avoid building a large array.
            for j in range(N):
                if ((j+i*N < NPRINT) and DEBUG):
                    logging.info("Address = %s", hex(j+i*N))
                    logging.info("Data Wt = 0x%04x", ram_data[j+i*N])
                    logging.info("Data Rd = %s", hex(mem[j]))
                if (mem[j] != ram_data[j+i*N]) and (err < MAX_ERR):
                    err+=1
                    logging.error("Data read back from RAM0 does not match data written")
                    logging.error("Address = %s", hex(j+i*N))
                    logging.error("Data read = %s", hex(mem[j]))
                    logging.error("Data written = 0x%04x", ram_data[j+i*N])
                j+=1
            i+=1

