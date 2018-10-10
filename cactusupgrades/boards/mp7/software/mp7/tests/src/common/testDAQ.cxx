///////////////////////////////////////////////////////////
// 
// DAQ integration test
//
// code for testing the DAQ link between MP7 and AMC13
// 
// Kristian Harder
// Rutherford Appleton Laboratory
//
////////////////////////////////////////////////////////////


#include "amc13/AMC13.hh"
#include "uhal/uhal.hpp"
#include "mp7/TTCNode.hpp"
#include "mp7/MP7Controller.hpp"
#include "mp7/Logger.hpp"
#include <curlpp/cURLpp.hpp>
#include <curlpp/Easy.hpp>
#include <curlpp/Options.hpp>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <cstdio>

#define FED_ID 0


//==================================================================


class AMC13DAQ {

public:
  AMC13DAQ(const std::string connectionFile);
  void initialize();
  void configureLocalDAQ(const std::vector<unsigned> amcSlotList);
  void configureFEROLDAQ(const std::vector<unsigned> amcSlotList);
  void dumpRegisters(std::string& dumpString);
  void sendTTCCommand(const uint8_t bitPattern, const uint32_t bx);
  void startRun(const unsigned numTriggers);
  void sendTriggerBurst();
  void endRun();
  bool checkStatus();
  void downloadEvents(std::vector<uint64_t>& data,
		      std::vector<uint32_t>& eventOffsets);

private:
  void configureDAQ(const std::vector<unsigned> amcSlotList, bool local);
  amc13::AMC13* amc13;
  std::vector<unsigned> amcSlots;
};


AMC13DAQ::AMC13DAQ(const std::string connectionFile){

  amc13 = new amc13::AMC13("etc/mp7/connections-RAL.xml");

  // reload FPGAs from flash. This is currently the only way of
  // resetting all registers to default values
  std::cout << "reloading AMC13 FPGAs. Please wait 10 seconds..." << std::endl;
  amc13->getFlash()->loadFlash();
  delete amc13;

  // wait for FPGAs to be reconfigured.
  // yes, this takes a long time. 5 seconds is not enough.
  sleep(10);

  // now connect to AMC13 again
  amc13 = new amc13::AMC13("etc/mp7/connections-RAL.xml");  

  unsigned firmware_version_T1 = amc13->read(amc13::AMC13::T1,"STATUS.FIRMWARE_VERS");
  unsigned firmware_version_T2 = amc13->read(amc13::AMC13::T2,"STATUS.FIRMWARE_VERS");
  std::cout << "AMC13 firmware version 0x" << std::hex << firmware_version_T1
	    << " / 0x" << firmware_version_T2 << std::endl;
}



void AMC13DAQ::initialize() {

  // general reset
  amc13->reset(amc13::AMC13::T1);
  amc13->reset(amc13::AMC13::T2);
  amc13->endRun();

  // set delay for BC0
  amc13->write(amc13::AMC13::T1,"CONF.BCN_OFFSET",0);

  // configure TTC commands
  amc13->setOcrCommand(0x8);

  // enable local TTC signal generation (for loopback fibre)
  amc13->localTtcSignalEnable(true);

  // activate TTC output to all AMCs
  amc13->enableAllTTC();
}


void AMC13DAQ::configureDAQ(const std::vector<unsigned> amcSlotList, bool local) {

  // store slot IDs for later
  amcSlots = amcSlotList;

  // set FED ID and S-link ID
  if (FED_ID>0xfff || FED_ID%4!=0) {
    std::cout << "ERROR: FED_ID is invalid" << std::endl;
    exit(1);
  }
  amc13->setFEDid(FED_ID); // notes this sets the CONF.ID.SOURCE_ID register
  amc13->write(amc13::AMC13::T1,"CONF.ID.FED_ID",FED_ID);

  // enable incoming DAQ link.
  // Note that an MP7 reset brings down the DAQ link, and it has to be
  // re-enabled with the following command on the AMC13 afterwards!
  // Note also that you must not enable channels here that we are not
  // expecting data from. Enaqbled but unconnected channels seem to prevent
  // the AMC13 from building events.
  // bit mask:  0x001 = slot  1
  //            0x002 = slot  2
  //            0x004 = slot  3
  //            ...
  //            0x800 = slot 12
  unsigned bitmask = 0;
  for (unsigned i=0; i<amcSlots.size(); i++) {
    bitmask+=(1<<(amcSlots[i]-1));
  }
  amc13->AMCInputEnable(bitmask);

  // enable outgoing DAQ link on the topmost SFP if readou via FEROL
  // note that if the daq link is enabled,
  // you cannot read events from the AMC13 monitoring buffer
  amc13->daqLinkEnable(!local);
  amc13->sfpOutputEnable(1);
  amc13->resetDAQ();
}


void AMC13DAQ::configureLocalDAQ(const std::vector<unsigned> amcSlotList) {
  configureDAQ(amcSlotList,true);
}


void AMC13DAQ::configureFEROLDAQ(const std::vector<unsigned> amcSlotList) {
  configureDAQ(amcSlotList,false);
}


void AMC13DAQ::sendTTCCommand(const uint8_t bitPattern, const uint32_t bx) {
  amc13->write(amc13::AMC13::T1,"CONF.TTC.BGO0.COMMAND",bitPattern);
  amc13->write(amc13::AMC13::T1,"CONF.TTC.BGO0.LONG_CMD",0);
  amc13->write(amc13::AMC13::T1,"CONF.TTC.BGO0.BX",bx);
  amc13->write(amc13::AMC13::T1,"CONF.TTC.BGO0.ORBIT_PRESCALE",0);
  amc13->write(amc13::AMC13::T1,"CONF.TTC.BGO0.ENABLE",1);
  sleep(0.002);
  amc13->write(amc13::AMC13::T1,"CONF.TTC.BGO0.ENABLE",0);
}

void AMC13DAQ::startRun(const unsigned numTriggers) {

  // configure local L1A generation
  // this one is for one burst per orbit, at BX 500
  amc13->configureLocalL1A(true,0,numTriggers,1,0);
  amc13->enableLocalL1A(true);
  
  amc13->startRun();

  // align counters;
  amc13->sendLocalEvnOrnReset(1,1);
}


void AMC13DAQ::sendTriggerBurst() {

   // send triggers
  amc13->sendL1ABurst();
}


void AMC13DAQ::endRun() {

  amc13->endRun();
}


void AMC13DAQ::dumpRegisters(std::string& dumpString) {

  std::stringstream log;

  for (unsigned i=0; i<amcSlots.size(); i++) {
    char slotChar[3];
    std::sprintf(slotChar,"%02i",amcSlots[i]);
    std::string slotString=slotChar;

    // dump relevant AMC13 registers
    std::vector<std::string> amc13registers;
    amc13registers.push_back("STATUS.AMC"+slotString+".AMC_LINK_READY_MASK");
    amc13registers.push_back("STATUS.AMC"+slotString+".LINK_BUFFER_FULL");
    amc13registers.push_back("STATUS.AMC"+slotString+".LINK_VERS_WRONG_MASK");
    amc13registers.push_back("STATUS.AMC"+slotString+".LOSS_OF_SYNC_MASK");
    // TTS bit meanings: MSB..LSB = DIS,ERR,SYN,BSY,OFW
    amc13registers.push_back("STATUS.AMC"+slotString+".TTS_ENCODED");
    amc13registers.push_back("STATUS.AMC_TTS_STATE");
    amc13registers.push_back("STATUS.EVB.OVERFLOW_WARNING");
    amc13registers.push_back("STATUS.MONITOR_BUFFER.UNREAD_EVENTS");

    // the following registers refer to the trigger link back from AMC to AMC13
    // which is not currently used on the MP7. Thus let's not print them.
    //amc13registers.push_back("STATUS.AMC"+slotString+".BC0_LOCKED_MASK");
    //amc13registers.push_back("STATUS.AMC"+slotString+".TTC_LOCKED_MASK");

    for (unsigned i=0; i<amc13registers.size(); i++) {
      log << amc13registers[i] << ": "
	  << amc13->read(amc13::AMC13::T1,amc13registers[i]) << std::endl;
    }
  }

  dumpString = log.str();
}


void AMC13DAQ::downloadEvents(std::vector<uint64_t>& data,
			      std::vector<uint32_t>& eventOffsets) {

  data.clear();

  // believe it or not, but downloading events only works in run mode!
  if (!amc13->read(amc13::AMC13::T1,"CONF.RUN")) {
    std::cout << "ERROR: must be in run mode to download data from AMC13"
	      << std::endl;
    return;
  }

  int rc=0;
  while (rc==0) {
    size_t nwords=999;
    rc=99;
    uint64_t* evPtr = amc13->readEvent(nwords,rc);
    if (rc==0) {
      eventOffsets.push_back(data.size());
      for (size_t i=0; i<nwords; i++) {
	data.push_back(evPtr[i]);
      }
    }
  }
}


