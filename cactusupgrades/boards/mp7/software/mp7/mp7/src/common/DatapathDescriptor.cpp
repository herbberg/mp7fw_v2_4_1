/**
 * @file    ChannelIDSet.cpp
 * @author  Alessandro Thea
 * @date    December 2014
 */

#include "mp7/DatapathDescriptor.hpp"

// C++ Headers
#include <stdexcept>

// Boost Headers
//#include <boost/foreach.hpp>
#include <boost/range/adaptor/map.hpp>
#include <boost/range/algorithm/copy.hpp>
#include <boost/range/counting_range.hpp>
#include <boost/bind.hpp>
#include <boost/phoenix/bind/bind_member_variable.hpp>
#include <boost/lambda/lambda.hpp>
#include <boost/optional.hpp>
// MP7 Headers
#include "mp7/Utilities.hpp"

namespace mp7 {

// ----------------------------------------
DatapathDescriptor::DatapathDescriptor() : mMask(boost::none) {
}

// ----------------------------------------
DatapathDescriptor::DatapathDescriptor(const DatapathDescriptor& aOther, const std::vector<uint32_t> aChannels) : 
  mRegions(aOther.mRegions), mMask(aChannels) {
}

// ----------------------------------------
DatapathDescriptor::DatapathDescriptor( const std::map<uint32_t, RegionInfo>& aRegionMap ) : 
mRegions(aRegionMap), mMask(boost::none) {
}

// ----------------------------------------
const std::map<uint32_t, RegionInfo>& 
DatapathDescriptor::getRegionInfoMap() const {
  return mRegions;
}


const RegionInfo& DatapathDescriptor::getRegionInfo(uint32_t aRegion) const
{
  return mRegions.at(aRegion);
}


const RegionInfo& DatapathDescriptor::getRegionInfoByChannel(uint32_t aChannel) const
{
  return getRegionInfo(ChannelGroup::channelToRegion(aChannel));
}


// ----------------------------------------
ChannelGroup 
DatapathDescriptor::pickAllIDs() const {
  std::vector<uint32_t> all;
  boost::copy(mRegions | boost::adaptors::map_keys, std::back_inserter(all));
  ChannelGroup ids = ChannelGroup::fromRegions(all);

  return ( mMask == boost::none ? ids : ids.intersect(*mMask) );
}

// ----------------------------------------
ChannelGroup 
DatapathDescriptor::pickRxMGTIDs(MGTKind aMGTKind) const {
  return pickIDs(boost::bind(&RegionInfo::mgtIn, _1) == aMGTKind);
}

// ----------------------------------------
ChannelGroup
DatapathDescriptor::pickRxCheckSumIDs(CheckSumKind aCheckSumKind) const {
  return pickIDs(boost::bind(&RegionInfo::chkIn, _1) == aCheckSumKind);
}

// ----------------------------------------
ChannelGroup
DatapathDescriptor::pickRxBufferIDs(BufferKind aBufferKind) const {
  return pickIDs(boost::bind(&RegionInfo::bufIn, _1) == aBufferKind);
}

// ----------------------------------------
ChannelGroup
DatapathDescriptor::pickFmtIDs( FormatterKind aFmtKind ) const {
  return pickIDs(boost::bind(&RegionInfo::fmt, _1) == aFmtKind);
}


// ----------------------------------------
ChannelGroup
DatapathDescriptor::pickTxBufferIDs(BufferKind aBufferKind) const {
  return pickIDs(boost::bind(&RegionInfo::bufOut, _1) == aBufferKind);

}

ChannelGroup DatapathDescriptor::pickTxCheckSumIDs(CheckSumKind aCheckSumKind) const {
  return pickIDs(boost::bind(&RegionInfo::chkOut, _1) == aCheckSumKind);
}

// ----------------------------------------
ChannelGroup 
DatapathDescriptor::pickTxMGTIDs(MGTKind aMGTKind) const {
  return pickIDs(boost::bind(&RegionInfo::mgtOut, _1) == aMGTKind);
}


const uint32_t ChannelGroup::kChannelsPerRegion = 4;


// ----------------------------------------
uint32_t
ChannelGroup::channelToRegion(uint32_t aChannel) {
  return aChannel/kChannelsPerRegion;
}


// ----------------------------------------
uint32_t
ChannelGroup::channelToLocal(uint32_t aChannel) {
  return aChannel % kChannelsPerRegion;
}


// ----------------------------------------
ChannelGroup::ChannelGroup() {
}


// ----------------------------------------
ChannelGroup::ChannelGroup(const std::vector<uint32_t>& aChannels) :
  mChannels(sanitize(aChannels)) {

  // Arrange channels into regions
  for(const uint32_t& c :  mChannels) {
    mRegions2Channels[channelToRegion(c)].push_back(c);
    mRegions2Locals[channelToRegion(c)].push_back(channelToLocal(c));
  }
  
}


// ----------------------------------------
ChannelGroup::~ChannelGroup() {
}


// ----------------------------------------
ChannelGroup
ChannelGroup::fromRegions(const std::vector<uint32_t>& aRegions) {
  using namespace boost;
  ChannelGroup chanSet;

  // Using boost counting_range just for fun
  iterator_range< counting_iterator<uint32_t> > locals = counting_range((uint32_t)0, kChannelsPerRegion);

  // Create corresponding channels
  for(uint32_t r :  sanitize(aRegions) ) {
    // Using boost counting_range just for fun
    iterator_range< counting_iterator<uint32_t> > range = counting_range(r*kChannelsPerRegion, (r+1) * kChannelsPerRegion);
    // and boost copy
    copy(
        range,
        std::back_inserter(chanSet.mRegions2Channels[r])
        );
    // once more for local ids
    copy(
        locals,
        std::back_inserter(chanSet.mRegions2Locals[r])
        );
    // again :)
    copy(
        range,
        std::back_inserter(chanSet.mChannels)
        );
  }
  return chanSet;
}


// ----------------------------------------
const std::vector<uint32_t>&
ChannelGroup::channels() const {
  return mChannels;
}

// ----------------------------------------
const std::vector<uint32_t>&
ChannelGroup::channels(const uint32_t aRegion) const {
  
  std::map<uint32_t, std::vector<uint32_t> >::const_iterator it = mRegions2Channels.find(aRegion);
  if (it == mRegions2Channels.end())
    throw std::runtime_error("Region " + to_string(aRegion) + " not found");

  return it->second;
}

// ----------------------------------------
const std::vector<uint32_t>&
ChannelGroup::locals(const uint32_t aRegion) const {
  
  std::map<uint32_t, std::vector<uint32_t> >::const_iterator it = mRegions2Locals.find(aRegion);
  if (it == mRegions2Channels.end())
    throw std::runtime_error("Region " + to_string(aRegion) + " not found");

  return it->second;
}

// ----------------------------------------
std::vector<uint32_t>
ChannelGroup::regions() const {
  std::vector<uint32_t> regions;
  // Retrieve all keys
  boost::copy(mRegions2Channels | boost::adaptors::map_keys, std::back_inserter(regions));
  return regions;
}


// ----------------------------------------
ChannelGroup
ChannelGroup::intersect(const std::vector<uint32_t> aChannels) const {

  // Sanitise the inputs, by copying
  std::vector<uint32_t> sorted = sanitize(aChannels);

  // Resulting set
  std::vector<uint32_t> enabled;

  std::set_intersection(
      sorted.begin(), sorted.end(),
      mChannels.begin(), mChannels.end(),
      std::back_insert_iterator< std::vector<uint32_t> >(enabled));
  
  return ChannelGroup(enabled);
}


}
