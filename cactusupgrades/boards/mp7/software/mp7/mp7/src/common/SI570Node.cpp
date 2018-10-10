/**
 * @file    SI570Node.cpp
 * @author  Alessandro Thea
 * @date    June 2014
 */

#include "mp7/SI570Node.hpp"

#include <fstream>

// MP7 Headers
#include "mp7/exception.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"

// Namespace Resolution
namespace l7 = mp7::logger;

namespace mp7 {

//---
SI570Slave::SI570Slave(const opencores::I2CBaseNode* aMaster, uint8_t aSlaveAddress) : opencores::I2CSlave(aMaster,aSlaveAddress) {
}


//---
SI570Slave::~SI570Slave() {
}


//---
void
SI570Slave::configure(const std::string& aFilename) const {
    
    fileExists(aFilename);

    // using namespace uhal;
    std::string lLine;
    std::ifstream lFile(aFilename.c_str());

    // TODO: Redundant: Move this check into fileExists
    if (!lFile.is_open()) {
        mp7::MP7HelperException lExc(aFilename + " was not found!");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }

    while (lFile.good()) {
        std::getline(lFile, lLine);

        if (lLine[0] == '#') {
            continue;
        }

        if (lLine.length() == 0) {
            break;
        }

        std::stringstream lStr;
        uint32_t lAddr(0), lData(0);
        char lDummy1, lDummy2;
        lStr << lLine;
        lStr >> std::dec >> lAddr >> lDummy1 >> std::hex >> lData >> lDummy2;
        //    log( Info() ,  "Register Address = ", Integer( lAddr ), " : Register Value = " , Integer(  lData, IntFmt<uhal::hex>() ) );
        MP7_LOG(l7::kDebug) << "Register Address = " << l7::hexFmt(lAddr) << " : Register Value = " << l7::hexFmt(lData);
        this->writeI2C(lAddr, lData);
    }

    lFile.close();

}

//___
UHAL_REGISTER_DERIVED_NODE(SI570Node);


//---
SI570Node::SI570Node( const uhal::Node& aNode ) : opencores::I2CBaseNode(aNode), SI570Slave(this, this->getSlaveAddress("i2caddr") ) {
}


//---
SI570Node::SI570Node( const SI570Node& aOther ) : opencores::I2CBaseNode(aOther), SI570Slave(this, this->getSlaveAddress("i2caddr") ) {
}


//---
SI570Node::~SI570Node() {
}

}
