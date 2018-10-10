#include "mp7/TTCNode.hpp"


#include "mp7/exception.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"

// Boost Headers
#include <boost/filesystem.hpp>
//#include <boost/foreach.hpp>


// Namespace resolution
using namespace std;
using namespace uhal;

namespace l7 = mp7::logger;

namespace mp7 {
UHAL_REGISTER_DERIVED_NODE(TTCNode);

// PRIVATE CONSTANTS
// const uint32_t TTCNode::mBTestCode = 0xc;
const float TTCNode::kClockRate = 40e6;
const std::vector<TTCBCommand> TTCNode::kCtrIndexes = {
    kHardReset,     // TTC_BCMD_HARD_RESET,
    kTestEnable,    // TTC_BCMD_TEST_ENABLE,
    kBC0,           // TTC_BCMD_BC0,
    kEC0,           // TTC_BCMD_EC0,
    kResync,        // TTC_BCMD_RESYNC,
    kOC0,           // TTC_BCMD_OC0,
    kTest,          // TTC_BCMD_TEST_SYNC,
    kStart,         // TTC_BCMD_START,
    kStop           // TTC_BCMD_STOP
};


// PUBLIC METHODS

//---
TTCNode::TTCNode(const uhal::Node& aNode) :
uhal::Node(aNode) {
}

//---
TTCNode::~TTCNode() {
}


//---
void
TTCNode::configure(const ConfigParams& aConfig) const {
    // TODO: Put some meat on.
    
    // enable ttc L1As and Bgo commands
    enable(aConfig.enable);

    // Set phase after enabling TTC and BGos
    if ( aConfig.enable )
        setPhase(aConfig.phase);

    // clear counters
    clear();

    generateInternalBC0(aConfig.generateBC0);

    waitBC0Lock();

    waitGlobalBC0Lock();
}


//---
void
TTCNode::enable(bool enable) const {
    getNode("csr.ctrl.ttc_enable").write(enable);
    getClient().dispatch();
}

void
TTCNode::generateInternalBC0(bool enable) const {
    getNode("csr.ctrl.int_bc0_enable").write(enable);
    getClient().dispatch();
}

//---
void TTCNode::setPhase(uint32_t aPhase) const {
   
    // Enable the phase shift only if aPhase is != 0 (which is default) 
    getNode("csr.ctrl1.ttc_phase_en").write( bool(aPhase) );
  
    // Then set the phase
    getNode("csr.ctrl1.ttc_phase").write(aPhase);

    getClient().dispatch();

    // Little nap required
    mp7::millisleep(10);

    // And check the locking
    uhal::ValWord<uint32_t> phase_ok = getNode("csr.stat0.ttc_phase_ok").read();
    getClient().dispatch();
    
    if (phase_ok != 1 )
        throw mp7::TTCPhaseError("Failed to set TTC phase to "+to_string(aPhase));
}


//---
void
TTCNode::clear() const {
    getNode("csr.ctrl.err_ctr_clear").write(1);
    getNode("csr.ctrl.err_ctr_clear").write(0);
    getNode("csr.ctrl.ctr_clear").write(1);
    getNode("csr.ctrl.ctr_clear").write(0);
    getClient().dispatch();
}

void
TTCNode::clearErrors() const {
    getNode("csr.ctrl.err_ctr_clear").write(1);
    getNode("csr.ctrl.err_ctr_clear").write(0);
    getClient().dispatch();
}


//---
void
TTCNode::forceL1A() const {
    MP7_LOG(l7::kDebug) << "Injecting l1a now!";

    // Async cmd
    getNode("csr.ctrl.ttc_sync_en").write(0x0);
    // Fire
    getNode("csr.ctrl.l1a_force").write(0x1);
    getNode("csr.ctrl.l1a_force").write(0x0);
    getClient().dispatch();
}

void
TTCNode::forceL1AOnBx( uint32_t aBx ) const {
  
    MP7_LOG(l7::kDebug) << "Injecting l1a on bx " << aBx;

    // Enable sync
    getNode("csr.ctrl.ttc_sync_en").write(0x1);
    getNode("csr.ctrl.ttc_sync_bx").write(aBx);

    // Fire
    getNode("csr.ctrl.l1a_force").write(0x1);
    getNode("csr.ctrl.l1a_force").write(0x0);
    getClient().dispatch();
}

//---
void
TTCNode::forceBCmd(uint32_t aCode) const {

    MP7_LOG(l7::kDebug) << "Injecting B-cmd: " << std::showbase << std::hex << aCode << " now!";
    // Async cmd
    getNode("csr.ctrl.ttc_sync_en").write(0x0);
    getNode("csr.ctrl.b_cmd").write(aCode);

    // Fire
    getNode("csr.ctrl.b_cmd_force").write(0x1);
    getNode("csr.ctrl.b_cmd_force").write(0x0);
    getClient().dispatch();
}


//---
void
TTCNode::forceBCmdOnBx(uint32_t aCode, uint32_t aBx) const {

  MP7_LOG(l7::kDebug) << "Injecting B-cmd: " << std::showbase << std::hex << aCode << " on bx " << aBx;

  // Enable sync
    getNode("csr.ctrl.ttc_sync_en").write(0x1);
    getNode("csr.ctrl.ttc_sync_bx").write(aBx);

    // Fire
    getNode("csr.ctrl.b_cmd").write(aCode);
    getNode("csr.ctrl.b_cmd_force").write(0x1);
    getNode("csr.ctrl.b_cmd_force").write(0x0);
    getClient().dispatch();
}

//---
void
TTCNode::forceBTest() const {
    this->forceBCmd(kTest);
}


//---
void TTCNode::maskHistoryBC0L1a(bool aMask) const {
  const StateHistoryNode& hist = getNode<StateHistoryNode>("hist");
  hist.mask(aMask);
  // Clear the history by default
  hist.clear();
  
}


//---
std::vector<TTCHistoryEntry>
TTCNode::captureHistory() const {

  std::vector<HistoryEntry> tmp = getNode<StateHistoryNode>("hist").capture();

  std::vector<TTCHistoryEntry> hist;
  hist.reserve(tmp.size());
  
  for( const HistoryEntry& he :  tmp) {
    TTCHistoryEntry e;
    //e.cyc = he.cyc;
    e.bx = he.bx;
    e.orbit = he.orbit;
    e.event = he.event;
    e.l1a   = ( (he.data & 0x800) >> 11 ) ;
    e.cmd   = (he.data & 0xff);
    
    hist.push_back(e);
    
  }
  MP7_LOG(l7::kInfo) << "TTCHistory: " << hist.size() << " values captured";

  return hist;
  
}


//---
void
TTCNode::waitBC0Lock() const {
    uhal::ValWord< uint32_t > bc0_lock(0);
    int countdown = 100 ;

    while (countdown > 0) {
        bc0_lock = getNode("csr.stat0.bc0_lock").read();
        getClient().dispatch();
        
        if (bc0_lock) {
            break;
        }

        countdown--;
        millisleep(10);
    }

    if (countdown == 0) {
        mp7::BC0LockFailed lExc("Timed out waiting for bc0_lock signal");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }

    MP7_LOG(l7::kNotice) << "TTC BC0 Locked";
}

//---
void
TTCNode::waitGlobalBC0Lock() const {
    uhal::ValWord< uint32_t > bc0_lock(0);
    int countdown = 100 ;

    while (countdown > 0) {
        bc0_lock = getNode("csr.stat0.dist_lock").read();
        getClient().dispatch();
        
        if (bc0_lock) {
            break;
        }

        countdown--;
        millisleep(10);
    }

    if (countdown == 0) {
        mp7::BC0LockFailed lExc("Timed out waiting for dist_lock signal");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }

    MP7_LOG(l7::kNotice) << "Global BC0 Locked";
}

//---
bool
TTCNode::readBC0Locked() const {
    uhal::ValWord<uint32_t> lock = getNode("csr.stat0.bc0_lock").read();
    getClient().dispatch();
    return  lock.value();
}

//---
double
TTCNode::measureClockFreq(FreqClockChannel aChan, bool aCrap) const {

    getNode("freq.ctrl.chan_sel").write(aChan);
    getNode("freq.ctrl.en_crap_mode").write(aCrap);
    getClient().dispatch();
    
    // Wait for 1.1 seconds if not in crap mode, 0.11 otherwise.
    millisleep( ( aCrap ? 0.11 : 1.1 ) * 1000);
    uhal::ValWord<uint32_t> fq = getNode("freq.freq.count").read();
    uhal::ValWord<uint32_t> fv = getNode("freq.freq.valid").read();
    getClient().dispatch();

    if (fv == 0) {
        throw mp7::TTCFrequencyInvalid("TTC Frequency Measurement not valid");
    }

    return int ( fq) * 119.20928 / 1000000;
}
 

uint32_t
TTCNode::readBunchCounter() const {
    uhal::ValWord<uint32_t> ctr = getNode("csr.stat0.bunch_ctr").read();
    getClient().dispatch();
    return ctr.value();
}

uint32_t
TTCNode::readOrbitCounter() const {
    uhal::ValWord<uint32_t> ctr = getNode("csr.stat2.orb_ctr").read();
    getClient().dispatch();
    return ctr.value();
}

uint32_t
TTCNode::readEventCounter() const {
    uhal::ValWord<uint32_t> ctr = getNode("csr.stat1.evt_ctr").read();
    getClient().dispatch();
    return ctr.value();
}

uint32_t
TTCNode::readSingleBitErrorCounter() const {
    uhal::ValWord<uint32_t> ctr = getNode("csr.stat3.single_biterr_ctr").read();
    getClient().dispatch();
    return ctr.value();
}

uint32_t
TTCNode::readDoubleBitErrorCounter() const {
    uhal::ValWord<uint32_t> ctr = getNode("csr.stat3.double_biterr_ctr").read();
    getClient().dispatch();
    return ctr.value();
}

uint32_t
TTCNode::readBCmdCounter( TTCBCommand aCommand ) const {

    std::vector<TTCBCommand>::const_iterator lIt = std::find(kCtrIndexes.begin(), kCtrIndexes.end(), aCommand);
    // TODO: Check lIt != kCtrIndexes.end()

    uint32_t lIndex = std::distance(kCtrIndexes.begin(), lIt);

    getNode("cmd_ctrs.ctr_sel").write(lIndex);
    uhal::ValWord<uint32_t> ctr = getNode("cmd_ctrs.ctr").read();
    getClient().dispatch();

    return ctr;
}


std::map<std::string, std::string>
TTCNode::report() const {
    std::map<std::string, std::string> report;
    Snapshot ttccsr = snapshot(getNode("csr"));

    double freq = -1.;
    try {
        freq = this->measureClockFreq(TTCNode::kClock40);
    } catch (const mp7::TTCFrequencyInvalid& e) {
        // Nothing to do. The exception is already logged when thrown
    }
    
    report["Measured Clock40 Frequency"] = ( freq >= 0. ? strprintf("%.3f MHz", freq) : "Failed");
    report["BC0 Register"] = strprintf("0x%x", ttccsr["stat0"] >> 16);
    report["BC0 Internal"] = ( ttccsr["ctrl.int_bc0_enable"] ? "Ok" : "Off");
    report["BC0 Lock"]     = ( ttccsr["stat0.bc0_lock"] ? "Yes" : "No");
    // report["BC0 Error"]    = ( ttccsr["stat0.bc0_err"] ? "Yes" : "No");
    report["Dist Lock"]    = ( ttccsr["stat0.dist_lock"] ? "Yes" : "No");
    
    return report;

}



//---
void TTCNode::generateRandomL1As(float aRate) const {
  
  float maxRate = kClockRate/4;
  
  if ( aRate < 0 ) {
      throw ArgumentError("Aaargh, negative rate requested!");
  }
  
  if ( aRate > maxRate ) {
    // Alternative, set it to the max
    throw ArgumentError("Aaargh, rate too high");
  }
  
  uint32_t rate = 0x3fffffff * (aRate/maxRate);
  
  MP7_LOG(l7::kWarning) << "Input rate = " << aRate << " hex " << rate;
  
  getNode("l1_gen.ctrl.rate").write(rate);
  getClient().dispatch();
  
}

//---
void TTCNode::enableL1ATrgRules(bool aEnable) const {
  getNode("l1_gen.ctrl.rules_en").write(aEnable);
  getClient().dispatch();
}


//---
void
TTCNode::enableL1AThrottling(bool aEnable) const {
  getNode("csr.ctrl.throttle_en").write(aEnable);
  getClient().dispatch();
}


//---
TTCConfigurator::TTCConfigurator(const std::string aFilename, const std::string& kind, const std::string& aPrefix) {

    boost::filesystem::path prefix, file;
    
    if ( aPrefix.size() != 0 )
        prefix /= aPrefix;
    
    // R1 files are in {aPrefix}/ttc/
    file = ( prefix / kind / "ttc" / aFilename );
    
    // This is the configuration
    mConfig = parseFromXML(file.string());

    // Load file
//    mConfig = parseFromXML(aFilename);
}

//---
TTCConfigurator::~TTCConfigurator() {
}

//---
const 
TTCNode::ConfigParams& TTCConfigurator::getConfig() {
    return mConfig;
}


//---
void 
TTCConfigurator::configure(const TTCNode& aTTC) {
    aTTC.configure(mConfig);
}


//---
TTCNode::ConfigParams 
TTCConfigurator::parseFromXML(const std::string& aFilePath) {

    pugi::xml_document doc;

    boost::filesystem::path p(shellExpandPath(aFilePath));

    if ( !boost::filesystem::exists(p) ) {
        mp7::FileNotFound e("TTC config file \"" + p.string() + "\" not found");
        MP7_LOG(l7::kError) << e.what();
        throw e;
    }

    if (!doc.load_file(p.c_str())) {
        mp7::InvalidConfigFile e("Could not load TTC config file \"" + p.string() + "\"");
        MP7_LOG(l7::kError) << e.what();
        throw e;
    }


    TTCNode::ConfigParams cfg;
    
    pugi::xml_node top = xml::get_valid_node(doc, "ttccfg");
    cfg.name = top.attribute("name").value();

    cfg.clkSrc = xml::get_valid_node(top, "clksrc").text().get();
    cfg.enable = xml::node_text_as_bool(xml::get_valid_node(top, "enable"));
    cfg.generateBC0 = xml::node_text_as_bool(xml::get_valid_node(top, "generateBC0"));
    cfg.phase = boost::lexical_cast<uint32_t>(xml::get_valid_node(top, "phase").text().get());

    return cfg;
}


}

