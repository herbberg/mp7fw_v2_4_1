#include "mp7/python/registrators.hpp"

// Boost Headers
#include <boost/python/def.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/class.hpp>
#include <boost/python/enum.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>
#include <boost/python/operators.hpp>

// MP7 Headers
#include "mp7/BoardData.hpp"
#include "mp7/ChanBufferNode.hpp"
#include "mp7/CtrlNode.hpp"
#include "mp7/definitions.hpp"
#include "mp7/FormatterNode.hpp"
#include "mp7/MP7Controller.hpp"
#include "mp7/MmcController.hpp"
#include "mp7/PathConfigurator.hpp"
#include "mp7/Orbit.hpp"
#include "mp7/TTCNode.hpp"
#include "mp7/DatapathNode.hpp"
#include "mp7/ReadoutNode.hpp"



using namespace boost::python;

BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_ChannelManager_refClkReport_overloads, refClkReport, 0, 1);
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_MP7Controller_scanTTCPhase_overloads, scanTTCPhase, 0, 2);


void
pycomp7::register_controller() {

  class_<mp7::TransactionQueue>("TransactionQueue", no_init)
      .def("write", &mp7::TransactionQueue::write)
      .def("writeBlock", &mp7::TransactionQueue::writeBlock)
      .def("execute", &mp7::TransactionQueue::execute)
      .def("clear", &mp7::TransactionQueue::clear)
      ;

  {
    class_<mp7::MP7MiniController, boost::noncopyable >("MP7MiniController", init<const uhal::HwInterface& >())
        .def("isBuilt", &mp7::MP7MiniController::isBuilt)
        .def("id", &mp7::MP7MiniController::id)
        .def("identify", &mp7::MP7MiniController::identify)
        .def("getChannelIDs", &mp7::MP7MiniController::getChannelIDs)
        .def("getGenerics", &mp7::MP7MiniController::getGenerics, return_value_policy<copy_const_reference>())
        .def("getMetric", &mp7::MP7MiniController::getMetric)
        .def("hw", &mp7::MP7MiniController::hw, return_internal_reference<>())
        .def("getCtrl", &mp7::MP7MiniController::getCtrl, return_internal_reference<>())
        .def("getTTC", &mp7::MP7MiniController::getTTC, return_internal_reference<>())
        .def("getDatapath", &mp7::MP7MiniController::getDatapath, return_internal_reference<>())
        .def("getBuffer", &mp7::MP7MiniController::getBuffer, return_internal_reference<>())
        .def("getAlignmentMonitor", &mp7::MP7MiniController::getAlignmentMonitor, return_internal_reference<>())
        .def("getFormatter", &mp7::MP7MiniController::getFormatter, return_internal_reference<>())
        .def("channelMgr", static_cast<mp7::ChannelManager (mp7::MP7MiniController::*)() const>(&mp7::MP7MiniController::channelMgr))
        .def("channelMgr", static_cast<mp7::ChannelManager (mp7::MP7MiniController::*)(const std::vector<uint32_t>&) const>(&mp7::MP7MiniController::channelMgr))
        .def("checkTTC", &mp7::MP7MiniController::checkTTC)
        .def("scanTTCPhase", &mp7::MP7MiniController::scanTTCPhase, mp7_MP7Controller_scanTTCPhase_overloads())
        ;    
  }

  {
    // wrap MP7 690 driver 
    class_<mp7::MP7Controller, bases<mp7::MP7MiniController>, boost::noncopyable >("MP7Controller", init<const uhal::HwInterface& >())
        .def("kind", &mp7::MP7Controller::kind)
        .def("identify", &mp7::MP7Controller::identify)
        .def("getReadout", &mp7::MP7Controller::getReadout, return_internal_reference<>())
        .def("mmcMgr", &mp7::MP7Controller::mmcMgr)
        .def("reset", &mp7::MP7Controller::reset)
        .def("resetPayload", &mp7::MP7Controller::resetPayload)
        .def("computeEventSizes", &mp7::MP7Controller::computeEventSizes)
        .def("createSequence", &mp7::MP7Controller::createQueue)
        ;

  }
  
  // Wrap MmcManager
  class_<mp7::MmcManager>("MmcManager", no_init)
      .def("hardReset", &mp7::MmcManager::hardReset)
      .def("rebootFPGA", &mp7::MmcManager::rebootFPGA)
      .def("setDummySensorValue", &mp7::MmcManager::setDummySensorValue)
      .def("filesOnSD", &mp7::MmcManager::filesOnSD)
      .def("copyFileToSD", &mp7::MmcManager::copyFileToSD)
      .def("readSensorInfo", &mp7::MmcManager::readSensorInfo)
      .def("copyFileFromSD", &mp7::MmcManager::copyFileFromSD)
      .def("deleteFileFromSD", &mp7::MmcManager::deleteFileFromSD)
    ;


  // Wrap ChannlesManager
  class_<mp7::ChannelManager>("ChannelManager", no_init)
      .def("getDescriptor", &mp7::ChannelManager::getDescriptor, return_internal_reference<>())
      .def("pickBufferIDs", &mp7::ChannelManager::pickBufferIDs)   
      .def("pickMGTIDs", static_cast<mp7::ChannelGroup (mp7::ChannelManager::*)() const>(&mp7::ChannelManager::pickMGTIDs))
      .def("pickMGTIDs", static_cast<mp7::ChannelGroup (mp7::ChannelManager::*)( mp7::RxTxSelector ) const>(&mp7::ChannelManager::pickMGTIDs))
      .def("refClkReport", &mp7::ChannelManager::refClkReport, mp7_ChannelManager_refClkReport_overloads())
      .def("readRxStatus", &mp7::ChannelManager::readRxStatus)
      .def("readTxStatus", &mp7::ChannelManager::readTxStatus)
      .def("readAlignmentStatus", &mp7::ChannelManager::readAlignmentStatus)
      .def("resetMGTs", &mp7::ChannelManager::resetMGTs)
      .def("clearRxCounters", &mp7::ChannelManager::clearRxCounters)
      .def("configureBuffers", &mp7::ChannelManager::configureBuffers)
      .def("clearBuffers", static_cast<void (mp7::ChannelManager::*)(mp7::RxTxSelector) const >(&mp7::ChannelManager::clearBuffers))
      .def("clearBuffers", static_cast<void (mp7::ChannelManager::*)(mp7::RxTxSelector , mp7::ChanBufferNode::BufMode) const >(&mp7::ChannelManager::clearBuffers))
      .def("waitCaptureDone", &mp7::ChannelManager::waitCaptureDone)
      .def("readBuffers", &mp7::ChannelManager::readBuffers)
      .def("loadPatterns", &mp7::ChannelManager::loadPatterns)
      .def("configureRxMGTs", &mp7::ChannelManager::configureRxMGTs)
      .def("configureTxMGTs", &mp7::ChannelManager::configureTxMGTs)
      .def("setupTx2RxPattern", &mp7::ChannelManager::setupTx2RxPattern)
      .def("setupTx2Rx3GPattern", &mp7::ChannelManager::setupTx2Rx3GPattern)
      .def("setupTx2RxOrbitPattern", &mp7::ChannelManager::setupTx2RxOrbitPattern)
      .def("readAlignmentPoints", &mp7::ChannelManager::readAlignmentPoints)
      .def("findMinimaAlignmentPoints", &mp7::ChannelManager::findMinimaAlignmentPoints)
      .def("minimizeAndAlign", static_cast<mp7::orbit::Point (mp7::ChannelManager::*)(uint32_t) const>(&mp7::ChannelManager::minimizeAndAlign))
      .def("minimizeAndAlign", static_cast<mp7::orbit::Point (mp7::ChannelManager::*)(const std::map<uint32_t, uint32_t>&, uint32_t) const>(&mp7::ChannelManager::minimizeAndAlign))
      .def("align", static_cast<void (mp7::ChannelManager::*)(const mp7::orbit::Point&) const>(&mp7::ChannelManager::align))
      .def("align", static_cast<void (mp7::ChannelManager::*)(const mp7::orbit::Point&, const std::map<uint32_t, uint32_t>& ) const>(&mp7::ChannelManager::align))
      .def("resetAlignment", &mp7::ChannelManager::resetAlignment)
      .def("freezeAlignment", &mp7::ChannelManager::freezeAlignment)
      .def("checkAlignment", &mp7::ChannelManager::checkAlignment)

      .def("checkMGTs", &mp7::ChannelManager::checkMGTs)
      .def("configureHdrFormatters", &mp7::ChannelManager::configureHdrFormatters)
      .def("configureDVFormatters", &mp7::ChannelManager::configureDVFormatters)
      .def("disableDVFormatters", &mp7::ChannelManager::disableDVFormatters)
      .def("readBankSummary", &mp7::ChannelManager::readBankSummary)
      .def("readBankDetails", &mp7::ChannelManager::readBankDetails)


      
    ;


}
