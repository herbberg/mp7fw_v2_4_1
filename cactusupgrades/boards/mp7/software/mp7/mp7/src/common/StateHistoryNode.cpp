/**
 * @file    StateHistoryNode.cpp
 * @author  Alessandro Thea
 * @date    November 2014
 */


#include "mp7/StateHistoryNode.hpp"

// uHAL Headers
#include "uhal/ValMem.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/Logger.hpp"

// Namespace resolution
namespace l7 = mp7::logger;

namespace mp7 {
UHAL_REGISTER_DERIVED_NODE( StateHistoryNode );

//---
StateHistoryNode::StateHistoryNode(const uhal::Node& aNode) :
  uhal::Node(aNode) {
}

//---
StateHistoryNode::~StateHistoryNode() {
}


//---
void
StateHistoryNode::mask(bool aMask) const {
  getNode("csr.ctrl.mask").write(aMask);
  getClient().dispatch();
}


//--
void StateHistoryNode::clear() const {
  
  getNode("csr.ctrl.rst").write(0x1);
  getNode("csr.ctrl.rst").write(0x0);
  // Leave it running
  getNode("csr.ctrl.freeze").write(0x0);
  getClient().dispatch();
}

//---
std::vector<HistoryEntry> StateHistoryNode::capture() const {
    
  // The commands are continuously captured. Freeze it first
  getNode("csr.ctrl.freeze").write(0x1);
  
  // Save the history size for later use
  size_t size = getNode("buffer.data").getSize()/4;

  uhal::ValWord<uint32_t> ptr = getNode("csr.stat.ptr").read();
  uhal::ValWord<uint32_t> wrap = getNode("csr.stat.wrap_flag").read();
  getClient().dispatch();

  // Reset the read pointer
  getNode("buffer.addr").write(0x0);
  uhal::ValVector<uint32_t> data = getNode("buffer.data").readBlock(size*4);
  getClient().dispatch();
  
  std::vector<HistoryEntry> history;
  const uint32_t mask = 0x3ffff;

  if ( wrap == 0x0 ) {
    // The buffer has not wrapped aroud
    MP7_LOG(l7::kDebug) << "StateHistory: " << ptr.value() << " values captured";

    // prepare history to receive the data
    history.resize(ptr.value());
    uint64_t w0,w1,w2,w3;

    for (uint32_t i = 0; i < ptr.value() ; ++i) {

      
      w0 = ( data[i*4] & mask );
      w1 = ( data[i*4+1] & mask );
      w2 = ( data[i*4+2] & mask );
      w3 = ( data[i*4+3] & mask );

      // -- 71:56 state_data; 55:36 evt_num; 35:16 orb_num; 15:4 bx_num; 3:0 

      // Cycle counter: bits 3:0, 3 bits
      history[i].cyc = (w0 & 0xf);

      // Bunch counter: bits 15:4, 12 bits
      history[i].bx = ((w0 >> 4) & 0xfff);
  
      // Bunch counter: bits 35:16, 20 bits
      history[i].orbit = ( (w1 << 18) + w0 ) >> 16;

      // Event counter: bits 55:36, 20 bits
      history[i].event = ( (w3 << 18) + w2 ) & 0xfffff;

      // Bunch counter: bits 71:56, 16 bits
      history[i].data  = ( w3 >> 2 );
    }
  } else {
    // The buffer has wrapped aroud
    MP7_LOG(l7::kDebug) << "StateHistory: " << size << " values captured";

    // prepare history to receive the data
    history.resize(size);
    uint64_t w0,w1,w2,w3;
    
    for (uint32_t i = 0; i < size ; ++i) {
      
      // Start from ptr and end at ptr-1
      uint32_t j = (i+ptr) % size;

      w0 = ( data[j*4] & mask );
      w1 = ( data[j*4+1] & mask );
      w2 = ( data[j*4+2] & mask );
      w3 = ( data[j*4+3] & mask );


      // Cycle counter: bits 3:0, 3 bits
      history[i].cyc = (w0 & 0xf);

      // Bunch counter: bits 15:4, 12 bits
      history[i].bx = ((w0 >> 4) & 0xfff);
  
      // Bunch counter: bits 35:16, 20 bits
      history[i].orbit = ( (w1 << 18) + w0 ) >> 16;

      // Event counter: bits 55:36, 20 bits
      history[i].event = ( (w3 << 18) + w2 ) & 0xfffff;

      // Bunch counter: bits 72:56, 16 bits
      history[i].data  = ( w3 >> 2 );
    } 
  }
  
  // Resume captures
  getNode("csr.ctrl.freeze").write(0x0);
  getClient().dispatch();

  return history;

}



} // namespace mp7
