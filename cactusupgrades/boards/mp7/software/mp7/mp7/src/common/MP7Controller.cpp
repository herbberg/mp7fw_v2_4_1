
#include "mp7/MP7Controller.hpp"

// C++ Headers
#include <cstdlib>
#include <sstream>
#include <algorithm>
#include <ext/slist>

// Boost Headers
#include <boost/assign.hpp>
#include <boost/filesystem.hpp>
//#include <boost/foreach.hpp>
#include <boost/lexical_cast.hpp>
#include <boost/range/adaptor/map.hpp>
#include <boost/range/algorithm/copy.hpp>
#include <boost/range/algorithm/find.hpp>
#include <boost/unordered/unordered_map.hpp>

// pugi headers
#include "pugixml/pugixml.hpp"

// MP7 Headers
#include "mp7/AlignMonNode.hpp"
#include "mp7/BoardData.hpp"
#include "mp7/ChanBufferNode.hpp"
#include "mp7/ClockingNode.hpp"
#include "mp7/ClockingR1Node.hpp"
#include "mp7/ClockingXENode.hpp"
#include "mp7/CtrlNode.hpp"
#include "mp7/DatapathNode.hpp"
#include "mp7/exception.hpp"
#include "mp7/FormatterNode.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Measurement.hpp"
#include "mp7/MGTRegionNode.hpp"
#include "mp7/MiniPODMasterNode.hpp"
#include "mp7/MmcPipeInterface.hpp"
#include "mp7/operators.hpp"
#include "mp7/operators.hpp"
#include "mp7/Orbit.hpp"
#include "mp7/PathConfigurator.hpp"
#include "mp7/ReadoutNode.hpp"
#include "mp7/ReadoutCtrlNode.hpp"
#include "mp7/SI5326Node.hpp"
#include "mp7/SI570Node.hpp"
#include "mp7/TTCNode.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/ZeroSuppressionNode.hpp"

// Namespace declaration
namespace l7 = mp7::logger;