//==================================================================


class MP7DAQ {

public:
  MP7DAQ(const std::string connectionFile, const std::string deviceName);
  void initialize();
  void configureLocalDAQ();
  void configureAMC13DAQ();
  void setEventSize(uint32_t size);
  void enableFakeData(bool fullDAQPath);
  void dumpRegisters(std::string& dumpString);
  bool checkStatus();
  void downloadEvents(std::vector<uint64_t>& data,
		      std::vector<uint32_t>& eventOffsets);
  void dumpTTCHistory();

private:
  void configureDAQ(bool local);

  uhal::HwInterface* mp7hw;
  mp7::MP7Controller* mp7;
  std::string deviceString;
  uint32_t eventSize;
};


MP7DAQ::MP7DAQ(const std::string connectionFile, const std::string deviceName) {

  // establish connection
  uhal::ConnectionManager conn("file://"+connectionFile);
  mp7hw = new uhal::HwInterface(conn.getDevice(deviceName));
  mp7 = new mp7::MP7Controller(*mp7hw);
  mp7::logger::Log::setLogThreshold(mp7::logger::LogLevel::kError);
  deviceString = deviceName;
  eventSize=0;
}


void MP7DAQ::initialize() {

  // general reset and configuration for external clock
  mp7->reset("external","external","amc13xg_6slx25t");

  // configure TTC history record
  // bit 0 on: ignore BC0
  // bit 1 on: ignore L1A
  mp7->getTTC().maskHistoryBC0L1a(1);

}


void MP7DAQ::configureDAQ(bool local) {

  // set TTS status by hand.
  // 1 = warning
  // 2 = out of sync
  // 4 = busy
  // 8 = ready
  // 12 = error
  // 0 or 15 = disconnected
  //mp7hw->getNode("readout.tts_csr.ctrl.tts_force").write(1);
  //mp7hw->getNode("readout.tts_csr.ctrl.tts").write(8);
  mp7hw->getNode("readout.tts_csr.ctrl.tts_force").write(0);

  // declare the board ready for readout
  mp7hw->getNode("readout.tts_csr.ctrl.board_rdy").write(1);

  // configure DAQ buffer in MP7. if this is set to 1, your buffer
  // is likely to drain faster than you can read it :-)
  mp7hw->getNode("readout.csr.ctrl.auto_empty").write(0);

  // determine event size
  mp7hw->getNode("readout.csr.ctrl.fake_evt_size").write(eventSize);

  //mp7hw->getNode("readout.readout_ctrl.csr.ctrl.sel").write(0);
  mp7hw->getNode("readout.readout_ctrl.mode.l1a_delay").write(0);
  const unsigned capsize=1; // number of bunch crossings to be captured per buffer
  mp7hw->getNode("readout.readout_ctrl.mode.capture_size").write(capsize);
  //mp7hw->getNode("readout.readout_ctrl.mode.event_size").write(4*(capsize+1)+3);
  mp7hw->getNode("readout.readout_ctrl.mode.event_size").write(eventSize);
  mp7hw->getNode("readout.readout_ctrl.mode.token_delay").write(30);
  mp7hw->getNode("readout.readout_ctrl.mode.bank_capture_mask").write(3);
  mp7hw->getNode("readout.readout_ctrl.mode.evt_trig").write(1);

  // enable DAQ link if we are not planning to use local DAQ
  if (!local) {
    mp7hw->getNode("readout.csr.ctrl.amc13_en").write(1);
  } else {
    mp7hw->getNode("readout.csr.ctrl.amc13_en").write(0);
  }
  mp7hw->dispatch();
}


void MP7DAQ::configureLocalDAQ() {
  configureDAQ(true);
}


void MP7DAQ::configureAMC13DAQ() {
  configureDAQ(false);
}


void MP7DAQ::setEventSize(uint32_t size) {
  eventSize=size;
}


void MP7DAQ::enableFakeData(bool fullDAQPath) {

  if (!fullDAQPath) {
    // enable fake data generator in mp7_readout block
    mp7hw->getNode("readout.csr.ctrl.src_sel").write(1);
    mp7hw->dispatch();
  } else {
    // disable fake data generator in mp7_readout block,
    // to allow the actual DAQ bus to fill the readout buffer
    mp7hw->getNode("readout.csr.ctrl.src_sel").write(0);
    mp7hw->dispatch();
    //std::cout << "KHDEBUG: NOW!!!" << std::endl;
    //system(("bash -c \"cd /data/pff62257/daqtest/mp7/tests; source env.sh; mp7butler.py -c file://etc/mp7/connections-RAL.xml buffers "+deviceString+" daqTest\"").c_str());
    //std::cout << "KHDEBUG: WOW!!!" << std::endl;
  }
}


void MP7DAQ::dumpRegisters(std::string& dumpString) {

  // dump relevant MP7 registers
  std::vector<std::string> mp7registers;
  mp7registers.push_back("ttc.csr.stat0.bc0_lock");
  mp7registers.push_back("ttc.csr.stat1.evt_ctr");
  mp7registers.push_back("readout.csr.stat.amc13_rdy");
  mp7registers.push_back("readout.csr.stat.amc13_warn");
  mp7registers.push_back("readout.csr.stat.src_err");
  mp7registers.push_back("readout.csr.stat.rob_err");
  mp7registers.push_back("readout.csr.evt_count");
  mp7registers.push_back("readout.tts_csr.stat.tts_stat");


  std::vector<uhal::ValWord<uint32_t> > mp7results;
  for (unsigned i=0; i<mp7registers.size(); i++) {
    mp7results.push_back(mp7hw->getNode(mp7registers[i]).read());
  }
  mp7hw->dispatch();

  std::stringstream log;
  for (unsigned i=0; i<mp7registers.size(); i++) {
    log << mp7registers[i] << ": " << mp7results[i] << std::endl;
  }
  dumpString = log.str();
}


void MP7DAQ::downloadEvents(std::vector<uint64_t>& data,
			    std::vector<uint32_t>& eventOffsets) {

  uhal::ValWord<uint32_t> fifo_cnt=mp7hw->getNode("readout.buffer.fifo_flags.fifo_cnt").read();
  mp7hw->dispatch();
  data.clear();
  unsigned maxwords=10000000;
  unsigned iword=0;
  while (fifo_cnt && iword<maxwords) {
    iword+=fifo_cnt;
    uhal::ValWord<uint32_t> fifo_valid=mp7hw->getNode("readout.buffer.fifo_flags.fifo_valid").read();
    uhal::ValWord<uint32_t> fifo_empty=mp7hw->getNode("readout.buffer.fifo_flags.fifo_empty").read();
    uhal::ValWord<uint32_t> fifo_warn=mp7hw->getNode("readout.buffer.fifo_flags.fifo_warn").read();
    uhal::ValWord<uint32_t> fifo_full=mp7hw->getNode("readout.buffer.fifo_flags.fifo_full").read();
    uhal::ValVector<uint32_t> datablock=mp7hw->getNode("readout.buffer.data").readBlock(3*fifo_cnt);
    mp7hw->dispatch();
    for (uint32_t i=0; i<fifo_cnt; i++) {
      uint32_t data_low=datablock[i*3];
      uint32_t data_high=datablock[i*3+1];
      uint32_t data_flags=datablock[i*3+2];
      bool daq_start = (data_flags & 0x8);  // identical to amc13_header
      bool daq_valid = (data_flags & 0x4);
      bool daq_start_del = (data_flags & 0x2);
      bool daq_valid_del = (data_flags & 0x1);
      bool amc13_trailer = (data_flags & 0x40);
      bool amc13_header = (data_flags & 0x80);
      if (amc13_header && !amc13_trailer) eventOffsets.push_back(data.size());
      if (false) {
	std::cout << std::setw(4) << std::dec << data.size() << ": " << std::hex << std::setw(16) << (uint64_t(data_high)<<32)+data_low;
	if (fifo_valid) std::cout << " valid"; else std::cout << "      ";
	if (fifo_empty) std::cout << " empty"; else std::cout << "      ";
	if (daq_valid) std::cout << " daqvalid0"; else std::cout << "           ";
	if (daq_valid_del) std::cout << " daqvalid1"; else std::cout << "           ";
	if (daq_start) std::cout << " daqstart0"; else std::cout << "           ";
	if (daq_start_del) std::cout << " daqstart1"; else std::cout << "           ";
	if (amc13_header) std::cout << " amc13hdr"; else std::cout << "         ";
	if (amc13_trailer) std::cout << " amc13trl"; else std::cout << "         ";
	std::cout << std::endl;
      }
      if (fifo_valid) {
	data.push_back((uint64_t(data_high)<<32)+data_low);
      }
    }
    fifo_cnt=mp7hw->getNode("readout.buffer.fifo_flags.fifo_cnt").read();
    mp7hw->dispatch();
  }
  if (iword==maxwords) {
    std::cout << "DATA ERROR: read " << maxwords << " words from FIFO without emptying it" << std::endl;
  }
}


