/**
 * @file    ReadoutControlNode.cpp
 * @author  Alessandro Thea
 * @date    March 2015
 */

#include "mp7/ReadoutNode.hpp"

// MP7 Headers
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/exception.hpp"
#include "mp7/ReadoutCtrlNode.hpp"

// uHAL Headers
#include "uhal/ValMem.hpp"

// C++ Headers
#include <iomanip>

namespace l7 = mp7::logger;

namespace mp7 {
UHAL_REGISTER_DERIVED_NODE(ReadoutNode);

//-----------------------------------------------------------------------------
ReadoutNode::ReadoutNode(const uhal::Node& aNode) :
uhal::Node(aNode) {
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
ReadoutNode::~ReadoutNode() {

}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
const ReadoutCtrlNode& ReadoutNode::getControl() const {
  return getNode<ReadoutCtrlNode>("readout_control");
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
ReadoutNode::selectEventSource(EventSource aSource) const {
  getNode("csr.ctrl.src_sel").write(aSource);
  getClient().dispatch();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
ReadoutNode::enableAMC13Output(bool aEnable) const {
  getNode("csr.ctrl.amc13_en").write(aEnable);
  getClient().dispatch();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
ReadoutNode::enableAutoDrain(bool aEnable, uint32_t aRate) const {
  getNode("csr.ctrl.auto_empty").write(aEnable);
  getNode("csr.ctrl.auto_empty_rate").write(aRate);
  getClient().dispatch();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
ReadoutNode::forceTTSState(bool aForce, uint32_t aState) const {
  getNode("tts_csr.ctrl.tts_force").write(aForce);
  getNode("tts_csr.ctrl.tts").write(aState);
  getClient().dispatch();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void ReadoutNode::start() const {
  getNode("tts_csr.ctrl.board_rdy").write(0x1);
  //TODO add counter reset here;
  getClient().dispatch();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void ReadoutNode::stop() const {
  getNode("tts_csr.ctrl.board_rdy").write(0x0);
  getClient().dispatch();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
ReadoutNode::setBxOffset(uint32_t aOffset) const {
  getNode("csr.ctrl.bx_offset").write(aOffset);
  getClient().dispatch();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
ReadoutNode::configureFakeEventSize(uint32_t aSize) const {
  if ( aSize == 0 ) {
    throw ArgumentError("Fake event size can't be 0");
  }
  
  getNode("csr.ctrl.fake_evt_size").write(aSize);
  getClient().dispatch();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
ReadoutNode::setFifoWaterMarks(uint32_t aLowWM, uint32_t aHighWM) const {
  getNode("csr.warn_ctrl.buffer_hwm").write(aHighWM); //48 = 25% 
  getNode("csr.warn_ctrl.buffer_lwm").write(aLowWM); //32 = 50%
  getClient().dispatch();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void 
ReadoutNode::resetAMC13Block() const {
  getNode("csr.ctrl.amc13_link_rst").write(0x1);
  getClient().dispatch();
  getNode("csr.ctrl.amc13_link_rst").write(0x0);
  getClient().dispatch();

}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
bool
ReadoutNode::isAMC13LinkReady() const {
  uhal::ValWord<uint32_t> rdy = getNode("csr.stat.amc13_rdy").read();
  getClient().dispatch();
  
  return rdy;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
uint32_t
ReadoutNode::readEventCounter() const {
  uhal::ValWord<uint32_t> ev = getNode("csr.evt_count").read();
  getClient().dispatch();
  
  return ev;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
TTSStateCounters
ReadoutNode::readTTSCounters() const {

  uhal::ValWord<uint32_t> ctr_up_l = getNode("tts_ctrs.uptime_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_up_h = getNode("tts_ctrs.uptime_ctr_h").read();
  uhal::ValWord<uint32_t> ctr_bsy_l = getNode("tts_ctrs.busy_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_bsy_h = getNode("tts_ctrs.busy_ctr_h").read();
  uhal::ValWord<uint32_t> ctr_rdy_l = getNode("tts_ctrs.ready_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_rdy_h = getNode("tts_ctrs.ready_ctr_h").read();
  uhal::ValWord<uint32_t> ctr_wrn_l = getNode("tts_ctrs.warn_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_wrn_h = getNode("tts_ctrs.warn_ctr_h").read();
  uhal::ValWord<uint32_t> ctr_oos_l = getNode("tts_ctrs.oos_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_oos_h = getNode("tts_ctrs.oos_ctr_h").read();
  getClient().dispatch();

  TTSStateCounters cntrs;
  
  cntrs.uptime = ((uint64_t)ctr_up_h << 32) + ctr_up_l;
  cntrs.busy   = ((uint64_t)ctr_bsy_h << 32) + ctr_bsy_l;
  cntrs.ready  = ((uint64_t)ctr_rdy_h << 32) + ctr_rdy_l;
  cntrs.warn   = ((uint64_t)ctr_wrn_h << 32) + ctr_wrn_l;
  cntrs.oos    = ((uint64_t)ctr_oos_h << 32) + ctr_oos_l;
  
  return cntrs;

}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
uint64_t
ReadoutNode::readUptimeCounts() const {
  uhal::ValWord<uint32_t> ctr_l = getNode("tts_ctrs.uptime_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_h = getNode("tts_ctrs.uptime_ctr_h").read();
  getClient().dispatch();
  return ((uint64_t)ctr_h << 32) + ctr_l;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
uint64_t
ReadoutNode::readBusyCounts() const {
  uhal::ValWord<uint32_t> ctr_l = getNode("tts_ctrs.busy_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_h = getNode("tts_ctrs.busy_ctr_h").read();
  getClient().dispatch();
  return ((uint64_t)ctr_h << 32) + ctr_l;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
uint64_t
ReadoutNode::readReadyCounts() const {
  uhal::ValWord<uint32_t> ctr_l = getNode("tts_ctrs.ready_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_h = getNode("tts_ctrs.ready_ctr_h").read();
  getClient().dispatch();
  return ((uint64_t)ctr_h << 32) + ctr_l;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
uint64_t
ReadoutNode::readWarnCounts() const {
  uhal::ValWord<uint32_t> ctr_l = getNode("tts_ctrs.warn_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_h = getNode("tts_ctrs.warn_ctr_h").read();
  getClient().dispatch();
  return ((uint64_t)ctr_h << 32) + ctr_l;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
uint64_t
ReadoutNode::readOOSCounts() const {
  uhal::ValWord<uint32_t> ctr_l = getNode("tts_ctrs.oos_ctr_l").read();
  uhal::ValWord<uint32_t> ctr_h = getNode("tts_ctrs.oos_ctr_h").read();
  getClient().dispatch();
  return ((uint64_t)ctr_h << 32) + ctr_l;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
TTSState
ReadoutNode::readTTSState() const {
  uhal::ValWord<uint32_t> tts = getNode("tts_csr.stat.tts_stat").read();
  getClient().dispatch();
  
  // TODO: Add a protection, to catch if nonesense is read from the board
  return static_cast<TTSState>(tts.value());
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
bool
ReadoutNode::isFifoEmpty() const {
  uhal::ValWord<uint32_t>  empty = getNode("buffer.fifo_flags.fifo_empty").read();
  getClient().dispatch();

  return (bool)empty;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
bool
ReadoutNode::isFifoFull() const {
  uhal::ValWord<uint32_t>  full = getNode("buffer.fifo_flags.fifo_full").read();
  getClient().dispatch();

  return (bool)full;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
uint32_t
ReadoutNode::readFifoOccupancy() const {
  uhal::ValWord<uint32_t>  counts = getNode("buffer.fifo_flags.fifo_cnt").read();
  getClient().dispatch();

  return counts;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
std::vector<uint64_t>
ReadoutNode::readFifo() const {
  std::vector<uint64_t> data;

  while( true ) {
    FifoEntry e = readFifoEntry();
    if ( e.fifoEmpty ) break;
    data.push_back( e.data );
  }

  return data;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
ReadoutNode::FifoEntry
ReadoutNode::readFifoEntry() const {

    uhal::ValWord<uint32_t> fifo_valid = getNode("buffer.fifo_flags.fifo_valid").read();
    uhal::ValWord<uint32_t> fifo_empty = getNode("buffer.fifo_flags.fifo_empty").read();
    uhal::ValWord<uint32_t> fifo_warn  = getNode("buffer.fifo_flags.fifo_warn").read();
    uhal::ValWord<uint32_t> fifo_full  = getNode("buffer.fifo_flags.fifo_full").read();
    // First word is the least significant word
    uhal::ValWord<uint32_t> data_low   = getNode("buffer.data").read();
    // Second word is the most significant word
    uhal::ValWord<uint32_t> data_high  = getNode("buffer.data").read();    
    // Third word is are the flags
    uhal::ValWord<uint32_t> data_flags = getNode("buffer.data").read();

    // Go! go! go!
    getClient().dispatch();
    
    FifoEntry entry;
    entry.data = ((uint64_t)data_high << 32) + data_low;


    // Unpack the data flags. Note that they are 1 cycle early. Sad life
    entry.dataStart = ( data_flags & 0x8);  // identical to amc13_header
    entry.dataVal = ( data_flags & 0x4);
    entry.dataStartDlyd = ( data_flags & 0x2);
    entry.dataValDlyd = ( data_flags & 0x1);
    entry.dataHdr = ( data_flags & 0x80);
    entry.dataTrl = ( data_flags & 0x40);

    // And the fifo flags as well
    entry.fifoValid = fifo_valid;
    entry.fifoWarning = fifo_warn;
    entry.fifoEmpty = fifo_empty;
    entry.fifoFull = fifo_full;
    
    MP7_LOG(l7::kDebug1) << std::setfill('0') << std::setw(8) << std::hex << data_low.value() << " "
                       << std::setfill('0') << std::setw(8) << std::hex << data_high.value() << " | "
                       << std::setfill('0') << std::setw(8) << std::hex << data_flags.value() << " "
                       << ( fifo_valid ? "V" : " " ) << " "
                       << ( fifo_empty ? "E" : " ") << " "
                       << ( fifo_warn ? "W" : " " ) << " "
                       << ( fifo_full ? "F" : " ");
    return entry;

}


std::vector<uint64_t>
ReadoutNode::readEvent() const {

  std::vector<uint64_t> lData;
  FifoEntry entry;

  uhal::ValWord<uint32_t> lRoChunks = getNode("buffer.info.ro_chunks").read();
  getClient().dispatch();


  // First read. It should be an header
  entry = readFifoEntry();

  // Nothing to see here. Bye
  if ( entry.fifoEmpty ) return lData; 

  // The first word must be marked as header ()
  if ( not entry.dataHdr ) {
    // replace it with a decent exception
    throw FifoError("readEvent: no header flag found.");
  }

  lData.push_back(entry.data);

  // 4 should be taken from ro_chunk
  uint32_t lBufSize = lRoChunks*0x200;

  // OK, let's look for the trailer
  for ( uint32_t i(0x0); i < lBufSize; ++i){
    // Read an entry

    entry = readFifoEntry();

    // There's nothinng for me here
    if ( entry.fifoEmpty ) {
      throw FifoError("readEvent: Fifo empty when not supposed to."); 
    }

    // Data trailer detected.
    if ( entry.dataTrl ) {
      // End of the line. push back and exit
      lData.push_back(entry.data);
      break;
    }
    
    lData.push_back(entry.data);

  }
  
  return lData;
}
//-----------------------------------------------------------------------------


}

