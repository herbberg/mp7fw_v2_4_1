#include "mp7/ZeroSuppressionNode.hpp"

#include "mp7/definitions.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/Logger.hpp"
//#include <boost/foreach.hpp>

namespace mp7 {
UHAL_REGISTER_DERIVED_NODE(ZeroSuppressionNode);

// //---
// std::string printhex( const std::vector<uint32_t>& v) {

//     if ( v.empty() ) return "";

//     std::ostringstream ss;

//     ss << "[" << std::noshowbase << std::hex << "'0x" << v.front() << "'";
//     for( std::vector<uint32_t>::const_iterator it(next(v.begin())); it != v.end(); ++it) {
//         ss << ", '" << std::noshowbase << std::hex << "0x" << *it << "'";
//     }

//     ss << "]";

//     return ss.str();
// }
// //---


//-----------------------------------------------------------------------------
ZeroSuppressionMenu::Mask::Mask() :
enable(false),
data(ZeroSuppressionNode::kBxMaskSize, 0x0)
{
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
ZeroSuppressionMenu::ZeroSuppressionMenu( ) :
mNumCapIds(ZeroSuppressionNode::kNumCapIds),
mValidationMode(0x0),
mMasks(ZeroSuppressionNode::kNumCapIds)
{

}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void ZeroSuppressionMenu::setValidationMode( uint32_t aValMode ) {
  mValidationMode = aValMode;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
uint32_t ZeroSuppressionMenu::validationMode() const {
  return mValidationMode;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
ZeroSuppressionMenu::Mask& ZeroSuppressionMenu::operator[]( uint32_t aCapId ) {

  try {
    return mMasks.at(aCapId);
  } catch ( const std::out_of_range& e ) {
    std::ostringstream lExc;
    lExc << "Capture id " << aCapId << " outside valid range [0," << mMasks.size() << "]";
    throw InvalidCaptureId(lExc.str());
  }
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
const ZeroSuppressionMenu::Mask&
ZeroSuppressionMenu::operator[]( uint32_t aCapId ) const {
  return const_cast<ZeroSuppressionMenu*>(this)->operator [](aCapId);
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
std::ostream& operator<<( std::ostream& oStream, const ZeroSuppressionMenu& aMenu ) {
  auto fmt = oStream.flags();
  oStream << std::showbase
          << "validation mode: " << std::hex << aMenu.validationMode() << std::endl;


  for( uint32_t lCapId(0); lCapId < aMenu.mMasks.size(); ++lCapId ) {
    const ZeroSuppressionMenu::Mask& lMask = aMenu.mMasks[lCapId];
    oStream << "cap " << std::hex << std::noshowbase << "0x" << lCapId << " : { enable: " << lMask.enable << ", invert: " << lMask.invert << ", data: [" << std::showbase;  

    std::vector<uint32_t>::const_iterator lLast(std::prev(lMask.data.end()));
    std::copy(lMask.data.begin(), lLast, std::ostream_iterator<uint32_t>(oStream, ","));
    oStream << *lLast << "] }";
    oStream << std::endl;
  }
  // for( const Mask& lItem :  aMenu.mMasks ) {
  //   oStream << lItem.first << " : {" << std::showbase;

  //   std::vector<uint32_t>::const_iterator lIt(lItem.second.begin()), lE(std::prev(lItem.second.end()));
    
  //   for ( ; lIt != lE; ++lIt ) {
  //     oStream << std::hex << *lIt << ",";
  //   }
  //   oStream << std::hex << *lIt;
  //   oStream << "}" << std::endl;
  // }

  oStream.flags(fmt);
  return oStream;
}
//-----------------------------------------------------------------------------

// Constants
const uint32_t ZeroSuppressionNode::kNumCapIds = 16;
const uint32_t ZeroSuppressionNode::kBxMaskSize = 6;

//-----------------------------------------------------------------------------
ZeroSuppressionNode::ZeroSuppressionNode(const uhal::Node& aNode) :
  uhal::Node(aNode) {
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
bool 
ZeroSuppressionNode::isAvailable() const {
    uhal::ValWord<uint32_t> lAvailable = getNode("csr.info.zs_enabled").read();
    getClient().dispatch();

    return lAvailable;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
ZeroSuppressionNode::throwIfNotAvailable() const {
  // Stop here if the ZS block has not be instantiated
  if ( !isAvailable() ) 
    throw ZeroSuppressionNotAvailable();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
bool
ZeroSuppressionNode::isEnabled() const {
  uhal::ValWord<uint32_t> lEnabled = getNode("csr.ctrl.en").read();
  getClient().dispatch();

  return lEnabled;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
ZeroSuppressionNode::MainState
ZeroSuppressionNode::readMainState() const {
  uhal::ValWord<uint32_t> lStateMain = getNode("csr.stat.state_main").read();
  getClient().dispatch();
  
  // TODO: Add a protection, to catch if nonesense is read from the board
  return static_cast<MainState>(lStateMain.value());
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
ZeroSuppressionNode::FifoTransferState
ZeroSuppressionNode::readFifoTransferState() const {
  uhal::ValWord<uint32_t> lFifoState = getNode("csr.stat.transfer_state").read();
  getClient().dispatch();
  
  // TODO: Add a protection, to catch if nonesense is read from the board
  return static_cast<FifoTransferState>(lFifoState.value()); 
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
ZeroSuppressionNode::OutputState
ZeroSuppressionNode::readOutputState() const {
  uhal::ValWord<uint32_t> lOutputState = getNode("csr.stat.output_state").read();
  getClient().dispatch();
  
  // TODO: Add a protection, to catch if nonesense is read from the board
  return static_cast<OutputState>(lOutputState.value());
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void 
ZeroSuppressionNode::enable(bool aEnable) const {
  // Stop here if the ZS block has not be instantiated
  throwIfNotAvailable();

  getNode("csr.ctrl.en").write(aEnable);
  getClient().dispatch();

}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
std::vector<uint32_t> 
ZeroSuppressionNode::mask2Raw( const ZeroSuppressionMenu::Mask& aMask ) {
  std::vector<uint32_t> lRaw(kBxMaskSize*2);
  for (size_t i(0); i<aMask.data.size(); ++i) {
    lRaw[2*i] = aMask.data[i] & 0x3ffff;
    lRaw[2*i+1] = (aMask.data[i] >> 18) & 0x3fff;
    lRaw[2*i+1] |= (aMask.invert << 17);
  }

  // Bit 35 of the first mask word caries the mask invert information.
  // This means setting bit 17 of the second raw word (hopefully)
  // lRaw[1] |= (aMask.invert << 17);

  return lRaw;

}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
ZeroSuppressionMenu::Mask
ZeroSuppressionNode::raw2Mask( std::vector<uint32_t>::const_iterator aBegin ) {
  ZeroSuppressionMenu::Mask lMask;

  for ( size_t i(0); i<kBxMaskSize; ++i) {
    lMask.data[i] = ( (aBegin[2*i+1] << 18) + aBegin[2*i] ) & 0xffffffff;
  }

  // Retrieve the invert bit from the second word, bit 19 (i.e. bit 35 in fw)
  lMask.invert = (aBegin[1] >> 17 ) & 0x1;

  return lMask;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void 
ZeroSuppressionNode::configureMenu( const ZeroSuppressionMenu& aMenu ) const {

  // Stop here if the ZS block has not be instantiated
  throwIfNotAvailable();

  const uhal::Node& lCsr = getNode("csr");
  const uhal::Node& lRam = getNode("ram");

  if ( aMenu.numCapIds() != kNumCapIds )
    throw CaptureNumberMismatch("The number of CapIds in the menu doesn't match the firmware");

  // This is the expected size of the mask in 32-bit words
  // N.B.: each mask word is split into 2 due to the but to DRAM mapping in firmware.
  size_t lRawMaskSize = kNumCapIds*kBxMaskSize*2;

  // Instantiate a buffer where to write the masks
  std::vector<uint32_t> lRawMaskBuf;

  // Reserve the required space for all masks x2
  lRawMaskBuf.reserve(lRawMaskSize);

  uint32_t lCapIdEnable = 0x0;
  for( uint32_t lCapId(0); lCapId<kNumCapIds; ++lCapId ) {
    const ZeroSuppressionMenu::Mask& lMask = aMenu[lCapId];
    lCapIdEnable |= (lMask.enable << lCapId);

    if ( lMask.data.size() != kBxMaskSize ) {
      // Do something nasty
    }

    std::vector<uint32_t> lRaw( mask2Raw(lMask) );


    // std::cout << lCapId << " mask: " << printhex(lRaw) << std::endl;


    lRawMaskBuf.insert(lRawMaskBuf.end(), lRaw.begin(), lRaw.end());
  }

  if (lRawMaskBuf.size() != lRawMaskSize) {
    std::ostringstream lExc;
    lExc << "Total masks size " << lRawMaskBuf.size() << " differs from expected size " << lRawMaskSize;
    throw MaskSizeError(lExc.str());
  }

  // Set the capture-id enable word
  lCsr.getNode("ctrl.cap_en").write(lCapIdEnable);
  // Set the mode used vor ZS validation
  lCsr.getNode("ctrl.val_mode").write(aMenu.validationMode());
  lCsr.getClient().dispatch();

  // std::cout<<   printhex(lRawMaskBuf) << std::endl;
  // Reset address
  lRam.getNode("addr").write(0);
  // Write the masks
  lRam.getNode("mask_data").writeBlock(lRawMaskBuf);
  // Push it
  lRam.getClient().dispatch();
}

//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
ZeroSuppressionMenu
ZeroSuppressionNode::readMenu() const {
  
  // Stop here if the ZS block has not be instantiated
  throwIfNotAvailable();

  uint32_t lMaskSize = kNumCapIds*kBxMaskSize;

  const uhal::Node& lCsr = getNode("csr");
  const uhal::Node& lRam = getNode("ram");

  uhal::ValWord<uint32_t> lCapEn = lCsr.getNode("ctrl.cap_en").read();
  uhal::ValWord<uint32_t> lValMode = lCsr.getNode("ctrl.val_mode").read();
  getClient().dispatch();

  // Reset address
  lRam.getNode("addr").write(0);
  // Read the block
  uhal::ValVector<uint32_t> lRawMask = lRam.getNode("mask_data").readBlock(lMaskSize*2);
  lRam.getClient().dispatch();
  // std::cout << printhex(lRawMask.value()) << std::endl;

  // std::vector<uint32_t> lMasks  = readRawMasks();

  ZeroSuppressionMenu lMenu;
  lMenu.setValidationMode(lValMode);

  for( uint32_t lCapId(0); lCapId<kNumCapIds; ++lCapId ) {

    //
    ZeroSuppressionMenu::Mask lMask = raw2Mask(next(lRawMask.begin(),lCapId*kBxMaskSize*2));

    // Extract the enable bit
    lMask.enable = ((lCapEn >> lCapId) & 0x1);

    lMenu[lCapId] = lMask;
  }
  
  return lMenu;
}
//-----------------------------------------------------------------------------

} // namespace mp7