#include "mp7/python/registrators.hpp"

// Boost Headers
#include <boost/python/def.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/class.hpp>
#include <boost/python/enum.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <boost/python/operators.hpp>
// MP7 Headers
#include "mp7/ReadoutNode.hpp"
#include "mp7/ReadoutCtrlNode.hpp"
#include "mp7/ZeroSuppressionNode.hpp"

// Namespace resolution
using namespace boost::python;


BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_ReadoutNode_enableAMC13Output_overloads, enableAMC13Output, 0, 1)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_ReadoutNode_enableAutoEmpty_overloads, enableAutoDrain, 0, 2)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_ReadoutNode_forceTTSState_overloads, forceTTSState, 1, 2)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_ZeroSuppressionNode_enable_overloads, enable, 0, 1)

namespace pycomp7 {

void
register_ro() {
  // Wrap Generics
  class_<mp7::TTSStateCounters> ("TTSStateCounters")
      .def_readwrite("uptime",&mp7::TTSStateCounters::uptime)
      .def_readwrite("busy",&mp7::TTSStateCounters::busy)
      .def_readwrite("ready",&mp7::TTSStateCounters::ready)
      .def_readwrite("warn",&mp7::TTSStateCounters::warn)
      .def_readwrite("oos",&mp7::TTSStateCounters::oos)
  ;

  {
    scope mp7_ReadoutNode_scope = class_<mp7::ReadoutNode, bases<uhal::Node> > ("ReadoutNode", init<const uhal::Node&>())
        .def("getControl", &mp7::ReadoutNode::getControl, return_internal_reference<>())
        .def("selectEventSource", &mp7::ReadoutNode::selectEventSource)
        .def("enableAMC13Output", &mp7::ReadoutNode::enableAMC13Output, mp7_ReadoutNode_enableAMC13Output_overloads())
        .def("enableAutoDrain", &mp7::ReadoutNode::enableAutoDrain, mp7_ReadoutNode_enableAutoEmpty_overloads())
        .def("forceTTSState", &mp7::ReadoutNode::forceTTSState, mp7_ReadoutNode_forceTTSState_overloads())
        .def("start", &mp7::ReadoutNode::start)
        .def("stop", &mp7::ReadoutNode::stop)
        .def("setBxOffset", &mp7::ReadoutNode::setBxOffset)
        .def("resetAMC13Block", &mp7::ReadoutNode::resetAMC13Block)
        .def("isAMC13LinkReady", &mp7::ReadoutNode::isAMC13LinkReady)
        .def("configureFakeEventSize", &mp7::ReadoutNode::configureFakeEventSize)
        .def("setFifoWaterMarks", &mp7::ReadoutNode::setFifoWaterMarks)

        .def("isFifoEmpty", &mp7::ReadoutNode::isFifoEmpty)
        .def("isFifoFull", &mp7::ReadoutNode::isFifoFull)
        .def("readFifoOccupancy", &mp7::ReadoutNode::readFifoOccupancy)
        .def("readEventCounter", &mp7::ReadoutNode::readEventCounter)
        .def("readTTSCounters", &mp7::ReadoutNode::readTTSCounters)
        .def("readUptimeCounts", &mp7::ReadoutNode::readUptimeCounts)
        .def("readBusyCounts", &mp7::ReadoutNode::readBusyCounts)
        .def("readReadyCounts", &mp7::ReadoutNode::readReadyCounts)
        .def("readWarnCounts", &mp7::ReadoutNode::readWarnCounts)
        .def("readOOSCounts", &mp7::ReadoutNode::readOOSCounts)
        .def("readTTSState", &mp7::ReadoutNode::readTTSState)
        .def("readFifo", &mp7::ReadoutNode::readFifo)
        .def("readEvent", &mp7::ReadoutNode::readEvent)
        ;

    enum_<mp7::ReadoutNode::EventSource> ("EventSource")
        .value("kReadoutEventSource", mp7::ReadoutNode::kReadoutEventSource)
        .value("kFakeEventSource", mp7::ReadoutNode::kFakeEventSource)
        .export_values()
        ;
  }

  class_<mp7::ReadoutCtrlNode, bases<uhal::Node> > ("ReadoutCtrlNode", init<const uhal::Node&>())
        .def("readNumModes",&mp7::ReadoutCtrlNode::readNumModes)
        .def("readNumCaptures",&mp7::ReadoutCtrlNode::readNumCaptures)
        .def("selectBank",&mp7::ReadoutCtrlNode::selectBank)
        .def("selectMode",&mp7::ReadoutCtrlNode::selectMode)
        .def("selectCapture",&mp7::ReadoutCtrlNode::selectCapture)
        .def("reset",&mp7::ReadoutCtrlNode::reset)
        .def("configureMenu",&mp7::ReadoutCtrlNode::configureMenu)
        .def("readMenu",&mp7::ReadoutCtrlNode::readMenu)
        .def("setDerandWaterMarks", &mp7::ReadoutCtrlNode::setDerandWaterMarks)
  ;

  {
    scope mp7_ReadoutMenu_scope = class_<mp7::ReadoutMenu>("ReadoutMenu", init<size_t, size_t, size_t>())
        .def("numModes", &mp7::ReadoutMenu::numModes)
        .def("numCaptures", &mp7::ReadoutMenu::numCaptures)
        .def("numBanks", &mp7::ReadoutMenu::numBanks)
        .def("bank", static_cast<mp7::ReadoutMenu::Bank& (mp7::ReadoutMenu::*)( size_t )>(&mp7::ReadoutMenu::bank), return_internal_reference<>())
        .def("mode", static_cast<mp7::ReadoutMenu::Mode& (mp7::ReadoutMenu::*)( size_t )>(&mp7::ReadoutMenu::mode), return_internal_reference<>())
        .def("capture", static_cast<mp7::ReadoutMenu::Capture& (mp7::ReadoutMenu::*)( size_t, size_t )>(&mp7::ReadoutMenu::capture), return_internal_reference<>())
        .def("setMode", &mp7::ReadoutMenu::setMode)
//        .def("__len__", &mp7::ReadoutMenu::size )
//        .def("__getitem__", static_cast<mp7::ReadoutMenu::Mode& (mp7::ReadoutMenu::*)( uint32_t )>(&mp7::ReadoutMenu::getMode), boost::python::arg( "index" ), return_internal_reference<>() )
        .def(self_ns::str(self))
    ;

    class_<mp7::ReadoutMenu::Bank> ("Bank")
        .def_readwrite("wordsPerBx", &mp7::ReadoutMenu::Bank::wordsPerBx)
        .def(self_ns::str(self))
    ;
    class_<mp7::ReadoutMenu::Mode> ("Mode", init<size_t>())
        .def_readwrite("eventSize", &mp7::ReadoutMenu::Mode::eventSize)
        .def_readwrite("eventToTrigger", &mp7::ReadoutMenu::Mode::eventToTrigger)
        .def_readwrite("eventType", &mp7::ReadoutMenu::Mode::eventType)
        // .def_readwrite("tokenDelay", &mp7::ReadoutMenu::Mode::tokenDelay)
        .def( "__len__", &mp7::ReadoutMenu::Mode::size )
        .def( "__getitem__", static_cast<mp7::ReadoutMenu::Capture& (mp7::ReadoutMenu::Mode::*)( size_t )>(&mp7::ReadoutMenu::Mode::operator[]), boost::python::arg( "index" ), return_internal_reference<>() )
        .def(self_ns::str(self))
    ;
    
    class_<mp7::ReadoutMenu::Capture> ("Capture")
        .def_readwrite("enable", &mp7::ReadoutMenu::Capture::enable)
        .def_readwrite("id", &mp7::ReadoutMenu::Capture::id)
        .def_readwrite("bankId", &mp7::ReadoutMenu::Capture::bankId)
        .def_readwrite("length", &mp7::ReadoutMenu::Capture::length)
        .def_readwrite("delay", &mp7::ReadoutMenu::Capture::delay)
        .def_readwrite("readoutLength", &mp7::ReadoutMenu::Capture::readoutLength)
        .def(self_ns::str(self))
    ;
  }

  {
    scope mp7_ReadoutMenu_scope = class_<mp7::ZeroSuppressionMenu>("ZeroSuppressionMenu")
      // .def_readwrite("enable", &mp7::ZeroSuppressionMenu::enable)
      .def("validationMode", &mp7::ZeroSuppressionMenu::validationMode)
      .def("setValidationMode", &mp7::ZeroSuppressionMenu::setValidationMode)
      // .def_readwrite("masks", &mp7::ZeroSuppressionMenu::masks)
      .def( "__getitem__", static_cast<mp7::ZeroSuppressionMenu::Mask& (mp7::ZeroSuppressionMenu::*)( uint32_t )>(&mp7::ZeroSuppressionMenu::operator[]), boost::python::arg( "index" ), return_internal_reference<>() )
      
      .def(self_ns::str(self))
    ;

    class_<mp7::ZeroSuppressionMenu::Mask>("Mask")

      .def_readwrite("enable", &mp7::ZeroSuppressionMenu::Mask::enable)
      .def_readwrite("invert", &mp7::ZeroSuppressionMenu::Mask::invert)
      // .def_readwrite("data", &mp7::ZeroSuppressionMenu::Mask::data)
      .add_property("data", make_getter(&mp7::ZeroSuppressionMenu::Mask::data, return_value_policy<return_by_value>()),make_setter(&mp7::ZeroSuppressionMenu::Mask::data))
    ;
  }

  {
    scope mp7_ZeroSuppressionNode_scope = class_<mp7::ZeroSuppressionNode, bases<uhal::Node> > ("ZeroSuppressionNode", init<const uhal::Node&>())
      .def("isAvailable", &mp7::ZeroSuppressionNode::isAvailable)
      .def("isEnabled", &mp7::ZeroSuppressionNode::isEnabled)
      .def("enable", &mp7::ZeroSuppressionNode::enable, mp7_ZeroSuppressionNode_enable_overloads())
      .def("readMenu", &mp7::ZeroSuppressionNode::readMenu)
      .def("readMainState", &mp7::ZeroSuppressionNode::readMainState)
      .def("readFifoTransferState", &mp7::ZeroSuppressionNode::readFifoTransferState)
      .def("readOutputState", &mp7::ZeroSuppressionNode::readOutputState)
      .def("configureMenu", &mp7::ZeroSuppressionNode::configureMenu)
    ;

    enum_<mp7::ZeroSuppressionNode::MainState> ("MainState")
      .value("kMainIDLE", mp7::ZeroSuppressionNode::kMainIDLE)
      .value("kMainHDR", mp7::ZeroSuppressionNode::kMainHDR)
      .value("kMainINIT", mp7::ZeroSuppressionNode::kMainINIT)
      .value("kMainDATA", mp7::ZeroSuppressionNode::kMainDATA)
      .value("kMainDONE", mp7::ZeroSuppressionNode::kMainDONE)
      .export_values()
      ;

    enum_<mp7::ZeroSuppressionNode::FifoTransferState> ("FifoTransferState")
      .value("kFifoIDLE", mp7::ZeroSuppressionNode::kFifoIDLE)
      .value("kFifoBLK", mp7::ZeroSuppressionNode::kFifoBLK)
      .value("kFifoDONE", mp7::ZeroSuppressionNode::kFifoDONE)
      .export_values()
      ;

    enum_<mp7::ZeroSuppressionNode::OutputState> ("OutputState")
      .value("kOutIDLE", mp7::ZeroSuppressionNode::kOutIDLE)
      .value("kOutHDR", mp7::ZeroSuppressionNode::kOutHDR)
      .value("kOutDATA", mp7::ZeroSuppressionNode::kOutDATA)
      .value("kOutDONE", mp7::ZeroSuppressionNode::kOutDONE)
      .export_values()
      ;
  }
}

}
