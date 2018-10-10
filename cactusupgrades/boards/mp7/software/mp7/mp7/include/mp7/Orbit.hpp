/**
 * @file    Orbit.hpp
 * @author  Alessandro Thea
 * @date    January 2015
 */


#ifndef __MP7_POINT_HPP__
#define	__MP7_POINT_HPP__

// C++ Headers
#include <stdint.h>
#include <ostream>

// MP7 Headers
#include "mp7/definitions.hpp"

namespace mp7 {

namespace orbit {

/**
 * @class Point
 * 
 * Helper class that represents a location in the orbit, in terms of the local clock.
 */
class Point {
public:
  explicit Point( uint32_t aBx=0, uint32_t aCycle=0);
  
  uint32_t bx;
  uint32_t cycle;

  bool operator==( const Point& aPoint ) const;
  bool operator<( const Point& aPoint ) const;
  bool operator>( const Point& aPoint ) const;
  bool operator!=( const Point& aPoint ) const;
  bool operator<=( const Point& aPoint ) const;
  bool operator>=( const Point& aPoint ) const;
};

std::ostream& operator<<(std::ostream& oStream, const Point& aPoint);

/**
 * @class Metric
 * 
 * Helper class to calculate the relation between Points of the orbit.
 */
class Metric {
  public:
  Metric( const Generics& aGens );
  Metric( uint32_t aBunchCount, uint32_t aClockRatio );
  virtual ~Metric();

  const Point& first() const;
  const Point& last() const;

  
  Point add( const Point& a, const Point& b) const;
  Point addCycles( const Point& aPoint, uint32_t aCycles) const;
  Point addBXs( const Point& aPoint, uint32_t aBXs) const;
  Point sub( const Point& a, const Point& b) const;
  Point subCycles( const Point& aPoint, uint32_t aCycles) const;
  Point subBXs( const Point& aPoint, uint32_t aBXs) const;

  /**
   * Minimum distance between 2 orbit points.
   * 
   * @param a First point
   * @param b Second point
   * 
   * @return Minimum distance between the points,-O/2 < d < O/2
   */
  int32_t distance(const Point& a, const Point& b) const;
  
  uint32_t bunchCount() const;
  
  uint32_t clockRatio() const;
  
  uint32_t bxsToCycles( uint32_t aBxs ) const;

private:

  uint32_t len( const Point& aPoint ) const;
  Point pnt( uint32_t aLen ) const;

  uint32_t mBunchCount;
  uint32_t mClockRatio;

  const Point mFirst;
  const Point mLast;
 
};

extern const Point kOneBx;
extern const Point kOneCycle;

} // namespace orbit

} // namespace mp7

#endif	/* __MP7_POINT_HPP__ */

