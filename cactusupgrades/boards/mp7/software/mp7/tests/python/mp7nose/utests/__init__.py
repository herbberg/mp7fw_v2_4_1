# from mp7.cli_core import CLIEngine, FunctorInterface
# from mp7.cli_plugins import MmcPlugin, MP7Plugin

# class TestContext:
#   '''Container for global objects common to all MP7Nose tests'''
#   # --
#   def __init__(self):
#     self._cm = None
#     self._mp7 = None
#     self._mmc = None

#   # ---
#   @property
#   def cm(self):
#     if self._cm is not None:
#       return self._cm
    
#     if not env.connectionFiles:
#       raise ValueError('Connection files not found in TestEnvironment. Was '+__name__+' initialised?')

#     print 'Building uhal.ConnectionManager'

#     self._cm =  CLIEngine.buildManager(env.connectionFiles)

#     return self._cm

#   # ---
#   @property
#   def mp7(self):
#     if self._mp7 is not None:
#       return self._mp7

#     if not env.boardId:
#       raise ValueError('MP7 ID not found in TestEnvironment. Was '+__name__+' initialised?')
    
#     print 'Building mp7.MP7Controller'

#     cm = self.cm

#     # Create a parameterset
#     pset = {'connectionManager':cm, 'board':env.boardId, 'timeout':env.timeout}

#     # And use MP7 Command to create the MP7 Controller
#     MP7Plugin.prepare(pset)

#     self._mp7 = pset['board']
#     return self._mp7

#   # ---
#   @property
#   def mmc(self):
#     if self._mmc is not None:
#       return self._mmc

#     if not env.boardId:
#       raise ValueError('MMC ID not found in TestEnvironment. Was '+__name__+' initialised?')
    
#     print 'Building mp7.MMCManager'
#     cm = self.cm

#     # Create a parameterset
#     pset = {'connectionManager':cm, 'board':env.boardId, 'timeout':env.timeout}

#     # And use MP7 Command to create the MP7 Controller
#     MmcPlugin.prepare(pset)

#     self._mmc = pset['board']
#     return self._mmc


# context = TestContext()
  
# # ---
# class TestUnit:

#   @staticmethod
#   def context():
#       return context
  

# class TestEnvironment: pass

# env = TestEnvironment()


# # Deal with core environment parameters here
# env.connectionFiles = ''
# env.boardId = ''
# env.timeout = 1000


# class TestConfig: pass




