/**
 * @file    PathConfigurator.hpp
 * @author  Tom William
 * @date    October 2014
 */


#ifndef __MP7_PATH_CONFIGURATOR_HPP__
#define __MP7_PATH_CONFIGURATOR_HPP__

#include <cstddef>
#include <utility>

#include "mp7/Utilities.hpp"
#include "mp7/Orbit.hpp"
#include "mp7/ChanBufferNode.hpp"

namespace mp7 {

namespace orbit {
class Point;
class Metric;
}

/*!
 * @class PathConfigurator
 * @brief PathConfigurator translates the mode into the buffer mode + data source and applies them to the block 
 *
 * @author Tom Williams
 * @date October 2014
 */

class PathConfigurator {
public:

  enum Mode {
    kLatency,
    kCapture,
    kPlayOnce,
    kPlayLoop,
    kPattern,
    kZeroes,
    kCaptureStrobe,
    kPattern3G,
    kPlayOnceStrobe,
    kPlayOnce3G
  };

  PathConfigurator(uint32_t aBankId, Mode aMode, uint32_t aMaxWords, const orbit::Point& aPoint);

  virtual ~PathConfigurator();

  /*
      
   */
  virtual void configure(const ChanBufferNode& buf) const;

protected:

  PathConfigurator();
  
  static const int32_t kFillBuffer;
  static const int32_t kNoBankId;

  Mode mMode;
  int32_t mMaxWord;
  int32_t mBankId;
  orbit::Point mPoint;

  typedef std::map<Mode, ChanBufferNode::Configuration> ModeMap;

  static const ModeMap mModeMap;
  static ModeMap initMap();

};


/**
 * @class LatencyPathConfigurator
 * @brief Latency mode specific configurator
 */
class LatencyPathConfigurator : public PathConfigurator {
public:
  LatencyPathConfigurator( uint32_t aBank, uint32_t aDepth );
  virtual ~LatencyPathConfigurator();

};

/**
 * @class TestPathConfigurator
 * @brief Latency mode specific configurator
 */
class TestPathConfigurator : public PathConfigurator {
public:
  TestPathConfigurator( Mode aMode, const orbit::Point& aFirstBx, const orbit::Metric& aMetric );
  TestPathConfigurator( Mode aMode, const orbit::Point& aFirstBx, uint32_t aFrames, const orbit::Metric& aMetric );
  TestPathConfigurator( Mode aMode, const orbit::Point& aFirstBx, const orbit::Point& aLast, const orbit::Metric& aMetric );
  virtual ~TestPathConfigurator();

};

} /* namespace mp7 */



#endif /* __MP7_PATH_CONFIGURATOR_HPP__ */



