#include "mp7/DatapathNode.hpp"

#include "mp7/definitions.hpp"
#include "mp7/exception.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/Logger.hpp"

//#include <boost/foreach.hpp>

// Namespace declaration
namespace l7 = mp7::logger;

namespace mp7 {

UHAL_REGISTER_DERIVED_NODE(DatapathNode);

// PUBLIC METHODS
//---
DatapathNode::DatapathNode(const uhal::Node& aNode) :
uhal::Node(aNode) {
}


//---
DatapathNode::~DatapathNode() {
}


//---
void
DatapathNode::selectChannel(uint32_t channel) const {
    // throw here if channel > 4
    getNode("ctrl.chan_sel").write(channel);
    getClient().dispatch();
}


//---
void
DatapathNode::selectRegion(uint32_t region) const {
    //
    getNode("ctrl.quad_sel").write(region);
    getClient().dispatch();
}


//---
void
DatapathNode::selectRegChan(uint32_t quad, uint32_t chan) const {
    getNode("ctrl.quad_sel").write(quad);
    getNode("ctrl.chan_sel").write(chan);
    getClient().dispatch();
}


//---
void
DatapathNode::selectLink(uint32_t link) const {
    // MP7_LOG(l7::Debug) << "Selecting link " << link;
    this->selectRegChan(link / 4, link % 4);
}


//---
void
DatapathNode::selectLinkBuffer(uint32_t aLink, RxTxSelector aBuffer) const {
    // MP7_LOG(l7::Debug) << "Selecting link buffer " << aLink;
    getNode("ctrl.quad_sel").write(aLink / 4);
    getNode("ctrl.chan_sel").write(aLink % 4);
    getNode("ctrl.txrx_sel").write(aBuffer);
    getClient().dispatch();
}

std::map<uint32_t, RegionInfo> 
DatapathNode::readRegionInfoMap( const std::vector<uint32_t>& aRegions ) const {

    std::map<uint32_t, RegionInfo> map;

    uhal::ValWord<uint32_t> mgtI, bufI, chkI, fmt, chkO, bufO, mgtO;

    for ( uint32_t r :  aRegions ) {
        this->getNode("ctrl.quad_sel").write(r);

        RegionInfo& ri = map[r];

        mgtI = getNode("region_info.mgt_i_kind").read();
        chkI = getNode("region_info.chk_i_kind").read();
        bufI = getNode("region_info.buf_i_kind").read();
        fmt  = getNode("region_info.fmt_kind").read();
        bufO = getNode("region_info.buf_o_kind").read();
        chkO = getNode("region_info.chk_o_kind").read();
        mgtO = getNode("region_info.mgt_o_kind").read();

        getClient().dispatch();


        ri.mgtIn  = safe_enum_cast((uint32_t)mgtI, kKnownMGTs, kUnknownMGT);
        ri.chkIn  = safe_enum_cast((uint32_t)chkI, kKnownCheckSums, kUnknownCheckSum);
        ri.bufIn  = safe_enum_cast((uint32_t)bufI, kKnownBuffers, kUnknownBuffer);
        ri.fmt    = safe_enum_cast((uint32_t)fmt,  kKnownFormatters, kUnknownFormatter);
        ri.bufOut = safe_enum_cast((uint32_t)bufO, kKnownBuffers, kUnknownBuffer);
        ri.chkOut = safe_enum_cast((uint32_t)chkO, kKnownCheckSums, kUnknownCheckSum);
        ri.mgtOut = safe_enum_cast((uint32_t)mgtO, kKnownMGTs, kUnknownMGT);
        
        if ( ri.mgtIn == kUnknownMGT ) {
            ri.mgtIn = kNoMGT;
            MP7_LOG(l7::kWarning) << "Region " << r << ": Unknown Input MGT type. Forced to NoMGT";
        }
        if ( ri.chkIn == kUnknownCheckSum ) {
            ri.chkIn = kNoCheckSum;
            MP7_LOG(l7::kWarning) << "Region " << r << ": Unknown Input CheckSum type. Forced to NoChecksum";
        }
        if ( ri.bufIn == kUnknownBuffer ) {
            ri.bufIn = kNoBuffer;  
            MP7_LOG(l7::kWarning) << "Region " << r << ": Unknown Input Buffer type. Forced to NoBuffer";
        }        
        if ( ri.fmt == kUnknownFormatter ) {
            ri.fmt = kNoFormatter;  
            MP7_LOG(l7::kWarning) << "Region " << r << ": Unknown Formatter type. Forced to NoFormatter";
        }      
        if ( ri.bufOut == kUnknownBuffer ) {
            ri.bufOut = kNoBuffer;  
            MP7_LOG(l7::kWarning) << "Region " << r << ": Unknown Output Buffer type. Forced to NoBuffer";
        }      
        if ( ri.chkOut == kUnknownCheckSum ) {
            ri.chkOut = kNoCheckSum;  
            MP7_LOG(l7::kWarning) << "Region " << r << ": Unknown Output CheckSum type. Forced to NoChecksum";
        }
        if ( ri.mgtOut == kUnknownMGT ) {
            ri.mgtIn = kNoMGT;
            MP7_LOG(l7::kWarning) << "Region " << r << ": Unknown Output MGT type. Forced to NoMGT";
        }

    }

    return map;
}




//---Experimental-------------------------------------------------------------//

DatapathSequencer DatapathNode::queue(TransactionQueue& aSequence) const {
    return DatapathSequencer(*this, aSequence);
}


//---
DatapathSequencer::DatapathSequencer(const DatapathNode& aDatapath, TransactionQueue& aSequence) :
    mDatapath(aDatapath),
    mSequence(aSequence) {

}


//---
DatapathSequencer::~DatapathSequencer() {
}


//---
void DatapathSequencer::selectRegion(uint32_t aRegion) const {
    mSequence.write(mDatapath.getNode("ctrl.quad_sel"), aRegion);
}


//---
void DatapathSequencer::selectRegChan(uint32_t aRegion, uint32_t aChannel) const {
    mSequence.write(mDatapath.getNode("ctrl.quad_sel"), aRegion);
    mSequence.write(mDatapath.getNode("ctrl.chan_sel"), aChannel);
}


//---
void DatapathSequencer::selectLink(uint32_t aLink) const {
    this->selectRegChan( aLink / 4, aLink % 4);
}


//---
void DatapathSequencer::selectLinkBuffer(uint32_t aLink, RxTxSelector aBuffer) const {
    mSequence.write(mDatapath.getNode("ctrl.quad_sel"), aLink / 4);
    mSequence.write(mDatapath.getNode("ctrl.chan_sel"), aLink % 4);
    mSequence.write(mDatapath.getNode("ctrl.txrx_sel"), aBuffer);
}

} // namespace mp7
