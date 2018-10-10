/**
 * @file    MiniPODMasterNode.hpp
 * @author  Alessandro Thea
 * @brief   Brief description
 * @date    30/08/2014
 **/

#ifndef __MP7_MINIPODMASTERNODE_HPP__
#define	__MP7_MINIPODMASTERNODE_HPP__

#include "mp7/I2CMasterNode.hpp"

#include "mp7/Measurement.hpp"

namespace mp7 {

  struct MiniPODinfo {
    uint8_t type_identifier;
    uint8_t module_description;
    uint8_t required_power_supplies;
    Measurement maximum_operating_temperature;
    Measurement minimum_bit_rate;
    Measurement maximum_bit_rate;
    Measurement wavelength;
    uint8_t supported_flags;
    uint16_t supported_monitors;
    uint16_t supported_controls;
    std::string vendor_name;
    std::vector<uint8_t> vendor_ieee_id;
    std::string vendor_part_number;
    std::string vendor_revision_number;
    std::string vendor_serial_number;
    tm vendor_date_code;
    uint16_t vendor_firmware_revision;
  };

// Forward declarations
class MiniPODRxSlave;
class MiniPODTxSlave;


/**
 * @class MiniPODMasterNode
 */
class MiniPODMasterNode : public opencores::I2CBaseNode {
    UHAL_DERIVEDNODE(MiniPODMasterNode);

public:

    MiniPODMasterNode(const uhal::Node& aNode);

    MiniPODMasterNode(const MiniPODMasterNode& aOther);

    virtual ~MiniPODMasterNode();

    const MiniPODRxSlave& getRxPOD(const std::string& name) const;
    const MiniPODTxSlave& getTxPOD(const std::string& name) const;

    std::vector<std::string> getRxPODs() const;
    std::vector<std::string> getTxPODs() const;

protected:
    boost::unordered_map<std::string, MiniPODRxSlave*> mRxPODs;
    boost::unordered_map<std::string, MiniPODTxSlave*> mTxPODs;
private:
    /// Construct the object from uhal::Node
    void constructor();
};

/**
 * @class MiniPODSlave
 */
class MiniPODSlave : public opencores::I2CSlave {
public:
    MiniPODSlave(const opencores::I2CBaseNode* aMaster, uint8_t aSlaveAddress);
    virtual ~MiniPODSlave();

    virtual Measurement get3v3() const;
    virtual Measurement get2v5() const;
    virtual Measurement getTemp() const; 
    virtual Measurement getOnTime() const;
    virtual Measurement getOpticalPower(uint32_t) const;
    virtual std::vector < Measurement > getOpticalPowers() const;

    virtual void setChannelPolarity(const uint32_t& aMask) const;
    virtual void disableChannel(const uint32_t& aMask) const;
    virtual void disableSquelch(const bool& aDisabled) const;

    virtual std::pair< bool, bool > getAlarmTemp() const;
    virtual std::pair< bool, bool > getAlarm3v3() const;
    virtual std::pair< bool, bool > getAlarm2v5() const;
    virtual std::vector< bool > getAlarmLOS() const;
    virtual std::vector< std::pair< bool, bool > > getAlarmOpticalPower() const;

    virtual MiniPODinfo getInfo() const;

protected:
    uint16_t getUint16(const uint32_t& aMSB, const uint32_t& aLSB) const;
    std::vector<uint8_t> block_read(const uint32_t& aI2CbusAddress, const uint32_t aSize) const;

};

/**
 * @class MiniPODRxSlave
 */
class MiniPODRxSlave : public MiniPODSlave {
public:
    MiniPODRxSlave(const opencores::I2CBaseNode* aMaster, uint8_t aSlaveAddress);
    virtual ~MiniPODRxSlave();
    
    void setDeemphasis ( const double& aPercentage );
    void setOutputAmplitude ( const double& aPercentage );
private:

};

class MiniPODTxSlave : public MiniPODSlave {
public:
    MiniPODTxSlave(const opencores::I2CBaseNode* aMaster, uint8_t aSlaveAddress);
    virtual ~MiniPODTxSlave();
    
    virtual std::vector < Measurement > getBiasCurrents();

    virtual void setInputEqualization ( const double& aPercentage );

    virtual void marginMode ( const bool& aEnabled );

    virtual std::vector< bool > getAlarmFault();
    virtual std::vector< std::pair< bool , bool > > getAlarmBiasCurrent();
private:

};



}

#endif	/* __MP7_MINIPODMASTERNODE_HPP__ */

