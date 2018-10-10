import os
import logging
import sys

from nose.plugins import Plugin
from mp7nose import env

from mp7.cli_core import CLIEngine

class MP7Loader(Plugin):

    name = 'mp7'

    def __init__(self):
        try:
            env.boardId=sys.argv[1]
            if env.boardId == "-h":
                print "Syntax: mp7jeeves BOARDID --optionals"
                return
            sys.argv.pop(1)
        except:
            print "Is that the right command structure? (mp7jeeves BOARDID --optionals)"
            raise
        
        Plugin.__init__(self)
    
    def options(self, parser, env=os.environ):

        def_connections=['file://${MP7_TESTS}/etc/mp7/connections-'+x+'.xml' for x in ['test']]

        super(MP7Loader, self).options(parser, env=env)
        parser.add_option('--mp7-connections',
                          dest='connections',
                          default=';'.join(def_connections),
                          help='connections file')
        parser.add_option('--mp7-timeout',
                          default=1000,
                          type=int,
                          dest='timeout',
                          help='uhal timeout')
        parser.add_option('--mp7-verbose',
                          default=False,
                          action='store_true',
                          dest='mp7_verbose',
                          help='mp7 verbosity')
    
    def configure(self, options, conf):
        super(MP7Loader, self).configure(options, conf)
        
        self.enable=True

        env.timeout = options.timeout
        env.connectionFiles = options.connections
        
        cli = CLIEngine()        
        # cli.buildManager(options.connections)
        cli.initEnvironment(verbose = 1 if options.mp7_verbose else -1)
        
