# Core module
import mp7nose

# Settings
from mp7nose.settings.buffers import getSettings

# MP7 commands
import mp7.cmds.mgts as mgts
import mp7.cmds.infra as infra

# Global default settings for buffer test cases
defaults = {}


def setup_module(module):
    print ("") # this is to get a newline after the dots
    print ("setup_module before anything in "+__name__)

    global defaults
    
    defaults = getSettings()

def teardown_module(module):
    print ("teardown_module after everything in "+__name__)


# ---
class TestMGTReset(mp7nose.TestUnit):
    '''
    .

    '''

    def setup(self):
        print (self.__class__.__name__+".setup() before each test method")

        # Preparing test
        self.board = self.context().mp7
        
        # Reset board
        infra.Reset.run(self.board, **defaults['reset'])

        self.cfg = mp7nose.TestConfig()

        self.cfg.chans = [0,1,2,3]

    def test_rx_mgt_config(self):

        # Put Tx buffers in pattern mode?
        # 
        
        # Configure Tx
        mgts.TxMGTs.run(self.board, self.cfg.chans)

        # Check Tx config
