#include "mp7/ClockingNode.hpp"


namespace mp7 {
// DerivedNode registration

ClockingNode::ClockingNode(const uhal::Node& node) :
uhal::Node(node) {
}

ClockingNode::~ClockingNode() {
}

} // namespace mp7

