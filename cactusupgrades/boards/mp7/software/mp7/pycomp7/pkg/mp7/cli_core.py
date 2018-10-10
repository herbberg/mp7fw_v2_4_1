import argparse
import logging
import re

import uhal 
from mp7.tools.cli_utils import IntListAction
from mp7.tools.helpers import logo, hookDebugger
from mp7.tools.log_config import initLogging

defaultFmtStr = " (default: '%(default)s')"

_log = logging.getLogger('cli_core')
_formatter = logging.Formatter('%(asctime)s : %(message)s')
_streamHandler = logging.StreamHandler()
_streamHandler.setFormatter(_formatter)

_log.setLevel(logging.WARNING)
_log.addHandler(_streamHandler) 

#---
class FunctorInterface(object):
    @staticmethod
    def addArgs(subp):
        pass

    # @staticmethod
    def run(self, *args, **kwargs):
        raise NotImplementedError('Metod \'run\' must be implemented in derived class')

    def __call__(self, *args, **kwargs):
        self.run(*args, **kwargs)

#---
class CommandAdaptor(FunctorInterface):
    """Simple class that binds run function (and optionally argument-parsing function)
    into object instance for use with cli_core.Command class"""
    @staticmethod
    def defaultConfigureArgSubParser(subp):
        pass

    def __init__(self, fRun, fCfgArgSubParser=None):
        self._fRun = fRun
        self._fCfgArgSubParser=fCfgArgSubParser

    def addArgs(self, subp):
        if self._fCfgArgSubParser is not None:
            self._fCfgArgSubParser()

    def run(self, *args, **kwargs):
        return self._fRun(*args,**kwargs)


#---
class CLIEngine(object):

    @staticmethod
    def initEnvironment(verbose = 0, logfile = None, gdb = False):
        import mp7

        # Default to uhal ARNING level
        uhal.setLogLevelTo(uhal.LogLevel.WARNING)
        

        if verbose < 0:
            pyLogLevel, mp7LogLevel = logging.WARNING, mp7.kWarning
        elif verbose == 0:
            pyLogLevel, mp7LogLevel = logging.INFO, mp7.kInfo
        elif verbose == 1:
            pyLogLevel, mp7LogLevel = logging.DEBUG, mp7.kDebug
        elif verbose > 1:
            pyLogLevel, mp7LogLevel = logging.DEBUG, mp7.kDebug1

        initLogging( pyLogLevel, logfile )
        mp7.setLogThreshold(mp7LogLevel)

        # if selected, call gdb here
        if gdb:
            hookDebugger()

    @staticmethod
    def buildManager(connections):
        conns = connections.split(';')
        for i,c in enumerate(conns):
            if re.match('^\w+://.*', c) is None:
                conns[i] = 'file://'+c

        # Assing the connection manager to the plugin as part fo the environment
        return uhal.ConnectionManager( ';'.join(conns) )


    def __init__(self, description=None, logo=logo ):
        self._description = description
        self._logo = logo
        self.defaultConnFiles = []
        self.commands = []



    def setDefaultConnectionFiles(self,defaultConnFiles):
        self.defaultConnFiles = defaultConnFiles


    def addCommand(self, cmd):
        self.commands.append( cmd )


    def run(self):

        # topparser = argparse.ArgumentParser( add_help=False) # Why this formatter? Which other formatters are available ?
        parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter, description=self._description) # Why this formatter? Which other formatters are available ?

        # Add common arguments to parser
        generalArgs = parser.add_argument_group('General optional arguments')
        generalArgs.add_argument('-c', '--connections', default = ';'.join(self.defaultConnFiles),  help='uHAL connection file')
        generalArgs.add_argument('--log', dest='logfile', default=None, help='Log file'+defaultFmtStr)
        generalArgs.add_argument('-v', '--verbose', action='count', default=0)
        generalArgs.add_argument('-l', '--nologo', dest='logo', action='store_false', default=True) 
        generalArgs.add_argument('--gdb', action='store_true', default=False)

        # Add commands to parser
        subparsers = parser.add_subparsers(dest='cmd', title='Available sub-commands', metavar='COMMAND')
        for cmd in self.commands:
            subp = cmd.addParser( subparsers )
            # Add the command itself to the namespace a default of a new argument
            # Avoids searching the correct command later
            subp.set_defaults( plugin = cmd )

        # cm is a reserved word. Make sure it's not used
        if 'connectionManager' in [a.dest for a in parser._actions] or 'connectionManager' in parser._defaults.keys():
            parser.error('Conflict: "cm" is reserved and cannot be used as argument')


        # Parse arguments
        args = parser.parse_args()

        _log.info("\n>>> PARSED ARGS <<<")
        for (key, val) in dict(vars(args)).items():
            _log.info("   %s : %s", key , val)

        # Sanitise the arguments for callback function (i.e. strip off arguments outside of command scope)
        pluginArgs = dict( vars(args) )

        for key in ['plugin']+[ a.dest for a in parser._actions if a.dest != 'help']:
            pluginArgs.pop(key)

        self.initEnvironment(args.verbose, args.logfile, args.gdb )

        if args.logo:
            self._logo()

        _log.info("MP7 script is calling plugin: %s", args.plugin)

        #TODO ?? Catch exceptions from callback function, and reformulate as exit code (-1?)
        #TODO / Open question -- should callbacks be required to return an exit code, or just set a non-zero exit code if an exception is thrown ?

        # Construct the connection manager and add it to 

        # Sanitise the connection strings
        # conns = args.connections.split(';')
        # for i,c in enumerate(conns):
            # if re.match('^\w+://.*', c) is None:
                # conns[i] = 'file://'+c

        # Assing the connection manager to the plugin as part fo the environment
        # pluginArgs['connectionManager'] = uhal.ConnectionManager( ';'.join(conns) )
        pluginArgs['connectionManager'] = self.buildManager(args.connections)
        
        plugin = args.plugin
        try:
            # Prepare the command arguments
            plugin.prepare(pluginArgs)
            
            # run the command
            result = plugin.execute( pluginArgs )
        except Exception as e:
            logging.exception(e)
            # import sys, traceback
            # traceback.print_exc(file=sys.stdout)
            import sys
            sys.exit(-1)


        if result:
            logging.info('Plugin %s returned: %s', args.cmd, result)

        return result