void MP7DAQ::dumpTTCHistory() {

  std::vector<mp7::TTCHistoryEntry> hist;

  hist = mp7->getTTC().captureHistory();
  std::cout << "TTC history: " << std::endl;
  for (unsigned i=0; i<hist.size(); i++) {
    mp7::TTCHistoryEntry& e = hist[i];
    std::cout << "TTC hist #" << std::dec << std::setw(3) << i << ": orbit=" << e.orbit << ", bx=" << e.bx
	      << " event=" << e.event << ", l1a=" << e.l1a
	      << ", cmd=" << std::hex << e.cmd << std::endl;
  }
  
}

//==================================================================


class FEROLDAQ {

public:
  FEROLDAQ();
  ~FEROLDAQ();
  void initialize();
  void startRun();
  void endRun();
  void downloadEvents(std::vector<uint64_t>& data,
		      std::vector<uint32_t>& eventOffsets);

private:
  int xdaq_pid1, xdaq_pid2;
};


FEROLDAQ::FEROLDAQ() {

  unsigned xdaqPort = 33000;
  unsigned ferolDestPort = 34000;
  std::string hostName = "heplnw236.pp.rl.ac.uk";
  std::string outputDir = "/tmp";
  unsigned runNumber = 100;

  std::fstream config(outputDir+"/fedkit_config.xml",std::fstream::out);

  config << "<xc:Partition xmlns:soapenc=\"http://schemas.xmlsoap.org/soap/encoding/\""
	 << " xmlns:xc=\"http://xdaq.web.cern.ch/xdaq/xsd/2004/XMLConfiguration-30\""
	 << " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">";

  // ferolController context
  config << "<xc:Context url=\"http://" << hostName << ":" << xdaqPort << "\">";
  config << "<xc:Application class=\"ferol::FerolController\" id=\"11\" instance=\"0\" network=\"local\" service=\"ferolcontroller\">";
  config << "<properties xmlns=\"urn:xdaq-application:ferol::FerolController\" xsi:type=\"soapenc:Struct\">";
  config << "<slotNumber xsi:type=\"xsd:unsignedInt\">0</slotNumber>";
  config << "<expectedFedId_0 xsi:type=\"xsd:unsignedInt\">" << FED_ID << "</expectedFedId_0>";
  config << "<expectedFedId_1 xsi:type=\"xsd:unsignedInt\">1</expectedFedId_1>";
  config << "<SourceIP xsi:type=\"xsd:string\">10.0.0.4</SourceIP>";
  config << "<TCP_SOURCE_PORT_FED0 xsi:type=\"xsd:unsignedInt\">10</TCP_SOURCE_PORT_FED0>";
  config << "<TCP_SOURCE_PORT_FED1 xsi:type=\"xsd:unsignedInt\">11</TCP_SOURCE_PORT_FED1>";
  config << "<enableStream0 xsi:type=\"xsd:boolean\">true</enableStream0>";
  config << "<enableStream1 xsi:type=\"xsd:boolean\">false</enableStream1>";
  config << "<OperationMode xsi:type=\"xsd:string\">FEDKIT_MODE</OperationMode>";
  config << "<DataSource xsi:type=\"xsd:string\">L6G_SOURCE</DataSource>";
  config << "<FrlTriggerMode xsi:type=\"xsd:string\">FRL_AUTO_TRIGGER_MODE</FrlTriggerMode>";
  config << "<DestinationIP xsi:type=\"xsd:string\">10.0.0.5</DestinationIP>";
  config << "<TCP_DESTINATION_PORT_FED0 xsi:type=\"xsd:unsignedInt\">" << ferolDestPort << "</TCP_DESTINATION_PORT_FED0>";
  config << "<TCP_DESTINATION_PORT_FED1 xsi:type=\"xsd:unsignedInt\">" << ferolDestPort << "</TCP_DESTINATION_PORT_FED1>";
  config << "<N_Descriptors_FRL xsi:type=\"xsd:unsignedInt\">8192</N_Descriptors_FRL>";
  config << "<Seed_FED0 xsi:type=\"xsd:unsignedInt\">14462</Seed_FED0>";
  config << "<Seed_FED1 xsi:type=\"xsd:unsignedInt\">14463</Seed_FED1>";
  config << "<Event_Length_bytes_FED0 xsi:type=\"xsd:unsignedInt\">2048</Event_Length_bytes_FED0>";
  config << "<Event_Length_bytes_FED1 xsi:type=\"xsd:unsignedInt\">2048</Event_Length_bytes_FED1>";
  config << "<Event_Length_Stdev_bytes_FED0 xsi:type=\"xsd:unsignedInt\">0</Event_Length_Stdev_bytes_FED0>";
  config << "<Event_Length_Stdev_bytes_FED1 xsi:type=\"xsd:unsignedInt\">0</Event_Length_Stdev_bytes_FED1>";
  config << "<Event_Length_Max_bytes_FED0 xsi:type=\"xsd:unsignedInt\">65000</Event_Length_Max_bytes_FED0>";
  config << "<Event_Length_Max_bytes_FED1 xsi:type=\"xsd:unsignedInt\">65000</Event_Length_Max_bytes_FED1>";
  config << "<Event_Delay_ns_FED0 xsi:type=\"xsd:unsignedInt\">20</Event_Delay_ns_FED0>";
  config << "<Event_Delay_ns_FED1 xsi:type=\"xsd:unsignedInt\">20</Event_Delay_ns_FED1>";
  config << "<Event_Delay_Stdev_ns_FED0 xsi:type=\"xsd:unsignedInt\">0</Event_Delay_Stdev_ns_FED0>";
  config << "<Event_Delay_Stdev_ns_FED1 xsi:type=\"xsd:unsignedInt\">0</Event_Delay_Stdev_ns_FED1>";
  config << "<TCP_CWND_FED0 xsi:type=\"xsd:unsignedInt\">80000</TCP_CWND_FED0>";
  config << "<TCP_CWND_FED1 xsi:type=\"xsd:unsignedInt\">80000</TCP_CWND_FED1>";
  config << "<ENA_PAUSE_FRAME xsi:type=\"xsd:boolean\">true</ENA_PAUSE_FRAME>";
  config << "<MAX_ARP_Tries xsi:type=\"xsd:unsignedInt\">20</MAX_ARP_Tries>";
  config << "<ARP_Timeout_Ms xsi:type=\"xsd:unsignedInt\">1500</ARP_Timeout_Ms>";
  config << "<Connection_Timeout_Ms xsi:type=\"xsd:unsignedInt\">7000</Connection_Timeout_Ms>";
  config << "<enableSpy xsi:type=\"xsd:boolean\">false</enableSpy>";
  config << "<deltaTMonMs xsi:type=\"xsd:unsignedInt\">1000</deltaTMonMs>";
  config << "<TCP_CONFIGURATION_FED0 xsi:type=\"xsd:unsignedInt\">16384</TCP_CONFIGURATION_FED0>";
  config << "<TCP_CONFIGURATION_FED1 xsi:type=\"xsd:unsignedInt\">16384</TCP_CONFIGURATION_FED1>";
  config << "<TCP_OPTIONS_MSS_SCALE_FED0 xsi:type=\"xsd:unsignedInt\">74496</TCP_OPTIONS_MSS_SCALE_FED0>";
  config << "<TCP_OPTIONS_MSS_SCALE_FED1 xsi:type=\"xsd:unsignedInt\">74496</TCP_OPTIONS_MSS_SCALE_FED1>";
  config << "<TCP_TIMER_RTT_FED0 xsi:type=\"xsd:unsignedInt\">312500</TCP_TIMER_RTT_FED0>";
  config << "<TCP_TIMER_RTT_FED1 xsi:type=\"xsd:unsignedInt\">312500</TCP_TIMER_RTT_FED1>";
  config << "<TCP_TIMER_RTT_SYN_FED0 xsi:type=\"xsd:unsignedInt\">312500000</TCP_TIMER_RTT_SYN_FED0>";
  config << "<TCP_TIMER_RTT_SYN_FED1 xsi:type=\"xsd:unsignedInt\">312500000</TCP_TIMER_RTT_SYN_FED1>";
  config << "<TCP_TIMER_PERSIST_FED0 xsi:type=\"xsd:unsignedInt\">40000</TCP_TIMER_PERSIST_FED0>";
  config << "<TCP_TIMER_PERSIST_FED1 xsi:type=\"xsd:unsignedInt\">40000</TCP_TIMER_PERSIST_FED1>";
  config << "<TCP_REXMTTHRESH_FED0 xsi:type=\"xsd:unsignedInt\">3</TCP_REXMTTHRESH_FED0>";
  config << "<TCP_REXMTTHRESH_FED1 xsi:type=\"xsd:unsignedInt\">3</TCP_REXMTTHRESH_FED1>";
  config << "<TCP_REXMTCWND_SHIFT_FED0 xsi:type=\"xsd:unsignedInt\">6</TCP_REXMTCWND_SHIFT_FED0>";
  config << "<TCP_REXMTCWND_SHIFT_FED1 xsi:type=\"xsd:unsignedInt\">6</TCP_REXMTCWND_SHIFT_FED1>";
  config << "<!--N_Descriptors_FED0 xsi:type=\"xsd:unsignedInt\">4</N_Descriptors_FED0>";
  config << "<TCP_SOCKET_BUFFER_DDR xsi:type=\"xsd:boolean\">false</TCP_SOCKET_BUFFER_DDR>";
  config << "<DDR_memory_mask xsi:type=\"xsd:unsignedInt\">0x0fffffff</DDR_memory_mask>";
  config << "<QDR_memory_mask xsi:type=\"xsd:unsignedInt\">0x007fffff</QDR_memory_mask>";
  config << "<lightStop xsi:type=\"xsd:boolean\">false</lightStop-->";
  config << "</properties>";
  config << "</xc:Application>";
  config << "<xc:Module>/opt/xdaq/lib/libFerolController.so</xc:Module>";
  config << "</xc:Context>";

  // EvB context
  config << "<xc:Context url=\"http://" << hostName << ":" << xdaqPort+1 << "\">";

  config << "<xc:Endpoint protocol=\"ftcp\" service=\"frl\" hostname=\"10.0.0.5\" port=\""
	 << ferolDestPort << "\" network=\"ferol00\" sndTimeout=\"2000\" rcvTimeout=\"0\""
	 << " targetId=\"12\" singleThread=\"true\" pollingCycle=\"4\" rmode=\"select\""
	 << " nonblock=\"true\" datagramSize=\"131072\" />";
  
  config << "<xc:Application class=\"pt::frl::Application\" id=\"10\" instance=\"1\" network=\"local\">";
  config << "<properties xmlns=\"urn:xdaq-application:pt::frl::Application\" xsi:type=\"soapenc:Struct\">";
  config << "<frlRouting xsi:type=\"soapenc:Array\" soapenc:arrayType=\"xsd:ur-type[1]\">";
  config << "<item xsi:type=\"soapenc:Struct\" soapenc:position=\"[0]\">";
  config << "<fedid xsi:type=\"xsd:string\">" << FED_ID << "</fedid>";
  config << "<className xsi:type=\"xsd:string\">evb::EVM</className>";
  config << "<instance xsi:type=\"xsd:string\">0</instance>";
  config << "</item>";
  config << "</frlRouting>";
  config << "<frlDispatcher xsi:type=\"xsd:string\">copy</frlDispatcher>";
  config << "<useUdaplPool xsi:type=\"xsd:boolean\">true</useUdaplPool>";
  config << "<autoConnect xsi:type=\"xsd:boolean\">false</autoConnect>";
  config << "<!-- Copy worker configuration -->";
  config << "<i2oFragmentBlockSize xsi:type=\"xsd:unsignedInt\">32768</i2oFragmentBlockSize>";
  config << "<i2oFragmentsNo xsi:type=\"xsd:unsignedInt\">128</i2oFragmentsNo>";
  config << "<i2oFragmentPoolSize xsi:type=\"xsd:unsignedInt\">10000000</i2oFragmentPoolSize>";
  config << "<copyWorkerQueueSize xsi:type=\"xsd:unsignedInt\">16</copyWorkerQueueSize>";
  config << "<copyWorkersNo xsi:type=\"xsd:unsignedInt\">1</copyWorkersNo>";
  config << "<!-- Super fragment configuration -->";
  config << "<doSuperFragment xsi:type=\"xsd:boolean\">false</doSuperFragment>";
  config << "<!-- Input configuration e.g. PSP -->";
  config << "<inputStreamPoolSize xsi:type=\"xsd:double\">1400000</inputStreamPoolSize>";
  config << "<maxClients xsi:type=\"xsd:unsignedInt\">5</maxClients>";
  config << "<ioQueueSize xsi:type=\"xsd:unsignedInt\">64</ioQueueSize>";
  config << "<eventQueueSize xsi:type=\"xsd:unsignedInt\">64</eventQueueSize>";
  config << "<maxInputReceiveBuffers xsi:type=\"xsd:unsignedInt\">8</maxInputReceiveBuffers>";
  config << "<maxInputBlockSize xsi:type=\"xsd:unsignedInt\">131072</maxInputBlockSize>";
  config << "</properties>";
  config << "</xc:Application>";

  config << "<xc:Application class=\"evb::EVM\" id=\"12\" instance=\"0\" network=\"local\">";
  config << "<properties xmlns=\"urn:xdaq-application:evb::EVM\" xsi:type=\"soapenc:Struct\">";
  config << "<inputSource xsi:type=\"xsd:string\">FEROL</inputSource>";
  config << "<runNumber xsi:type=\"xsd:unsignedInt\">" << runNumber << "</runNumber>";
  config << "<fakeLumiSectionDuration xsi:type=\"xsd:unsignedInt\">20</fakeLumiSectionDuration>";
  config << "<numberOfResponders xsi:type=\"xsd:unsignedInt\">1</numberOfResponders>";
  config << "<checkCRC xsi:type=\"xsd:unsignedInt\">1</checkCRC>";
  config << "<fedSourceIds soapenc:arrayType=\"xsd:ur-type[1]\" xsi:type=\"soapenc:Array\">";
  config << "<item soapenc:position=\"[0]\" xsi:type=\"xsd:unsignedInt\">" << FED_ID << "</item>";
  config << "</fedSourceIds>";
  config << "</properties>";
  config << "</xc:Application>";

  config << "<xc:Application class=\"evb::BU\" id=\"13\" instance=\"0\" network=\"local\">";
  config << "<properties xmlns=\"urn:xdaq-application:evb::BU\" xsi:type=\"soapenc:Struct\">";
  config << "<runNumber xsi:type=\"xsd:unsignedInt\">" << runNumber << "</runNumber>";
  config << "<dropEventData xsi:type=\"xsd:boolean\">false</dropEventData>";
  config << "<lumiSectionTimeout xsi:type=\"xsd:unsignedInt\">30</lumiSectionTimeout>";
  config << "<numberOfBuilders xsi:type=\"xsd:unsignedInt\">1</numberOfBuilders>";
  config << "<checkCRC xsi:type=\"xsd:unsignedInt\">1</checkCRC>";
  config << "<rawDataDir xsi:type=\"xsd:string\">" << outputDir << "</rawDataDir>";
  config << "<metaDataDir xsi:type=\"xsd:string\">" << outputDir << "</metaDataDir>";
  config << "<rawDataHighWaterMark xsi:type=\"xsd:double\">0.99</rawDataHighWaterMark>";
  config << "<rawDataLowWaterMark xsi:type=\"xsd:double\">0.9</rawDataLowWaterMark>";
  config << "</properties>";
  config << "</xc:Application>";

  config << "<xc:Module>/opt/xdaq/lib/libtcpla.so</xc:Module>";
  config << "<xc:Module>/opt/xdaq/lib/libptfrl.so</xc:Module>";
  config << "<xc:Module>/opt/xdaq/lib/libptutcp.so</xc:Module>";
  config << "<xc:Module>/opt/xdaq/lib/libxdaq2rc.so</xc:Module>";
  config << "<xc:Module>/opt/xdaq/lib/libevb.so</xc:Module>";

  config << "</xc:Context>";

  config << "<i2o:protocol xmlns:i2o=\"http://xdaq.web.cern.ch/xdaq/xsd/2004/I2OConfiguration-30\">";
  config << "<i2o:target class=\"evb::EVM\" instance=\"0\" tid=\"1\"/>";
  config << "<i2o:target class=\"evb::BU\" instance=\"0\" tid=\"30\"/>";
  config << "</i2o:protocol>";


  config << "</xc:Partition>";

  config.close();

  // start XDAQ processes
  xdaq_pid1 = fork();
  xdaq_pid2 = 0;
  if (xdaq_pid1==0) {
    std::cout << "running xdaq1" << std::endl;
    char commandString[500];
    sprintf(commandString,"/opt/xdaq/bin/xdaq.exe -p %i -lDEBUG -c %s/fedkit_config.xml &> %s/fedkit_%i.log",
	    xdaqPort,outputDir.c_str(),outputDir.c_str(),xdaqPort);
    system(commandString);
    std::cout << "XDAQ process 1 quit prematurely" << std::endl;
    exit(1);
  } else {
    xdaq_pid2=fork();
    if (xdaq_pid2==0) {
      std::cout << "running xdaq2" << std::endl;
      char commandString[500];
      sprintf(commandString,"/opt/xdaq/bin/xdaq.exe -p %i -lDEBUG -c %s/fedkit_config.xml &> %s/fedkit_%i.log",
	      xdaqPort+1,outputDir.c_str(),outputDir.c_str(),xdaqPort+1);
      system(commandString);
      std::cout << "XDAQ process 2 quit prematurely" << std::endl;
      exit(1);
    }
  }
}




  // start or stop run with
  /*
    urn = "urn:xdaq-application:class="+app+",instance="+str(instance)
    soapMessage = self._soapTemplate%("<xdaq:"+command+" xmlns:xdaq=\"urn:xdaq-soap:3.0\"/>")
    headers = {"Content-Type":"text/xml",
    "Content-Description":"SOAP Message",
    "SOAPAction":urn}
    server = httplib.HTTPConnection(self._host,self._port)
    #server.set_debuglevel(4)
    server.request("POST","",soapMessage,headers)
    response = server.getresponse().read()
    xmldoc = minidom.parseString(response)
    xdaqResponse = xmldoc.getElementsByTagName('xdaq:'+command+'Response')
    if len(xdaqResponse) == 0:
    xdaqResponse = xmldoc.getElementsByTagName('xdaq:'+command.lower()+'Response')
    if len(xdaqResponse) != 1:
    raise(SOAPexception("Did not get a proper FSM response from "+app+":"+str(instance)+":\n"+xmldoc.toprettyxml()))
    try:
    newState = xdaqResponse[0].firstChild.attributes['xdaq:stateName'].value
    except (AttributeError,KeyError):
    raise(SOAPexception("FSM response from "+app+":"+str(instance)+" is missing state name:\n"+xmldoc.toprettyxml()))
  */


