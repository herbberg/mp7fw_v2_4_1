/**
 * @file    StateHistoryNode.cpp
 * @author  Alessandro Thea
 * @brief   Brief description
 * @date    November 2014
 */

#ifndef __MP7_STATEHISTORYNODE_HPP__
#define	__MP7_STATEHISTORYNODE_HPP__

// uHAL Headers
#include "uhal/DerivedNode.hpp"

namespace mp7 {

class HistoryEntry {
public:
  uint32_t cyc;
  uint32_t bx;
  uint32_t orbit;
  uint32_t event;
  uint32_t data;
};


class StateHistoryNode : public uhal::Node {
    UHAL_DERIVEDNODE( StateHistoryNode );    
public:
    StateHistoryNode(const uhal::Node& aNode);
    virtual ~StateHistoryNode();

    virtual void mask( bool aMask = true ) const;

    /**
     * @brief [brief description]
     * @details [long description]
     */
    virtual void clear() const;
    
    /**
     * @brief [brief description]
     * @details [long description]
     * @return [description]
     */
    virtual std::vector<HistoryEntry> capture() const;
    
private:

};

} // namespace mp7


#endif	/* __MP7_STATEHISTORYNODE_HPP__ */

