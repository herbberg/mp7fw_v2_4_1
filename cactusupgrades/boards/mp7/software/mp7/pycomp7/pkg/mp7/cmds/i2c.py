import logging
import os 

import uhal
import mp7

import mp7.tools.helpers as hlp

from mp7.cli_core import defaultFmtStr, FunctorInterface

class PrintMinipodSensors(FunctorInterface):

    @staticmethod
    def addArgs(subp):
        subp.add_argument('-l', '--logical_ids', dest='logicalIds', default=False, action='store_true', help='Show logical link IDs for link power')

    @staticmethod
    def run(board, logicalIds):
        minipodNodes = [ board.hw().getNode(m) for m in ['i2c.minipods_bot','i2c.minipods_top']]
        
        lcToLogicalMap = dict(zip(range(0,72),[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,
                          25,28,26,27,30,29,31,32,33,34,35,36,62,61,64,63,66,65,67,68,69,
                          71,70,72,50,49,52,51,54,53,56,55,58,57,59,60,38,37,40,39,42,41,
                          44,43,46,45,47,48]))
        opPows = []
        
        for node in minipodNodes:
            for pod in ['rx3','rx4','rx5','rx0','rx1','rx2']: # ordering of minipods according to LC num
                if pod in node.getRxPODs():
                    rxpod = node.getRxPOD(pod)
                    logging.info("Reading MiniPOD %s", pod)
                    logging.info("%s 3v3            = %s", pod, rxpod.get3v3())
                    logging.info("%s 2v5            = %s", pod, rxpod.get2v5())
                    logging.info("%s Temp           = %s", pod, rxpod.getTemp())
                    logging.info("%s on time        = %s", pod, rxpod.getOnTime())
                    
                    for i,op in enumerate(rxpod.getOpticalPowers()):
                        opPows.append([pod, op])
                        logging.info('   %02d = %s', i,op)
                
        for node in minipodNodes:
            for pod in node.getTxPODs():
                rxpod = node.getTxPOD(pod)
                logging.info("Reading MiniPOD %s", pod)
                logging.info("%s 3v3            = %s", pod, rxpod.get3v3())
                logging.info("%s 2v5            = %s", pod, rxpod.get2v5())
                logging.info("%s Temp           = %s", pod, rxpod.getTemp())
                logging.info("%s on time        = %s", pod, rxpod.getOnTime())
            
                
        if logicalIds:
            logging.info('Printing link optical powers for logical link IDs...')
            
            for i in range(72):
                logging.info("Minipod %s, chan %i \t Fibre %i    \t Logical link id %i \t=\t %s", opPows[lcToLogicalMap.get(i)-1][0], (lcToLogicalMap.get(i)-1)%12, lcToLogicalMap.get(i), i, opPows[lcToLogicalMap.get(i)-1][1])
            
            # for i in range(72):
                # logging.info("{%02i, {\"\",\"%s\",%i}}", i, opPows[lcToLogicalMap.get(i)-1][0], (lcToLogicalMap.get(i)-1)%12)


class PrintSensors(FunctorInterface):

    @staticmethod
    def run(board):
        logging.info("Retrieving and displaying MP7 sensor information...")
        sensorInfoMap = board.mmcMgr().readSensorInfo()
        sensList = ["Imperial MP7", "MP7 HS\t", "Humidity\t", "FPGA Temp", "+1.0 V\t", "+1.0 I\t", 
                        "+1.5 V\t", "+1.5 I\t", "+1.8 V\t", "+1.8 I\t", "+2.5 V\t", "+2.5 I\t", 
                        "+3.3 V\t", "+3.3 I\t", "MP+3.3 V\t", "MP+3.3 I\t", "+12 V\t", "+12 I\t", 
                        "+1.0 V GTX T", "+1.0 I GTX T", "+1.2 V GTX T", "+1.2 I GTX T", 
                        "+1.8 V GTX T", "+1.8 I GTX T", "+1.0 V GTX B", "+1.0 I GTX B", 
                    "+1.2 V GTX B", "+1.2 I GTX B", "+1.8 V GTX B", "+1.8 I GTX B"]
        
        for i in xrange(2,len(sensorInfoMap)):
            logging.info("%s \t %s", sensList[i], sensorInfoMap[sensList[i]])
        
