BXS_HIGH=$(seq 3554 3563)
BXS_LOW=$(seq 0 10)

mp7butler.py reset SIM --clksrc=internal
sleep 10
mp7butler.py ttccapture SIM --maskbc0 yes

echo "Injecting on $BXS_HIGH"
for bx in ${BXS_HIGH}; do
  mp7butler.py -v -q pycmd SIM "board.getTTC().forceL1AOnBx($bx)";
  sleep 3;
done
mp7butler.py ttccapture SIM
mp7butler.py ttccapture SIM --clear

echo "Injecting on $BXS_LOW"
for bx in ${BXS_LOW}; do
  mp7butler.py -v -q pycmd SIM "board.getTTC().forceL1AOnBx($bx)";
  sleep 3;
done
mp7butler.py ttccapture SIM

