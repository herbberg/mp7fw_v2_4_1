mp7butler.py -c p5.xml reset XE_SL9  --clksrc=internal
mp7butler.py -c p5.xml mgts XE_SL9 --loopback
mp7daqgrinder.py -v -c file://p5.xml s1demo XE_SL9 loop full events --add 12 --inject events/s1golden-clean-strobed
mp7butler.py  -c p5.xml rosetup XE_SL9
mp7butler.py -v -c p5.xml romenu XE_SL9 ${MP7_TESTS}/python/daq/stage1.py menu
mp7butler.py -v -c p5.xml roevents XE_SL9  1 --bx=1 