FEROLDAQ::~FEROLDAQ() {
  std::cout << "killing XDAQ processes " << xdaq_pid1 << ", " << xdaq_pid2 << std::endl;
  //kill(xdaq_pid1,15);
  //kill(xdaq_pid2,15);
}


//==================================================================

bool rawread(std::fstream& rawdata, uint64_t& word) {
  if (!rawdata.eof()) {
    rawdata.read((char*)&word, sizeof(word));
    std::cout << std::hex << std::setw(16) << std::setfill('0') << word << std::endl;
    return true;
  } else {
    std::cout << "EOF-EOF-EOF-EOF" << std::endl;
    word=0x0;
    return false;
  }
}
    
//==================================================================


class AMCdata {

public:
  AMCdata(std::fstream& rawdata);
  uint32_t length;
  uint32_t slotnum;
  uint32_t bxid;
  uint32_t l1aid;
  uint32_t orbitnum;
  uint32_t boardid;
  uint32_t userdata;
  uint32_t reserve1;
  std::vector<uint64_t> payload;
  uint32_t length2;
  uint32_t reserve2;
  uint32_t l1aid2;
  uint32_t crc32;
  bool valid;
};


AMCdata::AMCdata(std::fstream& rawdata) {

  std::cout << "------------amcdata header" << std::endl;

  uint64_t header1;
  valid=rawread(rawdata, header1);
  if (!valid) return;
  length   = header1       &    0xfffff;
  bxid     = (header1>>20) &      0xfff;
  l1aid    = (header1>>32) &   0xffffff;
  slotnum  = (header1>>56) &        0xf;
  reserve1 = (header1>>60);

  uint64_t header2;
  valid&=rawread(rawdata, header2);
  if (!valid) return;
  boardid  = header2       &     0xffff;
  orbitnum = (header2>>16) &     0xffff;
  userdata = (header2>>32);

  std::cout << "----------------amcdata payload" << std::endl;

  payload.clear();
  uint64_t data;
  for (unsigned i=0; i<length-3; i++) {
    valid&=rawread(rawdata,data);
    if (!valid) return;
    payload.push_back(data);
  }

  std::cout << "---------------amcdata trailer" << std::endl;

  uint64_t trailer;
  valid&=rawread(rawdata, trailer);
  if (!valid) return;
  length2  = trailer       &    0xfffff;
  reserve2 = (trailer>>20) &        0xf;
  l1aid2   = (trailer>>24) &       0xff;
  crc32    = (trailer>>32);
};


