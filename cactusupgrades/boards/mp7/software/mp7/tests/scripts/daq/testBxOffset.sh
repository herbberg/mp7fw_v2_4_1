mp7butler.py -v reset SIM --clksrc=internal
# mp7daqgrinder.py -v s1demo SIM algo test counts
mp7butler.py -l -v rosetup SIM
mp7butler.py -l -v romenu SIM ${MP7_TESTS}/python/daq/simple.py menuA

BXS_LOW=$(seq 0 3)
BXS_HIGH=$(seq 3554 3563)

for bx in ${BXS_HIGH}; do
    echo Injecting on ${bx}
    mp7butler.py -l roevents --timeout=10000 SIM 1 --bx ${bx}
    sleep 3;
done

for bx in ${BXS_LOW}; do
    echo Injecting on ${bx}
    mp7butler.py -l roevents --timeout=10000 SIM 1 --bx ${bx}
    sleep 3;
done