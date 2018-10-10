#!/usr/bin/python

#
# Heavily based on C.Lazaridis simpleTcdsControl.py
#
import os.path
import sys
import httplib
import time
from xml.dom.minidom import parseString
import urllib2
import threading
import logging

_log = logging.getLogger('tcds')

def _parseReply(reply):
    dom = parseString(reply)
    d = {}

    return _parseDomReply(dom,d)

def _parseDomReply(dom,d):
    for n in dom.childNodes:
        if n.nodeType == n.TEXT_NODE:
            d[str(n.parentNode.localName)] = str(n.data)
        else:
            _parseDomReply(n,d)

    return d

def _handleFaults(d):
    if d.has_key('faultstring'):
        raise Exception("%s" % d['faultstring'].replace("\n"," "))


class TCDSLeaseHolder(threading.Thread):
    """docstring for TCDSLeaseHolder"""
    def __init__(self, tcdsctrl, period=5):
        super(TCDSLeaseHolder, self).__init__()
        self.tcdsctrl_ = tcdsctrl
        self.period_ = period

    def run(self):
        while self.tcdsctrl_.keepLease_:
            _log.debug('Renewing hardware lease')
            self.tcdsctrl_.sendSoapMsg(self.tcdsctrl_.makeSoapMsg('RenewHardwareLease'))
            time.sleep(self.period_)

class TCDSController(object):

    """docstring for TCDSController"""
    def __init__(self, host, port, lid):
        super(TCDSController, self).__init__()



        self.commands_with_params = ["Configure", "Enable"];
        self.commands_without_params = ["Halt", "Stop", "Pause", "Resume", "RenewHardwareLease", 
                                    "ReadHardwareConfiguration", 
                                    "SendL1A", 
                                    "InitCyclicGenerators",
                                    "EnableTTCSpy","DisableTTCSpy","ResetTTCSpyLog",
                                    "TTCResync", "TTCHardReset"];
        self.commands_ = self.commands_with_params + self.commands_without_params



        self.host_ = host
        self.port_ = port
        self.lid_  = lid


        self.actionRequestorId_ = "TCDS_MP7_DAQ_TESTER"
        self.hwCfgString_ = ""
        self.hwCfgPath_ = None
        self.runNumber_ = 0
        self.keepLease_ = False
        self.leaseHolder_ = None
        self.fedEnableMask_ = None


    def __del__(self):
        self.release()

    def loadHwCfg(self, hw_config_path) :
        self.hwCfgPath_ = os.path.expandvars(hw_config_path)
        
        if not os.path.isfile(self.hwCfgPath_) :
          print "ERROR. Can not open file "+self.hwCfgPath_+""
          sys.exit(2)
        else :
          self.hwCfgString_ = "" 
          
          ifile = open (self.hwCfgPath_, "r")
          
          for line in ifile :
            li=line.strip()
            if not li.startswith("#") :
                self.hwCfgString_ += line
             
        ifile.close()

    def lock(self):
        if self.leaseHolder_ is not None:
            raise RuntimeError('Lease Holder Thread already exists')

        self.leaseHolder_ = TCDSLeaseHolder(self,5)
        self.keepLease_ = True
        self.leaseHolder_.setDaemon(True)
        self.leaseHolder_.start()

    def release(self):
        if self.leaseHolder_ is None:
            return;
        self.keepLease_ = False
        self.leaseHolder_.join()
        self.leaseHolder_ = None
    #
    #
    # make the SOAP command
    # returns the full string of the command
    #
    def makeSoapMsg(self, command):
      if command == "Configure" :
        from xml.sax.saxutils import escape
        soapMessage = ( self.makeCmdHeader(command) 
                    + self.makeSoapParameter('hardwareConfigurationString','string',self.hwCfgString_)
                    + ( self.makeSoapParameter('fedEnableMask', 'string', escape(self.fedEnableMask_)) if self.fedEnableMask_ else '')
                    # + ( self.makeSoapParameter('fedVector', 'string', self.fedEnableMask_) if self.fedEnableMask_ else '')
                    + self.makeCmdFooter(command) )
    
      
      elif command == "Enable" :
        soapMessage =  ( self.makeCmdHeader(command)
                    + self.makeSoapParameter('runNumber', 'unsignedInt', self.runNumber_)
                    + self.makeCmdFooter(command) )
    
      elif str(command).isdigit() :
        soapMessage = ( self.makeCmdHeader("SendBgo")
                     + self.makeSoapParameter('bgoNumber', 'unsignedInt', command)
                     + self.makeCmdFooter("SendBgo") )
    
      else :
        soapMessage = self.makeCmdHeader(command) + self.makeCmdFooter(command)
      
      return soapMessage
    
    def makeSoapParameter(self, name, type, value):
      template = '<xdaq:%s xsi:type="xsd:%s">%s</xdaq:%s>'
    
      return template % (name, type, value, name)
    

    def makeCmdHeader(self, command) :
      template = """<?xml version="1.0" ?>
<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<env:Header/><env:Body><xdaq:%s xdaq:actionRequestorId="%s" xmlns:xdaq="urn:xdaq-soap:3.0">"""
    
      return template %(command,self.actionRequestorId_)
    
    def makeCmdFooter(self, command) :
      template = """</xdaq:%s></env:Body></env:Envelope>"""
      return template %(command)
    

    def sendSoapMsg(self, msg):
        urn = 'urn:xdaq-application:lid='+str(self.lid_)
        url = 'http://'+self.host_+':'+str(self.port_)+'/'+urn
        header = {"SOAPAction":urn}

        req = urllib2.Request(url,msg,header)
        reply = urllib2.urlopen(req).read()

        _log.debug(reply)

        d = _parseReply(reply)
        _log.debug(d)

        _handleFaults(d)

    #
    # send a command
    #
    def sendCmd(self, command):
        if command not in self.commands_ and not (str(command).isdigit() and int(command) >= 0 and int(command) <= 15) :
          raise RuntimeError('ERROR. Unknown command "'+command+'"" requested.')
        
        print "Summary :"
        print "  Sending command : '"+str(command)+"'"
        print "  URL : http://"+self.host_+":"+str(self.port_)+"/urn:xdaq-application:lid="+str(self.lid_)
        print "  Lease actionRequestorId : '"+self.actionRequestorId_+"'"
        if self.hwCfgPath_ and command == "Configure" :
          print "  HwConfig from: '"+self.hwCfgPath_+"'"
        if self.runNumber_ and command == "Enable" :
          print "  Run # : "+str(self.runNumber_)
        print  
        
        data = self.makeSoapMsg(command)
        
        _log.debug('===============================================================================================')
        _log.debug('Sending SOAP message...')
        _log.debug(data)
        _log.debug('===============================================================================================')
        
        self.sendSoapMsg(data)