//==================================================================


class AMC13Block {

public:
  AMC13Block(std::fstream& rawdata);
  uint32_t reserve1;
  uint32_t orbitnum;
  uint32_t reserve2;
  uint32_t numamc;
  uint32_t reserve3;
  uint32_t ufov;
  std::vector<uint32_t> amcboardid;
  std::vector<uint32_t> amcslotnum;
  std::vector<uint32_t> amcblocknum;
  std::vector<uint32_t> amcreserve;
  std::vector<uint32_t> amclength;
  std::vector<uint32_t> amcbits;
  std::vector<AMCdata>  amcdata;
  uint32_t bxid;
  uint32_t l1aid;
  uint32_t blocknum;
  uint32_t reserve4;
  uint32_t crc32;
  bool valid;
};


AMC13Block::AMC13Block(std::fstream& rawdata) {

  std::cout << "-------------AMC13Block header" << std::endl;

  uint64_t header1;
  valid=rawread(rawdata, header1);
  if (!valid) return;
  reserve1 = header1       &        0xf;
  orbitnum = (header1>> 4) & 0xffffffff;
  reserve2 = (header1>>36) &     0xffff;
  numamc   = (header1>>52) &        0xf;
  reserve3 = (header1>>56) &        0xf;
  ufov     = (header1>>60);

  for (unsigned i=0; i<numamc; i++) {
    uint64_t amcheader;
    valid&=rawread(rawdata, amcheader);
    if (!valid) return;
    amcboardid.push_back( amcheader       &   0xffff);
    amcslotnum.push_back( (amcheader>>16) &      0xf);
    amcblocknum.push_back((amcheader>>20) &     0xff);
    amcreserve.push_back( (amcheader>>28) &      0xf);
    amclength.push_back(  (amcheader>>32) & 0xffffff);
    amcbits.push_back(    (amcheader>>56) &     0xff);
  }

  for (unsigned i=0; i<numamc; i++) {
    std::cout << "------------------------AMC13Block payload block" << std::endl;
    amcdata.push_back(AMCdata(rawdata));
    valid&=amcdata[i].valid;
  }

  std::cout << "---------------------------AMC13Block trailer" << std::endl;
  uint64_t trailer;
  valid&=rawread(rawdata, trailer);
  if (!valid) return;
  bxid     = trailer       &    0xfff;
  l1aid    = (trailer>>12) &     0xff;
  blocknum = (trailer>>20) &     0xff;
  reserve4 = (trailer>>28) &     0xff;
  crc32    = (trailer>>32);
  
}


//==================================================================


class AMC13Event {

public:
  AMC13Event(std::fstream& rawdata);
  uint32_t headerlowbits;
  uint32_t fov;
  uint32_t sourceid;
  uint32_t bxid;
  uint32_t l1aid;
  uint32_t evttype;
  std::vector<AMC13Block> amc13block;
  uint32_t trailerlowbits;
  uint32_t tts;
  uint32_t evtstatus;
  uint32_t trailermidbits;
  uint32_t crc16;
  uint32_t eventlength;
  uint32_t reserve1;
  bool valid;
};


