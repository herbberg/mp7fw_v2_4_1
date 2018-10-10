/* 
 * File:   FormatterNode.cpp
 * Author: ale
 * 
 * Created on January 13, 2015, 11:32 PM
 */

#include "mp7/FormatterNode.hpp"

// MP7 Headers
#include "mp7/exception.hpp"
#include "mp7/Orbit.hpp"

namespace mp7 {
UHAL_REGISTER_DERIVED_NODE(FormatterNode);

FormatterNode::FormatterNode(const uhal::Node& aNode) :
    uhal::Node (aNode) {
}

FormatterNode::~FormatterNode() {
}

void
FormatterNode::stripInsert(bool aStrip, bool aInsert) const {
    getNode("csr.ctrl.enable_strip").write(aStrip);
    getNode("csr.ctrl.enable_insert").write(aInsert);
    getClient().dispatch();
}

void
FormatterNode::overrideValid(const orbit::Point& aStart, const orbit::Point& aStop) const {
  
//    if ( aStart >= aStop ) {
//      throw FormatterError("Formatter error: start >= stop");
//    }
    getNode("csr.dv_override.enable_dv_override").write(0x1);
    getNode("csr.dv_override.bx_start").write(aStart.bx);
    getNode("csr.dv_override.sub_bx_start").write(aStart.cycle);
    getNode("csr.dv_override.bx_stop").write(aStop.bx);
    getNode("csr.dv_override.sub_bx_stop").write(aStop.cycle);
    getClient().dispatch();
}


void
FormatterNode::enableValidOverride(bool aEnable) const {
    getNode("csr.dv_override.enable_dv_override").write(aEnable);
    getClient().dispatch();
}


void FormatterNode::tagBC0(const orbit::Point& aBx) const {
    getNode("csr.ctrl.enable_insert").write(0x1);
    getNode("csr.ctrl.flag_bx").write(aBx.bx);
}


void FormatterNode::enableBC0Tag(bool aEnable) const {
    getNode("csr.ctrl.enable_insert").write(aEnable);
    getClient().dispatch();
}

} // namespace mp7

