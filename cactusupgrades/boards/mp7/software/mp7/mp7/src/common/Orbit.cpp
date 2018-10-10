#include "mp7/Orbit.hpp"

#include <cmath>

// #include <iostream>

namespace mp7 {
namespace orbit {

const Point kOneBx(1);
const Point kOneCycle(0,1);

//---
Point::Point(uint32_t aBx, uint32_t aCycle) :
  bx(aBx),
  cycle(aCycle) {
}

//---
bool
Point::operator==(const Point& aPoint) const {
  return ( this->bx == aPoint.bx and this->cycle == aPoint.cycle );
}

//---
bool
Point::operator<(const Point& aPoint) const {
  if ( this->bx == aPoint.bx)
    return this->cycle < aPoint.cycle;
  else
    return this->bx < aPoint.bx;
}

//---
bool
Point::operator>(const Point& aPoint) const {
  if ( this->bx == aPoint.bx)
    return this->cycle > aPoint.cycle;
  else
    return this->bx > aPoint.bx;
}

//---
bool
Point::operator!=(const Point& aPoint) const {
  return not this->operator==(aPoint);
}


//---
bool
Point::operator<=(const Point& aPoint) const {
  return ( this->operator<(aPoint) or this->operator==(aPoint) );
}


//---
bool
Point::operator>=(const Point& aPoint) const {
  return ( this->operator>(aPoint) or this->operator==(aPoint) );
}


//---
std::ostream&
operator<<(std::ostream& oStream, const Point& aPoint) {
  return (oStream << "(" << aPoint.bx << "," << aPoint.cycle << ")");
}


//---
Metric::Metric(uint32_t aBunchCount, uint32_t aClockRatio ) :
  mBunchCount(aBunchCount),
  mClockRatio(aClockRatio),
  mFirst(0,0),
  mLast(mBunchCount-1, mClockRatio-1) {
}


//---
Metric::Metric(const Generics& aGens) :
  mBunchCount(aGens.bunchCount),
  mClockRatio(aGens.clockRatio),
  mFirst(0,0),
  mLast(mBunchCount-1, mClockRatio-1) {
}


//---
Metric::~Metric() {
}


//---
uint32_t Metric::len(const Point& aPoint) const {
  return aPoint.bx*mClockRatio+aPoint.cycle;
}


//---
Point Metric::pnt(uint32_t aLen) const {
  return Point(aLen / mClockRatio, aLen % mClockRatio);
}



//---
const Point& Metric::first() const {
  return mFirst;
}


//---
const Point& Metric::last() const {
  return mLast;
}


//---
Point Metric::add(const Point& a, const Point& b) const {
  
  Point z = pnt( (len(a) + len(b)) % (mBunchCount*mClockRatio) );
    
  return z;
}


//---
Point Metric::addCycles(const Point& aPoint, uint32_t aCycles ) const {

  Point z = pnt( (len(aPoint) + aCycles) % (mBunchCount*mClockRatio) );

  return z;
}


//---
Point Metric::addBXs(const Point& aPoint, uint32_t aBXs) const {
  
  return addCycles( aPoint, aBXs*mClockRatio);
  
}

//---
Point Metric::sub(const Point& a, const Point& b) const {
  int32_t d = distance(a,b);
  
  int32_t offset = int(floor(d / float(mBunchCount*mClockRatio)));
  
  d -= offset*mBunchCount*mClockRatio;
  
  return pnt( d );

}

//---
Point Metric::subCycles(const Point& aPoint, uint32_t aCycles ) const {
  
  int32_t d = len(aPoint)-aCycles;
  
  int32_t offset = int(floor(d / float(mBunchCount*mClockRatio)));
  
  d -= offset*mBunchCount*mClockRatio;

  return pnt( d );
}


//---
Point Metric::subBXs(const Point& aPoint, uint32_t aBXs ) const {
  return subCycles(aPoint, aBXs*mClockRatio);
}


//---
int32_t
Metric::distance(const Point& a, const Point& b) const {
  int32_t d = len(a)-len(b);
  // What it d > orbitsize or d < -orbitsize?
  // Should there be a protection?

  // Compute the 'other' distance
  int32_t d2 = ( d > 0 ? d-mBunchCount*mClockRatio : d+mBunchCount*mClockRatio);
  
  if ( abs(d) < abs(d2) ) 
    return d;
  else
    return d2;
}


//---
uint32_t Metric::bunchCount() const {
  return mBunchCount;
}


//---
uint32_t Metric::clockRatio() const {
  return mClockRatio;
}


//---
uint32_t Metric::bxsToCycles(uint32_t aBxs) const {
  return aBxs * mClockRatio;
}

}
} // namespace mp7
