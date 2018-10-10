/*
 * File:   ChannelsConfigurator.cpp
 * Author: ale
 *
 * Created on December 3, 2014, 5:09 PM
 */

#include "mp7/ChannelManager.hpp"

// Boost Headers
//#include <boost/foreach.hpp>
#include <boost/assign/list_inserter.hpp>
#include <boost/tuple/tuple_comparison.hpp>
#include <boost/assign/std/vector.hpp>
#include <boost/bind.hpp>

// C++ Headers
#include <sstream>

// MP7 Headers
#include "mp7/AlignMonNode.hpp"
#include "mp7/BoardData.hpp"
#include "mp7/DatapathDescriptor.hpp"
#include "mp7/DatapathNode.hpp"
#include "mp7/FormatterNode.hpp"
#include "mp7/Logger.hpp"
#include "mp7/MGTRegionNode.hpp"
#include "mp7/MP7MiniController.hpp"
#include "mp7/operators.hpp"
#include "mp7/Orbit.hpp"
#include "mp7/PathConfigurator.hpp"
#include "mp7/TTCNode.hpp"

// Namespace Resolution
namespace l7 = mp7::logger;

namespace mp7 {


// ------------------------------------------------------------

ChannelManager::ChannelManager(const MP7MiniController& aController) :
  mController(aController),
  mDescriptor(mController.mDescriptor) {
}

// ------------------------------------------------------------
ChannelManager::ChannelManager(const MP7MiniController& aController, const std::vector<uint32_t> aChannels) :
  mController(aController),
  mDescriptor(mController.mDescriptor, aChannels) {
}


// ------------------------------------------------------------
ChannelManager::~ChannelManager() {
}


const DatapathDescriptor& ChannelManager::getDescriptor() const {
  return mDescriptor;
}



// ------------------------------------------------------------
ChannelGroup
ChannelManager::pickBufferIDs(RxTxSelector aSelection) const {
  ChannelRule rule;
  switch ( aSelection) {
  case kRx:
    rule = (boost::bind(&mp7::RegionInfo::bufIn, _1) == kBuffer);
    break;
  case kTx:
    rule = (boost::bind(&mp7::RegionInfo::bufOut, _1) == kBuffer);
    break;
  default:
    std::ostringstream oss;
    oss << "Unknown buffer kind " << aSelection;
    throw ArgumentError(oss.str());
  }

  // Fetch the list of buffers ids
  return mDescriptor.pickIDs( rule );
}


// ------------------------------------------------------------
ChannelGroup
ChannelManager::pickMGTIDs() const {
  return mDescriptor.pickIDs(
           ( boost::bind(&mp7::RegionInfo::mgtIn, _1) != kNoMGT ) or
           ( boost::bind(&mp7::RegionInfo::mgtOut, _1) != kNoMGT )
         );
}

// ------------------------------------------------------------
ChannelGroup
ChannelManager::pickMGTIDs(RxTxSelector aSelection) const {
  ChannelRule rule;
  switch ( aSelection ) {
  case kRx:
    rule = (boost::bind(&mp7::RegionInfo::mgtIn, _1) != kNoMGT);
    break;
  case kTx:
    rule = (boost::bind(&mp7::RegionInfo::mgtOut, _1) != kNoMGT);
    break;
  default:
    std::ostringstream oss;
    oss << "Unknown buffer kind " << aSelection;
    throw ArgumentError(oss.str());
  }

  // Fetch the list of buffers ids
  return mDescriptor.pickIDs( rule );
}


// ------------------------------------------------------------
void
ChannelManager::resetMGTs() const {

  // pick regions with ionput or output links
  const mp7::ChannelGroup allMgts = pickMGTIDs();

  // Local references
  const DatapathNode& datapath = mController.mDatapath;
  const MGTRegionNode& mgts = mController.mMGTs;


  MP7_LOG(l7::kInfo) << "Resetting MGTs on regions " << l7::shortVecFmt(allMgts.regions());

  for(const uint32_t& r :  allMgts.regions()) {
    MP7_LOG(l7::kDebug) << "---> Resetting region " << r;
    datapath.selectRegion(r);

    mgts.softReset(true);

  }

  millisleep(100);

  for(const uint32_t& r :  allMgts.regions()) {
    MP7_LOG(l7::kDebug) << "---> Region " << r << " reset completed";
    datapath.selectRegion(r);

    mgts.softReset(false);

  }
}


// ------------------------------------------------------------
void
ChannelManager::setupTx2RxPattern() {

  // Get all Tx links
  const ChannelGroup& txMgts = pickMGTIDs(mp7::kTx);

  // Local Node References
  const DatapathNode& datapath = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;

  orbit::Point first(0x0), last(0x10);

  // Pattern for 10 bx
  MP7_LOG(l7::kInfo) << "Configuring loopback pattern on "<< l7::shortVecFmt(txMgts.channels()) << ". Patterns over bx range " << first << "-" << last;
  PathConfigurator txconfig = TestPathConfigurator(mp7::PathConfigurator::kPattern, first, last, mController.getMetric());

  for(const uint32_t ch :  txMgts.channels()) {
    datapath.selectLinkBuffer(ch, mp7::kTx);
    txconfig.configure(buf);
  }

  MP7_LOG(l7::kNotice) << "Generating Tx -> Rx patterns";
}


// ------------------------------------------------------------
void
ChannelManager::setupTx2Rx3GPattern() {

  const ChannelGroup& txMgts = pickMGTIDs(mp7::kTx);

  // Local References
  const DatapathNode& datapath = mController.mDatapath;

  const ChanBufferNode& buf = mController.mBuffer;

  // Internal buffer loop :  Tx -> Rx
  // Uses playbacks

  // 1024 frames, starting at bx 0
  //  std::pair<size_t, size_t> pattrng(0xdec - 1, 0x400 - 1);

  orbit::Point firstBx(0x0);
  MP7_LOG(l7::kInfo) << "Configuring loopback pattern on "<< l7::shortVecFmt(txMgts.channels()) << ". Patterns starting at " << firstBx << " for " << buf.getBufferSize() << " frames";
  PathConfigurator txconfig = TestPathConfigurator(PathConfigurator::kPlayOnce3G, firstBx, mController.getMetric());

  // WARNING: Clearing all buffers here - May be too much
  clearBuffers(mp7::kTx);

  mp7::BoardData data_tx(mp7::BoardDataFactory::generate("generate://3gpattern"));

  for(const uint32_t ch :  txMgts.channels()) {
    datapath.selectLinkBuffer(ch, mp7::kTx);
    txconfig.configure(buf);
  }

  loadPatterns(mp7::kTx, data_tx);

}

// ------------------------------------------------------------
void
ChannelManager::setupTx2RxOrbitPattern() {

  // Get all Tx links
  const ChannelGroup& txMgts = pickMGTIDs(mp7::kTx);

  // Local References
  const DatapathNode& datapath = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;

  orbit::Point firstBx(0x0);

  MP7_LOG(l7::kInfo) << "Configuring loopback pattern on "<< l7::shortVecFmt(txMgts.channels()) << " : starts at " << firstBx << " for " << buf.getBufferSize() << " frames";
  PathConfigurator txconfig = TestPathConfigurator(PathConfigurator::kPlayOnce, firstBx, mController.getMetric());

  // WARNING: Clearing all buffers here - May be too much
  clearBuffers(mp7::kTx);

  mp7::BoardData data_tx(mp7::BoardDataFactory::generate("generate://orbitpattern"));

  for(const uint32_t ch :  txMgts.channels()) {
    datapath.selectLinkBuffer(ch, mp7::kTx);
    txconfig.configure(buf);
  }

  loadPatterns(mp7::kTx, data_tx);

}


// ------------------------------------------------------------
void
ChannelManager::clearRxCounters() const {

  // Local Namespace Resolution
  using namespace boost::assign;

  // Get the list of all known Rx links
  const ChannelGroup& rxMgts = pickMGTIDs(mp7::kRx);

  const DatapathNode& datapath = mController.mDatapath;
  const MGTRegionNode& mgts = mController.mMGTs;
  const AlignMonNode& align = mController.mAlignMon;

  MP7_LOG(l7::kInfo) << "Clearing counters on " << l7::shortVecFmt(rxMgts.channels());

  for(const uint32_t& r :  rxMgts.regions()) { 
    datapath.selectRegion(r);

    // Build a local list of channels ids
    std::vector<uint32_t> chans;
    for(uint32_t c :  rxMgts.channels(r))
    chans += c % 4;

    mgts.clearCRCs( chans );
  }

  for(const uint32_t& l :  rxMgts.channels()) {
    datapath.selectLink(l);
    align.clear();
  }
}


// ------------------------------------------------------------
void
ChannelManager::configureRxMGTs(bool aInvPolarity, bool aOrbittag) const {
  const ChannelGroup rxMgts = pickMGTIDs(mp7::kRx);

  // Local references
  const DatapathNode& datapath = mController.mDatapath;
  const MGTRegionNode& mgts = mController.mMGTs;

  MP7_LOG(l7::kInfo) << "Configuring Rx regions " << l7::shortVecFmt(rxMgts.regions());;

  // Configure first
  for(const uint32_t& r :  rxMgts.regions()) {
    MP7_LOG(l7::kDebug) << "---> Rx Region " << r;
    datapath.selectRegion(r);

    mgts.configureRx(aInvPolarity, aOrbittag, rxMgts.locals(r));
  }

  // Bring all channels in reset (Rx & Tx) first
  for(const uint32_t& r :  rxMgts.regions()) {
    MP7_LOG(l7::kDebug) << "---> Rx Region " << r << " Reset Start";
    datapath.selectRegion(r);

    mgts.resetRxFSM( true, rxMgts.locals(r) );

  }

  // Sleep a bit
  millisleep(100);

  // Reset is over
  for(const uint32_t& r :  rxMgts.regions()) {
    MP7_LOG(l7::kDebug) << "---> Rx Region " << r << " Reset End";
    datapath.selectRegion(r);

    mgts.resetRxFSM( false, rxMgts.locals(r) );
  }

  millisleep(100);

  // Commented because FSM doesn't get out of reset if there are no inputs
  // for(const uint32_t& r :  links.regions()) {

  //       // Build a channel list with local channel ids
  //       std::vector<uint32_t> chans;
  //       for(const uint32_t& l :  links.channels(r))
  //         chans.push_back( l%4 );

  //       datapath.selectRegion(r);
  //       mgts.clear();
  //       mgts.waitRxFMSResetDone(100,chans);
  // }
  MP7_LOG(l7::kInfo) << "Rx Regions configuration completed";
  clearRxCounters();

  // TODO: Remove this automatic check
  MP7_LOG(l7::kInfo) << "Checking Rx MGTs for errors";

  auto status = readRxStatus();
  for( const auto & p :  status) {
    const RxChannelStatus& s = p.second;
    // MP7_LOG(l7::kInfo)
    //   << p.first << ": "
    //   << s.crcChecked << ", "
    //   << s.crcErrors << ", "
    //   << s.trailerId;

    if ( !s.crcChecked ) {
      MP7_LOG(l7::kWarning) << "[" << p.first << "] no packets received";
    } else if ( s.crcErrors ) {
      MP7_LOG(l7::kWarning) << "[" << p.first << "] crc errors detected " << s.crcErrors;
    }
  }

  for(const uint32_t& r :  rxMgts.regions()) { // mLinksIDs.enabledRegions()
    datapath.selectRegion(r);

    // Check for errors ...
    std::vector<bool> errs;
    // But on the active channels only
    // errs.push_back(mgts.check(chans));
    errs.push_back( mgts.checkRx(rxMgts.locals(r)) );

    if (std::count(errs.begin(), errs.end(), true))
      MP7_LOG(l7::kError) << "--> Region: " << r << " Error";
    else
      MP7_LOG(l7::kDebug) << "--> Region: " << r << " OK";
  }

}


// ------------------------------------------------------------
void
ChannelManager::configureTxMGTs(bool aInvPolarity, bool aLoop) const {
  const ChannelGroup txMgts = pickMGTIDs(mp7::kTx);

  // Local references
  const DatapathNode& datapath = mController.mDatapath;
  const MGTRegionNode& mgts = mController.mMGTs;

  MP7_LOG(l7::kInfo) << "Configuring Tx regions " << l7::shortVecFmt(txMgts.regions());;

  // Configure first
  for(const uint32_t& r :  txMgts.regions()) {
    MP7_LOG(l7::kDebug) << "---> Tx Region " << r;
    datapath.selectRegion(r);

    mgts.configureTx(aInvPolarity, aLoop, txMgts.locals(r));
  }

  // Bring all channels in reset (Rx & Tx) first
  for(const uint32_t& r :  txMgts.regions()) {
    MP7_LOG(l7::kDebug) << "---> Tx Region " << r << " Reset Start";
    datapath.selectRegion(r);

    mgts.resetTxFSM( true, txMgts.locals(r) );

  }

  // Sleep a bit
  millisleep(100);

  // Reset is over
  for(const uint32_t& r :  txMgts.regions()) {
    MP7_LOG(l7::kDebug) << "---> Tx Region " << r << " Reset End";
    datapath.selectRegion(r);

    mgts.resetTxFSM( false, txMgts.locals(r) );
  }

  millisleep(100);

  // Commented because FSM doesn't get out of reset if there are no inputs
  // for(const uint32_t& r :  links.regions()) {

  //       // Build a channel list with local channel ids
  //       std::vector<uint32_t> chans;
  //       for(const uint32_t& l :  links.channels(r))
  //         chans.push_back( l%4 );

  //       datapath.selectRegion(r);
  //       mgts.clear();
  //       mgts.waitTxFMSResetDone(100,chans);
  // }

}


// ------------------------------------------------------------
std::map<uint32_t, RxChannelStatus>
ChannelManager::readRxStatus() const {
  // Get the list of all known Rx links
  const ChannelGroup rxMgts = pickMGTIDs(mp7::kRx);

  // Local references
  const DatapathNode& datapath = mController.mDatapath;
  const MGTRegionNode& mgts = mController.mMGTs;

  std::map<uint32_t, RxChannelStatus> status;
  // Loop over the regions
  for(const uint32_t& r :  rxMgts.regions()) {
    datapath.selectRegion(r);

    // Then look into the links
    for(const uint32_t& l :  rxMgts.channels(r)) {
      status[l] = mgts.readRxChannelStatus(rxMgts.channelToLocal(l));
    }
  }

  return status;
}


// ------------------------------------------------------------
std::map<uint32_t, TxChannelStatus>
ChannelManager::readTxStatus() const {
  // Get the list of all known Rx links
  const ChannelGroup txMgts = pickMGTIDs(mp7::kTx);

  // Local references
  const DatapathNode& datapath = mController.mDatapath;
  const MGTRegionNode& mgts = mController.mMGTs;

  std::map<uint32_t, TxChannelStatus> status;
  // Loop over the regions
  for(const uint32_t& r :  txMgts.regions()) {
    datapath.selectRegion(r);

    // Then look into the links
    for(const uint32_t& l :  txMgts.channels(r)) {
      status[l] = mgts.readTxChannelStatus(txMgts.channelToLocal(l));
    }
  }

  return status;
}

// ------------------------------------------------------------
std::map<uint32_t, AlignStatus>
ChannelManager::readAlignmentStatus() const {
  // Get the list of all known Rx links
  const ChannelGroup rxMgts = pickMGTIDs(mp7::kRx);

  // Local references
  const DatapathNode& datapath = mController.mDatapath;
  const AlignMonNode& align = mController.mAlignMon;

  std::map<uint32_t, AlignStatus> status;
  // Loop over the regions
  for(uint32_t l :  rxMgts.channels()) {
    datapath.selectLink(l);

    status[l] = align.readStatus();

  }
  return status;
}


// ------------------------------------------------------------
void
ChannelManager::checkMGTs() {

  // Get the list of all known Rx links
  const ChannelGroup rxMgts = pickMGTIDs(mp7::kRx);

  // Local references
  const DatapathNode& datapath = mController.mDatapath;
  const MGTRegionNode& mgts = mController.mMGTs;


  MP7_LOG(l7::kInfo) << "Checking CRCs";

  std::vector<uint32_t> crcErrs;

  for(const uint32_t& r :  rxMgts.regions()) {
    datapath.selectRegion(r);

    // Check the QPLL status if it's a 10G MGT
    if ( mgts.usesQpll() && !mgts.isQpllLocked()) {
      MP7_LOG(l7::kError) << "Errors detected on quad " << r;
      MP7_LOG(l7::kWarning) << "-- Dumping registers for region " << r;
      Snapshot regDump = mp7::snapshot(mgts, "ro_regs.common\\..*");

      for(const Snapshot::value_type & p :  regDump)
      MP7_LOG(l7::kWarning) << "      " << p.first << " : 0x" << std::hex << p.second << std::dec;
    }

    // Then look into the rxMgts
    std::vector<uint32_t> lMGTError;
    for(const uint32_t& l :  rxMgts.channels(r)) {
      datapath.selectLink(l);
      if (!mgts.checkRx(rxMgts.channelToLocal(l)) or !mgts.checkTx(rxMgts.channelToLocal(l)))
        lMGTError.push_back(l);
    }

    if (lMGTError.size()) {
      std::ostringstream oss;
      oss << l7::shortVecFmt(lMGTError);

      MP7_LOG(l7::kError) << "Errors detected on rxMgts " << oss.str() << " (region " << r << ")";

      // dump channels

      for(const uint32_t& lErr :  lMGTError) {
        datapath.selectLink(lErr);

        MP7_LOG(l7::kWarning) << "-- Dumping link " << lErr << " registers";
        Snapshot regDump = mp7::snapshot(mgts, std::string("ro_regs\\.ch") + to_string((lErr) % 4) + "\\..*");
        for(const Snapshot::value_type & p :  regDump)
        MP7_LOG(l7::kWarning) << "     " << p.first << " : " << std::hex << p.second << std::dec;
        crcErrs.push_back(lErr);
      }
    }
  }
  std::ostringstream ossCRC;
  ossCRC << l7::shortVecFmt(crcErrs);
  MP7_LOG(l7::kDebug) << "CRCs summary: " << ossCRC.str();// l7::shortVecFmt(crcErrs);
}

// ------------------------------------------------------------
void ChannelManager::checkAlignment() const {

  // Get all Rx mgts available
  const ChannelGroup& rxMgts = pickMGTIDs(mp7::kRx);

  // Local references
  const AlignMonNode& align = mController.mAlignMon;
  const DatapathNode& datapath = mController.mDatapath;

  MP7_LOG(l7::kInfo) << "Checking alignment for channels "  << l7::shortVecFmt(rxMgts.channels());;

  std::vector<uint32_t> alignErrs;

  for(const uint32_t& l :  rxMgts.channels()) {
    datapath.selectLink(l);
    uint32_t e = align.readErrors();
    bool m = align.markerDetected();

    MP7_LOG(l7::kDebug) << "   marker = " << m << " pos = " << align.readPosition() << " errs = " << e;
    if ( e > AlignMonNode::kErrorThreshold || !m ) // can be 0 or 1
      alignErrs.push_back(l);
  }

  std::ostringstream ossAlign;
  ossAlign << l7::shortVecFmt(alignErrs);

  if ( alignErrs.size() ) {
    MP7_LOG(l7::kError) << "--Alignment: Error";
    MP7_LOG(l7::kError) << "   Errors detected on channels" << ossAlign.str();
  } else {
    MP7_LOG(l7::kDebug) << "--Alignment: OK";
  }

}



// ------------------------------------------------------------
std::map<std::string, mp7::Measurement>
ChannelManager::refClkReport(bool aCrap /* = false */) {

  // pick regions with ionput or output links
  const mp7::ChannelGroup allMgts = pickMGTIDs();

  // Local References
  const DatapathNode& datapath = mController.mDatapath;
  const TTCNode& ttc = mController.mTTC;

  std::map<std::string, mp7::Measurement> report;

  // Loop over enabled allMgts
  for(uint32_t l :  allMgts.channels() ) {
    MP7_LOG(l7::kDebug) << "Measuring clock frequencies for channel " << l;

    datapath.selectLink(l);
    std::string chid = strprintf("[%02d]", l);
    double refclock = ttc.measureClockFreq(TTCNode::kRefClock, aCrap);
    double rxclock = ttc.measureClockFreq(TTCNode::kRxClock, aCrap);
    double txclock = ttc.measureClockFreq(TTCNode::kTxClock, aCrap);
    boost::assign::insert(report)
    ("RefClk" + chid, mp7::Measurement(refclock, "Mhz"))
    ("RxClk" + chid, mp7::Measurement(rxclock, "Mhz"))
    ("TxClk" + chid, mp7::Measurement(txclock, "Mhz"));
  }
  return report;
}


// ------------------------------------------------------------
ChannelManager::PointMap_t
ChannelManager::readAlignmentPoints() const {
  // Default: mLinkIDs
  const ChannelGroup& links = pickMGTIDs(mp7::kRx);

  const DatapathNode& datapath = mController.mDatapath;
  const AlignMonNode& align = mController.mAlignMon;

  PointMap_t points;

  for(const uint32_t& l :  links.channels()) {
    datapath.selectLink(l);

    points[l] = align.readPosition();
  }

  return points;

}


void
ChannelManager::resetAlignment() const {
  const ChannelGroup& links = pickMGTIDs(mp7::kRx);

  const DatapathNode& datapath = mController.mDatapath;

  const AlignMonNode& align = mController.mAlignMon;


  std::vector<uint32_t> markers;
  std::vector<uint32_t> missing;
  std::vector<uint32_t> errors;
  std::vector<uint32_t> ok;

  // Check the presence of the alignment marker on the channels
  for(const uint32_t& l :  links.channels()) {
    datapath.selectLink(l);

    // Reset the channel first
    align.reset();
    // Clear the error counter, just in case
    align.clear();

    // Check the presence of the alignment marker
    if ( !align.markerDetected() ) {
      MP7_LOG(l7::kError) << "No marker on link " << l;
      missing.push_back(l);
    } else {
      markers.push_back(l);
    }


    if ( align.readErrors() > AlignMonNode::kErrorThreshold ) {
      MP7_LOG(l7::kError) << "Marker errors on link " << l;
      for ( uint32_t i(0); i < 8; ++i)
        MP7_LOG(l7::kError) << "   -" << i << align.readErrors() << " " << align.readPosition();

      errors.push_back(l);
    } else {
      ok.push_back(l);
    }
  }

  MP7_LOG(l7::kInfo) << "Alignment markers detected on " << l7::shortVecFmt(markers);

  // If any marker is missing, stop here.
  if ( missing.size()  ) {
    std::ostringstream oss;
    oss << "Alignment marker missing on channels " << l7::shortVecFmt(missing);
    MP7_LOG(l7::kError) << oss.str();
    throw AlignmentFailed(oss.str(), missing);
  } else {
    MP7_LOG(l7::kDebug) << "Alignment marker present on all channels";
  }

  MP7_LOG(l7::kInfo) << "No alignment errors on " << l7::shortVecFmt(ok);

  // If there are errors, don't go further
  if ( errors.size()  ) {
    std::ostringstream oss;
    oss << "Alignment errors detected on channels " << l7::shortVecFmt(errors);
    MP7_LOG(l7::kError) << oss.str();
    throw AlignmentFailed(oss.str(), errors);
  } else {
    MP7_LOG(l7::kDebug) << "Alignment marker stable on all channels";
  }
}

// ------------------------------------------------------------
ChannelManager::PointMap_t
ChannelManager::findMinimaAlignmentPoints() const {
  // Default: mLinkIDs
  const ChannelGroup& rxMgts = pickMGTIDs(mp7::kRx);
  const DatapathNode& datapath = mController.mDatapath;
  const AlignMonNode& align = mController.mAlignMon;


  resetAlignment();

  AlignmentFinder lFinder(mController.mGenerics);

  PointMap_t markers;
  for(const uint32_t& lChan :  rxMgts.channels()) {
    datapath.selectLink(lChan);

    MP7_LOG(l7::kDebug) << "Minimizing latency on link " << lChan;

    orbit::Point p = lFinder.findMinimum(align);

    MP7_LOG(l7::kDebug) << "  - min: " << p;

    markers[lChan] = p;
  }

  return markers;

}


// ------------------------------------------------------------
orbit::Point
ChannelManager::minimizeAndAlign(uint32_t aMargin /* = 3 */) const {
  // Default: mLinkIDs
  const ChannelGroup& rxMgts = pickMGTIDs(mp7::kRx);


  orbit::Metric m = mController.getMetric();

  MP7_LOG(l7::kDebug) << "Minimizing latency(margin = " << aMargin << ")";;

  PointMap_t lMinima = findMinimaAlignmentPoints();

  // The minimum latency position is the maximum
  orbit::Point pmin = std::max_element(
                        lMinima.begin(),
                        lMinima.end(),
                        // minima.value_comp()
                        ( boost::bind(&PointMap_t::value_type::second, _1) <
                          boost::bind(&PointMap_t::value_type::second, _2 ) )
                      )->second;
  MP7_LOG(l7::kDebug) << "Minimum delay position found at : " << pmin;

  // Calculate the target alignment point by adding the margin to the minimum.
  orbit::Point lAlignPoint = m.addCycles(pmin, aMargin);

  MP7_LOG(l7::kDebug) << "Calculated alignment point: " << lAlignPoint;

  align(lAlignPoint);

  MP7_LOG(l7::kInfo) << "Channels " << l7::shortVecFmt(rxMgts.channels()) << " aligned to " << lAlignPoint;

  return lAlignPoint;
}


// ------------------------------------------------------------
orbit::Point
ChannelManager::minimizeAndAlign(const std::map<uint32_t, uint32_t>& aDelays, uint32_t aMargin) const {

  // Check that all rxMgts are present in the delay map
  const ChannelGroup& rxMgts = pickMGTIDs(mp7::kRx);


  // const uint32_t clockRatio = mController.mGenerics.clockRatio;

  orbit::Metric m = mController.getMetric();

  MP7_LOG(l7::kDebug) << "Minimizing latency on channels " << l7::shortVecFmt(rxMgts.regions()) << "(margin = " << aMargin << ", per channel delays applied)";


  // const AlignMonNode& align = mController.mAlignMon;

  std::vector<uint32_t> missing;
  for(const uint32_t& l :  rxMgts.channels()) {
    if ( aDelays.count(l) == 0 )
      missing.push_back(l);
  }

  if ( missing.size() ) {
    std::ostringstream oss;
    oss << "Channels " << l7::shortVecFmt(missing) << "are not in the delay map";
    throw EntryNotFoundError(oss.str());
  }

  // Find all minima
  PointMap_t minima = findMinimaAlignmentPoints();


  // Correct for the delays to find the minimum
  for( PointMap_t::value_type & p :  minima ) {
    std::ostringstream oss;
    oss << "   > " << p.first << " " << p.second << " -> ";
    // Subtract each channel its additional expected delay
    p.second = m.subCycles(p.second, aDelays.find(p.first)->second);

    oss << p.second;
    MP7_LOG(l7::kDebug1) << oss.str();
  }


  // The minimum latency position is the maximum of minima
  // Not sure how I put the comparator together, but it seems to work
  orbit::Point lMinimum = std::max_element(
                        minima.begin(),
                        minima.end(),
                        (
                          boost::bind(&PointMap_t::value_type::second, _1) <
                          boost::bind(&PointMap_t::value_type::second, _2 ) )
                      )->second;
  MP7_LOG(l7::kInfo) << "Minimum delay position found at : " << lMinimum;

  // Calculate the base alignment point by adding the margin to the minimum.
  orbit::Point lAlignPoint = m.addCycles(lMinimum, aMargin);

  MP7_LOG(l7::kDebug) << "Calculated base alignment point: " << lAlignPoint;

  align( lAlignPoint, aDelays );

  MP7_LOG(l7::kInfo) << "Channels " << l7::shortVecFmt(rxMgts.channels()) << " aligned";

  return lAlignPoint;
}


// ------------------------------------------------------------
void
ChannelManager::align( const orbit::Point& aPoint ) const {

  const ChannelGroup& rxMgts = pickMGTIDs(mp7::kRx);


//  const CtrlNode& ctrl = mController.mCtrl;
  const DatapathNode& datapath = mController.mDatapath;
  const AlignMonNode& align = mController.mAlignMon;

  orbit::Metric m = mController.getMetric();


  MP7_LOG(l7::kInfo) << "Aligning rxMgts " << l7::shortVecFmt(rxMgts.regions()) << " to " << aPoint;

  // Reset rxMgts first
  resetAlignment();

  std::vector<uint32_t> errors;
  for(const uint32_t& l :  rxMgts.channels()) {
    datapath.selectLink(l);
    MP7_LOG(l7::kDebug) << "Aligning Link " << l;
    try {
      millisleep(10);

      // And only then line all channels up
      align.moveTo( aPoint, m );

      // Then lock the reference alignment position in place for monitoring
      align.freeze();

    } catch ( AlignmentShiftFailed &ae ) {
      MP7_LOG(l7::kError) << "Failed to align link " << l << ": " << ae.what();
      errors.push_back(l);
    }
  }

  // Throw is errors are detected while aligning
  if ( errors.size() != 0 ) {
    std::ostringstream oss;
    oss << "Failed to align rxMgts " << l7::shortVecFmt(errors);
    throw AlignmentFailed(oss.str(), errors);
  }

  // Clear before leaving
  clearRxCounters();
}


// ------------------------------------------------------------
void
ChannelManager::align(const orbit::Point& aPoint, const std::map<uint32_t, uint32_t>& aDelays) const {

  const ChannelGroup& rxMgts = pickMGTIDs(mp7::kRx);

//  const CtrlNode& ctrl = mController.mCtrl;
  const DatapathNode& datapath = mController.mDatapath;
  const AlignMonNode& align = mController.mAlignMon;

  orbit::Metric m = mController.getMetric();

  MP7_LOG(l7::kInfo) << "Aligning rxMgts " << l7::shortVecFmt(rxMgts.channels()) << " to " << aPoint << " (per channel delays applied)";

  // Check that all rxMgts are present in the delay map
  std::vector<uint32_t> missing;
  for(const uint32_t& l :  rxMgts.channels()) {
    if ( aDelays.count(l) == 0 )
      missing.push_back(l);
  }

  if ( missing.size() ) {
    std::ostringstream oss;
    oss << "Channels " << l7::shortVecFmt(missing) << "are not in the delay map";
    throw EntryNotFoundError(oss.str());
  }

  // Everybody back to square 0
  resetAlignment();

  // Small wait (not really necessary)
  millisleep(10);

  // Apply the per-link delay, reset and move the pointer
  std::vector<uint32_t> errors;
  for(const uint32_t& l :  rxMgts.channels()) {

    orbit::Point palign;
    uint32_t delay = aDelays.find(l)->second;

    palign = m.addCycles(aPoint, delay);

    datapath.selectLink(l);
    MP7_LOG(l7::kDebug) << "Aligning channel " << l << " to " << palign;
    try {

      // And only then line all channels up
      align.moveTo( palign, m );

      // Then lock the reference alignment position in place for monitoring
      align.freeze();

    } catch ( AlignmentFailed &ae ) {
      MP7_LOG(l7::kError) << "Failed to align link " << l << ": " << ae.what();
      errors.push_back(l);
    }
  }

  // Throw is errors are detected while aligning
  if ( errors.size() != 0 ) {
    std::ostringstream oss;
    oss << "Failed to align rxMgts " << l7::shortVecFmt(errors);
    throw AlignmentFailed(oss.str(), errors);
  }

  // Clear before leaving
  clearRxCounters();
}


// ------------------------------------------------------------
void
ChannelManager::freezeAlignment( bool aFreeze ) const {

  const ChannelGroup& rxMgts = pickMGTIDs(mp7::kRx);

  const DatapathNode& datapath = mController.mDatapath;
  const AlignMonNode& align = mController.mAlignMon;

  for(const uint32_t& l :  rxMgts.channels()) {
    datapath.selectLink(l);
    align.freeze( aFreeze);
  }

}


// ------------------------------------------------------------
void
ChannelManager::configureBuffers(RxTxSelector aSelection, const PathConfigurator& aConfigurator ) const {

  // Fetch the list of buffers ids
  const ChannelGroup& buffers = pickBufferIDs(aSelection);

  // Local References
  const DatapathNode& datapath = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;


  for(const uint32_t& c :  buffers.channels()) {
    datapath.selectLinkBuffer(c, aSelection);
    aConfigurator.configure(buf);
  }
}


// ------------------------------------------------------------
void
ChannelManager::clearBuffers(mp7::RxTxSelector aSelection) const {

  // Fetch the list of buffers ids

  const ChannelGroup& buffers = pickBufferIDs(aSelection);

  // Local References
  const DatapathNode& datapath = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;

  for(const uint32_t& c :  buffers.channels()) { // was mBufferIDs.enabled();
    datapath.selectLinkBuffer(c, aSelection);
    MP7_LOG(l7::kDebug) << "Clearing " << aSelection << "." << c;
    buf.clear();
  }

}


// ------------------------------------------------------------
void
ChannelManager::clearBuffers(mp7::RxTxSelector aSelection, ChanBufferNode::BufMode aMode ) const {

  // Fetch the list of buffers ids
  const ChannelGroup& buffers = pickBufferIDs(aSelection);

  // Local References
  const DatapathNode& datapath = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;

  for(const uint32_t& c :  buffers.channels()) { // was mBufferIDs.enabled();
    datapath.selectLinkBuffer(c, aSelection);
    if ( buf.readBufferMode() != aMode )
      continue;
    MP7_LOG(l7::kDebug) << "Clearing " << aSelection << "." << c;
    buf.clear();
  }

}

// ------------------------------------------------------------
mp7::BoardData
ChannelManager::readBuffers(mp7::RxTxSelector aSelection) const {
  const ChannelGroup& buffers = pickBufferIDs(aSelection);

  const DatapathNode& datapath = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;

  size_t depth = buf.getBufferSize();
  mp7::BoardData data(mController.id());

  MP7_LOG(l7::kInfo) << "Reading " << aSelection << " channels: " << l7::shortVecFmt(buffers.channels()) << " (" << depth << " words each)";

  for(const uint32_t c :  buffers.channels()) {
    MP7_LOG(l7::kDebug) << "  - Reading " << aSelection << "." << c;
    datapath.selectLinkBuffer(c, aSelection);

    // Get the buffer configuration
    ChanBufferNode::Configuration cfg = buf.readConfiguration();
    data[c] = buf.download(depth);
    // Mark the link as "strobed" if either the strobe buffer playback or capture strobe override is enabled
    data[c].setStrobed( cfg.stbsrc == ChanBufferNode::kBufferStrobe or cfg.captureStrobeOverride);
  }

  return data;
}



// ------------------------------------------------------------
void ChannelManager::loadPatterns(mp7::RxTxSelector aSelection, const mp7::BoardData& aData) const {
  const ChannelGroup& buffers = pickBufferIDs(aSelection);

  const DatapathNode& datapath = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;

  // TODO add a catch for out-of-range exceptions
  for(const uint32_t& c :  buffers.channels()) {
    MP7_LOG(l7::kDebug) << "Loading pattern to " << aSelection << "." << c;
    datapath.selectLinkBuffer(c, aSelection);
    buf.upload(aData.link(c));
  }

}


// ------------------------------------------------------------
void ChannelManager::waitCaptureDone() const {

  const ChannelGroup& rxbufs = mDescriptor.pickRxBufferIDs(kBuffer);
  const ChannelGroup& txbufs = mDescriptor.pickTxBufferIDs(kBuffer);

  const DatapathNode& datapath = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;

  bool done = true;

  std::vector<uint32_t> rxNotDone, txNotDone;

  // Simple loop over the channels (no timeout) because the fpga logic is much faster than this loop.
  for(const uint32_t& c :  rxbufs.channels()) {
    datapath.selectLinkBuffer(c, kRx);

    if ( buf.readBufferMode() == ChanBufferNode::kCapture ) {
      if ( not buf.hasCaptured() ) {
        rxNotDone.push_back(c);
        done = false;
      }

      MP7_LOG(l7::kDebug) << "Buffer " << kRx << "." << c << " capture_done = " << buf.hasCaptured();
    }
  }

  for(const uint32_t& c :  txbufs.channels()) {
    datapath.selectLinkBuffer(c, kTx);

    if ( buf.readBufferMode() == ChanBufferNode::kCapture ) {
      if ( not buf.hasCaptured() ) {
        txNotDone.push_back(c);
        done = false;
      }

      MP7_LOG(l7::kDebug) << "Buffer " << kTx << "." << c << " capture_done = " << buf.hasCaptured();
    }

  }

  if ( not done ) {
    std::ostringstream oss;
    oss << "Failed to capture on channels Rx " << l7::shortVecFmt(rxNotDone)  << ", Tx " << l7::shortVecFmt(txNotDone);
    throw CaptureFailed(oss.str());
  }

  MP7_LOG(l7::kNotice) << "Capture completed ";
}


// ------------------------------------------------------------
std::map<uint32_t, uint32_t>
ChannelManager::readBankSummary() const {


  const DatapathNode& dp = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;


  // Create a bankID histogram
  std::map<uint32_t, uint32_t> bankMap;

  const ChannelGroup& rxBufs = mDescriptor.pickRxBufferIDs(kBuffer);
  for(const uint32_t& c :  rxBufs.channels()) {
    dp.selectLinkBuffer(c, mp7::kRx);

    ++bankMap[buf.readDAQBank()];
  }

  const ChannelGroup& txBufs = mDescriptor.pickTxBufferIDs(kBuffer);
  for(const uint32_t& c :  txBufs.channels()) {
    dp.selectLinkBuffer(c, mp7::kTx);

    ++bankMap[buf.readDAQBank()];
  }

  return bankMap;
}


// ------------------------------------------------------------
std::map<uint32_t, uint32_t>
ChannelManager::readBankDetails( RxTxSelector aSelection ) const {

  const DatapathNode& dp = mController.mDatapath;
  const ChanBufferNode& buf = mController.mBuffer;

  // Create a bankID histogram
  std::map<uint32_t, uint32_t> bankMap;

  const ChannelGroup& bufs = pickBufferIDs(aSelection);
  for(const uint32_t& c :  bufs.channels()) {
    dp.selectLinkBuffer(c, aSelection);

    bankMap[c] = buf.readDAQBank();
  }

  return bankMap;

}


// ------------------------------------------------------------
void
ChannelManager::configureHdrFormatters( FormatterKind aFmtKind, uint32_t aStrip,  uint32_t aInsert ) {

  if ( aFmtKind != kTDRFormatter and aFmtKind != kDemuxFormatter ) {
    // Throw something
  }

  const ChannelGroup& fmts = mDescriptor.pickFmtIDs(aFmtKind);

  MP7_LOG(l7::kInfo) << "Configuring " << aFmtKind << " header formatting on regions: " << l7::shortVecFmt(fmts.regions());

  const DatapathNode& datapath = mController.mDatapath;
  const FormatterNode& fmt = mController.mFmtNode;

  for(const uint32_t& r :  fmts.regions()) {
    datapath.selectRegion(r);
    MP7_LOG(l7::kInfo) << " Header stripping for region: " << r << " strip = " << aStrip << " insert = " << aInsert;
    fmt.stripInsert(aStrip, aInsert);
  }
}


// ------------------------------------------------------------
void
ChannelManager::configureDVFormatters( const orbit::Point& aStart, const orbit::Point& aStop ) {

  const ChannelGroup& fmts = mDescriptor.pickFmtIDs(kDemuxFormatter);
  orbit::Metric m = mController.getMetric();

  MP7_LOG(l7::kInfo) << "Configuring " << kDemuxFormatter << " datavalid override "<< aStart << "-" << aStop << " on regions: " << l7::shortVecFmt(fmts.regions());

  const DatapathNode& datapath = mController.mDatapath;
  const FormatterNode& fmt = mController.mFmtNode;

  const orbit::Point& lFirst = m.subCycles(aStart,1);
  const orbit::Point& lLast = m.subCycles(aStop,1);

  for(const uint32_t& r :  fmts.regions()){
    datapath.selectRegion(r);
    fmt.overrideValid( lFirst, lLast );
  }
}

// ------------------------------------------------------------
void
ChannelManager::disableDVFormatters() {

  const ChannelGroup& fmts = mDescriptor.pickFmtIDs(kDemuxFormatter);

  MP7_LOG(l7::kInfo) << "Disabling " << kDemuxFormatter << " datavalid override on regions: " << l7::shortVecFmt(fmts.regions());
  
  const DatapathNode& datapath = mController.mDatapath;
  const FormatterNode& fmt = mController.mFmtNode;

  for(const uint32_t& r :  fmts.regions()){
    datapath.selectRegion(r);
    fmt.enableValidOverride( false );

  }
}

} // namespace mp7
