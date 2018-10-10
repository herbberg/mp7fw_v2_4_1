/**
 * @file    PathConfigurator.cpp
 * @author  Alessandro Thea
 * @date    2014
 */

#include "mp7/PathConfigurator.hpp"

#include "mp7/exception.hpp"
#include "mp7/Orbit.hpp"
#include "mp7/ChanBufferNode.hpp"

namespace mp7 {

const int32_t PathConfigurator::kFillBuffer = -1;
const int32_t PathConfigurator::kNoBankId = -1;

const PathConfigurator::ModeMap PathConfigurator::mModeMap = PathConfigurator::initMap();


//---
PathConfigurator::ModeMap PathConfigurator::initMap() {
  ModeMap map;
  //                          mode                       data                          cap_stb_mask  pb_stb_en   pb_stb_gen  pb_stb_patt  pb_invalid
  // map[kLatency]        = { ChanBufferNode::kLatency,  ChanBufferNode::kInputData,   0x1,          0x0,        0x0,        0x0,         0x0 };
  // map[kCapture]        = { ChanBufferNode::kCapture,  ChanBufferNode::kInputData,   0x0,          0x0,        0x0,        0x0,         0x0 };
  // map[kPlayOnce]       = { ChanBufferNode::kPlayOnce, ChanBufferNode::kBufferData,  0x0,          0x0,        0x0,        0x0,         0x0 };
  // map[kPlayLoop]       = { ChanBufferNode::kPlayLoop, ChanBufferNode::kBufferData,  0x0,          0x0,        0x0,        0x0,         0x0 };
  // map[kPattern]        = { ChanBufferNode::kPlayOnce, ChanBufferNode::kPatternData, 0x0,          0x0,        0x0,        0x0,         0x0 };
  // map[kZeroes]         = { ChanBufferNode::kPlayOnce, ChanBufferNode::kZeroData,  0x0,          0x0,        0x0,        0x0,         0x0 };
  // map[kCaptureStrobe]  = { ChanBufferNode::kCapture,  ChanBufferNode::kInputData,   0x1,          0x0,        0x0,        0x0,         0x0 };
  // map[kPlayOnceStrobe] = { ChanBufferNode::kPlayOnce, ChanBufferNode::kBufferData,  0x0,          0x1,        0x0,        0x0,         0x0 };
  // map[kPattern3G]      = { ChanBufferNode::kPlayOnce, ChanBufferNode::kPatternData, 0x0,          0x1,        0x1,        0x9,         0x0 };
  // map[kPlayOnce3G]     = { ChanBufferNode::kPlayOnce, ChanBufferNode::kBufferData,  0x0,          0x1,        0x1,        0x9,         0x0 };

  //                       mode                       data                          strobe                          patt_valid_disable  cap_stb_ovrride  pb_stb_patt
  map[kLatency]        = { ChanBufferNode::kLatency,  ChanBufferNode::kInputData,   ChanBufferNode::kInputStrobe,    0x0,           0x1,             0x0 };
  map[kCapture]        = { ChanBufferNode::kCapture,  ChanBufferNode::kInputData,   ChanBufferNode::kInputStrobe,    0x0,           0x0,             0x0};
  map[kPlayOnce]       = { ChanBufferNode::kPlayOnce, ChanBufferNode::kBufferData,  ChanBufferNode::kOverrideStrobe, 0x0,           0x0,             0x0};
  map[kPlayLoop]       = { ChanBufferNode::kPlayLoop, ChanBufferNode::kBufferData,  ChanBufferNode::kOverrideStrobe, 0x0,           0x0,             0x0};
  map[kPattern]        = { ChanBufferNode::kPlayOnce, ChanBufferNode::kPatternData, ChanBufferNode::kOverrideStrobe, 0x0,           0x0,             0x0};
  map[kZeroes]         = { ChanBufferNode::kPlayOnce, ChanBufferNode::kZeroData,    ChanBufferNode::kOverrideStrobe, 0x0,           0x0,             0x0};
  map[kCaptureStrobe]  = { ChanBufferNode::kCapture,  ChanBufferNode::kInputData,   ChanBufferNode::kInputStrobe,    0x0,           0x0,             0x0};
  map[kPlayOnceStrobe] = { ChanBufferNode::kPlayOnce, ChanBufferNode::kBufferData,  ChanBufferNode::kBufferStrobe,   0x0,           0x1,             0x0};
  map[kPattern3G]      = { ChanBufferNode::kPlayOnce, ChanBufferNode::kPatternData, ChanBufferNode::kPatternStrobe,  0x0,           0x0,             0x9};
  map[kPlayOnce3G]     = { ChanBufferNode::kPlayOnce, ChanBufferNode::kBufferData,  ChanBufferNode::kPatternStrobe,  0x0,           0x0,             0x9};
  return map;
}


PathConfigurator::PathConfigurator() :
  mMode(kLatency),
  mMaxWord(0x0),
  mBankId(0x0) {

}

//---
PathConfigurator::PathConfigurator( uint32_t aBankId, Mode aMode, uint32_t aMaxWords, const orbit::Point& aPoint) : 
  mMode(aMode),
  mMaxWord(aMaxWords),
  mBankId(aBankId),
  mPoint(aPoint) { 
}


//---
PathConfigurator::~PathConfigurator() {
}


//---
void
PathConfigurator::configure(const mp7::ChanBufferNode& buf) const {

  const ChanBufferNode::Configuration& cfg = (mModeMap.find(mMode)->second);

  // if mMaxWords is kFillBuffer use all the buffer
  uint32_t maxWord = ( mMaxWord != kFillBuffer ? mMaxWord : buf.getBufferSize()-1);
  uint32_t bankid = ( mBankId != kNoBankId ? mBankId : 0x0 );

  // Apply configuration
  buf.configure(cfg);
  buf.writeDAQBank(bankid);
  buf.writeMaxWord(maxWord);
  buf.writeTrigPoint(mPoint);
}


//--- 
LatencyPathConfigurator::LatencyPathConfigurator(uint32_t aBankId, uint32_t aDepth) {
  
  if ( aDepth == 0 ) {
    throw BufferConfigError("0-length Latency buffer not allowed");
  }

  mBankId = aBankId;
  mMode = kLatency;
  mMaxWord = aDepth - 1;
}


//---
LatencyPathConfigurator::~LatencyPathConfigurator() {
}


//---
TestPathConfigurator::TestPathConfigurator( Mode aMode, const orbit::Point& aFirstBx, uint32_t aFrames, const orbit::Metric& aMetric )  {
  
  if ( aFrames == 0 ) {
    throw BufferConfigError("0-length capture/pattern/playback not allowed");
  }

  mBankId  = kNoBankId;
  mMode = aMode;
  mMaxWord = aFrames - 1;

  // In order for the desired action to take place at 
  // the exact desired time, subtract 2 clock cycles
  mPoint  = aMetric.subCycles(aFirstBx,2);

}


//---
TestPathConfigurator::TestPathConfigurator( Mode aMode, const orbit::Point& aFirstBx, const orbit::Metric& aMetric )  {

  mBankId  =  kNoBankId;
  mMode    =  aMode; 
  mMaxWord =  kFillBuffer; 
  // In order for the desired action to take place at 
  // the exact desired time, subtract 2 clock cycles
  mPoint  =  aMetric.subCycles(aFirstBx,2);

}


//---
TestPathConfigurator::TestPathConfigurator( Mode aMode, const orbit::Point& aFirstBx, const orbit::Point& aLast, const orbit::Metric& aMetric ) {
  
  int32_t d = aMetric.distance(aLast,aFirstBx);
  if (d <= 0) {
    std::ostringstream oss;
    oss << "Invalid capture/playback bx range, " << aFirstBx << "-" << aLast << " : End of the range must be greater than start";
    throw BufferConfigError(oss.str());
  }
  
    mBankId  = kNoBankId;
    mMode    = aMode;
    mMaxWord = d-1;
  // In order for the desired action to take place at 
  // the exact desired time, subtract 2 clock cycles
    mPoint  = aMetric.subCycles(aFirstBx,2);

}

//---
TestPathConfigurator::~TestPathConfigurator() {
}



} // namespace mp7
