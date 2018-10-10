mp7butler.py -c p5.xml reset XE_SL9  --clksrc=internal
mp7butler.py -c p5.xml mgts XE_SL9 --loopback
mp7daqgrinder.py -v -c file://p5.xml s1demo XE_SL9 loop test counts --add 12
mp7butler.py  -c p5.xml rosetup XE_SL9 --bxoffset=1
mp7butler.py -v -c p5.xml romenu XE_SL9 ${MP7_TESTS}/python/daq/simple.py menuB
mp7butler.py -v -c p5.xml roevents XE_SL9  1 --outputpath dumps/simpledaqtest.txt
