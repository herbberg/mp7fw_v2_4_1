#include "mp7/CtrlNode.hpp"

// Boost Headers
#include <boost/iterator/counting_iterator.hpp>
#include <boost/iterator/zip_iterator.hpp>
//#include <boost/foreach.hpp>

// MP7 Headers
#include "mp7/CommandSequence.hpp"
#include "mp7/exception.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"


// Namespace resolution
using namespace std;
//using namespace uhal;
namespace l7 = mp7::logger;

namespace mp7 {

UHAL_REGISTER_DERIVED_NODE(CtrlNode);

//---
CtrlNode::CtrlNode(const uhal::Node& node) : uhal::Node(node) {
}


//---
CtrlNode::~CtrlNode() {
}


//---
uint32_t CtrlNode::readDesign() const {
  
  uhal::ValWord<uint32_t> design = getNode("id.fwrev.design").read();
  getClient().dispatch();
  
  return design;
}


//---
uint32_t CtrlNode::readFwRevision() const {
  uhal::ValWord<uint32_t> revision = getNode("id.fwrev").read();
  getClient().dispatch();
  
  return revision & 0xffffff;
}


//---
uint32_t CtrlNode::readAlgoRevision() const {
  uhal::ValWord<uint32_t> revision = getNode("id.algorev").read();
  getClient().dispatch();
  
  return revision;
}


//---
std::vector<uint32_t>
CtrlNode::readRegions() const {
    uhal::ValWord<uint32_t> n_region = this->getNode("id.generics.n_region").read();
    this->getClient().dispatch();

    return vector<uint32_t>(boost::counting_iterator<uint32_t>(0), boost::counting_iterator<uint32_t>(n_region.value()));
}


//---
Snapshot
CtrlNode::readGenerics() const {
    return snapshot( this->getNode("id.generics") );
}

void CtrlNode::writeBoardID(uint32_t aSubsystem, uint32_t aCrate, uint32_t aBoard) const {
  getNode("board_id.subsys").write(aSubsystem);
  getNode("board_id.crate").write(aCrate);
  getNode("board_id.board").write(aBoard);
  getClient().dispatch();

}

//---
void
CtrlNode::hardReset(double aMilliSleep) const {
    getNode("csr.ctrl.nuke").write(0x1);
    getClient().dispatch();
    millisleep(aMilliSleep);
}


//---
void
CtrlNode::softReset() const {
    getNode("csr.ctrl.soft_rst").write(0x1);
    getClient().dispatch();
}


//---
void
CtrlNode::resetClock40(bool aReset) const {
    getNode("csr.ctrl.clk40_rst").write((int)aReset);
    getClient().dispatch();
}


//---
void
CtrlNode::selectClk40Source(bool aExternalClock) const {
    uhal::ValWord<uint32_t> isreset = getNode("csr.ctrl.clk40_rst").read();
    getClient().dispatch();
    
    if ( !isreset.value() ) {
        mp7::Clock40NotInReset lExc( std::string("Cannot change the source if Clock 40 is not in reset (isreset=") + l7::hexFmt(isreset) + ")" );
        MP7_LOG(l7::kError) << lExc.what();
//        throw lExc;
    }
    
    getNode("csr.ctrl.clk40_sel").write((int) aExternalClock);
    getClient().dispatch();
}


//---
bool
CtrlNode::clock40Locked() const {
    uhal::ValWord<uint32_t> lock = getNode("csr.stat.clk40_lock").read();
    getClient().dispatch();
    return  lock.value();
}

//---
void
CtrlNode::waitClk40Lock(uint32_t aMaxTries) const {
    uhal::ValWord< uint32_t > clk40_lck(0);
    uint32_t countdown(aMaxTries);

    while (countdown > 0) {
        clk40_lck = this->getNode("csr.stat.clk40_lock").read();
        this->getClient().dispatch();

        if (clk40_lck.value()) {
            break;
        }

        millisleep(1);
        countdown--;
    }

    if (countdown == 0) {
        std::ostringstream oss;
        oss << "Timed out while waiting for Clock40 to lock (" << aMaxTries << " ms)";
        MP7_LOG(l7::kError) << oss.str();
        throw mp7::Clock40LockFailed(oss.str());
    } else {
        MP7_LOG(l7::kNotice) << "Clock 40 Locked after " << (aMaxTries - countdown) << " ms";
    }
}




//---
CtrlNode::Clock40Guard::Clock40Guard(const CtrlNode& aCtrl, double aMilliSleep) :
    mCtrl(aCtrl), mMilliSleep(aMilliSleep) {
    MP7_LOG(l7::kDebug) << "Clock40Guard constructor: resetting clock";
    mCtrl.resetClock40(0x1);
}


//---
CtrlNode::Clock40Guard::~Clock40Guard() {
    MP7_LOG(l7::kDebug) << "Clock40Guard destructor: releasing clock 40";
    mCtrl.resetClock40(0x0);
    millisleep(mMilliSleep);
}




}