AMC13Event::AMC13Event(std::fstream& rawdata) {

  std::cout << "---------------------BEGIN AMC13EVENT" << std::endl;

  uint64_t header1;
  valid=rawread(rawdata, header1);
  if (!valid) return;
  headerlowbits = header1       &        0xf;
  fov           = (header1>> 4) &        0xf;
  sourceid      = (header1>> 8) &      0xfff;
  bxid          = (header1>>20) &      0xfff;
  l1aid         = (header1>>32) &   0xffffff;
  evttype       = (header1>>56);


  bool payloadblock=true;
  while(payloadblock) {
    // need to read ahead by one word to find out whether we get a trailer now
    // or another payload block
    std::cout << "---------------------CHECK FOR PAYLOADBLOCK" << std::endl;
    uint64_t nextword;
    valid&=rawread(rawdata,nextword);
    if (!valid) return;
    rawdata.seekg(-sizeof(nextword),std::fstream::cur);
    std::cout << "---(rewind one word)---" << std::endl;
    payloadblock=((nextword>>60)!=0xa);
    if (payloadblock) {
      std::cout << "------------------------PAYLOADBLOCK" << std::endl;
      amc13block.push_back(AMC13Block(rawdata));
    }
  }

  std::cout << "---------------------BEGIN AMC13EVENT TRAILER" << std::endl;

  uint64_t trailer;
  valid&=rawread(rawdata, trailer);
  if (!valid) return;
  trailerlowbits = trailer       &      0xf;
  tts            = (trailer>> 4) &      0xf;
  evtstatus      = (trailer>> 8) &      0xf;
  trailermidbits = (trailer>>12) &      0xf;
  crc16          = (trailer>>16) &   0xffff;
  eventlength    = (trailer>>32) & 0xffffff;
  reserve1       = (trailer>>56);
  
}


//==================================================================


class TestController {

public:

  typedef enum {daqMP7, daqAMC13, daqFEROL} daqDestinations;

private:

  unsigned numTrigInBurst;
  float timeBeforeReadout;
  float timeBetweenIterations;
  unsigned numIterations;
  daqDestinations daqDestination;
  bool fullDAQPath;
  std::vector<unsigned> mp7_slots;
  std::string logDir;
  std::string testName;
  uint32_t eventSize;

  AMC13DAQ* amc13;
  std::vector<MP7DAQ*> mp7;

public:

  TestController();
  void addMP7(std::string deviceName, unsigned slotNum);
  void setNumTrigInBurst(unsigned num)      { numTrigInBurst = num; };
  void setTimeBeforeReadout(float time)     { timeBeforeReadout = time; };
  void setTimeBetweenIterations(float time) { timeBetweenIterations = time; };
  void setNumIterations(unsigned num)       { numIterations = num; };
  void setDAQDestination(daqDestinations dest) { daqDestination = dest; };
  void setEventSize(uint32_t size) { eventSize = size; };
  void useFullDAQPath(bool use) { fullDAQPath = use; };
  void setLogDir(std::string dir);
  void setTestName(std::string name) { testName = name; };
  void dumpAllRegisters(std::string connectionFile, std::string deviceName, std::string fileName);
  void testTTC();
  void testDAQ();
  uint64_t payloadFakeData(uint32_t offset, uint32_t mp7_board_id); 
  uint64_t payloadFixedPattern(uint32_t offset, uint32_t bxid,
			       uint32_t orbit_id, uint32_t capsize); 
  void readRawData(const char* fileName = NULL);
  bool decode(std::vector<uint64_t>& data,
	      bool AMC13Headers,
	      bool fullDAQPath,
	      std::fstream& log);

};


TestController::TestController() {

  // default test parameters
  numTrigInBurst = 1;
  timeBeforeReadout = 0.1;
  timeBetweenIterations = 0.01;
  numIterations = 10;
  daqDestination = daqAMC13;
  eventSize = 0;
  fullDAQPath = true;
  logDir="log";
  testName="test";
  mp7_slots.clear();
  
  // initialize AMC13 for clock distribution etc
  amc13 = new AMC13DAQ("etc/mp7/connections-RAL.xml");
  amc13->initialize();
}


void TestController::addMP7(std::string deviceName, unsigned slot) {

  if (slot<1 || slot>12) {
    std::cout << "slot number " << slot << " is illegal" << std::endl;
    return;
  }

  bool already_in_use=false;
  for (unsigned i=0; i<mp7_slots.size(); i++) {
    already_in_use |= (mp7_slots[i]==slot);
  }
  if (!already_in_use) {
    mp7_slots.push_back(slot);
    mp7.push_back(new MP7DAQ("etc/mp7/connections-RAL.xml",deviceName));
  }
}


void TestController::setLogDir(std::string dir) {
  logDir = dir;
  system(("mkdir -p "+dir).c_str());
}


void TestController::dumpAllRegisters(std::string connectionFile, std::string deviceName,
				      std::string fileName) {
  uhal::ConnectionManager conn("file://"+connectionFile);
  uhal::HwInterface* hw = new uhal::HwInterface(conn.getDevice(deviceName));

  std::vector<std::string> nodeList = hw->getNodes();
  std::sort(nodeList.begin(), nodeList.end());
  std::fstream outfile(logDir+"/"+fileName,std::fstream::out);
  for (unsigned i=0; i<nodeList.size(); i++) {
    if (hw->getNode(nodeList[i]).getPermission()==uhal::defs::NodePermission::WRITE) continue;
    if (hw->getNode(nodeList[i]).getNodes().size()>0) continue;
    uhal::ValWord<uint32_t> val = hw->getNode(nodeList[i]).read();
    hw->dispatch();
    outfile << nodeList[i] << std::setw(60-nodeList[i].length()) << " " << val << std::endl;
  }
  outfile.close();
}


void TestController::testTTC() {

  if (mp7_slots.size()==0) {
    std::cout << "need to add MP7 slots to test before running!" << std::endl;
    return;
  }

  // open log file
  std::fstream log(logDir+"/"+testName+".log",std::fstream::out);

  // introductory message
  std::stringstream intro;
  intro << "running TTC test (logfile " << testName << ")" << std::endl;
  for (unsigned i=0; i<mp7_slots.size(); i++) {
    intro << " using MP7 in slot " << mp7_slots[i] << std::endl;
  }
  log << intro.str();
  std::cout << intro.str();

  // set up all boards. configure for AMC13 DAQ so the AMC13 enables TTS links.
  amc13->initialize();
  for (unsigned i=0; i<mp7.size(); i++) {
    mp7[i]->initialize();
    mp7[i]->enableFakeData(false);
    mp7[i]->configureAMC13DAQ();
  }
  amc13->configureLocalDAQ(mp7_slots);

  amc13->startRun(5);

  // current bit pattern settings in MP7 firmware
  //
  //constant TTC_BCMD_BC0: ttc_cmd_t := X"01";
  //constant TTC_BCMD_EC0: ttc_cmd_t := X"02";
  //constant TTC_BCMD_RESYNC: ttc_cmd_t := X"04";
  //constant TTC_BCMD_OC0: ttc_cmd_t := X"08";
  //constant TTC_BCMD_TEST_SYNC: ttc_cmd_t := X"0c";
  //constant TTC_BCMD_START: ttc_cmd_t := X"10";
  //constant TTC_BCMD_STOP: ttc_cmd_t := X"14";

  amc13->sendTriggerBurst();
  std::vector<uint64_t> data;
  std::vector<uint32_t> eventOffsets;
  amc13->downloadEvents(data,eventOffsets);
  sleep(0.01);

  // send an EC0
  amc13->sendTTCCommand(0x8,2000);

  sleep(0.01);
  amc13->sendTriggerBurst();
  amc13->downloadEvents(data,eventOffsets);
  sleep(0.01);
  
  // send OC0. Note EC0 cannot be sent using the AMC13 API function sendLocalEvnOrnReset
  // because it is sent together with a BC0, i.e. sending bit pattern 0x3 instead of
  // separate patterns 0x1 and 0x2. 
  amc13->sendTTCCommand(0x2,2000);

  sleep(0.01);
  amc13->sendTriggerBurst();
  amc13->downloadEvents(data,eventOffsets);

  sleep(0.01);

  mp7[0]->dumpTTCHistory();

  amc13->endRun();
}