namespace mp7 {


//-----------------------------------------------------------------------------
MP7Controller::MP7Controller(const uhal::HwInterface& aHw) : 
  MP7MiniController(aHw),
  mClocking(mHw.getNode<ClockingNode>("clocking")),
  mReadout(mHw.getNode<ReadoutNode>("readout")),
  mMiniPODTop(mHw.getNode<MiniPODMasterNode>("i2c.minipods_top")),
  mMiniPODBottom(mHw.getNode<MiniPODMasterNode>("i2c.minipods_bot")),
  mKind(kMP7Unknown)
  {


  // MP7_LOG(l7::kDebug) << "Discovering MP7 " << id();

  uint32_t design = mCtrl.readDesign();

  mKind = safe_enum_cast(design, kKnownMP7s, kMP7Unknown);

  MP7_LOG(l7::kInfo) << "Building MP7 controller " << id();

}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
MP7Controller::~MP7Controller() {
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
MP7Kind
MP7Controller::kind() const {
  return mKind;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
MP7Controller::identify() const {

  MP7_LOG(l7::kNotice) << "MP7 " << mKind << " - " << id();

  MP7MiniController::identify();

  const ReadoutCtrlNode& mROCtrl = mReadout.getNode<ReadoutCtrlNode>("readout_control");

  uint32_t nBanks(mROCtrl.readNumBanks()), nModes(mROCtrl.readNumModes()), nCap(mROCtrl.readNumCaptures());
  bool zsAvailable = ( !mReadout.getNodes("readout_zs").empty() && mReadout.getNode<ZeroSuppressionNode>("readout_zs").isAvailable() );

  MP7_LOG(l7::kInfo) << "Readout - B:" << nBanks << " M:" << nModes << " C:" << nCap << " zs:" << (zsAvailable ? "Available" : "Not available");


}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
const mp7::ReadoutNode&
MP7Controller::getReadout() const {
  return mReadout;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
mp7::MmcManager
MP7Controller::mmcMgr() {
  return MmcManager(mHw.getNode<mp7::MmcPipeInterface>("uc"));
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void MP7Controller::reset(const std::string& aClkSrc, const std::string& aRefClkCfg, const std::string& aTTCCfg) {
  MP7_LOG(l7::kNotice) << "Resetting board '" << id() << "'";

  bool externalClock(false);
  if (aClkSrc == "external")
    externalClock = true;
  else if (aClkSrc == "internal")
    externalClock = false;
  else
    throw ArgumentError("Clock source can be either internal or external");


  mCtrl.softReset();

  std::string kindStr = boost::lexical_cast<std::string>(mKind);

  {
    // Hold clk4 in reset
    CtrlNode::Clock40Guard guard(mCtrl);

    mCtrl.selectClk40Source(externalClock);

    //FIXME: is this the only way?
    if (mKind == kMP7Xe) {
      MP7_LOG(l7::kInfo) << "MP7 XE detected";
      
      // Clocking first
      ClockingXEConfigurator clkCfgtor(aRefClkCfg + ".xml", kindStr, mp7::MP7Controller::sharePath);

      // Ensure that the master clock choice is compatible with the clock configuration
      const std::string& refClkSrc = clkCfgtor.getConfig().clkSrc;
      if (refClkSrc != "generic" and refClkSrc != aClkSrc) {
        MP7_LOG(l7::kError) << "Clock source mismatch: refclk=" << clkCfgtor.getConfig().clkSrc << ", master= " << aClkSrc;
      }

      clkCfgtor.configure(mClocking);
      
    } else if (mKind == kMP7R1) {
      MP7_LOG(l7::kInfo) << "MP7 R1 detected";

      // Clocking first
      ClockingR1Configurator clkCfgtor(aRefClkCfg + ".xml", kindStr, mp7::MP7Controller::sharePath);

      // Ensure that the master clock choice is compatible with the clock configuration
      const std::string& refClkSrc = clkCfgtor.getConfig().clkSrc;
      if (refClkSrc != "generic" and refClkSrc != aClkSrc) {
        MP7_LOG(l7::kError) << "Clock source mismatch: refclk=" << clkCfgtor.getConfig().clkSrc << ", master= " << aClkSrc;
      }

      clkCfgtor.configure(mClocking);
      
    } else if  ( mKind == kMP7Sim) {
      MP7_LOG(l7::kInfo) << "MP7 Sim detected";
    } else {
      throw std::runtime_error("Wrong node type detected! Expecting either ClockingXENode or ClockingR1Node object");
    }

  } // guard goes out of scope here, clk40 is released
  mCtrl.waitClk40Lock(); 
  
  
  // TTC Configuration
  // Takes place AFTER clock40 is released
  // FIXME clean up this horrible mess
  if ( mKind != kMP7Sim ) {
    TTCConfigurator ttcCfgtor(aTTCCfg + ".xml", kindStr, mp7::MP7Controller::sharePath);

    // Ensure that the master clock choice is compatible with the ttc configuration
    if (ttcCfgtor.getConfig().clkSrc != aClkSrc) {
      MP7_LOG(l7::kError) << "Clock source mismatch: ttcclk=" << ttcCfgtor.getConfig().clkSrc << ", master= " << aClkSrc;
    }
    ttcCfgtor.configure(mTTC);
  }

}


//-----------------------------------------------------------------------------
void MP7Controller::resetPayload() {
  MP7_LOG(l7::kInfo) << "Resetting algos on MP7 \"" << id() << "\" - nothing to do";
}


//-----------------------------------------------------------------------------
std::map<uint32_t,uint32_t>
MP7Controller::computeEventSizes( const ReadoutMenu& aMenu ) const {

  std::map<uint32_t, uint32_t> size64bMap;

  // 2 64b header + 1 64b trailer words
  uint32_t amcProtocolOverhead = 3;
  

  std::map<uint32_t, uint32_t> banksMap = channelMgr().readBankSummary();

  // for( const ReadoutMenu::Mode& m :  aMenu) {
  for( uint32_t iM(0); iM < aMenu.numModes(); ++iM) {
    
    uint32_t nWords32b = 0;

    const ReadoutMenu::Mode& m = aMenu.mode(iM);
    // Loop over capture modes
    for (uint32_t iC(0); iC < m.size(); ++iC) {
      const ReadoutMenu::Capture& c = m[iC];

      // Skip non-enabled captures
      if ( not c.enable ) continue;

      uint32_t nBanks = 0;
      try {
        nBanks = banksMap.at(c.bankId);
      } catch ( const std::out_of_range& oor ) {
        // No banks to capture
        continue;
      }
      
      uint32_t capFullSize  = nBanks*(c.readoutLength+1); // +1 because of the header
      
      MP7_LOG(l7::kDebug) << "mode " << iM << ", capture "<< iC << ": " << capFullSize << " 32b words";

      nWords32b += capFullSize;
    }
    
    // Add 1 word for the 2 MP7 specific header (FW_REV + ALGO_REV)
    nWords32b += 2;
    MP7_LOG(l7::kDebug) << "mode " << iM << " 32b words : " << nWords32b;

    size64bMap[iM] = 
        (nWords32b/2)+ // Convert in 64b words
        (nWords32b%2)+ // Add the padding if necessary
        amcProtocolOverhead // Add the AMC protocol overhead
        ;
  }

  return size64bMap;

}


/**
 * Experimental
 * "Hic Sunt Leones"
 */
mp7::TransactionQueue
MP7Controller::createQueue() {
  return mp7::TransactionQueue(mHw);
}



} // namespace mp7
