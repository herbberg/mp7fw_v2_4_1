/**
 * @file    AlignMonNode.cpp
 * @author  Alessandro Thea
 * @date    December 2014
 */

#include "mp7/AlignMonNode.hpp"
#include "mp7/exception.hpp"

// C++ Headers
#include <cstdlib>

// MP7 Headers
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/definitions.hpp"
#include "mp7/Orbit.hpp"

// Boost Headers
#include <boost/tuple/tuple_comparison.hpp>

namespace l7 = mp7::logger;

namespace mp7 {
UHAL_REGISTER_DERIVED_NODE(AlignMonNode);

// Constants initialization
const uint32_t AlignMonNode::kErrorThreshold = 1;
 
//---
AlignMonNode::AlignMonNode(const uhal::Node& aNode) : uhal::Node(aNode) {
}


//---
AlignMonNode::~AlignMonNode() {
}

//---
AlignStatus
AlignMonNode::readStatus() const {
  uhal::ValWord<uint32_t> bx = getNode("stat.bx").read();
  uhal::ValWord<uint32_t> cyc = getNode("stat.cyc").read();

  uhal::ValWord<uint32_t> err = getNode("stat.err_cnt").read();
  uhal::ValWord<uint32_t> freeze = getNode("ctrl.freeze").read();
  getClient().dispatch();

  AlignStatus status;
  status.position = orbit::Point(bx,cyc);
  status.errors = err;
  status.frozen = freeze;
  status.marker = not ( status.position.bx == 0xfff or status.position.cycle == 0x7 );
  
  return status;

}

//---
orbit::Point
AlignMonNode::readPosition() const {
  uhal::ValWord<uint32_t> bx = getNode("stat.bx").read();
  uhal::ValWord<uint32_t> cyc = getNode("stat.cyc").read();
  
  getClient().dispatch();
  
  return orbit::Point(bx.value(), cyc.value());
}


//---
uint32_t AlignMonNode::readErrors() const {
  
  uhal::ValWord<uint32_t> err = getNode("stat.err_cnt").read();
  getClient().dispatch();
  
  return (uint32_t)err;
  
}


//---
void
AlignMonNode::reset() const {
  
  // Zero inc and dec first
  getNode("ctrl.del_inc").write(0x0);
  getNode("ctrl.del_dec").write(0x0);
  getNode("ctrl.freeze").write(0x0);
  
  // Reset channel
  getNode("ctrl.del_rst").write(0x1);
  getNode("ctrl.del_rst").write(0x0);

  getClient().dispatch();
}


//---
void AlignMonNode::clear() const {
  // Reset channel
  getNode("ctrl.ctr_rst").write(0x1);
  getNode("ctrl.ctr_rst").write(0x0);

  getClient().dispatch();

}


//---
bool
AlignMonNode::markerDetected() const {
  orbit::Point here = readPosition();
  
  return not ( here.bx == 0xfff or here.cycle == 0x7 );
}


//---
void AlignMonNode::shift(int32_t aTick) const {
  std::string reg;
  if (aTick > 0) {
    reg = "ctrl.del_dec";
  } else if ( aTick < 0 ) {
    reg = "ctrl.del_inc";
    aTick *= -1;
  } else {
    MP7_LOG(l7::kDebug) << "Nothing to do";
    return;
  }

  // Print reg, cycles
  for ( int32_t i(0); i<aTick; ++i)
    getNode(reg).write(0x1);

  getNode(reg).write(0x0);

  // Dispatch here. Error counter cleanup requires a separate dispatch.
  getClient().dispatch();

  // Clear counters before moving on
  getNode("ctrl.ctr_rst").write(0x1);
  getNode("ctrl.ctr_rst").write(0x0);

  getClient().dispatch();


  // uhal::ValWord<uint32_t> err = getNode("stat.err_cnt").read();

  // getClient().dispatch();

  // MP7_LOG(l7::kWarning) << "Errors after shift " << err.value();}
}

//---
int32_t
AlignMonNode::moveTo(const orbit::Point& aPosition, const orbit::Metric& aMetric, uint32_t aTickToCycleRatio ) const {

  
    orbit::Point here = readPosition();
    orbit::Point there(aPosition);
    
    // We're already there. Stop.
    if ( here == there ) return 0;
    
    // Check that there are no errs
    // Will do something smarter if they are later
    // assert(errors()==1);

    MP7_LOG(l7::kDebug1) << "   Going from " << here << " to " << there;

    // Check that there are no errs
    // Will do something smarter if they are later
    uint32_t e = readErrors();
    if ( e > kErrorThreshold ) {
      MP7_LOG(l7::kWarning) << "Errors found before moving " << e;
    }

    // Calculate the distance
    int32_t d = aMetric.distance(there,here);

    
    // Check that d is a multiple of aTickToCycleRatio
    int32_t ticks = d/(int32_t)aTickToCycleRatio;

    MP7_LOG(l7::kDebug1) << "   Distance to go " << d;

    // Shift by n-ticks
    shift(ticks);

    orbit::Point here2 = readPosition();

    MP7_LOG(l7::kDebug1) << "   Reached " << here2;

    // Check that the destination was reached
    if (here2 != there) {
      std::ostringstream oss;
      oss << "Cannot shift alignment to " << there << ". Reached " << here2;
      throw AlignmentShiftFailed(oss.str());
    }

    uint32_t e2 = readErrors();
    if( e2 > e ) {
      MP7_LOG(l7::kDebug) << "Errors increased after moving (was " << e << " now is " << e2 << ")";
    }


    return d;
}


//---
void
AlignMonNode::freeze( bool aFreeze ) const {
  getNode("ctrl.freeze").write(aFreeze);
  getClient().dispatch();
}


// Constants Initialisation
const uint32_t AlignmentFinder::mDepth = 0x80;

AlignmentFinder::AlignmentFinder(const Generics& mGenerics) {
  mClockRatio = mGenerics.clockRatio;
  mOrbitLength = mGenerics.bunchCount;
}

AlignmentFinder::~AlignmentFinder() {

}


//---
int32_t AlignmentFinder::distance(const orbit::Point& a, const orbit::Point& b) const {
  int32_t d = (a.bx - b.bx) * mClockRatio + a.cycle-b.cycle;

  // What happens when the end of the orbit boundary is crossed?
  // The largest distance achievable is 0xdeb.5-0.0. That is expected when the marker crosses the end of the orbit.
  // Also, if end of orbit is in the accessible range of bxs, the distance space will be non contiguous.
  // 
  // h = upper chunk of the orbit
  // l = lower chunk of the orbit
  //
  // A: -depth < d(ha-hb) < depth
  // B: -depth < d(la-lb) < depth
  // C: orbit*ratio-depth > d(ha,lb) > orbit
  // D: -orbit*ratio > d(la,hb) > -(orbit*ratio-depth)
  //
  // The range can be made contigous again by artificially shifting the distance in C & D
  // C: if d > orbit*ratio-depth: d = d-(orbit*ratio)
  // D: if d < -orbit*ratio-depth: d = d+(orbit*ratio)

  int32_t max = (mOrbitLength-1)*mClockRatio;
  int32_t min = max-mDepth;
  // MP7_LOG(l7::kWarning) << d << " " << min << " " <<max;
  if ( d > min ) 
    d -= mOrbitLength*mClockRatio;

  if ( d < -min )
    d += mOrbitLength*mClockRatio;

  // Question: Should I shout if d is outside the expected boundaries?
  return d;
}

//---
orbit::Point
AlignmentFinder::findMinimum(const AlignMonNode& aAlignMon, uint32_t aTickToCycleRatio) {

  // Errors are already here, nothing to do
  if ( aAlignMon.readErrors() > AlignMonNode::kErrorThreshold ) {
    throw AlignmentErrorsDetected("Errors detected before minimizing latency");
  }

  // Take a reading of the current position
  orbit::Point start = aAlignMon.readPosition();

  MP7_LOG(l7::kDebug1) << "   Here we are: " << start  << " (errs=" <<  aAlignMon.readErrors() << ")";


  // Errors are already here, nothing to do
  if ( aAlignMon.readErrors() > AlignMonNode::kErrorThreshold ) 
    throw AlignmentErrorsDetected("Errors detected before minimizing latency");

  // uint32_t s = 0;
  orbit::Point last = aAlignMon.readPosition();
  // First minimize latency until errors are found
  for( uint32_t s=0; s<mDepth; ++s ) {
        // One step forward
        aAlignMon.shift(-1);
        orbit::Point here = aAlignMon.readPosition();


        uint32_t err = aAlignMon.readErrors();
        int32_t dist = distance(here,last);

        MP7_LOG(l7::kDebug1) << "here " << here << " - was " << last << " distance " << dist;


	// Stop if either
	// - Errors appear (pointers clash)
	// - The distance is not -1 (Metric takes into account the jump at the end of the orbit)
        // if ( err > 1 or dist == mDepth-1 /* or here > last */ ) { 
        if ( err > AlignMonNode::kErrorThreshold or dist != -(int32_t)aTickToCycleRatio /* or here > last */ ) { 
            MP7_LOG(l7::kDebug1) << "   Clash found after " << s << " iterations (errs=" << err << " dist=" << dist << ")"; 
            // Take one step back before getting out of the loop
            aAlignMon.shift(2);

            orbit::Point here2 = aAlignMon.readPosition();
            uint32_t errs = aAlignMon.readErrors();
            if ( errs > AlignMonNode::kErrorThreshold ) {
              throw AlignmentErrorsDetected("Errors found after minimizing latency");
            } 
            MP7_LOG(l7::kDebug1) << "   Reached " << here2;

            return here2;
        }

        last = here;
  }
  MP7_LOG(l7::kError) << "No error found?!? " << last;
  // return ( d <= 0 ? -d : depth-d);
  return last;
}


}