void TestController::testDAQ() {

  if (mp7_slots.size()==0) {
    std::cout << "need to add MP7 slots to test before running!" << std::endl;
    return;
  }

  // open log file
  std::fstream log(logDir+"/"+testName+".log",std::fstream::out);

  // introductory message
  std::stringstream intro;
  intro << "running test " << testName << std::endl;
  intro << " numTrigInBurst = " << numTrigInBurst << std::endl;
  intro << " numIterations = " << numIterations << std::endl;
  intro << " timeBeforeReadout = " << timeBeforeReadout << std::endl;
  intro << " timeBetweenIterations = " << timeBetweenIterations << std::endl;
  if (daqDestination==daqMP7) {
    intro << " readout from MP7" << std::endl;
  } else if (daqDestination==daqAMC13) {
    intro << " readout from AMC13" << std::endl;
  } else {
    intro << " readout from FEROL" << std::endl;
  }
  for (unsigned i=0; i<mp7_slots.size(); i++) {
    intro << " using MP7 in slot " << mp7_slots[i] << std::endl;
  }
  log << intro.str();
  std::cout << intro.str();

  // set up all boards
  amc13->initialize();
  for (unsigned i=0; i<mp7.size(); i++) {
    mp7[i]->initialize();
    mp7[i]->setEventSize(eventSize);
    mp7[i]->enableFakeData(fullDAQPath);
    if (daqDestination==daqMP7) {
      mp7[i]->configureLocalDAQ();
    } else {
      mp7[i]->configureAMC13DAQ();
    }
  }
  if (daqDestination==daqAMC13) {
    amc13->configureLocalDAQ(mp7_slots);
  } else if (daqDestination==daqFEROL) {
    amc13->configureFEROLDAQ(mp7_slots);
  }

  unsigned dataSize=0;
  unsigned numEvents=0;

  for (unsigned iter=0; iter < numIterations; iter++) { 

    // start run
    amc13->startRun(numTrigInBurst);

    std::string dumpstring;
    amc13->dumpRegisters(dumpstring);
    log << dumpstring << std::endl;
    mp7[0]->dumpRegisters(dumpstring);
    log << dumpstring << std::endl;

    amc13->sendTriggerBurst();
    sleep(timeBeforeReadout);

    std::vector<uint64_t> data;
    std::vector<uint32_t> eventOffsets;
    unsigned ntry=0;
    while ((eventOffsets.size()==0) && ntry<10) {
      if (daqDestination==daqMP7) {
	mp7[0]->downloadEvents(data,eventOffsets);
      } else if (daqDestination==daqAMC13) {
	amc13->downloadEvents(data,eventOffsets);
      }
      sleep(timeBeforeReadout);
      ntry++;
    }

    std::fstream dump(logDir+"/"+testName+".dat",
    		      std::fstream::out|std::fstream::binary|std::fstream::app);
    for (unsigned i=0; i<data.size(); i++) {
      dump.write(reinterpret_cast<const char *>(&data[i]),sizeof(data[i]));
    }
    dump.close();

    numEvents+=eventOffsets.size();
    dataSize+=data.size()*8;

    amc13->endRun();
    sleep(timeBetweenIterations);
  }
  std::stringstream summary;
  summary << "test summary: " << dataSize << " Bytes, " << numEvents << "/"
	  << numIterations*numTrigInBurst << " Events" << std::endl;
  log << summary.str();
  log.close();
  std::cout << summary.str();
}


uint64_t TestController::payloadFakeData(uint32_t offset, uint32_t mp7_board_id) {
  return (mp7_board_id << 16) + (offset);
}


uint64_t TestController::payloadFixedPattern(uint32_t offset, uint32_t bxid,
					     uint32_t orbit_id, uint32_t capsize) {
  uint8_t linkID=0xf8+(offset/2/(capsize+1));
  if (offset%(capsize+1)==0) {
    // block header
    return (linkID<<24) + (capsize<<16); 
  } else if (linkID%2) {
    // fixed pattern as read from buffer
    return (orbit_id<<20) + (bxid<<8) + linkID+1;
  } else {
    // these buffers are not in pattern mode, but in latency mode
    return 0;
  }
}


bool TestController::decode(std::vector<uint64_t>& data, bool AMC13Headers,
			    bool fullDAQPath,
			    std::fstream& log) {

  // MP7 fake data format parameters
  unsigned mp7_header_length=2;
  unsigned mp7_trailer_length = 1;
  unsigned mp7_board_id = 0x1001;
  if (fullDAQPath) mp7_board_id=0xf00d;
  unsigned mp7_user_data = 0xdead1001;
  unsigned mp7_event_size_64bit = 100;
  if (fullDAQPath) mp7_event_size_64bit= 100;

  // AMC13 data format parameters
  unsigned amc13_header_length = 3;
  unsigned amc13_trailer_length = 2;


  // data dump
  log << "======= event dump:" << std::endl;
  for (unsigned i=0; i<data.size(); i++) {
    log << std::hex << std::setw(16) << std::setfill('0') << data[i] << std::endl;
  }
  log << "======= end data dump. analysis follows." << std::endl;

  // event length sanity check
  unsigned min_length = mp7_header_length+mp7_trailer_length;
  if (AMC13Headers) min_length += amc13_header_length + amc13_trailer_length;
    
  if (data.size()<min_length) {
    log << "DATA ERROR: event size less than minimum" << std::endl;
    return false;
  }

  // keep track of errors
  bool good_event=true;

  // expected slot number
  unsigned slot_num = mp7_slots[0];

  // MP7 header
  unsigned mp7_header_offset=0;
  if (AMC13Headers) mp7_header_offset += amc13_header_length;
  uint32_t event_size = data[mp7_header_offset] & 0xfffff;
  if (event_size!=mp7_event_size_64bit) {
    log << "DATA ERROR: wrong event size " << event_size << std::endl;
    good_event=false;
  }
  uint32_t bx_id = (data[mp7_header_offset] >> 20) & 0xfff;
  uint32_t l1a_id_hdr = (data[mp7_header_offset] >> 32) & 0xffffff;
  uint32_t amc_num = ((data[mp7_header_offset] >> 56) & 0xf );
  if ((amc_num!=0) && !AMC13Headers) {
    log << "DATA ERROR: amc_num=" << amc_num << ", should be 0 on MP7" << std::endl;
    good_event=false;
  } else if ((amc_num==0) && AMC13Headers) {
    log << "DATA WARNING: AMC13 does not fill slot number into MP7 header" << std::endl;
  } else if ((amc_num!=slot_num) && AMC13Headers) {
    log << "DATA ERROR: amc_num=" << amc_num
	<< ", expected " << slot_num << std::endl;
    good_event=false;
  }
  uint32_t hdr0_reserved = (data[mp7_header_offset] >> 60) & 0xf;
  if (hdr0_reserved!=0) {
    log << "DATA WARNING: header 0 bits 60-63 have non-zero content" << std::endl;
  }
  uint32_t board_id = data[mp7_header_offset+1] & 0xffff;
  if (board_id!=mp7_board_id) {
    log << "DATA ERROR: wrong board ID " << board_id << std::endl;
    good_event=false;
  }
  uint32_t orbit_num = (data[mp7_header_offset+1] >> 16) & 0xffff;
  uint32_t user_data = data[mp7_header_offset+1] >> 32;
  if (((user_data>>24)==slot_num && (mp7_user_data>>24)!=slot_num)
      && (user_data&0xffffff)==(mp7_user_data&0xffffff)) {
    log << "DATA WARNING: user data overwritten by slot number" << std::endl;
  } else if (user_data!=mp7_user_data) {
    log << "DATA ERROR: wrong user data " << std::hex << user_data << std::endl;
    good_event=false;
  }

  // MP7 trailer
  uint32_t mp7_trailer_offset = data.size()-mp7_trailer_length;
  if (AMC13Headers) mp7_trailer_offset -= amc13_trailer_length;
  uint32_t length_counter = data[mp7_trailer_offset] & 0xffffff;
  if (length_counter != event_size) {
    log << "DATA ERROR: event length counter in trailer is " << length_counter << std::endl;
    good_event=false;
  }
  uint32_t mp7_crc = data[mp7_trailer_offset] >> 32;
  if ((!AMC13Headers) && (mp7_crc!=0)) {
    log << "DATA ERROR: unexpected CRC = " << mp7_crc << std::endl;
    good_event=false;
  }
  uint32_t l1a_id_trl = (data[mp7_trailer_offset] >> 24) & 0xff;
  if (l1a_id_trl != (l1a_id_hdr & 0xff)) {
    log << "DATA ERROR: L1A ID mismatch. header has " << l1a_id_hdr
	      << ", trailer has " << l1a_id_trl << std::endl;
    good_event=false;
  }

  // AMC13 header
  unsigned amc13_header_offset=0;
  if (AMC13Headers) {
    uint32_t event_type = data[amc13_header_offset] >> 56;
    if (event_type!=0x51) {
      log << "DATA ERROR: DAQ ID/firmware version in AMC13 header is "
		<< std::hex << event_type << std::endl;
      good_event=false;
    }
    uint32_t l1a_id_amc13 = (data[amc13_header_offset] >> 32) & 0xffffff;
    if (l1a_id_amc13!=l1a_id_hdr) {
      log <<"DATA ERROR: L1A ID expected " << l1a_id_amc13 <<", MP7 reports " << l1a_id_hdr << std::endl;
      good_event=false;
    }
    uint32_t bx_id_amc13 = (data[amc13_header_offset] >> 20 ) & 0xfff;
    if (bx_id_amc13!=bx_id) {
      log << "DATA WARNING: BX ID expected " << bx_id_amc13 << ", MP7 reports " << bx_id << std::endl;
      if (bx_id_amc13-bx_id!=23) {
	log << "DATA ERROR: BX ID offset is not 23" << std::endl;
	good_event=false;
      }
    }
    uint32_t src_id = (data[amc13_header_offset] >> 8 ) & 0xfff;
    if (src_id!=FED_ID) {
      log << "DATA ERROR: FED ID expected " << FED_ID
		<< ", AMC13 reports " << src_id << std::endl;
      good_event=false;
    }
    uint32_t hdr1 = data[amc13_header_offset] & 0xff;
    log << "lowest 8 bits in AMC13 header: " << hdr1 << std::endl;
    uint32_t orbit_num_amc13 = (data[amc13_header_offset+1] >> 4) & 0xffffffff;
    if ((orbit_num_amc13 & 0xffff) != orbit_num) {
      log << "DATA ERROR: orbit num expected " << std::hex
		<< orbit_num_amc13 << ", MP7 reports " << orbit_num << std::endl;
      good_event=false;
    }
  }


  // payload
  if (mp7_trailer_offset+mp7_trailer_length-mp7_header_offset!=mp7_event_size_64bit) {
    log << "DATA ERROR: payload length is " << data.size() << std::endl;
    good_event=false;
  }
  for (uint32_t i=mp7_header_offset+mp7_header_length;
       i<mp7_trailer_offset; i++) {
    uint64_t& dataword = data[i];
    uint64_t ctr = i-mp7_header_offset;
    uint64_t ctr2 = ctr-mp7_header_length;
    uint64_t expected;
    if (fullDAQPath) {
      expected = (payloadFixedPattern(ctr2*2+1,0x1f8,orbit_num,6)<<32)
	+payloadFixedPattern(ctr2*2,0x1f8,orbit_num,6);
    } else {
      expected = (payloadFakeData(ctr*2+1,mp7_board_id) << 32)
	+ payloadFakeData(ctr*2,mp7_board_id);
    }
    if (dataword!=expected) {
      log << "DATA ERROR: dataword " << i << ": " << dataword
		<< " expected " << expected << std::endl;
      good_event=false;
    }
  }

  return good_event;
}


