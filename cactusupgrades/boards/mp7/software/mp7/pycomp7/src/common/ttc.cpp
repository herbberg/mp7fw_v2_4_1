#include "mp7/python/registrators.hpp"

// Boost Headers
#include <boost/python/def.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/class.hpp>
#include <boost/python/enum.hpp>
#include <boost/python/copy_const_reference.hpp>

// MP7 Headers
#include "mp7/TTCNode.hpp"

BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_TTCNode_enable_overloads, enable, 0, 1)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_TTCNode_generateInternalBC0_overloads, generateInternalBC0, 0, 1)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_TTCNode_captureBGOs_overloads, captureBGOs, 0, 2)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_TTCNode_measureClockFreq_overloads, measureClockFreq, 1, 2)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_TTCNode_enableL1ATrgRules_overloads, enableL1ATrgRules, 0, 1)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_TTCNode_enableL1AThrottling_overloads, enableL1AThrottling, 0, 1)

// Namespace resolution
using namespace boost::python;

namespace pycomp7 {

void
register_ttc() {

    // Wrap TTCHistoryEntry
    class_<mp7::TTCHistoryEntry>("TTCHistoryEntry")
      //.def_readwrite("cyc", &mp7::TTCHistoryEntry::cyc)
      .def_readwrite("bx", &mp7::TTCHistoryEntry::bx)
      .def_readwrite("orbit", &mp7::TTCHistoryEntry::orbit)
      .def_readwrite("event", &mp7::TTCHistoryEntry::event)
      .def_readwrite("l1a", &mp7::TTCHistoryEntry::l1a)
      .def_readwrite("cmd", &mp7::TTCHistoryEntry::cmd)
      ;

    // Wrap TTCNode
    {
        scope mp7_TTCNode_scope = class_<mp7::TTCNode, bases<uhal::Node> > ("TTCNode", init<const uhal::Node&>())
                .def("configure", &mp7::TTCNode::configure )
                .def("enable", (void ( mp7::TTCNode::*) (bool)) 0x0, mp7_TTCNode_enable_overloads())
                .def("generateInternalBC0", (void ( mp7::TTCNode::*) (bool)) 0x0, mp7_TTCNode_generateInternalBC0_overloads())
                .def("setPhase", &mp7::TTCNode::setPhase )
                .def("clear", &mp7::TTCNode::clear)
                .def("clearErrors", &mp7::TTCNode::clearErrors)
                .def("captureHistory", &mp7::TTCNode::captureHistory)
                .def("maskHistoryBC0L1a", &mp7::TTCNode::maskHistoryBC0L1a)
                .def("forceL1A", &mp7::TTCNode::forceL1A)
                .def("forceL1AOnBx", &mp7::TTCNode::forceL1AOnBx)
                .def("forceBCmd", &mp7::TTCNode::forceBCmd)
                .def("forceBCmdOnBx", &mp7::TTCNode::forceBCmdOnBx)
                .def("forceBTest", &mp7::TTCNode::forceBTest)
                .def("waitBC0Lock", &mp7::TTCNode::waitBC0Lock)
                .def("waitGlobalBC0Lock", &mp7::TTCNode::waitGlobalBC0Lock)
                .def("readBC0Locked", &mp7::TTCNode::readBC0Locked)
                .def("measureClockFreq", (double ( mp7::TTCNode::*) (mp7::TTCNode::FreqClockChannel, double)) 0, mp7_TTCNode_measureClockFreq_overloads())
                .def("readBunchCounter",&mp7::TTCNode::readBunchCounter)
                .def("readOrbitCounter",&mp7::TTCNode::readOrbitCounter)
                .def("readEventCounter",&mp7::TTCNode::readEventCounter)
                .def("readSingleBitErrorCounter",&mp7::TTCNode::readSingleBitErrorCounter)
                .def("readDoubleBitErrorCounter",&mp7::TTCNode::readDoubleBitErrorCounter)
                .def("readBCmdCounter",&mp7::TTCNode::readBCmdCounter)
                .def("report", &mp7::TTCNode::report)
                .def("generateRandomL1As", &mp7::TTCNode::generateRandomL1As)
                .def("enableL1ATrgRules", (void ( mp7::TTCNode::*) (bool)) 0x0, mp7_TTCNode_enableL1ATrgRules_overloads())
                .def("enableL1AThrottling", (void ( mp7::TTCNode::*) (bool)) 0x0, mp7_TTCNode_enableL1AThrottling_overloads())

                ;

        enum_<mp7::TTCNode::FreqClockChannel> ("FreqClockChannel")
                .value("kClock40", mp7::TTCNode::kClock40)
                .value("kRefClock", mp7::TTCNode::kRefClock)
                .value("kRxClock", mp7::TTCNode::kRxClock)
                .value("kTxClock", mp7::TTCNode::kTxClock)
                .export_values()
                ;

        class_<mp7::TTCNode::ConfigParams>("ConfigParams")
            .def_readwrite("clkSrc",&mp7::TTCNode::ConfigParams::clkSrc)
            .def_readwrite("enable",&mp7::TTCNode::ConfigParams::enable)
            .def_readwrite("generateBC0",&mp7::TTCNode::ConfigParams::generateBC0)
            .def_readwrite("phase",&mp7::TTCNode::ConfigParams::phase)
        ;
    }

    class_<mp7::TTCConfigurator>("TTCConfigurator", init<const std::string&, const std::string&, const std::string&>() )
        .def("configure", &mp7::TTCConfigurator::configure)
        .def("parseFromXML", &mp7::TTCConfigurator::parseFromXML).staticmethod("parseFromXML")
    ;
}

}
