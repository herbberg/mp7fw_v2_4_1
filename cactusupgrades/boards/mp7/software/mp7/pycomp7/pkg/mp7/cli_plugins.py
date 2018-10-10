import logging
import uhal

from cli_core import defaultFmtStr
from mp7 import MP7MiniController, MP7Controller, MmcController


_log = logging.getLogger('cli_plugins')
_formatter = logging.Formatter('%(asctime)s : %(message)s')
_streamHandler = logging.StreamHandler()
_streamHandler.setFormatter(_formatter)

_log.setLevel(logging.WARNING)
_log.addHandler(_streamHandler) 
#---
class Plugin(object):

    defaultConnFiles = []

    def __init__(self, name, helpText, cmdInterface):
        try:
            assert( hasattr(cmdInterface, 'run') )
            assert( callable(cmdInterface.run) )
            assert( hasattr(cmdInterface, 'addArgs') )
            assert( callable(cmdInterface.addArgs) )
        except AssertionError as ae:
            logging.error('Failed to build Plugin from %s', cmdInterface.__class__.__name__)
            raise ae

        self.name = name
        self._helpText = helpText
        self._cmdInterface = cmdInterface

    def __str__(self):
        return type(self).__name__+"<'"+self.name+"'>"

    __repr__ = __str__
    
    def addParser(self, subparsers):
        _log.info('>>> REGISTERING %s <<<', self)
        # Add a new subparser
        subp = subparsers.add_parser(self.name, help=self._helpText)
        # Add plugin arguments
        self._addArgs(subp)
        # Add functor arguments 
        self._cmdInterface.addArgs(subp)

        return subp

    def execute(self, cmdArgs):
        _log.info(">>> CALLBACK FOR %s ...", self)
        
        return self._cmdInterface.run(**cmdArgs)

    @classmethod
    def _addArgs(cls, subp):
        _log.debug(' > Entering:  Plugin._addArgs')
        _log.debug(' > Exiting :  Plugin._addArgs')

    @classmethod
    def prepare(cls, kwargs):
        _log.debug(' > Entering:  Plugin.prepare')
        _log.debug(' > Exiting :  Plugin.prepare')


#---
class DevicePlugin(Plugin):

    def __init__(self, *args, **kwargs):
        super(DevicePlugin,self).__init__(*args, **kwargs)

    @classmethod
    def _addArgs(cls, subp):
        _log.debug(" > Entering:  DevicePlugin._addArgs")
        super(DevicePlugin, cls)._addArgs(subp)
        _log.debug(" > Meat of :  DevicePlugin._addArgs")
        subp.add_argument('board', help='Board to connect to')
        subp.add_argument('--timeout', type=int, default=1000, help='IPbus timeout'+defaultFmtStr)
        _log.debug(" > Exiting :  DevicePlugin._addArgs")

    @classmethod
    def prepare(cls, kwargs):
        _log.debug(" > Entering:  DevicePlugin.prepare")
        super(DevicePlugin, cls).prepare(kwargs)
        _log.debug(" > Meat of :  DevicePlugin.prepare")

        # Pop the connection manager
        cm = kwargs.pop('connectionManager')

        # Try instanciating the board
        try:
            board = cm.getDevice(kwargs['board'])
        except uhal.exception as e:
            for d in cm.getDevices():
                logging.error('%s',d)
            raise ValueError('Requested device not found in connection files')

        board.setTimeoutPeriod( kwargs.pop('timeout') )

        # Replace board with the newly created hardware interface
        kwargs['board'] = board

        _log.debug(" > Exiting :  DevicePlugin.prepare")


#---
class MP7MiniPlugin(DevicePlugin):

    def __init__(self, *args, **kwargs):
        super(MP7MiniPlugin,self).__init__(*args, **kwargs)

    @classmethod
    def _addArgs(cls, subp):
        _log.debug(" > Entering:  MP7MiniPlugin._addArgs")
        super(MP7MiniPlugin, cls)._addArgs(subp)
        _log.debug(" > Meat of :  MP7MiniPlugin._addArgs")
        _log.debug(" > Exiting :  MP7MiniPlugin._addArgs")

    @classmethod
    def prepare(cls, kwargs):
        _log.debug(" > Entering:  MP7MiniPlugin.prepare")
        super(MP7MiniPlugin, cls).prepare(kwargs)
        _log.debug(" > Meat of :  MP7MiniPlugin.prepare")

        print kwargs
        # Consume 'build'
        # build = kwargs.pop('build')

        # Create the subject
        board = MP7MiniController( kwargs['board'] )

        # Replace board id with the controller itself
        kwargs['board'] = board

        _log.debug(" > Exiting :  MP7MiniPlugin.prepare")
        board.identify()

#---
class MP7Plugin(DevicePlugin):

    def __init__(self, *args, **kwargs):
        super(MP7Plugin,self).__init__(*args, **kwargs)

    @classmethod
    def _addArgs(cls, subp):
        _log.debug(" > Entering:  MP7Plugin._addArgs")
        super(MP7Plugin, cls)._addArgs(subp)
        _log.debug(" > Meat of :  MP7Plugin._addArgs")
        _log.debug(" > Exiting :  MP7Plugin._addArgs")

    @classmethod
    def prepare(cls, kwargs):
        _log.debug(" > Entering:  MP7Plugin.prepare")
        super(MP7Plugin, cls).prepare(kwargs)
        _log.debug(" > Meat of :  MP7Plugin.prepare")

        # Create the subject
        # board = MP7Controller( kwargs['board'], build )
        board = MP7Controller( kwargs['board'] )

        # Replace board id with the controller itself
        kwargs['board'] = board

        _log.debug(" > Exiting :  MP7Plugin.prepare")
        board.identify()

#---
class MmcPlugin(DevicePlugin):

    def __init__(self, *args, **kwargs):
        super(MmcPlugin,self).__init__(*args, **kwargs)

    @classmethod
    def _addArgs(cls, subp):
        _log.debug(" > Entering:  MmcPlugin._addArgs")
        super(MmcPlugin, cls)._addArgs(subp)
        _log.debug(" > Meat of :  MmcPlugin._addArgs")

        _log.debug(" > Exiting :  MmcPlugin._addArgs")

    @classmethod
    def prepare(cls, kwargs):
        _log.debug(" > Entering:  MmcPlugin.prepare")
        super(MmcPlugin, cls).prepare(kwargs)
        _log.debug(" > Meat of :  MmcPlugin.prepare")

        # Create the subject
        board = MmcController( kwargs['board'] )

        # Replace board id with the controller itself
        kwargs['board'] = board

        _log.debug(" > Exiting :  MP7Plugin.prepare")