/* 
 * File:   OpenCoresI2CMasterNode.cpp
 * Author: ale
 * 
 * Created on August 29, 2014, 4:47 PM
 */

#include "mp7/I2CMasterNode.hpp"


#include <boost/lexical_cast.hpp>
#include <boost/unordered/unordered_map.hpp>
#include <boost/range/adaptor/map.hpp>
#include <boost/range/algorithm/copy.hpp>

#include "mp7/exception.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"

// Namespace Resolution
namespace l7 = mp7::logger;

namespace mp7 {
namespace opencores {

UHAL_REGISTER_DERIVED_NODE(I2CBaseNode);

// PRIVATE CONST definitions
const std::string I2CBaseNode::mPreHi = "ps_hi";
const std::string I2CBaseNode::mPreLo = "ps_lo";
const std::string I2CBaseNode::mCtrl = "ctrl";
const std::string I2CBaseNode::mTx = "data";
const std::string I2CBaseNode::mRx = "data";
const std::string I2CBaseNode::mCmd = "cmd_stat";
const std::string I2CBaseNode::mStatus = "cmd_stat";

I2CBaseNode::I2CBaseNode(const uhal::Node& aNode) : uhal::Node(aNode) {
    constructor();
}

//I2CBaseNode::I2CBaseNode(const I2CBaseNode& aOther ) : uhal::Node(aOther) {
////    std::cout << "Copy constructor" << std::endl;
//    // Rebuilds itself from aOther
////    constructor();
//}

void I2CBaseNode::constructor() {
    // 16 bit clock prescale factor.
    // formula: m_clockPrescale = (input_frequency / 5 / desired_frequency) -1
    // for typical IPbus applications: input frequency = IPbus clock = 31.x MHz
    // target frequency 100 kHz to play it safe (first revision of i2c standard),
    // but e.g. the SI5326 clock chip on the MP7 can do up to 400 kHz
    mClockPrescale = 0x40;
    
    // Build the list of slaves
    // Loop over node parameters. Each parameter becomes a slave node.
    const boost::unordered_map<std::string, std::string>& lPars = this->getParameters();
    boost::unordered_map<std::string, std::string>::const_iterator lIt;
    for ( lIt = lPars.begin(); lIt != lPars.end(); ++lIt ) {
        uint32_t slaveAddr = (boost::lexical_cast< mp7::stoul<uint32_t> > (lIt->second) & 0x7f);
        mSlavesAddresses.insert(std::make_pair( lIt->first, slaveAddr  ) );
    }
    
}

I2CBaseNode::~I2CBaseNode() {
}

std::vector<std::string>
I2CBaseNode::getSlaves() const {
    std::vector<std::string> lSlaves;

    boost::copy(mSlavesAddresses | boost::adaptors::map_keys, std::back_inserter(lSlaves));
    return lSlaves;
    
}

uint8_t
I2CBaseNode::getSlaveAddress(const std::string& name) const {
    boost::unordered_map<std::string, uint8_t>::const_iterator lIt = mSlavesAddresses.find(name);
    if ( lIt == mSlavesAddresses.end() ) {
        mp7::I2CSlaveNotFound lExc( std::string("Slave \"") + name + "\" not found" );
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }
    return lIt->second;
}

uint8_t I2CBaseNode::readI2C(uint8_t aSlaveAddress, uint32_t i2cAddress) const {
    // write one word containing the address
    std::vector<uint8_t> array(1, i2cAddress & 0x7f);
    this->writeBlockI2C(aSlaveAddress, array);
    // request the content at the specific address
    return this->readBlockI2C(aSlaveAddress, 1) [0];
}

void I2CBaseNode::writeI2C(uint8_t aSlaveAddress, uint32_t i2cAddress, uint32_t data) const {
    std::vector<uint8_t> block(2);
    block[0] = (i2cAddress & 0xff);
    block[1] = (data & 0xff);
    this->writeBlockI2C(aSlaveAddress, block);
}

void I2CBaseNode::writeBlockI2C(uint8_t aSlaveAddress, const std::vector<uint8_t>& array) const {
    // transmit reg definitions
    // bits 7-1: 7-bit slave address during address transfer
    //           or first 7 bits of byte during data transfer
    // bit 0: RW flag during address transfer or LSB during data transfer.
    // '1' = reading from slave
    // '0' = writing to slave
    // command reg definitions
    // bit 7: Generate start condition
    // bit 6: Generate stop condition
    // bit 5: Read from slave
    // bit 4: Write to slave
    // bit 3: 0 when acknowledgement is received
    // bit 2:1: Reserved
    // bit 0: Interrupt acknowledge. When set, clears a pending interrupt
    // Reset bus before beginning
    reset();
    // Set slave address in bits 7:1, and set bit 0 to zero (i.e. "write mode")
    getNode(mTx).write((aSlaveAddress << 1) & 0xfe);
    getClient().dispatch();
    // Set start and write bit in command reg
    getNode(mCmd).write(0x90);
    // Run the commands and wait for transaction to finish
    getClient().dispatch();
    waitUntilFinished();

    for (unsigned ibyte = 0; ibyte < array.size(); ibyte++) {
        uint8_t stop_bit = 0x00;

        if (ibyte == array.size() - 1) {
            stop_bit = 0x40;
        }

        // Set array to be written in transmit reg
        getNode(mTx).write(array[ibyte]);
        getClient().dispatch();
        // Set write and stop bit in command reg
        getNode(mCmd).write(0x10 + stop_bit);
        // Run the commands and wait for transaction to finish
        getClient().dispatch();

        if (stop_bit) {
            waitUntilFinished(true, true);
        } else {
            waitUntilFinished(true, false);
        }
    }
}


//void OpenCoresI2CMasterNode::read(const uint32_t numBytes,
//                            std::vector<uint8_t>& array) {

std::vector<uint8_t>
I2CBaseNode::readBlockI2C(uint8_t aSlaveAddress, uint32_t numBytes) const {
    // transmit reg definitions
    // bits 7-1: 7-bit slave address during address transfer
    //           or first 7 bits of byte during data transfer
    // bit 0: RW flag during address transfer or LSB during data transfer.
    //        '1' = reading from slave
    //        '0' = writing to slave
    // command reg definitions
    // bit 7:   Generate start condition
    // bit 6:   Generate stop condition
    // bit 5:   Read from slave
    // bit 4:   Write to slave
    // bit 3:   0 when acknowledgement is received
    // bit 2:1: Reserved
    // bit 0:   Interrupt acknowledge. When set, clears a pending interrupt
    // Reset bus before beginning
    reset();
    // Set slave address in bits 7:1, and set bit 0 to one
    // (i.e. we're writing an address to the bus and then want to read)
    getNode(mTx).write((aSlaveAddress << 1) | 0x01);
    getClient().dispatch();
    // Set start and write bit in command reg
    getNode(mCmd).write(0x90);
    // Run the commands and wait for transaction to finish
    getClient().dispatch();
    waitUntilFinished();
    std::vector<uint8_t> array;

    for (unsigned ibyte = 0; ibyte < numBytes; ibyte++) {
        // Set read bit, acknowledge and stop bit in command reg
        uint8_t stop_bit = 0x00;
        uint8_t ack_bit = 0x00;

        if (ibyte == numBytes - 1) {
            stop_bit = 0x40;
            ack_bit = 0x08;
        }

        getNode(mCmd).write(0x20 + ack_bit + stop_bit);
        getClient().dispatch();

        // Wait for transaction to finish.
        // Don't expect an ACK, do expect bus free at finish.
        if (stop_bit) {
            waitUntilFinished(false, true);
        } else {
            waitUntilFinished(false, false);
        }

        uhal::ValWord<uint32_t> result = getNode(mRx).read();
        getClient().dispatch();
        array.push_back(result);
    }

    return array;
}

void I2CBaseNode::reset() const {
    // Resets the I2C bus
    //
    // This function does the following:
    //        1) Disables the I2C core
    //        2) Sets the clock prescale registers
    //        3) Enables the I2C core
    //        4) Sets all writable bus-master registers to default values
    // disable the I2C core
    getNode(mCtrl).write(0x00);
    getClient().dispatch();
    // set the clock prescale
    getNode(mPreHi).write((mClockPrescale & 0xff00) >> 8);
    getClient().dispatch();
    getNode(mPreLo).write(mClockPrescale & 0xff);
    getClient().dispatch();
    // enable the I2C core
    getNode(mCtrl).write(0x80);
    getClient().dispatch();
    // set all writable bus-master registers to default values
    getNode(mTx).write(0x00);
    getClient().dispatch();
    getNode(mCmd).write(0x00);
    getClient().dispatch();
}

void I2CBaseNode::waitUntilFinished(bool requireAcknowledgement,
        bool requireBusIdleAtEnd) const {
    // Ensures the current bus transaction has finished successfully
    // before allowing further I2C bus transactions
    // This method monitors the status register
    // and will not allow execution to continue until the
    // I2C bus has completed properly.  It will throw an exception
    // if it picks up bus problems or a bus timeout occurs.
    const unsigned maxRetry = 20;
    unsigned attempt = 1;
    bool receivedAcknowledge, busy;

    while (attempt <= maxRetry) {
        usleep(10);
        // Get the status
        uhal::ValWord<uint32_t> i2c_status = getNode(mStatus).read();
        getClient().dispatch();
        receivedAcknowledge = !(i2c_status & 0x80);
        busy = (i2c_status & 0x40);
        bool arbitrationLost = (i2c_status & 0x20);
        bool transferInProgress = (i2c_status & 0x02);
        //bool interruptFlag = (i2c_status & 0x01);

        if (arbitrationLost) {
            // This is an instant error at any time
            mp7::I2CException lExc("OpenCoresI2CMasterNode error: bus arbitration lost. Is another application running?");
            MP7_LOG(l7::kError) << lExc.what();
            throw lExc;
        }

        if (!transferInProgress) {
            // The transfer looks to have completed successfully,
            // pending further checks
            break;
        }

        attempt += 1;
    }

    // At this point, we've either had too many retries, or the
    // Transfer in Progress (TIP) bit went low.  If the TIP bit
    // did go low, then we do a couple of other checks to see if
    // the bus operated as expected:

    if (attempt > maxRetry) {
        mp7::I2CException lExc("OpenCoresI2CMasterNode error: Transaction timeout - the 'Transfer in Progress' bit remained high for too long");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }

    if (requireAcknowledgement && !receivedAcknowledge) {
        mp7::I2CException lExc("OpenCoresI2CMasterNode error: No acknowledge received");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }

    if (requireBusIdleAtEnd && busy) {
        mp7::I2CException lExc("OpenCoresI2CMasterNode error: Transfer finished but bus still busy");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }
}

I2CSlave::I2CSlave(const I2CBaseNode* aMaster, uint8_t aSlaveAddress) :
mMaster(aMaster), mAddress(aSlaveAddress) {
}


I2CSlave::~I2CSlave() {

}


// comodity functions
uint8_t
I2CSlave::readI2C(uint32_t i2cAddress) const {
    return mMaster->readI2C(mAddress, i2cAddress);
}


void
I2CSlave::writeI2C(uint32_t i2cAddress, uint32_t data) const {
    mMaster->writeI2C(mAddress, i2cAddress, data);
}


//____________________________________________________________________________//
I2CMasterNode::I2CMasterNode( const uhal::Node& aNode ) : I2CBaseNode(aNode) {
    constructor();
}


I2CMasterNode::I2CMasterNode(const I2CMasterNode& aOther ) : I2CBaseNode(aOther) {
    constructor();
}


void I2CMasterNode::constructor() {
   
    /// Use the list of addresses to build plain slaves
    boost::unordered_map<std::string, uint8_t>::const_iterator lIt;
    for( lIt = mSlavesAddresses.begin(); lIt != mSlavesAddresses.end(); ++lIt) {
        mSlaves.insert(std::make_pair( lIt->first, new I2CSlave( this, lIt->second ) ) );
    }
}


I2CMasterNode::~I2CMasterNode() {
    boost::unordered_map<std::string, I2CSlave*>::iterator lIt;
    for ( lIt = mSlaves.begin(); lIt != mSlaves.end(); ++lIt ) {
        // Delete slaves
        delete lIt->second;
    }
}


const I2CSlave&
I2CMasterNode::getSlave(const std::string& name) const {
    boost::unordered_map<std::string, I2CSlave*>::const_iterator lIt = mSlaves.find(name);
    if ( lIt == mSlaves.end() ) {
        mp7::I2CSlaveNotFound lExc(std::string("Slave ")+name+" not found.");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }
    return *(lIt->second);
}

} // namespace opencores
} // namespace mp7

