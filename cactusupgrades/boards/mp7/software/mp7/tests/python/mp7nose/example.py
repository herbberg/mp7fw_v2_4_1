import mp7nose
import mp7.cmds.infra as infra


# from nose import with_setup # optional
# from nose import config
from nose import tools


# def multiply(x,y):
#     return x*y

# def setup_module(module):
#     print ("") # this is to get a newline after the dots
#     print ("setup_module before anything in this file")
#     global theBoard
#     theBoard = mp7nose.getMP7Controller()

# def teardown_module(module):
#     print ("teardown_module after everything in this file")

# def my_setup_function():
#     print ("my_setup_function")

# def my_teardown_function():
#     print ("my_teardown_function")

#
# First Test
# @with_setup(my_setup_function, my_teardown_function)
# def test_numbers_3_4():
#     print 'test_numbers_3_4  <============================ actual test code'
#     assert multiply(3,4) == 12

# @with_setup(my_setup_function, my_teardown_function)
# def test_strings_a_3():
#     print 'test_strings_a_3  <============================ actual test code'
#     assert multiply('a',3) == 'aaa'


class TestFirstMP7(mp7nose.TestUnit):

    def setup(self):
        print ("TestFirstMP7:setup() before each test method")
        # Preparing test
        self.board = self.context().mp7

    def teardown(self):
        print ("TestFirstMP7:teardown() after each test method")

    @classmethod
    def setup_class(cls):
        print ("setup_class() before any methods in this class")

    @classmethod
    def teardown_class(cls):
        print ("teardown_class() after any methods in this class")

    def test_00_none(self):
        pass

    def test_01_reset_internal(self):
        print 'test_01_reset_internal()  <============================ actual test code'
        infra.Reset.run(self.board, 'internal','internal','internal')
        
        # Analyse the result
        ctrl = self.board.getCtrl()
        ttc = self.board.getTTC()

        # Clock must be locked
        tools.assert_true(ctrl.clock40Locked())

        # Clock must not be stopped
        # tools.assert_false(ctrl.clock40Stopped())

    def test_02_reset_external(self):
        print 'test_02_reset_external()  <============================ actual test code'
        infra.Reset.run(self.board, 'external','external','external')