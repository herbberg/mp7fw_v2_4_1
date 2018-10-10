mp7butler.py -c p5.xml reset XE_SL9 --clksrc=internal
mp7daqgrinder.py -v -c p5.xml s1demo XE_SL9 algo test counts
mp7butler.py  -c p5.xml rosetup XE_SL9
mp7butler.py -v -c p5.xml romenu XE_SL9 ${MP7_TESTS}/python/daq/simple.py menuB
mp7butler.py -v -c p5.xml roevents XE_SL9  2 --bx 1 
