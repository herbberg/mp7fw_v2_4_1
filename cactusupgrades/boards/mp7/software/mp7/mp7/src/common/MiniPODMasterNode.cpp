/**
 * @file    MiniPODMasterNode.cpp
 * @author  Alessandro Thea
 * @brief   Brief description
 * @date    30/08/2014
 **/


#include "mp7/exception.hpp"

#include "mp7/Logger.hpp"
#include "mp7/MiniPODMasterNode.hpp"
#include "mp7/Utilities.hpp"

#include <boost/unordered/unordered_map.hpp>
#include <boost/regex.hpp>
#include <boost/range/adaptor/map.hpp>
#include <boost/range/algorithm/copy.hpp>
#include "boost/algorithm/string.hpp"

#include <iomanip>


// Namespace resolution
namespace l7 = mp7::logger;


std::ostream& operator<< ( std::ostream& aStream , const mp7::MiniPODinfo& aInfo )
{
  char buffer [11];
  strftime ( buffer , 11 , "%d/%m/%Y" , &aInfo.vendor_date_code );
  aStream << "Modular Optics Info :\n"
          << std::hex << std::setfill ( '0' )
          << " > type identifier : 0x" << std::setw ( 2 ) << ( uint16_t ) aInfo.type_identifier << '\n'
          << " > module description : 0x" << std::setw ( 2 ) << ( uint16_t ) aInfo.module_description << '\n'
          << " > required power supplies : 0x" << std::setw ( 2 ) << ( uint16_t ) aInfo.required_power_supplies << '\n'
          << std::dec
          << " > maximum operating temperature : " << aInfo.maximum_operating_temperature << '\n'
          << " > minimum bit-rate : " << aInfo.minimum_bit_rate << '\n'
          << " > maximum bit-rate : " << aInfo.maximum_bit_rate << '\n'
          << " > wavelength : " << aInfo.wavelength << '\n'
          << std::hex << std::setfill ( '0' )
          << " > supported flags : 0x" << std::setw ( 2 ) << ( uint16_t ) aInfo.supported_flags << '\n'
          << " > supported monitors : 0x" << std::setw ( 4 ) << aInfo.supported_monitors << '\n'
          << " > supported controls : 0x" << std::setw ( 4 ) << aInfo.supported_controls << '\n'
          << " > vendor name : '" << aInfo.vendor_name << "'\n"
          << " > vendor ieee id : " << std::setw ( 2 ) << ( uint16_t ) aInfo.vendor_ieee_id[0] << '-' << std::setw ( 2 ) << ( uint16_t ) aInfo.vendor_ieee_id[1] << '-' << std::setw ( 2 ) << ( uint16_t ) aInfo.vendor_ieee_id[2] << " (hex)\n"
          << " > vendor part-number : '" << aInfo.vendor_part_number << "'\n"
          << " > vendor revision-number : '" << aInfo.vendor_revision_number << "'\n"
          << " > vendor serial-number : '" << aInfo.vendor_serial_number << "'\n"
          << std::dec
          << " > vendor firmware revision : " << aInfo.vendor_firmware_revision << '\n'
          << " > vendor date code : " << buffer << '\n';
  aStream << std::flush;
  return aStream;
}


