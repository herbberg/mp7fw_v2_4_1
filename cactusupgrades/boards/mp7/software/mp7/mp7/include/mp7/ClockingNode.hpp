#ifndef __MP7_CLOCKINGNODE_HPP__
#define	__MP7_CLOCKINGNODE_HPP__

// uHAL Headers
#include "uhal/Node.hpp"

namespace mp7 {

class ClockingNode : public uhal::Node {
public:

    // PUBLIC METHODS
    ClockingNode(const uhal::Node&);
    virtual ~ClockingNode();
    
//    virtual void configure( const std::string& aFilePath, const std::string& aRequiresClock ) const = 0;
    
private:

};

} // namespace mp7

#endif	/* __MP7_CLOCKINGNODE_HPP__ */

