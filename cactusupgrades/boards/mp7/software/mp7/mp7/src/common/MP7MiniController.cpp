#include "mp7/MP7MiniController.hpp"


#include "mp7/Logger.hpp"
#include "mp7/CtrlNode.hpp"
#include "mp7/TTCNode.hpp"
#include "mp7/DatapathNode.hpp"
#include "mp7/FormatterNode.hpp"

#include "mp7/definitions.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/AlignMonNode.hpp"
#include "mp7/operators.hpp"
#include <iomanip>

// Namespace declaration
namespace l7 = mp7::logger;

namespace mp7 {

// Static Members initialisation
const size_t MP7MiniController::maxQuads = 18;

const size_t MP7MiniController::maxNchans = maxQuads * 4;

const std::string MP7MiniController::sharePath = MP7MiniController::getDefaultSharePath();


//---
std::string 
MP7MiniController::getDefaultSharePath(){
  std::string lPath = MP7_ETC_DEFAULT ;

  if(char* lEnvVar = std::getenv("MP7_ETC"))
  {
    lPath = lEnvVar;
    lPath += "/mp7";
  }

  return lPath;
}

//---
MP7MiniController::MP7MiniController(const uhal::HwInterface& aHw) :
  mBuilt(false),
  mHw(aHw),
  mCtrl(mHw.getNode<CtrlNode>("ctrl")),
  mTTC(mHw.getNode<TTCNode>("ttc")),
  mDatapath(mHw.getNode<DatapathNode>("datapath")),
  mFmtNode(mHw.getNode<FormatterNode>("datapath.region.formatter")),
  mMGTs(mHw.getNode<MGTRegionNode>("datapath.region.mgt")),
  mBuffer(mHw.getNode<ChanBufferNode>("datapath.region.buffer")),
  mAlignMon(mHw.getNode<AlignMonNode>("datapath.region.align"))
  {


  MP7_LOG(l7::kDebug) << "Discovering MP7 Core " << id();

  // uint32_t design = mCtrl.readDesign();
  uint32_t fwrev = mCtrl.readFwRevision();
  uint32_t algorev = mCtrl.readAlgoRevision();


  // std::set<uint32_t> knownKinds = { kMP7Xe, kMP7R1, kMP7Sim };
  // auto it = knownKinds.find(design);
  // mKind = ( it != knownKinds.end() ? static_cast<MP7Kind>(*it) : kMP7Unknown );
   
  // MP7_LOG(l7::kDebug) << "Desing " << mKind;
  MP7_LOG(l7::kDebug) << "Firmware Revision " << std::hex << std::showbase << fwrev;
  MP7_LOG(l7::kDebug) << "Algorithm Revision " << std::hex << std::showbase << algorev;

  // MP7_LOG(l7::kInfo) << "Building MP7 controller " << id();
  
  // Store generics locally
  Snapshot gens = mp7::snapshot(mCtrl.getNode("id.generics"));
  
  mGenerics.nRegions = gens.at("n_region");
  mGenerics.bunchCount = gens.at("bunch_count");
  mGenerics.clockRatio = gens.at("clock_ratio");
  mGenerics.roChunks = gens.at("ro_chunks");

  // Populate regions and channels
  this->populateIDs();
}

//---
MP7MiniController::~MP7MiniController() {
}


void MP7MiniController::populateIDs() {
  
  std::vector<uint32_t> regions = mCtrl.readRegions();
  std::map<uint32_t, RegionInfo> riMap = mDatapath.readRegionInfoMap(regions);
  mDescriptor = DatapathDescriptor(riMap);

}


//---
bool MP7MiniController::isBuilt() const {
  return isBuilt();
}

//---
std::string
MP7MiniController::id() const {
  return mHw.id();
}

// void MP7CoreController::populateIDs() {
  
//   std::vector<uint32_t> regions = mCtrl.readRegions();
//   std::map<uint32_t, RegionInfo> riMap = mDatapath.readRegionInfoMap(regions);
//   mDescriptor = DatapathDescriptor(riMap);

// }


//---
void
MP7MiniController::identify() const {

  uhal::ValWord<uint32_t> a(mCtrl.getNode("id.fwrev.a").read());
  uhal::ValWord<uint32_t> b(mCtrl.getNode("id.fwrev.b").read());
  uhal::ValWord<uint32_t> c(mCtrl.getNode("id.fwrev.c").read());
  uhal::ValWord<uint32_t> design(mCtrl.getNode("id.fwrev.design").read());
  uhal::ValWord<uint32_t> algorev(mCtrl.getNode("id.algorev").read());
  mCtrl.getClient().dispatch();

  std::ostringstream fwrevStream;
  fwrevStream 
    << "design: 0x" << std::setfill ('0') << std::setw (2) << std::hex << design
    << " infra: 0x" << std::setfill ('0') << std::setw (6) << std::hex << ( (a << 16) + (b << 8) + c) 
    << " algo: 0x" << std::setfill ('0') << std::setw (8) << algorev;
  MP7_LOG(l7::kInfo) << "Firmware revision - " << fwrevStream.str();
  
  std::ostringstream oss;
  // Input MGTs
  oss.str("");  
  oss << "Channels - ";
  ChannelGroup all = mDescriptor.pickAllIDs();
  oss << l7::shortVecFmt(all.channels()) << "  ";
  MP7_LOG(l7::kInfo) << oss.str();

  // Input MGTs
  oss.str("");
  oss << "iMGTs - ";
  for(MGTKind k :  kKnownMGTs) {
    ChannelGroup iMgts = mDescriptor.pickRxMGTIDs(k);
    if ( iMgts.channels().empty() ) continue;

    oss << k << ":" << l7::shortVecFmt(iMgts.channels()) << "  ";
  }
  MP7_LOG(l7::kDebug) << oss.str();


  // Input CheckSums
  oss.str("");
  oss << "iChks - ";
  for(CheckSumKind k :  kKnownCheckSums) {
    ChannelGroup iChks = mDescriptor.pickRxCheckSumIDs(k);
    if ( iChks.channels().empty() ) continue;

    oss << k << ":" << l7::shortVecFmt(iChks.channels()) << "  ";
  }
  MP7_LOG(l7::kDebug) << oss.str();


  // Input Buffers
  oss.str("");
  oss << "iBufs - ";
  for(BufferKind k :  kKnownBuffers) {

    ChannelGroup iBufs = mDescriptor.pickRxBufferIDs(k);
    if ( iBufs.channels().empty() ) continue;

    oss << k << ":" << l7::shortVecFmt(iBufs.channels()) << "  ";
  }
  MP7_LOG(l7::kDebug) << oss.str();


  // Formatters
  oss.str("");
  oss << "Fmts  - ";
  for(FormatterKind k :  kKnownFormatters) {

    ChannelGroup fmts = mDescriptor.pickFmtIDs(k);
    if ( fmts.channels().empty() ) continue;

    oss << k << ":" << l7::shortVecFmt(fmts.channels()) << "  ";
  }
  MP7_LOG(l7::kDebug) << oss.str();


  // output buffers
  oss.str("");
  oss << "oBufs - ";
  for(BufferKind k :  kKnownBuffers) {
    ChannelGroup oBufs = mDescriptor.pickTxBufferIDs(k);
    if ( oBufs.channels().empty() ) continue;

    oss << k << ":" << l7::shortVecFmt(oBufs.channels()) << "  ";
  }
  MP7_LOG(l7::kDebug) << oss.str();

  // Output CheckSums
  oss.str("");
  oss << "oChks - ";
  for(CheckSumKind k :  kKnownCheckSums) {
    ChannelGroup oChks = mDescriptor.pickTxCheckSumIDs(k);
    if ( oChks.channels().empty() ) continue;

    oss << k << ":" << l7::shortVecFmt(oChks.channels()) << "  ";
  }
  MP7_LOG(l7::kDebug) << oss.str();

  // Output MGTs
  oss.str("");
  oss << "oMGTs - ";
  for(MGTKind k :  kKnownMGTs) {
    ChannelGroup oMgts = mDescriptor.pickTxMGTIDs(k);
    if ( oMgts.channels().empty() ) continue;

    oss << k << ":" << l7::shortVecFmt(oMgts.channels()) << "  ";
  }
  MP7_LOG(l7::kDebug) << oss.str();

}


// GETTERS
//---
const Generics&
MP7MiniController::getGenerics() const {
  return mGenerics;
}

orbit::Metric
MP7MiniController::getMetric() const {
  return orbit::Metric(mGenerics);
}


//---
uhal::HwInterface&
MP7MiniController::hw() {
  return mHw;
}


//---
ChannelGroup
MP7MiniController::getChannelIDs() const {
  return mDescriptor.pickAllIDs();
}

//---
const mp7::CtrlNode&
MP7MiniController::getCtrl() const {
  return mCtrl;
}


//---
const mp7::TTCNode&
MP7MiniController::getTTC() const {
  return mTTC;
}


//---
const mp7::DatapathNode&
MP7MiniController::getDatapath() const {
  return mDatapath;
}


//---
const mp7::FormatterNode&
MP7MiniController::getFormatter() const {
 return mFmtNode;
}


//---
const mp7::AlignMonNode&
MP7MiniController::getAlignmentMonitor() const {
  return mAlignMon;
}


//---
const mp7::ChanBufferNode&
MP7MiniController::getBuffer() const {
  return mBuffer;
}


//---
mp7::ChannelManager
MP7MiniController::channelMgr() const {
  return ChannelManager(*this );
}


//---
mp7::ChannelManager MP7MiniController::channelMgr(const std::vector<uint32_t>& aSelection) const{
  
  // Make a sorted copy of the selection
  std::vector<uint32_t> sorted  = sanitize(aSelection);
  
  return ChannelManager(*this, sorted);
}

//---
void MP7MiniController::checkTTC() {
  Snapshot csrSnapshot = mp7::snapshot(mCtrl.getNode("csr"));
  Snapshot ttcSnapshot = mp7::snapshot(mTTC);

  double freq = 0.;
  try {
    freq = mTTC.measureClockFreq(TTCNode::kClock40);
  } catch (const mp7::TTCFrequencyInvalid& e) {
    MP7_LOG(l7::kError) << "Exception mp7::TTCFrequencyInvalid -- " << e.what();
  }

  std::ostringstream logEntry;
  logEntry << "TTC stats" << std::endl;
  logEntry
      << "                       Measured f40 : " << freq << " MHz" << std::endl << std::hex
      << "                       BC0 Internal : 0x" << ttcSnapshot["csr.ctrl.int_bc0_enable"] << std::endl
      << "                       BC0 Lock     : 0x" << ttcSnapshot["csr.stat0.bc0_lock"] << std::endl
      << "                       BC0 Error    : 0x" << ttcSnapshot["csr.stat0.bc0_err"] << std::endl
      << "                       Dist lock    : 0x" << ttcSnapshot["csr.stat0.dist_lock"] << std::endl;
  logEntry << "                       Status: 0x" << csrSnapshot["stat"]
      << ", Bunch: 0x" << ttcSnapshot["csr.stat0.bunch_str"]
      << ", Evt:   0x" << ttcSnapshot["csr.stat1.evt_ctr"]
      << ", Orb    0x" << ttcSnapshot["csr.stat2.orb_ctr"] << std::dec;

  MP7_LOG(l7::kInfo) << logEntry.str();

  MP7_LOG(l7::kInfo) << "Errors ... ";
  MP7_LOG(l7::kInfo) << "   Single Bit Errors: " << ttcSnapshot["csr.stat3.single_biterr_ctr"];
  MP7_LOG(l7::kInfo) << "   Double Bit Errors: " << ttcSnapshot["csr.stat3.double_biterr_ctr"];

  MP7_LOG(l7::kInfo) << "---- Breakdown";
  //TODO: Sorted sequence of registers may be better here
  for (Snapshot::const_iterator it = ttcSnapshot.begin(); it != ttcSnapshot.end(); it++)
    MP7_LOG(l7::kDebug) << "      " << it->first << " : " << l7::hexFmt(it->second);
  MP7_LOG(l7::kDebug) << "----";
}


//---
std::vector<uint32_t>
MP7MiniController::scanTTCPhase(const uint32_t aStart, const uint32_t aStop) {
  MP7_LOG(l7::kWarning) << "Resetting clock 40 and TTC phase settings, in preparation for phase scan";

  // Reset clock 40 in order to reset the TTC phase setting before the scan
  mCtrl.getNode("csr.ctrl.clk40_rst").write(0x1);
  mCtrl.getClient().dispatch();
  mp7::millisleep(100);
  mCtrl.getNode("csr.ctrl.clk40_rst").write(0x0);
  mCtrl.getClient().dispatch();

  mCtrl.waitClk40Lock();

  MP7_LOG(l7::kInfo) << "TTC phase scan range: " << l7::hexFmt(aStart) << " - " << l7::hexFmt(aStop);
  mTTC.getNode("csr.ctrl1.ttc_phase_en").write(1);
  mTTC.getClient().dispatch();

  std::vector<uint32_t> goodPhases;

  for (uint32_t i = aStart; i < aStop; i++) {
    mTTC.getNode("csr.ctrl1.ttc_phase").write(i);
    mTTC.getClient().dispatch();
    uhal::ValWord<uint32_t> phase_ok = mTTC.getNode("csr.stat0.ttc_phase_ok").read();
    mTTC.getClient().dispatch();
    if (phase_ok.value() != 0x1) {
      MP7_LOG(l7::kWarning) << "Phase not locked : " << l7::hexFmt(phase_ok);
    }

    mTTC.getNode("csr.ctrl.err_ctr_clear").write(1);
    mTTC.getNode("csr.ctrl.err_ctr_clear").write(0);
    mTTC.getClient().dispatch();
    mp7::millisleep(10);
    uhal::ValWord<uint32_t> errs = mTTC.getNode("csr.stat3").read();
    mTTC.getClient().dispatch();
    MP7_LOG(l7::kDebug) << "phase " << i << " -> error counts: " << l7::hexFmt(errs);
    if (errs.value() == 0)
      goodPhases.push_back(i);
  }

  mTTC.getNode("csr.ctrl1.ttc_phase_en").write(0);
  mTTC.getClient().dispatch();

  MP7_LOG(l7::kInfo) << "Good TTC phases are: " << l7::shortVecFmt<uint32_t>(goodPhases) << " / [" << aStart << "," << aStop << "]";
  return goodPhases;
}

} // namespace mp7