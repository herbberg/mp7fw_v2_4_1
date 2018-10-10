mp7butler.py -v reset SIM --clksrc=internal
# mp7daqgrinder.py -v s1demo SIM algo test counts
mp7daqgrinder.py -v s1demo SIM algo testsim counts
mp7butler.py -v rosetup SIM
mp7butler.py -v romenu SIM --timeout=10000 ${MP7_TESTS}/python/daq/simple.py menuA
mp7butler.py -v roevents --timeout=10000 SIM 1 --bx 1
