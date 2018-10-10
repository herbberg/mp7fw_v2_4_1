#include "mp7/python/registrators.hpp"

// Boost Headers
#include <boost/python/def.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/class.hpp>

// MP7 Headers
#include "mp7/CtrlNode.hpp"


// Namespace resolution
using namespace boost::python;

// Methods Overloads
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_CTRLNODE_hardReset_overloads, hardReset, 0, 1)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_CTRLNODE_resetClk40_overloads, resetClk40, 0, 1)
BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_CTRLNODE_waitClk40Lock_overloads, waitClk40Lock, 0, 1)

namespace pycomp7 {

void
register_ctrl() {

  // Wrap the CtrlNode
  {
    // CtrlNode scoping
    scope mp7_CtrlNode_scope = class_<mp7::CtrlNode, bases<uhal::Node> > ("CtrlNode", init<const uhal::Node&>())
        .def("readDesign", &mp7::CtrlNode::readDesign)
        .def("readFwRevision", &mp7::CtrlNode::readFwRevision)
        .def("readAlgoRevision", &mp7::CtrlNode::readAlgoRevision)
        .def("readRegions", &mp7::CtrlNode::readRegions)
        .def("readGenerics", &mp7::CtrlNode::readGenerics)
        .def("writeBoardID", &mp7::CtrlNode::writeBoardID)
        .def("hardReset", (void ( mp7::CtrlNode::*) (double)) 0, mp7_CTRLNODE_hardReset_overloads())
        .def("softReset", &mp7::CtrlNode::softReset)
        .def("waitClk40Lock", (void ( mp7::CtrlNode::*) (uint32_t)) 0, mp7_CTRLNODE_waitClk40Lock_overloads())
        .def("selectClk40Source", &mp7::CtrlNode::selectClk40Source)
        .def("clock40Locked", &mp7::CtrlNode::clock40Locked)

        ;

    // Wrap CtrlNode::Clock40Sentry
    class_<mp7::CtrlNode::Clock40Guard>("Clock40Guard", init<const mp7::CtrlNode&, optional<double> >())
        ;
  }
}

}