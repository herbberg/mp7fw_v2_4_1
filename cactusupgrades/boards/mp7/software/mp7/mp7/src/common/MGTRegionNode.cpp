#include "mp7/MGTRegionNode.hpp"

// uHAL Headers
#include "uhal/ValMem.hpp"

// MP7 Headers
#include "mp7/CommandSequence.hpp"
#include "mp7/exception.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"

// Boost Headers
#include <boost/assign/std/vector.hpp> // for 'operator+=()'
//#include <boost/foreach.hpp> // for for macro
#include <boost/lexical_cast.hpp>
#include <boost/assign/list_of.hpp>

// Namespace resolution
using namespace std;
using namespace uhal;
using namespace boost::assign;

namespace l7 = mp7::logger;

namespace mp7 {

UHAL_REGISTER_DERIVED_NODE(MGTRegionNode);

// PUBLIC METHODS


const std::vector<uint32_t> MGTRegionNode::kAllChannelIDs = boost::assign::list_of(0)(1)(2)(3);

// --------------------------------------------------------
MGTRegionNode::MGTRegionNode(const uhal::Node& node) :
uhal::Node(node) {
}


// --------------------------------------------------------
MGTRegionNode::~MGTRegionNode() {
}


// --------------------------------------------------------
MGTKind
MGTRegionNode::readRegionKind() const {
    uhal::ValWord<uint32_t> type = getNode("ro_regs.common.status.kind").read();
    getClient().dispatch();
    return static_cast<MGTKind>( type.value() );
}


// --------------------------------------------------------
bool
MGTRegionNode::usesQpll() const {
  MGTKind kind = readRegionKind();
  return (kind == kGth10g or kind == kGth10gStdLat or kind == kGtx10g);
}


// --------------------------------------------------------
void
MGTRegionNode::checkBoundaries(const std::vector<uint32_t>& aChans) const {
    std::vector<uint32_t> outOfBounds;
    for( uint32_t id : aChans ) {
        if ( id > 3 ) outOfBounds.push_back(id);
    }

    if ( outOfBounds.size() != 0 ) {
      std::ostringstream oss;
      oss << "Channel ids out of bound: " << l7::shortVecFmt(outOfBounds);
        throw MGTChannelIdOutOfBounds( oss.str() );
    }
}


// --------------------------------------------------------
void 
MGTRegionNode::clearCRCs(const std::vector<uint32_t>& aChans) const {
  
  checkBoundaries(aChans);

  for( uint32_t c :  aChans ) {

    const uhal::Node& reset = getNode("rw_regs.ch"+to_string(c)+".control.reset_crc_counters");
    reset.write(1);
    reset.write(0);
  }
  getClient().dispatch();    

}


// --------------------------------------------------------
void
MGTRegionNode::softReset( bool aReset ) const {
    getNode("rw_regs.common.control.soft_reset").write(aReset);
    getClient().dispatch();
    // millisleep(100);
    // getNode("rw_regs.common.control.soft_reset").write(0);
    // getClient().dispatch();
    // MP7_LOG(l7::kDebug) << "GTH Quad soft rest completed";
}

 
// --------------------------------------------------------
void
MGTRegionNode::resetRxFSM( bool aReset, const std::vector<uint32_t>& aChans ) const {
  checkBoundaries(aChans);
  
  for( uint32_t c :  aChans ) {
    const uhal::Node& reset = getNode("rw_regs.ch"+to_string(c)+".control.rx_fsm_reset");
    reset.write(aReset);
  }
  getClient().dispatch();
}


// --------------------------------------------------------
void
MGTRegionNode::resetTxFSM( bool aReset, const std::vector<uint32_t>& aChans ) const {
  checkBoundaries(aChans);
  
  for( uint32_t c :  aChans ) {
    const uhal::Node& reset = getNode("rw_regs.ch"+to_string(c)+".control.tx_fsm_reset");
    reset.write(aReset);
  }
  getClient().dispatch();
}


// --------------------------------------------------------
void
MGTRegionNode::configureRx(bool aOrbitTag, bool aPolarity, const std::vector<uint32_t>& aChans) const {

  checkBoundaries(aChans);

  for(uint32_t c :  aChans) {

    MP7_LOG(l7::kDebug) << "MGT channel " << c << ": polarity " << (aPolarity ? "normal" : "inverted");
    getNode("rw_regs.ch" + to_string(c) + ".control.rxpolarity").write(not aPolarity);

    MP7_LOG(l7::kDebug) << "MGT channel " << c << ": orbit-tag " << (aOrbitTag ? "enabled" : "disabled");
    getNode("rw_regs.ch" + to_string(c) + ".control.orbit_tag_enable").write(aOrbitTag);
  }

  getClient().dispatch();
}


// --------------------------------------------------------
void
MGTRegionNode::configureTx(bool aLoop, bool aPolarity, const std::vector<uint32_t>& aChans) const {
  checkBoundaries(aChans);

  for(uint32_t c :  aChans) {
    MP7_LOG(l7::kDebug) << "MGT channel " << c << ": polarity " << (aPolarity ? "normal" : "inverted");
    getNode("rw_regs.ch" + to_string(c) + ".control.txpolarity").write(not aPolarity);

    MP7_LOG(l7::kDebug) << "MGT channel " << c << ": loopback " << (aLoop ? "enabled" : "disabled");
    getNode("rw_regs.ch" + to_string(c) + ".control.loopback").write(aLoop ? 2 : 0);

  }
  getClient().dispatch();
}


// --------------------------------------------------------
bool MGTRegionNode::checkRx( const std::vector<uint32_t>& aChans ) const {
    
    bool ok = false;
    
    // Check the QPLL status only for 10G MGTs
    if ( usesQpll() ) 
        ok &= isQpllLocked();
    
    // Then check channels one by one, Rx first, Tx after
    for( uint32_t ch :  aChans ) {
        ok &= checkRx( ch );
    }
    
    return ok;
    
}


// --------------------------------------------------------
bool MGTRegionNode::checkTx( const std::vector<uint32_t>& aChans ) const {
    
    bool ok = false;
    
    // Check the QPLL status only for 10G MGTs
    if ( usesQpll() ) 
        ok &= isQpllLocked();
    
    // Then check channels one by one, Rx first, Tx after
    for( uint32_t ch :  aChans ) {
        ok &= checkTx( ch );
    }
    
    return ok;
    
}


// --------------------------------------------------------
void
MGTRegionNode::waitForFSMResetDone(const std::string& aGroup, uint32_t aMaxTries, const std::vector<uint32_t>& aChans) const {

  checkBoundaries(aChans);

  std::vector<const uhal::Node*> resetDoneNodes;
  for( uint32_t c :  aChans ) {
    resetDoneNodes += &getNode("ro_regs.ch"+to_string(c)+".status." + aGroup + ".fsm_reset_done");
  }
  
  std::vector< uhal::ValWord<uint32_t> > vals;

  int32_t countdown(aMaxTries);
  
  while( countdown > 0 ) {
      
      bool resetDone = true;

      // Clear previous values
      vals.clear();
      // Queue the reset_done reqd requests
      for( const uhal::Node* rdNode :  resetDoneNodes ) {
        vals += rdNode->read();
      }

      // Go!
      getClient().dispatch();

      // Loop over results, are we done by any chance?
      for( uhal::ValWord<uint32_t> v :  vals ) {
        resetDone &= v.value();
      }

      // Oh yeah! Goodbye
      if (resetDone)
        break;

      millisleep(1);
      countdown--;
  }

  if (countdown == 0) {
    std::ostringstream oss;
    oss << "Timed out while waiting for " << aGroup << " FMS to complete reset (" << aMaxTries << " ms)";
    MP7_LOG(l7::kError) << oss.str();
    throw mp7::MGTFSMResetTimeout(oss.str());
  } else {
    MP7_LOG(l7::kDebug) << "Channels " << aGroup << "." << l7::shortVecFmt(aChans)
            << " FSM reset complete after " << (aMaxTries - countdown) << " ms";
  }
}


// --------------------------------------------------------
void
MGTRegionNode::waitRxFMSResetDone(uint32_t aMaxTries, const std::vector<uint32_t>& aChans) const {
    waitForFSMResetDone("rx", aMaxTries, aChans);
}


// --------------------------------------------------------
void 
MGTRegionNode::waitTxFMSResetDone(uint32_t aMaxTries, const std::vector<uint32_t>& aChans) const {
    waitForFSMResetDone("tx", aMaxTries, aChans);
}


// --------------------------------------------------------
bool
MGTRegionNode::isQpllLocked() const {
    bool ok = true;
    uhal::ValWord< uint32_t > lTemp;

    lTemp = getNode("ro_regs.common.status.qplllock").read();
    getClient().dispatch();

    if (lTemp.value() != 1) {
        ok = false;
        MP7_LOG(l7::kWarning) << "qplllock = " << l7::hexFmt(lTemp);
    }

    // Add other checks here if needed
    return ok;
}


// --------------------------------------------------------
RxChannelStatus
MGTRegionNode::readRxChannelStatus(uint32_t aChannel) const {
  if (aChannel > 3)
    throw MGTChannelIdOutOfBounds("Invalid channel number requested");
  
  const uhal::Node& lStatusNode = getNode("ro_regs.ch"+to_string(aChannel));
  
  

//  uhal::ValWord<uint32_t> checked = getNode("ro_regs.ch"+to_string(aChannel)+".status.crc_checked").read();
//  uhal::ValWord<uint32_t> errors = getNode("ro_regs.ch"+to_string(aChannel)+".status.crc_error").read();
//  uhal::ValWord<uint32_t> id = getNode("ro_regs.ch"+to_string(aChannel)+".rx_trailer").read();
  uhal::ValWord<uint32_t> pllLocked = ( usesQpll() ? getNode("ro_regs.common.status.qplllock").read() : lStatusNode.getNode("status.cpll_lock").read() ); 
  uhal::ValWord<uint32_t> checked = lStatusNode.getNode("status.crc_checked").read();
  uhal::ValWord<uint32_t> errors = lStatusNode.getNode("status.crc_error").read();
  uhal::ValWord<uint32_t> trailer = lStatusNode.getNode("rx_trailer").read();
  uhal::ValWord<uint32_t> fsmResetDone = lStatusNode.getNode("status.rx_fsm_reset_done").read();
  uhal::ValWord<uint32_t> usrReset = lStatusNode.getNode("status.rxusrrst").read();

  getClient().dispatch();
  
  RxChannelStatus status({ pllLocked, checked, errors, trailer, fsmResetDone, usrReset });
  return status;
}


// --------------------------------------------------------
TxChannelStatus
MGTRegionNode::readTxChannelStatus(uint32_t aChannel) const {

  if (aChannel > 3)
    throw MGTChannelIdOutOfBounds("Invalid channel number requested");
  
  const uhal::Node& lStatusNode = getNode("ro_regs.ch"+to_string(aChannel));

  uhal::ValWord<uint32_t> pllLocked = ( usesQpll() ? getNode("ro_regs.common.status.qplllock").read() : lStatusNode.getNode("status.cpll_lock").read() ); 
  uhal::ValWord<uint32_t> fsmResetDone = lStatusNode.getNode("status.tx_fsm_reset_done").read();
  uhal::ValWord<uint32_t> usrReset = lStatusNode.getNode("status.txusrrst").read();

  getClient().dispatch();

  TxChannelStatus status({pllLocked, fsmResetDone, usrReset});
  return status;
}


// --------------------------------------------------------
bool
MGTRegionNode::checkRx(uint32_t aLocal) const {
    if (aLocal > 3)
        throw std::runtime_error("Invalid channel number requested");

    bool checkCpll = !usesQpll();
    
    
    // Read all status registers in one go
    const uhal::Node& chX_ro = this->getNode("ro_regs.ch"+to_string(aLocal));
    Snapshot status = snapshot(chX_ro.getNode("status"));
    
    bool ok = true;

    string chid = "[" + chX_ro.getId() + "]";

    // CPLL: Shared between Tx and Rx, and therefore must be checked by both.
    uint32_t cpllLock = status["cpll_lock"];
    if ( checkCpll && !cpllLock) {
        ok &= false;
        MP7_LOG(l7::kWarning) << chid << " status.cpll_lock = " << l7::hexFmt(status["cpll_lock"]);
    }

    // CRC Logic
    uint32_t chks(status["crc_checked"]), crcs(status["crc_error"]);
    MP7_LOG(l7::kDebug) << chid 
            << " status: chks/errs = " << l7::hexFmt(chks) 
            << "/" << l7::hexFmt(crcs);

    // CRC Checked:  logic operating
    if (chks == 0) {
        ok &= false;
        MP7_LOG(l7::kWarning) << chid << " status.crc_checked = " << l7::hexFmt(chks);
    }

    // CRC Errors
    if (crcs != 0) {
        ok &= false;
        MP7_LOG(l7::kWarning) << chid << " status.crc_checked = " << l7::hexFmt(chks);
        MP7_LOG(l7::kWarning) << chid << " status.crc_error = " << l7::hexFmt(crcs);
    }

    // RX FSM reset completed
    uint32_t rxfsmrst = status["rx_fsm_reset_done"];
    if (rxfsmrst == 0) {
        ok &= false;
        MP7_LOG(l7::kWarning) << chid << " rx_fsm_reset_done = " << l7::hexFmt(rxfsmrst);
    }

    // RX User Reset completed
    uint32_t rxrst = status["rxusrrst"];
    if (rxrst == 1) {
        ok &= false;
        MP7_LOG(l7::kWarning) << chid << " rxusrrst = " << l7::hexFmt(rxrst);
    }


    return ok;
}


// --------------------------------------------------------
bool
MGTRegionNode::checkTx(uint32_t aChannel) const {
    if (aChannel > 3)
        throw MGTChannelIdOutOfBounds("Invalid channel number requested");

    bool checkCpll = !usesQpll();
    
    
    // Read all status registers in one go
    const uhal::Node& chX_ro = this->getNode("ro_regs.ch"+to_string(aChannel));
    Snapshot status = snapshot(chX_ro.getNode("status"));
    
    bool ok = true;

    string chid = "[" + chX_ro.getId() + "]";

    // CPLL: Shared between Tx and Rx, and therefore must be checked by both.
    uint32_t cpllLock = status["cpll_lock"];
    if ( checkCpll && !cpllLock) {
        ok &= false;
        MP7_LOG(l7::kWarning) << chid << " status.cpll_lock = " << l7::hexFmt(status["cpll_lock"]);
    }

    uint32_t txfsmrst = status["tx_fsm_reset_done"];

    if (txfsmrst == 0) {
        ok &= false;
        MP7_LOG(l7::kWarning) << chid << " tx_fsm_reset_done = " << l7::hexFmt(txfsmrst);
    }

    uint32_t txrst = status["txusrrst"];

    if (txrst == 1) {
        ok &= false;
        MP7_LOG(l7::kWarning) << chid << " txusrrst = " << l7::hexFmt(txrst);
    }

    return ok;
}


/**
 * "Experimental"
 */


MGTRegionSequencer MGTRegionNode::queue(TransactionQueue& aSequence) const {
    return MGTRegionSequencer( *this, aSequence );
}


// --------------------------------------------------------
MGTRegionSequencer::MGTRegionSequencer(const MGTRegionNode& aRegion, TransactionQueue& aSequence) : 
    mMGTs( aRegion ),
    mSequence( aSequence ) {

}


// --------------------------------------------------------
MGTRegionSequencer::~MGTRegionSequencer() {
}


// --------------------------------------------------------
void
MGTRegionSequencer::softReset( bool aReset ) const {

    mSequence.write( mMGTs.getNode("rw_regs.common.control.soft_reset"), aReset );
    
}


// --------------------------------------------------------
void
MGTRegionSequencer::resetRxFSM( uint32_t aChannel, bool aReset) const {
   
    const uhal::Node& resetNode = mMGTs.getNode("rw_regs.ch"+to_string(aChannel)+".control.rx_fsm_reset");
    mSequence.write(resetNode, aReset);

}


// --------------------------------------------------------
void
MGTRegionSequencer::resetTxFSM( uint32_t aChannel, bool aReset) const {
    
    const uhal::Node& resetNode = mMGTs.getNode("rw_regs.ch"+to_string(aChannel)+".control.tx_fsm_reset");
    mSequence.write(resetNode, aReset);

}


}
