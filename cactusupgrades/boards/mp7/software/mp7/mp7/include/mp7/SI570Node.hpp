/**
 * @file    SI570Node.cpp
 * @author  Alessandro Thea
 * @brief   Brief description
 * @date 
 */


#ifndef __MP7_SI570NODE_HPP__
#define	__MP7_SI570NODE_HPP__

#include "mp7/I2CMasterNode.hpp"

namespace mp7 {

/**
 * @class SI570Slave
 * @brief I2C slave class to control SI570 chips.
 * @author Alessandro Thea
 * @date August 2013
 * 
 */
class SI570Slave : public opencores::I2CSlave {
public:
    SI570Slave(const opencores::I2CBaseNode* aMaster, uint8_t aSlaveAddress);
    virtual ~SI570Slave();

    void configure(const std::string& aFilename) const;
};

/**
 * @class SI570Node
 * @brief uhal::Node implementing single I2C Master Slave connection to control SI570 chips
 * @author Alessandro Thea
 * @date August 2013
 */
class SI570Node : public opencores::I2CBaseNode, public SI570Slave {
    UHAL_DERIVEDNODE(SI570Node);
public:
    SI570Node(const uhal::Node& aNode);
    SI570Node(const SI570Node& aOther);
    virtual ~SI570Node();

};

}
#endif	/* __MP7_SI570NODE_HPP__ */

