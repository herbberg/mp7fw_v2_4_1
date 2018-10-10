#ifndef __MP7_DATAPATHNODE_HPP__
#define	__MP7_DATAPATHNODE_HPP__

// uHAL Headers
#include "uhal/DerivedNode.hpp"

// MP7 Headers
#include "mp7/definitions.hpp"
#include "mp7/CommandSequence.hpp"

// C++ Headers
#include <vector>

namespace mp7 {

// Forward declaration
class TransactionQueue;
class DatapathSequencer;


/*!
 * @class DatapathNode
 * @brief Class to control the transciever buffer interface
 *
 * @author Alessandro Thea
 * @date Sometime in 2013
 */

class DatapathNode : public uhal::Node {
    UHAL_DERIVEDNODE(DatapathNode);
public:

    // PUBLIC METHODS
    DatapathNode(const uhal::Node& aNode);

    virtual ~DatapathNode();

    /// Select the channel to access to
    void selectChannel(uint32_t aChannel) const;

    /// Select quad to access to
    void selectRegion(uint32_t aRegion) const;

    /// Select quad and channel
    void selectRegChan(uint32_t aRegion, uint32_t aChannel) const;

    /// Select link
    void selectLink(uint32_t aLink) const;

    /// Select buffer
    void selectLinkBuffer(uint32_t aLink, RxTxSelector aBuffer) const;

    std::map<uint32_t, RegionInfo> readRegionInfoMap( const std::vector<uint32_t>& aRegions ) const;

    /**
     * Experimental
     */
    DatapathSequencer queue( TransactionQueue& aSequence ) const;

};

class DatapathSequencer {
    DatapathSequencer( const DatapathNode& aCtrl, TransactionQueue& aSequence );
public:
    ~DatapathSequencer();

    void selectRegion( uint32_t aRegion ) const;
    void selectRegChan( uint32_t aRegion, uint32_t aChannel ) const;
    void selectLink( uint32_t aLink ) const;
    void selectLinkBuffer( uint32_t aLink, RxTxSelector aBuffer ) const;

private:
    const DatapathNode& mDatapath;
    TransactionQueue& mSequence;
    
    friend class DatapathNode;    
};

}

#endif	/* __MP7_DATAPATHNODE_HPP__ */