void TestController::readRawData(const char* fileName) {

  std::string dataFileName = logDir+"/"+testName+".dat";
  if (fileName) dataFileName = std::string(fileName);

  std::fstream rawdata(dataFileName,std::fstream::in|std::fstream::binary);

  // first word will tell us what type of data file we are looking at
  uint64_t data;
  rawdata.read((char*)&data, sizeof(data));
  
  typedef enum {dataTypeMP7, dataTypeAMC13, dataTypeFEROL, dataTypeUnknown} dataType_t;
  dataType_t dataType;
  std::cout << "DATA: " << std::hex << std::setw(16) << std::setfill('0') << data << std::endl;
  switch (data>>60) {
  case 0: dataType=dataTypeMP7; std::cout << "MP7 data format" << std::endl; break;
  case 5: dataType=dataTypeAMC13; std::cout << "AMC13 data format" << std::endl; break;
  default: dataType=dataTypeUnknown; std::cout << "unknown data format" << std::endl; break;
  }

  // now go back to beginning of file and feed the data into the suitable decoder
  rawdata.clear();
  rawdata.seekg(0, rawdata.beg);

  while (!rawdata.eof()) {
    switch (dataType) {
    case dataTypeMP7:
      {
	AMCdata mp7event(rawdata);
	if (mp7event.valid) {
	  std::cout << "MP7 event length=" << mp7event.length << std::endl;
	}
	break;
      }
    case dataTypeAMC13:
      {
	AMC13Event amc13event(rawdata);
	if (amc13event.valid) {
	  std::cout << "AMC13 event length=" << amc13event.eventlength << std::endl;
	  break;
	}
      }
    default:
      {
	std::cout << "not implemented yet!" << std::endl;
	AMCdata rubbish(rawdata);
	break;
      }
    }
  }

  // all done
  rawdata.close();
}


//==================================================================


int main() {

  //{
  //  FEROLDAQ fedkit;
  //  sleep(5);
  //}
  // close parentheses before exit call because otherwise the destructor
  // of the FEROLDAQ object will not be called upon exit!
  //exit(0);



  uhal::setLogLevelTo ( uhal::Error() );


  // basic configuration
  TestController test;
  //test.addMP7("MP7XE_slot3",3);
  test.addMP7("MP7XE_slot10",10);
  test.setNumIterations(10);
  test.setEventSize(100);

  char buffer[80];
  time_t rawtime;
  std::time(&rawtime);
  strftime(buffer,80,"%Y%m%d_%H%M%S",std::localtime(&rawtime));
  test.setLogDir("log_"+std::string(buffer));

  // degrees of freedom:
  // - buffer or fake
  // - MP7, AMC13, FEROL readout
  // - event size
  // - number of triggers in single bursts
  // - trigger rate for continuous running


  /*
  // direct readout of individual fake events from MP7
  test.setTestName("ferol_single_fake");
  test.setNumTrigInBurst(1);
  test.setDAQDestination(TestController::daqFEROL);
  test.useFullDAQPath(false);
  test.testDAQ();


  // first check the TTC command link
  test.setTestName("ttc");
  test.dumpAllRegisters("etc/mp7/connections-RAL.xml","T1","amc13t1_regs_before_ttc.txt");
  test.dumpAllRegisters("etc/mp7/connections-RAL.xml","T2","amc13t2_regs_before_ttc.txt");
  test.testTTC();
  test.dumpAllRegisters("etc/mp7/connections-RAL.xml","T1","amc13t1_regs_after_ttc.txt");
  test.dumpAllRegisters("etc/mp7/connections-RAL.xml","T2","amc13t2_regs_after_ttc.txt");

  */

  // direct readout of individual fake events from MP7
  test.setTestName("mp7_single_fake");
  test.setNumTrigInBurst(1);
  test.setDAQDestination(TestController::daqMP7);
  test.useFullDAQPath(false);
  test.testDAQ();
  test.readRawData();

  /*

  test.dumpAllRegisters("etc/mp7/connections-RAL.xml","T1","amc13t1_regs_after_daq.txt");
  test.dumpAllRegisters("etc/mp7/connections-RAL.xml","T2","amc13t2_regs_after_daq.txt");

  // direct readout of individual buffer events from MP7
  test.setTestName("mp7_single_buffer");
  test.setNumTrigInBurst(1);
  test.setDAQDestination(TestController::daqMP7);
  test.useFullDAQPath(true);
  test.testDAQ();

  */

  // direct readout of individual fake events from AMC13
  test.setTestName("amc13_single_fake");
  test.setNumTrigInBurst(1);
  test.setDAQDestination(TestController::daqAMC13);
  test.useFullDAQPath(false);
  test.testDAQ();
  test.readRawData();

  /*

  // readout of individual events from AMC13
  test.setTestName("amc13_single_buffer");
  test.setNumTrigInBurst(1);
  test.setDAQDestination(TestController::daqAMC13);
  test.useFullDAQPath(true);
  test.testDAQ();

  // direct readout of multiple events from MP7
  // --- this does not seem to work more than once. TTS stopping further L1As?
  test.setTestName("mp7_twoevents_fake");
  test.setNumTrigInBurst(2);
  test.setDAQDestination(TestController::daqMP7);
  test.useFullDAQPath(false);
  test.testDAQ();

  // readout of multiple events from AMC13
  test.setTestName("amc13_twoevents_fake");
  test.setNumTrigInBurst(2);
  test.setDAQDestination(TestController::daqAMC13);
  test.useFullDAQPath(false);
  test.testDAQ();

  // direct readout of multiple events from MP7
  test.setTestName("mp7_twoevents_buffer");
  test.setNumTrigInBurst(2);
  test.setDAQDestination(TestController::daqMP7);
  test.useFullDAQPath(true);
  test.testDAQ();

  // readout of multiple events from AMC13
  test.setTestName("amc13_twoevents_buffer");
  test.setNumTrigInBurst(2);
  test.setDAQDestination(TestController::daqAMC13);
  test.useFullDAQPath(true);
  test.testDAQ();

  */

}