namespace mp7 {

// uHAL Registration
UHAL_REGISTER_DERIVED_NODE(MiniPODMasterNode);

MiniPODMasterNode::MiniPODMasterNode(const uhal::Node& aNode) : opencores::I2CBaseNode(aNode) {
    constructor();
}

MiniPODMasterNode::MiniPODMasterNode(const MiniPODMasterNode& aOther) : opencores::I2CBaseNode(aOther) {
    constructor();
}

MiniPODMasterNode::~MiniPODMasterNode() {

    // Delete Rx PODs
    boost::unordered_map<std::string, MiniPODRxSlave*>::iterator lRxIt;
    for (lRxIt = mRxPODs.begin(); lRxIt != mRxPODs.end(); ++lRxIt)
        delete lRxIt->second;

    // Delete Tx PODs
    boost::unordered_map<std::string, MiniPODTxSlave*>::iterator lTxIt;
    for (lTxIt = mTxPODs.begin(); lTxIt != mTxPODs.end(); ++lTxIt)
        delete lTxIt->second;
}

void
MiniPODMasterNode::constructor() {
    boost::regex reRxPOD("^(rx\\d*)"), reTxPOD("^(tx\\d*)");
    boost::smatch what;

    //    std::cout << mSlaves.size() << std::endl;

    boost::unordered_map<std::string, uint8_t>::iterator lIt;
    for (lIt = mSlavesAddresses.begin(); lIt != mSlavesAddresses.end(); ++lIt) {
        if (boost::regex_match(lIt->first, what, reRxPOD)) {
            //            std::cout << "Found rxPOD " << what[1].str() << std::endl;
            mRxPODs.insert(std::make_pair(lIt->first, new MiniPODRxSlave(this, lIt->second)));
        } else if (boost::regex_match(lIt->first, what, reTxPOD)) {
            //            std::cout << "Found txPOD " << what[1].str() << std::endl;
            mTxPODs.insert(std::make_pair(lIt->first, new MiniPODTxSlave(this, lIt->second)));
        } else {
            mp7::MP7HelperException lExc( std::string("Mispelled slave name ") + lIt->first + ". Must be tx\\d or rx\\d" );
            MP7_LOG(l7::kError) << lExc.what();
            //TODO: Why not throw??
        }
    }
}

const MiniPODRxSlave&
MiniPODMasterNode::getRxPOD(const std::string& name) const {
    boost::unordered_map<std::string, MiniPODRxSlave*>::const_iterator lIt = mRxPODs.find(name);
    if (lIt == mRxPODs.end()) {
        mp7::I2CSlaveNotFound lExc( std::string("Rx MiniPOD slave \"") + name + "\" not found.");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }
    return *(lIt->second);
}

const MiniPODTxSlave&
MiniPODMasterNode::getTxPOD(const std::string& name) const {
    boost::unordered_map<std::string, MiniPODTxSlave*>::const_iterator lIt = mTxPODs.find(name);
    if (lIt == mTxPODs.end()) {
        mp7::I2CSlaveNotFound lExc( std::string("Tx MiniPOD slave \"") + name + "\" not found." );
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }
    return *(lIt->second);
}

std::vector<std::string>
MiniPODMasterNode::getRxPODs() const {
    std::vector<std::string> lPODs;
    boost::copy(mRxPODs | boost::adaptors::map_keys, std::back_inserter(lPODs));
    return lPODs;
}

std::vector<std::string>
MiniPODMasterNode::getTxPODs() const {
    std::vector<std::string> lPODs;
    boost::copy(mTxPODs | boost::adaptors::map_keys, std::back_inserter(lPODs));
    return lPODs;
}

//____________________________________________________________________________//

MiniPODSlave::MiniPODSlave(const opencores::I2CBaseNode* aMaster, uint8_t aSlaveAddress) : opencores::I2CSlave(aMaster,aSlaveAddress) {
}

MiniPODSlave::~MiniPODSlave() {
}

Measurement
mp7::MiniPODSlave::get3v3() const {
    return Measurement(getUint16(32, 33) * 0.0001, "V", 0.1);
}

Measurement
mp7::MiniPODSlave::get2v5() const {
    return Measurement(getUint16(34, 35) * 0.0001, "V", 0.075);
}

Measurement
mp7::MiniPODSlave::getTemp() const {
    int8_t Integral(readI2C(28));
    uint16_t Fractional(readI2C(29));
    return Measurement(((Integral * 1.) + (Fractional / 256.)), "C", 3.);
}

Measurement
mp7::MiniPODSlave::getOnTime() const {
    return Measurement(getUint16(88, 89) * 2., "hours", 10, "%");
}

std::vector < Measurement >
mp7::MiniPODSlave::getOpticalPowers() const {
    uint8_t MSBaddr(86);
    uint8_t LSBaddr(87);
    std::vector < Measurement > lChannels;

    for (uint32_t i = 0; i != 12; ++i) {
        lChannels.push_back(Measurement(getUint16(MSBaddr, LSBaddr) * 0.1, "uW", 3., "dB"));
        MSBaddr -= 2;
        LSBaddr -= 2;
    }

    return lChannels;
}

Measurement
mp7::MiniPODSlave::getOpticalPower( uint32_t lIndex ) const {
    uint8_t MSBaddr(86);
    uint8_t LSBaddr(87);

    // Check index range
    if ( lIndex >= 12 ) throw MinipodChannelNotFound();

    MSBaddr -= 2*lIndex;
    LSBaddr -= 2*lIndex;
    
    return Measurement(getUint16(MSBaddr, LSBaddr) * 0.1, "uW", 3., "dB");
}
void
mp7::MiniPODSlave::setChannelPolarity(const uint32_t& aMask) const {
    //We will use upper-page #1
    writeI2C(127, 1);
    millisleep(50);
    uint8_t lValue;
    lValue = aMask & 0xFF;
    writeI2C(227, lValue);
    lValue = (aMask >> 8) & 0x0F;
    writeI2C(226, lValue);
}

void
mp7::MiniPODSlave::disableChannel(const uint32_t& aMask) const {
    uint8_t lValue;
    lValue = aMask & 0xFF;
    writeI2C(93, lValue);
    lValue = (aMask >> 8) & 0x0F;
    writeI2C(92, lValue);
}

void
mp7::MiniPODSlave::disableSquelch(const bool& aDisabled) const {
    if (aDisabled) {
        writeI2C(95, 0xFF);
        writeI2C(94, 0x0F);
    } else {
        writeI2C(95, 0x00);
        writeI2C(94, 0x00);
    }
}

std::pair< bool, bool >
mp7::MiniPODSlave::getAlarmTemp() const {
    uint8_t lValue(readI2C(13));
    return std::make_pair(bool ( lValue & 0x80), bool ( lValue & 0x40));
}

std::pair< bool, bool >
mp7::MiniPODSlave::getAlarm3v3() const {
    uint8_t lValue(readI2C(14));
    return std::make_pair(bool ( lValue & 0x80), bool ( lValue & 0x40));
}

std::pair< bool, bool >
mp7::MiniPODSlave::getAlarm2v5() const {
    uint8_t lValue(readI2C(14));
    return std::make_pair(bool ( lValue & 0x08), bool ( lValue & 0x04));
}

std::vector< bool >
mp7::MiniPODSlave::getAlarmLOS() const {
    std::vector< bool > lReturn;
    uint16_t lValue(getUint16(9, 10));

    for (uint32_t i = 0; i != 12; ++i) {
        lReturn.push_back(bool ( lValue & 0x0001));
        lValue >>= 1;
    }

    return lReturn;
}

std::vector< std::pair< bool, bool > >
mp7::MiniPODSlave::getAlarmOpticalPower() const {
    std::vector < std::pair< bool, bool > > lReturn;
    uint32_t lAddr(27);

    for (uint32_t i = 0; i != 6; ++i) {
        uint8_t lValue(readI2C(lAddr));
        lReturn.push_back(std::make_pair(bool ( lValue & 0x08), bool ( lValue & 0x04)));
        lReturn.push_back(std::make_pair(bool ( lValue & 0x80), bool ( lValue & 0x40)));
        lAddr -= 1;
    }

    return lReturn;
}

mp7::MiniPODinfo
mp7::MiniPODSlave::getInfo() const {
    using namespace uhal;
    //We will use upper-page #0
    writeI2C(127, 0);
    millisleep(50);
    mp7::MiniPODinfo lReply;
    std::vector<uint8_t> lTemp;
    std::string lTemp2;
    /*uint8_t*/
    lReply.type_identifier = readI2C(128);
    /*uint8_t*/
    lReply.module_description = readI2C(129);
    /*uint8_t*/
    lReply.required_power_supplies = readI2C(130);
    /*Measurement*/
    lReply.maximum_operating_temperature = Measurement(readI2C(131) *1., "C");
    /*Measurement*/
    lReply.minimum_bit_rate = Measurement(readI2C(132) *100., "Mb/s");
    /*Measurement*/
    lReply.maximum_bit_rate = Measurement(readI2C(133) *100., "Mb/s");
    /*Measurement*/
    lReply.wavelength = Measurement(getUint16(134, 135) / 20., "nm", getUint16(136, 137) / 200.);
    /*uint8_t*/
    lReply.supported_flags = readI2C(138);
    /*uint16_t*/
    lReply.supported_monitors = getUint16(139, 140); //note that manual lists this as though 139 is the MSB and 140 is the LSB, so that is what I have done here.
    /*uint16_t*/
    lReply.supported_controls = getUint16(142, 141);
    lTemp = block_read(152, 16);
    lTemp2 = std::string(lTemp.begin(), lTemp.end());
    boost::algorithm::trim(lTemp2);
    /*std::string*/
    lReply.vendor_name = lTemp2;
    /*std::vector<uint8_t>*/
    lReply.vendor_ieee_id = block_read(168, 3);
    lTemp = block_read(171, 16);
    lTemp2 = std::string(lTemp.begin(), lTemp.end());
    boost::algorithm::trim(lTemp2);
    /*std::string*/
    lReply.vendor_part_number = lTemp2;
    lTemp = block_read(187, 2);
    lTemp2 = std::string(lTemp.begin(), lTemp.end());
    boost::algorithm::trim(lTemp2);
    /*std::string*/
    lReply.vendor_revision_number = lTemp2;
    lTemp = block_read(189, 16);
    lTemp2 = std::string(lTemp.begin(), lTemp.end());
    boost::algorithm::trim(lTemp2);
    /*std::string*/
    lReply.vendor_serial_number = lTemp2;
    lTemp = block_read(205, 8);
    lTemp2 = std::string(lTemp.begin(), lTemp.end());
    strptime(lTemp2.c_str(), "%Y%m%d", &lReply.vendor_date_code);
    /*uint16_t*/
    lReply.vendor_firmware_revision = getUint16(255, 254);
    return lReply;
}

uint16_t
mp7::MiniPODSlave::getUint16(const uint32_t& aMSB, const uint32_t& aLSB) const {
    uint16_t MSB(readI2C(aMSB));
    uint16_t LSB(readI2C(aLSB));
    return ( (MSB << 8) | LSB);
}

std::vector<uint8_t>
mp7::MiniPODSlave::block_read(const uint32_t& aI2CbusAddress, const uint32_t aSize) const {
    uint32_t lAddr(aI2CbusAddress);
    std::vector<uint8_t> lReply;

    for (uint32_t i = 0; i != aSize; ++i) {
        lReply.push_back(readI2C(lAddr++));
    }

    return lReply;
}


//____________________________________________________________________________//

MiniPODRxSlave::MiniPODRxSlave(const opencores::I2CBaseNode* aMaster, uint8_t aSlaveAddress) : MiniPODSlave(aMaster,aSlaveAddress) {
}

MiniPODRxSlave::~MiniPODRxSlave() {
}
//____________________________________________________________________________//

MiniPODTxSlave::MiniPODTxSlave(const opencores::I2CBaseNode* aMaster, uint8_t aSlaveAddress) : MiniPODSlave(aMaster,aSlaveAddress) {
}

MiniPODTxSlave::~MiniPODTxSlave() {
}

std::vector < mp7::Measurement >
mp7::MiniPODTxSlave::getBiasCurrents() {
    uint8_t MSBaddr(62);
    uint8_t LSBaddr(63);
    std::vector < Measurement > lChannels;

    for (uint32_t i = 0; i != 12; ++i) {
        lChannels.push_back(Measurement(getUint16(MSBaddr, LSBaddr) * 2., "uA", 1., "mA"));
        MSBaddr -= 2;
        LSBaddr -= 2;
    }

    return lChannels;
}

void
mp7::MiniPODTxSlave::setInputEqualization(const double& aPercentage) {
    //We will use upper-page #1
    writeI2C(127, 1);
    millisleep(50);
    uint8_t lProportionOfSeven(uint8_t(((aPercentage / 100.) *7.) + 0.5) & 0x07);
    uint8_t lValue((lProportionOfSeven << 4) | lProportionOfSeven);
    uint8_t Addr(233);

    for (uint32_t i = 0; i != 6; ++i) {
        writeI2C(Addr, lValue);
        Addr -= 1;
    }
}

void
mp7::MiniPODTxSlave::marginMode(const bool& aEnabled) {
    //We will use upper-page #1
    writeI2C(127, 1);
    millisleep(50);

    if (aEnabled) {
        writeI2C(100, 0xFF);
        writeI2C(99, 0x0F);
    } else {
        writeI2C(100, 0x00);
        writeI2C(99, 0x00);
    }
}

std::vector< bool >
mp7::MiniPODTxSlave::getAlarmFault() {
    std::vector< bool > lReturn;
    uint16_t lValue(getUint16(11, 12));

    for (uint32_t i = 0; i != 12; ++i) {
        lReturn.push_back(bool ( lValue & 0x0001));
        lValue >>= 1;
    }

    return lReturn;
}

std::vector< std::pair< bool, bool > >
mp7::MiniPODTxSlave::getAlarmBiasCurrent() {
    std::vector < std::pair< bool, bool > > lReturn;
    uint32_t lAddr(21);

    for (uint32_t i = 0; i != 6; ++i) {
        uint8_t lValue(readI2C(lAddr));
        lReturn.push_back(std::make_pair(bool ( lValue & 0x08), bool ( lValue & 0x04)));
        lReturn.push_back(std::make_pair(bool ( lValue & 0x80), bool ( lValue & 0x40)));
        lAddr -= 1;
    }

    return lReturn;
}

} // namespace mp7
