/**
 * @file    ChannelIDSet.hpp
 * @author  Alessandro Thea
 * @date    December 2014
 */

#ifndef __MP7_CHANNELIDSET_HPP__
#define __MP7_CHANNELIDSET_HPP__

// C++ Headers
#include <vector>
#include <map>
#include <stdint.h>

#include "mp7/definitions.hpp"

#include <boost/function.hpp>
//#include <boost/foreach.hpp>
#include <boost/optional.hpp>

namespace mp7{

typedef boost::optional<std::vector<uint32_t> > ChannelMask;
typedef boost::function<bool (const RegionInfo&) > ChannelRule;

class ChannelGroup;

/**
 * class DatapathDescriptor
 * 
 * Helper class holding information about instantiated regions
 * 
 *  - Rx MGT Kind
 *  - Rx CRC
 *  - Rx Buffer
 *  - Formatter
 *  - Tx Buffer
 *  - Tx CRC
 *  - Tx MGT Kind
 */
class DatapathDescriptor {

public:
    
    /**
     * Default constructor
     */
    DatapathDescriptor();

    /**
     * Comy and mask constructor.
     * 
     * Copies a Datapath object and applies a channel mask in the proces
     * 
     * @param aOther Object to copy
     * @param aChannels Channel mask. Only channels listed here will beavailable in the copied object.
     */    
    DatapathDescriptor( const DatapathDescriptor& aOther, const std::vector<uint32_t> aChannels );
    
    /**
     * Constructor from map of region infos.
     * @details [long description]
     * 
     * @param aRegionMap Map of RegionInfos to build the DatapathDescripto from
     */
    explicit DatapathDescriptor( const std::map<uint32_t, RegionInfo>& aRegionMap );
    
    /**
     * RegionInfo mat getter
     * @details [long description]
     * @return [description]
     */
    const std::map<uint32_t, RegionInfo>& getRegionInfoMap() const;
    
    const RegionInfo& getRegionInfo( uint32_t aRegion ) const;
    
    const RegionInfo& getRegionInfoByChannel( uint32_t aChannel ) const;

    
    /**
     * Pick all channels
     * 
     * @return aChannelGroup including all known channels
     */
    ChannelGroup pickAllIDs() const;

    /**
     * Pick Rx channels of a given MGT kind
     * 
     * @param aMGTKind MGT kind selection
     * @return ChannelGroup including all Rx channels of the selected MGT kind
     */
    ChannelGroup pickRxMGTIDs( MGTKind aMGTKind ) const;

    /**
     * Pick Rx channels of a given checksum kind
     * 
     * @param aCheckSumKind checksum kind selection
     * @return ChannelGroup including all Rx channels of the selected checksum kind
     */
    ChannelGroup pickRxCheckSumIDs( CheckSumKind aCheckSumKind ) const;

    /**
     * Pick Rx channels with/without buffers
     * 
     * @param aBufferKind buffer kind selection
     * @return ChannelGroup including all Rx channels of the selected kind
     */
    ChannelGroup pickRxBufferIDs( BufferKind aBufferKind ) const;

    /**
     * Pick channels of a given formatter kind
     * 
     * @param aFmtKind formatter kind selection
     * @return ChannelGroup including all channels of the selected kind
     */
    ChannelGroup pickFmtIDs( FormatterKind aFmtKind ) const;
    
    /**
     * Pick Tx channels with/without buffers
     * 
     * @param aBufferKind buffer kind selection
     * @return ChannelGroup including all Rx channels of the selected kind
     */
    ChannelGroup pickTxBufferIDs( BufferKind aBufferKind ) const;
    
    /**
     * Pick Tx channels of a given checksum kind
     * 
     * @param aCheckSumKind checksum kind selection
     * @return ChannelGroup including all Tx channels of the selected checksum kind
     */
    ChannelGroup pickTxCheckSumIDs( CheckSumKind aCheckSumKind ) const;

    /**
     * Pick Tx channels of a given MGT kind
     * 
     * @param aMGTKind MGT kind selection
     * @return ChannelGroup including all Tx channels of the selected MGT kind
     */
    ChannelGroup pickTxMGTIDs( MGTKind aMGTKind ) const;

    template<class Selector>
    ChannelGroup pickIDs( Selector aSelector ) const;
    
private:
    std::map<uint32_t, RegionInfo> mRegions;
    ChannelMask mMask;
};


class ChannelGroup {
public:
  ChannelGroup();
  explicit ChannelGroup( const std::vector<uint32_t>& aChannels );
  ~ChannelGroup();
  
  /**
   * Creates a ChannelGroup object from a vector of region IDs
   * 
   * @param aRegions vector of region IDs.
   * @return ChannelGroup object conaining channels corresponding to the list of regions
   */
  static ChannelGroup fromRegions(const std::vector<uint32_t> &aRegions);
  
  /**
   * Returns a vector of known channel IDs
   * @return vector of known channel IDs
   */
  const std::vector<uint32_t>& channels() const;
  
  /**
   * Returns a vector of known channel IDs
   * @return vector of known channel IDs
   */
  std::vector<uint32_t> regions() const;
  
  //! Returns IDs of enabled channels within specified region
  const std::vector<uint32_t>& channels(const uint32_t aRegion) const;
  
  //! Returns Local IDs of enabled channels within specified region
  const std::vector<uint32_t>& locals(const uint32_t aRegion) const;
  
  ChannelGroup intersect( const std::vector<uint32_t> aChannels ) const;

  /**
   * Converts channel ID into a local id (region specific)
   * 
   * @param aChannel channel ID
   * @return local ID withing a region
   */
  static uint32_t channelToRegion( uint32_t aChannel );

  /**
   * Converts channel ID to a local ID (region specific)
   * 
   * @param aChannel channel ID
   * @return local ID withing a region
   */
  static uint32_t channelToLocal( uint32_t aChannel );

private:
  
  const static uint32_t kChannelsPerRegion;
  
  //! Channels
  std::vector<uint32_t> mChannels;

  //! Regions -> Channel map for enabled channels 
  std::map<uint32_t, std::vector<uint32_t> > mRegions2Channels;

  //! Regions -> Local IDs map for enabled channels 
  std::map<uint32_t, std::vector<uint32_t> > mRegions2Locals;

  //! 
  // std::map<uint32_t, RegionInfo> mRegionInfos;
};



template<typename Selector>
ChannelGroup
DatapathDescriptor::pickIDs( Selector aSelector ) const {
  std::vector<uint32_t> regs;
  for(const auto& ri : mRegions) {
    if ( !aSelector(ri.second) ) continue;
    regs.push_back(ri.first);
  }
  
  ChannelGroup ids = ChannelGroup::fromRegions(regs);
  return ( mMask == boost::none ? ids : ids.intersect(*mMask) ); 
}

} // namespace mp7

#endif /* __MP7_CHANNELIDSET_HPP__ */
