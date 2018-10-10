# mp7butler.py -v reset SIM --clksrc=internal
# mp7butler.py -v latency SIM -e 0,2,4,6,8,10 rx 1 1
# mp7butler.py -v latency SIM -e 1,3,5,7,9,11 rx 2 1
# mp7butler.py -v latency SIM -e 12-15 tx 3 1
# mp7butler.py -v rosetup SIM
# mp7butler.py -v romenu SIM ${MP7_TESTS}/python/daq/stage1.py menu
# mp7butler.py -v roevents SIM 1


mp7butler.py reset SIM  --clksrc=internal
mp7daqgrinder.py -v s1demo SIM algo testsim counts
mp7butler.py  rosetup SIM
mp7butler.py -v romenu SIM ${MP7_TESTS}/python/daq/stage1.py menu
mp7butler.py -v roevents SIM 1 --timeout=10000 --outputpath dumps/s1daqtest.txt
