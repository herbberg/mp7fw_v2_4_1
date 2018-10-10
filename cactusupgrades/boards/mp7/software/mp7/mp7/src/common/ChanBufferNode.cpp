/* 
 * File:   BufferNode.cpp
 * Author: ale
 * 
 * Created on May 5, 2014, 11:04 AM
 */

#include "mp7/ChanBufferNode.hpp"


// C++ Headers
#include <algorithm>

// MP7 Headers
#include "mp7/exception.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/Orbit.hpp"

// Namespace resolution
using namespace std;
namespace l7 = mp7::logger;

namespace mp7 {

UHAL_REGISTER_DERIVED_NODE(ChanBufferNode);


//---
ChanBufferNode::ChanBufferNode(const uhal::Node& aNode) :
  uhal::Node(aNode),
  mSize(aNode.getNode("buffer.data").getSize() / 2) {

}


//---
ChanBufferNode::~ChanBufferNode() {
}


//---
size_t
ChanBufferNode::getBufferSize() const {
//    return mSize;
    return getNode("buffer.data").getSize() / 2;

}


//---
ChanBufferNode::BufMode
ChanBufferNode::readBufferMode() const {
    uhal::ValWord< uint32_t > mode = getNode("csr.mode.mode").read();
    getClient().dispatch();

    return (ChanBufferNode::BufMode)mode.value();
}


//---
ChanBufferNode::DataSrc
ChanBufferNode::readDataSrc() const {
    uhal::ValWord< uint32_t > src = getNode("csr.mode.datasrc").read();
    getClient().dispatch();

    return static_cast<ChanBufferNode::DataSrc>(src.value());
}


//---
ChanBufferNode::StrobeSrc
ChanBufferNode::readStrobeSrc() const {
    uhal::ValWord< uint32_t > src = getNode("csr.mode.stbsrc").read();
    getClient().dispatch();

    return static_cast<ChanBufferNode::StrobeSrc>(src.value());
}


//---
void
ChanBufferNode::waitCaptureDone() const {
    uhal::ValWord< uint32_t > cap_done(0);
    int countdown = 100;

    while (countdown > 0) {
        cap_done = getNode("csr.stat.cap_done").read();
        getClient().dispatch();

        if (cap_done.value()) break;

        millisleep(1);
        countdown--;

    }

    if (countdown == 0) {
        throw CaptureFailed("timed out waiting for buffer capture done signal");
    }

}


//---
bool 
ChanBufferNode::hasCaptured() const {
    uhal::ValWord< uint32_t > cap_done = getNode("csr.stat.cap_done").read();
    getClient().dispatch();
    return cap_done.value();
}


//---
void
ChanBufferNode::configure( const Configuration& aConfig ) const {

    // Set buffer mode
    getNode("csr.mode.mode").write(aConfig.mode);
    
    // Set datasrc
    getNode("csr.mode.datasrc").write(aConfig.datasrc);
    
    // Set strobe source
    getNode("csr.mode.stbsrc").write(aConfig.stbsrc);

    // Disable valid bit when in Pattern/Zero mode
    getNode("csr.mode.patt_valid_disable").write(aConfig.patternValidMask);

    // Make the Pattern/Zero invalid
    getNode("csr.mode.cap_stb_mask").write(aConfig.captureStrobeOverride);

    // Strobe pattern to apply to patterns
    getNode("csr.mode.stb_patt").write(aConfig.strobePattern);

    getClient().dispatch();
}


//---
ChanBufferNode::Configuration
ChanBufferNode::readConfiguration() const {
  Configuration cfg;
  Snapshot s = snapshot(getNode("csr"));
  

  cfg.mode = static_cast<BufMode>(s.at( "mode.mode") );
  cfg.datasrc = static_cast<DataSrc>(s.at( "mode.datasrc") );
  cfg.stbsrc = static_cast<StrobeSrc>(s.at( "mode.stbsrc") );
  cfg.patternValidMask = s.at( "mode.patt_valid_disable") ;
  cfg.captureStrobeOverride = s.at( "mode.cap_stb_mask") ;
  cfg.strobePattern = s.at( "mode.stb_patt") ;
    
  return cfg;
}


//---
uint32_t
ChanBufferNode::readDAQBank() const {
    uhal::ValWord<uint32_t> bank =  getNode("csr.mode.daq_bank").read();
    getClient().dispatch();

    return bank;
}

//---
uint32_t
ChanBufferNode::readMaxWord() const {
    uhal::ValWord<uint32_t> bank =  getNode("csr.mode.max_word").read();
    getClient().dispatch();

    return bank;
}

//---
void 
ChanBufferNode::writeDAQBank(uint32_t aBank) const {
    getNode("csr.mode.daq_bank").write(aBank);
    getClient().dispatch();
}

//---
void
ChanBufferNode::writeTrigPoint( const orbit::Point& aTrigPoint) const {
    getNode("csr.range.trig_bx").write(aTrigPoint.bx);
    getNode("csr.range.trig_cyc").write(aTrigPoint.cycle);

    getClient().dispatch();

}

//---
void
ChanBufferNode::writeMaxWord(uint32_t aMaxWord) const {
    getNode("csr.range.max_word").write(aMaxWord);
    getClient().dispatch();
}

//---
void
ChanBufferNode::writeRaw(std::vector<uint32_t> aRawData) const {
    // set the write pointer to 0
    getNode("buffer.addr").write(0x0);
    // Upload data into the buffer
    getNode("buffer.data").writeBlock(aRawData);
    getClient().dispatch();
}


//---
std::vector<uint32_t>
ChanBufferNode::readRaw(size_t aSize) const {
    // Set the port pointer to 0
    getNode("buffer.addr").write(0x0);
    // Block read from the data register
    uhal::ValVector< uint32_t > valid_data = getNode("buffer.data").readBlock(aSize);
    getClient().dispatch();
    return valid_data.value();
}


//---
void
ChanBufferNode::clear() const {
    vector<uint32_t> zeroes(mSize * 2, 0x0);
    writeRaw(zeroes);
}


//---
void ChanBufferNode::upload(const LinkData& aData) const {
    if (aData.size() > mSize) {
        mp7::BufferSizeExceeded lExc("Data to upload bigger than buffersize");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }
    
    size_t size = aData.size();
    // Prepare the data to write to the port ram
    vector<uint32_t> rawData(size * 2);
    
    for (size_t i(0); i < size; ++i) {
        
        const Frame& f = aData.at(i);
        
        // Even address: 16 LSB bits
        rawData[2 * i] = f.data & 0xffff;
        // Odd address: 1 strobe + 1 valid + 16 MSB.
        rawData[2 * i + 1] = 
                ((uint64_t)f.strobe << 17) +
                ((uint64_t)f.valid << 16 ) +
                ((f.data >> 16) & 0xffff);
    }

    writeRaw(rawData);
}


//---
LinkData ChanBufferNode::download(size_t aSize) const {
    if (aSize > mSize) {
        mp7::BufferSizeExceeded lExc("Data to download bigger than buffersize");
        MP7_LOG(l7::kError) << lExc.what();
        throw lExc;
    }

    vector<uint32_t> rawData = readRaw(aSize * 2);
    LinkData data(aSize);

    for (size_t i(0); i < data.size(); ++i) {
        
        // 17 bit, 2nd word - strobe
        data[i].strobe = (rawData[2 * i + 1] >> 17) & 0x1;
        // 16 bit, 2nd word - valid
        data[i].valid  = (rawData[2 * i + 1] >> 16) & 0x1;
        // 15-0 bits, 2nd word + 15-0 1st word
        data[i].data   = ( (rawData[2 * i + 1] & 0xffff) << 16 ) + (rawData[2 * i] & 0xffff);
    }

    return data;
}


} // namespace mp7

