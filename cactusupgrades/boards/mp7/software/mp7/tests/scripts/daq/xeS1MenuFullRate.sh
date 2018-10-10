mp7butler.py -c p5.xml reset XE_SL9  --clksrc=internal
mp7daqgrinder.py -v -c file://p5.xml s1demo XE_SL9 algo full counts --add 12
mp7butler.py  -c p5.xml rosetup XE_SL9 --drain 0
mp7butler.py -v -c p5.xml romenu XE_SL9 ${MP7_TESTS}/python/daq/stage1.py menu
# mp7butler.py -v -c p5.xml roevents XE_SL9  1 --bx=1
mp7butler.py -v -c p5.xml rorate XE_SL9  --rate 100000
