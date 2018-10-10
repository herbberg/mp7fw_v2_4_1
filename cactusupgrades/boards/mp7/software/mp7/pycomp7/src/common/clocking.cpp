
#include "mp7/python/registrators.hpp"

// Boost Headers
#include <boost/python/def.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/class.hpp>
#include <boost/python/enum.hpp>

// MP7 Headers
#include "mp7/ClockingXENode.hpp"
#include "mp7/ClockingR1Node.hpp"


using namespace boost::python;

BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_CLOCKINGNODE_si5326WaitConfigured_overloads, si5326WaitConfigured, 0, 1)

BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_CLOCKINGXENODE_si5326BottomWaitConfigured_overloads, si5326BottomWaitConfigured, 0, 2)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_CLOCKINGXENODE_si5326TopWaitConfigured_overloads, si5326TopWaitConfigured, 0, 2)


void
pycomp7::register_clocking() {

    // Wrap ClockingNode. 
    // FIXME: It requires braces. Don't know why.
    {
        class_<mp7::ClockingNode, bases<uhal::Node>, boost::noncopyable > ("ClockingNode", no_init)
        ;
    }

    // Wrap ClockingR1Node
    {
        
        // ClockingNode scoping
        scope mp7_ClockingR1Node_scope = class_<mp7::ClockingR1Node, bases<mp7::ClockingNode> > ("ClockingR1Node", init<const uhal::Node&>())
            .def("configure", &mp7::ClockingR1Node::configure)
            .def("configureXpoint", &mp7::ClockingR1Node::configureXpoint)
            .def("configureU3", &mp7::ClockingR1Node::configureU3)
            .def("configureU15", &mp7::ClockingR1Node::configureU15)
            .def("configureU36", &mp7::ClockingR1Node::configureU36)
            .def("si5326Reset", &mp7::ClockingR1Node::si5326Reset)
            .def("si5326WaitConfigured", (void ( mp7::ClockingR1Node::*) (uint32_t)) 0, mp7_CLOCKINGNODE_si5326WaitConfigured_overloads())
            .def("si5326LossOfLock", &mp7::ClockingR1Node::si5326LossOfLock)
            .def("si5326Interrupt", &mp7::ClockingR1Node::si5326Interrupt)
            ;

        enum_<mp7::ClockingR1Node::Clk40Select> ("Clk40Select")
            .value("kExternalAMC13", mp7::ClockingR1Node::kExternalAMC13)
            .value("kExternalMCH", mp7::ClockingR1Node::kExternalMCH)
            .value("kDisconnected", mp7::ClockingR1Node::kDisconnected)
            .export_values()
            ;

        enum_<mp7::ClockingR1Node::RefClkSelect> ("RefClkSelect")
            .value("kOscillator", mp7::ClockingR1Node::kOscillator)
            .value("kClockCleaner", mp7::ClockingR1Node::kClockCleaner)
            .export_values()
            ;
        
        // TODO: Delete it
        class_<mp7::ClockingR1Node::ConfigParams>("ConfigParams")
            .def_readwrite("name",&mp7::ClockingR1Node::ConfigParams::name)
            .def_readwrite("clkSrc",&mp7::ClockingR1Node::ConfigParams::clkSrc)
            .def_readwrite("si5326_cfg",&mp7::ClockingR1Node::ConfigParams::si5326_cfg)
            .def_readwrite("si5326_file",&mp7::ClockingR1Node::ConfigParams::si5326_file)
            .def_readwrite("xpoint_clk40sel",&mp7::ClockingR1Node::ConfigParams::xpoint_clk40sel)
            .def_readwrite("xpoint_refclksel",&mp7::ClockingR1Node::ConfigParams::xpoint_refclksel)
        ;
    }
//    
    class_<mp7::ClockingR1Configurator>("ClockingR1Configurator", init<const std::string&, const std::string&, const std::string&>())
        .def("getConfig", &mp7::ClockingR1Configurator::getConfig, return_internal_reference<>())
        .def("configure", &mp7::ClockingR1Configurator::configure)
        .def("parseFromXML", &mp7::ClockingR1Configurator::parseFromXML).staticmethod("parseFromXML")
    ;
    

    // Wrap ClockingXENode
    {
        // ClockingXENode scoping
        scope mp7_ClockingXENode_scope = class_<mp7::ClockingXENode, bases<mp7::ClockingNode> > ("ClockingXENode", init<const uhal::Node&>())
            .def("configure", &mp7::ClockingXENode::configure)
            .def("configureXpoint", &mp7::ClockingXENode::configureXpoint)
            .def("configureU36", &mp7::ClockingXENode::configureU36)
            .def("si5326BottomReset", &mp7::ClockingXENode::si5326BottomReset)
            .def("si5326BottomWaitConfigured", (void ( mp7::ClockingXENode::*) (bool, uint32_t)) 0, mp7_CLOCKINGXENODE_si5326BottomWaitConfigured_overloads())
            .def("si5326BottomLossOfLock", &mp7::ClockingXENode::si5326BottomLossOfLock)
            .def("si5326BottomInterrupt", &mp7::ClockingXENode::si5326BottomInterrupt)
            .def("si5326TopReset", &mp7::ClockingXENode::si5326TopReset)
            .def("si5326TopWaitConfigured", (void ( mp7::ClockingXENode::*) (bool, uint32_t)) 0, mp7_CLOCKINGXENODE_si5326TopWaitConfigured_overloads())
            .def("si5326TopLossOfLock", &mp7::ClockingXENode::si5326TopLossOfLock)
            .def("si5326TopInterrupt", &mp7::ClockingXENode::si5326TopInterrupt)
            ;
                
        enum_<mp7::ClockingXENode::Clk40Select> ("Clk40Select")
            .value("kExternalAMC13", mp7::ClockingXENode::kExternalAMC13)
            .value("kExternalMCH", mp7::ClockingXENode::kExternalMCH)
            .value("kDisconnected", mp7::ClockingXENode::kDisconnected)
            .export_values()
            ;
        
        class_<mp7::ClockingXENode::ConfigParams>("ConfigParams")
        ;
    }
    
    class_<mp7::ClockingXEConfigurator>("ClockingXEConfigurator", init<const std::string&, const std::string&, const std::string&>())
        .def("getConfig", &mp7::ClockingXEConfigurator::getConfig, return_internal_reference<>())
        .def("configure", &mp7::ClockingXEConfigurator::configure)
        .def("parseFromXML", &mp7::ClockingXEConfigurator::parseFromXML).staticmethod("parseFromXML")
    ;


}