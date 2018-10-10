/**
 * @file    SI5326Node.hpp
 * @author  Alessandro Thea
 * @brief   Brief description
 * @date 
 */
#ifndef __MP7_SI5326_HPP__
#define	__MP7_SI5326_HPP__

#include "mp7/I2CMasterNode.hpp"

namespace mp7 {

/**
 * @class SI5326Slave
 * @brief I2C slave class to control SI5326 chips.
 * @author Alessandro Thea
 * @date August 2013
 * 
 */
class SI5326Slave : public opencores::I2CSlave {
public:
    SI5326Slave(const opencores::I2CBaseNode* aMaster, uint8_t aSlaveAddress);
    virtual ~SI5326Slave();

    void configure(const std::string& aFilename) const;
    void reset() const;
    void intcalib() const;
    void sleep(const bool& s) const;
    void debug() const;

    std::map<uint32_t, uint32_t> registers() const;

};

/**
 * @class SI5326Node
 * @brief uhal::Node implementing single I2C Master Slave connection to control SI5326 chips
 * @author Alessandro Thea
 * @date August 2013
 */
class SI5326Node : public opencores::I2CBaseNode, public SI5326Slave {
    UHAL_DERIVEDNODE(SI5326Node);
public:
    SI5326Node(const uhal::Node& aNode);
    SI5326Node(const SI5326Node& aOther);
    virtual ~SI5326Node();

};

}

#endif	/* __MP7_SI5326_HPP__ */


