/**
 * @file    AlignmentNode.hpp
 * @author  Alessandro Thea
 * @date    December 2014
 */

#ifndef __MP7_ALIGNMONNODE_HPP__
#define	__MP7_ALIGNMONNODE_HPP__

// Boost Headers
#include <boost/tuple/tuple.hpp>

// uHAL Headers
#include "uhal/DerivedNode.hpp"

// MP7 Header
#include "mp7/Orbit.hpp"

namespace mp7 {

struct Generics;

struct AlignStatus {
  orbit::Point position;
  uint32_t errors;
  bool marker;
  bool frozen;
};

/**
 * @class AlignMonNode
 * @brief Specialized node to control link alignment mechanism
 */
    
class AlignMonNode : public uhal::Node {
  UHAL_DERIVEDNODE( AlignMonNode );
public:
  
  static const uint32_t kErrorThreshold;
  
  // Position, 0 = bx, 1 = cycle
  // typedef boost::tuple<uint32_t, uint32_t> Point;
  
  AlignMonNode( const uhal::Node& aNode );
  
  virtual ~AlignMonNode();
  
  /**
   * Reads the status of the selected channel
   * @return 
   */
  AlignStatus readStatus() const;
  
  /**
   * Current position in the orbit
   * @return Returns a Point corresponding to the current position
   */
  orbit::Point readPosition() const;
  
  
  /**
   * Number of errors detected at the current position
   * @return Number of errors.
   */
  uint32_t readErrors() const;

  /**
   * Resets read pointer position and error counters.
   */
  void reset() const;
  
  /**
   * Clear error counters
   */
  void clear() const;
  
  /**
   * 
   * @return True if the alignment marker is present 
   */
  bool markerDetected() const;
  
  /**
   * Move the input buffer delay by x cycles
   * @param aCycles
   */
  void shift( int32_t aTicks ) const;

  /**
   * Move the marker to a given point in the orbit.
   * Needs to know the clock ratio
   * @param aPosition Requested alignment marker position
   * @param aClockRatio Clock ratio as defined by board generics
   * @return Distance between initial an final positions.
   */
  int32_t moveTo( const orbit::Point& aPosition, const orbit::Metric& aMetric, uint32_t aTickToCycleRatio=1 ) const;
  
  void freeze( bool aFreeze = true ) const;

private:

  // int32_t jump( int32_t aDistance, const orbit::Point& aLast ) const;
  
//  void smartScan() const;

};

class AlignmentFinder {

public:
  AlignmentFinder( const Generics& mGenerics );
  ~AlignmentFinder();
  
  /**
   * Find the minimum latency point using the bisection algorithm.
   * @return Distance between initial an final positions.
   */
  orbit::Point findMinimum( const AlignMonNode& aAlignMon, uint32_t aTickToCycleRatio=1 );
  
private:
  static const uint32_t mDepth;

public:
  int32_t distance( const orbit::Point& a, const orbit::Point& b ) const;

private:

  uint32_t mClockRatio;
  uint32_t mOrbitLength;
  
};

} // namespace mp7

#endif	/* __MP7_ALIGNMONNODE_HPP__ */

