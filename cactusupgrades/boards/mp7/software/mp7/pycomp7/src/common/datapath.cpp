#include "mp7/python/registrators.hpp"

// Boost Headers
#include <boost/python/def.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/class.hpp>
#include <boost/python/enum.hpp>
#include <boost/python/operators.hpp>
#include <boost/python/dict.hpp>
#include <boost/python/import.hpp>
#include <boost/python/copy_const_reference.hpp>


// MP7 Headers
#include "mp7/definitions.hpp"
#include "mp7/MGTRegionNode.hpp"
#include "mp7/DatapathNode.hpp"
#include "mp7/DatapathDescriptor.hpp"
#include "mp7/ChanBufferNode.hpp"
#include "mp7/PathConfigurator.hpp"
#include "mp7/AlignMonNode.hpp"
#include "mp7/Orbit.hpp"
#include "mp7/FormatterNode.hpp"

// Namespace resolution
using namespace boost::python;

BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_PathManager_setSize_overloads, setSize, 0, 1)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_ChanBufferNode_setSize_overloads, setSize, 0, 1)

namespace pycomp7 {

void register_datapath() {



  // Wrap RxChannelStatus
  class_<mp7::RxChannelStatus> ("RxChannelStatus")
      .def_readwrite("pllLocked",&mp7::RxChannelStatus::pllLocked)
      .def_readwrite("crcChecked",&mp7::RxChannelStatus::crcChecked)
      .def_readwrite("crcErrors",&mp7::RxChannelStatus::crcErrors)
      .def_readwrite("trailerId",&mp7::RxChannelStatus::trailerId)
      .def_readwrite("fsmResetDone",&mp7::RxChannelStatus::fsmResetDone)
      .def_readwrite("usrReset",&mp7::RxChannelStatus::usrReset)
  ;

  // Wrap Generics
  class_<mp7::TxChannelStatus> ("TxChannelStatus")
      .def_readwrite("pllLocked",&mp7::TxChannelStatus::pllLocked)
      .def_readwrite("fsmResetDone",&mp7::TxChannelStatus::fsmResetDone)
      .def_readwrite("usrReset",&mp7::TxChannelStatus::usrReset)
  ;

  // Wrap the MGTRegionNode
  class_<mp7::MGTRegionNode, bases<uhal::Node> > ("MGTRegionNode", init<const uhal::Node&>())
      .def("getRegionType", &mp7::MGTRegionNode::readRegionKind)
      .def("softReset", &mp7::MGTRegionNode::softReset)
      .def("resetRxFSMs", &mp7::MGTRegionNode::resetRxFSM)
      .def("resetTxFSMs", &mp7::MGTRegionNode::resetTxFSM)

      .def("clearCRCs", &mp7::MGTRegionNode::clearCRCs)

      .def("configureRx", &mp7::MGTRegionNode::configureRx)
      .def("configureTx", &mp7::MGTRegionNode::configureTx)

      .def("qpllLocked", &mp7::MGTRegionNode::isQpllLocked)
      .def("readRxChannelStatus", &mp7::MGTRegionNode::readRxChannelStatus)
      .def("readTxChannelStatus", &mp7::MGTRegionNode::readTxChannelStatus)

      .def("checkRx", static_cast<bool (mp7::MGTRegionNode::*)(const std::vector<uint32_t>&) const>(&mp7::MGTRegionNode::checkRx))
      .def("checkTx", static_cast<bool (mp7::MGTRegionNode::*)(const std::vector<uint32_t>&) const>(&mp7::MGTRegionNode::checkTx))
  
      .def("queue", &mp7::MGTRegionNode::queue)
      ;


  class_<mp7::MGTRegionSequencer>("MGTRegionSequencer", no_init)
      .def("softReset", &mp7::MGTRegionSequencer::softReset)
      .def("resetRxFSM", &mp7::MGTRegionSequencer::resetRxFSM)
      .def("resetTxFSM", &mp7::MGTRegionSequencer::resetTxFSM)
      ;

  {
    // Wrap ChanBufferNode
    scope mp7_ChanBufferNode_scope = class_<mp7::ChanBufferNode, bases<uhal::Node> > ("ChanBufferNode", init<const uhal::Node&>())
        .def("getBufferSize", &mp7::ChanBufferNode::getBufferSize)
        .def("readBufferMode", &mp7::ChanBufferNode::readBufferMode)
        .def("readDataSrc", &mp7::ChanBufferNode::readDataSrc)
        .def("readStrobeSrc", &mp7::ChanBufferNode::readStrobeSrc)
        .def("readDAQBank", &mp7::ChanBufferNode::readDAQBank)
        .def("readMaxWord", &mp7::ChanBufferNode::readMaxWord)
        .def("writeDAQBank", &mp7::ChanBufferNode::writeDAQBank)
        .def("writeMaxWord", &mp7::ChanBufferNode::writeMaxWord)
        .def("writeTrigBx", &mp7::ChanBufferNode::writeTrigPoint)
        .def("hasCaptured", &mp7::ChanBufferNode::hasCaptured)
        .def("waitCaptureDone", &mp7::ChanBufferNode::waitCaptureDone)
        .def("configure", &mp7::ChanBufferNode::configure)
        .def("readConfiguration", &mp7::ChanBufferNode::readConfiguration)
        .def("clear", &mp7::ChanBufferNode::clear)
        .def("readRaw", &mp7::ChanBufferNode::readRaw)
        .def("writeRaw", &mp7::ChanBufferNode::writeRaw)
        .def("upload", &mp7::ChanBufferNode::upload)
        .def("download", &mp7::ChanBufferNode::download)
        ;

    enum_<mp7::ChanBufferNode::BufMode> ("BufMode")
        .value("kLatency", mp7::ChanBufferNode::kLatency)
        .value("kCapture", mp7::ChanBufferNode::kCapture)
        .value("kPlayOnce", mp7::ChanBufferNode::kPlayOnce)
        .value("kPlayLoop", mp7::ChanBufferNode::kPlayLoop)
        .export_values()
        ;

    enum_<mp7::ChanBufferNode::DataSrc> ("DataSrc")
        .value("kInputData", mp7::ChanBufferNode::kInputData)
        .value("kBufferData", mp7::ChanBufferNode::kBufferData)
        .value("kPatternData", mp7::ChanBufferNode::kPatternData)
        .value("kZeroData", mp7::ChanBufferNode::kZeroData)
        .export_values()
        ;

    enum_<mp7::ChanBufferNode::StrobeSrc> ("StrobeSrc")
        .value("kInputStrobe", mp7::ChanBufferNode::kInputStrobe)
        .value("kBufferStrobe", mp7::ChanBufferNode::kBufferStrobe)
        .value("kPatternStrobe", mp7::ChanBufferNode::kPatternStrobe)
        .value("kOverrideStrobe", mp7::ChanBufferNode::kOverrideStrobe)
        .export_values()
        ;

    // Wrap RxChannelStatus
    class_<mp7::ChanBufferNode::Configuration> ("Configuration")
        .def_readwrite("mode",&mp7::ChanBufferNode::Configuration::mode)
        .def_readwrite("datasrc",&mp7::ChanBufferNode::Configuration::datasrc)
        .def_readwrite("stbsrc",&mp7::ChanBufferNode::Configuration::stbsrc)
        .def_readwrite("patternValidMask",&mp7::ChanBufferNode::Configuration::patternValidMask)
        .def_readwrite("captureStrobeOverride",&mp7::ChanBufferNode::Configuration::captureStrobeOverride)
        .def_readwrite("strobePattern",&mp7::ChanBufferNode::Configuration::strobePattern)
    ;
  }

  // Wrap PathConfigurator
  {
    scope pathConfiguratorScope = class_<mp7::PathConfigurator>("PathConfigurator", init<uint32_t, mp7::PathConfigurator::Mode, uint32_t, const mp7::orbit::Point&>())
        .def("configure", &mp7::PathConfigurator::configure)
        ;

    enum_<mp7::PathConfigurator::Mode> ("Mode")
        .value("kLatency", mp7::PathConfigurator::kLatency)
        .value("kCapture", mp7::PathConfigurator::kCapture)
        .value("kPlayOnce", mp7::PathConfigurator::kPlayOnce)
        .value("kPlayLoop", mp7::PathConfigurator::kPlayLoop)
        .value("kPattern", mp7::PathConfigurator::kPattern)
        .value("kZeroes", mp7::PathConfigurator::kZeroes)
        .value("kCaptureStrobe", mp7::PathConfigurator::kCaptureStrobe)
        .value("kPlayOnceStrobe", mp7::PathConfigurator::kPlayOnceStrobe)
        .value("kPattern3G", mp7::PathConfigurator::kPattern3G)
        .value("kPlayOnce3G", mp7::PathConfigurator::kPlayOnce3G)
        .export_values();
  }
  
  class_<mp7::LatencyPathConfigurator, bases<mp7::PathConfigurator> >("LatencyPathConfigurator", init<uint32_t, uint32_t>());
  class_<mp7::TestPathConfigurator, bases<mp7::PathConfigurator> >("TestPathConfigurator", init<mp7::PathConfigurator::Mode, const mp7::orbit::Point&, const mp7::orbit::Metric&>())
      .def(init<mp7::PathConfigurator::Mode, const mp7::orbit::Point&, uint32_t, const mp7::orbit::Metric&>())
      .def(init<mp7::PathConfigurator::Mode, const mp7::orbit::Point&, const mp7::orbit::Point&, const mp7::orbit::Metric&>());


  // Wrap Generics
  class_<mp7::RegionInfo> ("RegionInfo")
      .def_readwrite("mgtIn",&mp7::RegionInfo::mgtIn)
      .def_readwrite("chkIn",&mp7::RegionInfo::chkIn)
      .def_readwrite("bufIn",&mp7::RegionInfo::bufIn)
      .def_readwrite("fmt",&mp7::RegionInfo::fmt)
      .def_readwrite("bufOut",&mp7::RegionInfo::bufOut)
      .def_readwrite("chkOut",&mp7::RegionInfo::chkOut)
      .def_readwrite("mgtOut",&mp7::RegionInfo::mgtOut)
  ;

  class_<mp7::DatapathDescriptor>("DatapathDescriptor", init<>())
    .def("getRegionInfoMap", &mp7::DatapathDescriptor::getRegionInfoMap, return_value_policy<copy_const_reference>())
    .def("getRegionInfo", &mp7::DatapathDescriptor::getRegionInfo, return_value_policy<copy_const_reference>())
    .def("getRegionInfoByChannel", &mp7::DatapathDescriptor::getRegionInfoByChannel, return_value_policy<copy_const_reference>())
    .def("pickAllIDs", &mp7::DatapathDescriptor::pickAllIDs)
    .def("pickRxMGTIDs", &mp7::DatapathDescriptor::pickRxMGTIDs)
    .def("pickRxCheckSumIDs", &mp7::DatapathDescriptor::pickRxCheckSumIDs)
    .def("pickRxBufferIDs", &mp7::DatapathDescriptor::pickRxBufferIDs)
    .def("pickFmtIDs", &mp7::DatapathDescriptor::pickFmtIDs)
    .def("pickTxBufferIDs", &mp7::DatapathDescriptor::pickTxBufferIDs)
    .def("pickTxCheckSumIDs", &mp7::DatapathDescriptor::pickTxCheckSumIDs)
    .def("pickTxMGTIDs", &mp7::DatapathDescriptor::pickTxMGTIDs)
  ;

  class_<mp7::ChannelGroup>("ChannelGroup",init<>())
    .def(init<const std::vector<uint32_t> >())
    .def("channels",static_cast<const std::vector<uint32_t>& (mp7::ChannelGroup::*)() const>(&mp7::ChannelGroup::channels), return_value_policy<copy_const_reference>())
    .def("channels",static_cast<const std::vector<uint32_t>& (mp7::ChannelGroup::*)(const uint32_t) const>(&mp7::ChannelGroup::channels), return_value_policy<copy_const_reference>())
    .def("locals",&mp7::ChannelGroup::locals, return_value_policy<copy_const_reference>())
    .def("regions",&mp7::ChannelGroup::regions)
    .def("intersect",&mp7::ChannelGroup::intersect)
    .def("fromRegions", &mp7::ChannelGroup::fromRegions).staticmethod("fromRegions")
    .def("channelToRegion",&mp7::ChannelGroup::channelToRegion)
    .staticmethod("channelToRegion")
    .def("channelToLocal",&mp7::ChannelGroup::channelToLocal)
    .staticmethod("channelToLocal")
  ;

  // Wrap the Datapath
  {
    // Datapath scoping
    scope mp7_DatapathNode_scope = class_<mp7::DatapathNode, bases<uhal::Node> > ("DatapathNode", init<const uhal::Node&>())
        .def("selectChannel", &mp7::DatapathNode::selectChannel)
        .def("selectRegion", &mp7::DatapathNode::selectRegion)
        .def("selectRegChan", &mp7::DatapathNode::selectRegChan)
        .def("selectLink", &mp7::DatapathNode::selectLink)
        .def("selectLinkBuffer", &mp7::DatapathNode::selectLinkBuffer)
        .def("readRegionInfoMap", &mp7::DatapathNode::readRegionInfoMap)
        .def("queue", &mp7::DatapathNode::queue)
        ;
  }

    // *** Experimental ***
  class_<mp7::DatapathSequencer>("DatapathNodeSequencer", no_init)
      .def("selectLink", &mp7::DatapathSequencer::selectLink)
      .def("selectLinkBuffer", &mp7::DatapathSequencer::selectLinkBuffer)
      .def("selectRegChan", &mp7::DatapathSequencer::selectRegChan)
      .def("selectRegion", &mp7::DatapathSequencer::selectRegion)
      ;
  // *** Experimental - end ***
  
  // Wrap AlignStatus
  class_<mp7::AlignStatus> ("AlignStatus")
      .def_readwrite("position",&mp7::AlignStatus::position)
      .def_readwrite("errors",&mp7::AlignStatus::errors)
      .def_readwrite("marker",&mp7::AlignStatus::marker)
      .def_readwrite("frozen",&mp7::AlignStatus::frozen)
;

  // Wrap the AlignMonNode
  class_<mp7::AlignMonNode, bases<uhal::Node> > ("AlignMonNode", init<const uhal::Node&>())
      .def("reset", &mp7::AlignMonNode::reset)
      .def("clear", &mp7::AlignMonNode::clear)
      .def("readPosition", &mp7::AlignMonNode::readPosition)
      .def("readErrors", &mp7::AlignMonNode::readErrors)
      .def("shift", &mp7::AlignMonNode::shift)
      .def("markerDetected", &mp7::AlignMonNode::markerDetected)
      .def("seekBxCycle", &mp7::AlignMonNode::moveTo)
      .def("freeze", &mp7::AlignMonNode::freeze)
      ;

  class_<mp7::AlignmentFinder> ("AlignmentFinder", init<const mp7::Generics& >())
      .def("findMinimum", &mp7::AlignmentFinder::findMinimum)
      .def("distance", &mp7::AlignmentFinder::distance)
      ;

  class_<mp7::FormatterNode, bases<uhal::Node> > ("FormatterNode", init<const uhal::Node&>())
      .def("stripInsert", &mp7::FormatterNode::stripInsert)
      .def("overrideValid", &mp7::FormatterNode::overrideValid)
      .def("enableValidOverride", &mp7::FormatterNode::enableValidOverride)
      .def("tagBC0", &mp7::FormatterNode::tagBC0)
      .def("enableBC0Tag", &mp7::FormatterNode::enableBC0Tag)
      ;


  {
    scope packageScope;
    std::string orbModuleName(extract<const char*> (packageScope.attr("__name__")));
    orbModuleName += ".orbit";
    char* orbModuleCstr = new char [orbModuleName.size() + 1];
    strcpy(orbModuleCstr, orbModuleName.c_str());

    // Make test sub-module ...
    object orbModule(handle<> (borrowed(PyImport_AddModule(orbModuleCstr)))); //< Enables "from mp7.orbit import <whatever>"
    orbModule.attr("__file__") = "<synthetic>";

    packageScope.attr("orbit") = orbModule; //< Enables "from mp7 import orbit"
    
    extract<dict>(getattr(import("sys"),"modules"))()["mp7.orbit"]=orbModule;
    
    // Change to sub-module scope ...
    scope orbScope = orbModule;

    class_<mp7::orbit::Point>("Point", init< optional<uint32_t, uint32_t> >())
        .def_readwrite("bx", &mp7::orbit::Point::bx)
        .def_readwrite("cycle", &mp7::orbit::Point::cycle)
        .def(/*str*/ self_ns::repr(self))
        // .def( /*str*/ self_ns::str(self))
        .def(self == self)
        .def(self > self)
        .def(self < self)
        .def(self != self)
        ;

    orbScope.attr("kOneBx") = mp7::orbit::kOneBx;
    orbScope.attr("kOneCycle") = mp7::orbit::kOneCycle;


    class_<mp7::orbit::Metric>("Metric", init<const mp7::Generics&>())
        .def(init<uint32_t, uint32_t>())
        .def("bunchCount", &mp7::orbit::Metric::bunchCount)
        .def("clockRatio", &mp7::orbit::Metric::clockRatio)
        .def("bxsToCycles", &mp7::orbit::Metric::bxsToCycles)
        .def("first", &mp7::orbit::Metric::first, return_internal_reference<>())
        .def("last", &mp7::orbit::Metric::last, return_internal_reference<>())
        .def("add", &mp7::orbit::Metric::add)
        .def("addCycles", &mp7::orbit::Metric::addCycles)
        .def("addBXs", &mp7::orbit::Metric::addBXs)
        .def("sub", &mp7::orbit::Metric::sub)
        .def("subCycles", &mp7::orbit::Metric::subCycles)
        .def("subBXs", &mp7::orbit::Metric::subBXs)
        .def("distance", &mp7::orbit::Metric::distance)
        ;

  }
}

}
