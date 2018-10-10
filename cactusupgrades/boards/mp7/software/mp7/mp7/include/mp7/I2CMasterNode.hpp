/**
 * @file    I2CMasterNode.hpp
 * @author  Alessandro Thea
 * @brief   Brief description
 * @date 
 */

#ifndef __MP7_OPENCORESI2CMASTERNODE_HPP__
#define	__MP7_OPENCORESI2CMASTERNODE_HPP__

// uHal Headers
#include "uhal/DerivedNode.hpp"

namespace mp7 {
//TODO: Add a opencores namespace?
namespace opencores {

class I2CSlave; 

/*!
 * @class      I2CBaseNode
 *
 * @brief      OpenCode I2C interface to a ipbus node
 * @author     Kristian Harder, Alessandro Thea
 * @date       August 2013
 *
 *             The class is non-copyable on purpose as the inheriting object
 *             must properly set the node pointer in the copy i2c access through
 *             an IPbus interface
 */
class I2CBaseNode : public uhal::Node {
    UHAL_DERIVEDNODE(I2CBaseNode);
public:
    I2CBaseNode(const uhal::Node& aNode);
//    I2CBaseNode(const I2CBaseNode& aOther);
    virtual ~I2CBaseNode();

    ///
    virtual uint8_t getI2CClockPrescale() const {
        return mClockPrescale;
    }

    virtual std::vector<std::string>  getSlaves() const;
    virtual uint8_t  getSlaveAddress( const std::string& name ) const;
    /// commodity functions
    virtual uint8_t readI2C(uint8_t aSlaveAddress, uint32_t i2cAddress) const;
    virtual void writeI2C(uint8_t aSlaveAddress, uint32_t i2cAddress, uint32_t data) const;
    
protected:
    // low level i2c functions
    std::vector<uint8_t> virtual readBlockI2C(uint8_t aSlaveAddress, uint32_t numBytes) const;
    void virtual writeBlockI2C(uint8_t aSlaveAddress, const std::vector<uint8_t>& data) const;

    //! Slaves 
    boost::unordered_map<std::string,uint8_t> mSlavesAddresses;

private:
    ///
    void constructor();
    
    // low level i2c functions
    void reset() const;
    void waitUntilFinished(bool requireAcknowledgement = true,
            bool requireBusIdleAtEnd = false) const;
    
    //! IPBus register names for i2c bus
    static const std::string mPreHi;
    static const std::string mPreLo;
    static const std::string mCtrl;
    static const std::string mTx;
    static const std::string mRx;
    static const std::string mCmd;
    static const std::string mStatus;

    //! clock prescale factor
    uint16_t mClockPrescale;

    friend class I2CSlave;
};


/*!
 * @class I2CSlave
 * @brief Class to provide OpenCode I2C interface to a ipbus node
 *
 * The class is non copyable on purpose as the inheriting object
 * must properly set the node pointer in the copy
 * i2c access through an IPbus interface
 * @author Kristian Harder, Alessandro Thea
 * @date August 2013
 *
 */
class I2CSlave : boost::noncopyable {
protected:
    // Private constructor, accessible to I2CMaster
    I2CSlave(const I2CBaseNode* aMaster, uint8_t aSlaveAddress);
public:

    virtual ~I2CSlave();

    ///

    uint8_t getI2CAddress() const {
        return mAddress;
    }

    /// comodity functions
    uint8_t readI2C(uint32_t i2cAddress) const;
    void writeI2C(uint32_t i2cAddress, uint32_t data) const;

private:
    const I2CBaseNode* mMaster;

    // slave address
    uint8_t mAddress;

    friend class I2CMasterNode;
};

/*!
 * @class I2CMasterNode
 * @author Alessandro Thea
 * @brief Generic class to give access to multiple I2C targets
 */
class I2CMasterNode : public I2CBaseNode {
public:
    I2CMasterNode(const uhal::Node& aNode );
    I2CMasterNode(const I2CMasterNode& aOther );
    virtual ~I2CMasterNode();
    
    virtual const I2CSlave&  getSlave( const std::string& name ) const;
    
private:
    void constructor();
    //! Slaves 
    boost::unordered_map<std::string,I2CSlave*> mSlaves;

};


} // namespace opencores
} // namespace mp7

#endif	/* __MP7_OPENCORESI2CMASTERNODE_HPP__ */

