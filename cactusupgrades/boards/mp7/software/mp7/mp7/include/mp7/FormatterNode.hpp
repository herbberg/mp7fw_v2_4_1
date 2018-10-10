/**
 * @file    AlignmentNode.cpp
 * @author  Alessandro Thea
 * @date    January 2015
 */

#ifndef __MP7_FORMATTERNODE_HPP__
#define	__MP7_FORMATTERNODE_HPP__

#include "uhal/DerivedNode.hpp"


namespace mp7 {

// Forward declaration
namespace orbit {
  class Point;
}

class FormatterNode : public uhal::Node {
    UHAL_DERIVEDNODE( FormatterNode );
public:
  FormatterNode(const uhal::Node& aNode );
  virtual ~FormatterNode();
  
  void stripInsert( bool aStrip, bool aInsert ) const;

  /**
   * @brief [brief description]
   * @details [long description]    
   * 
   * @param aStart Data valid starting point. It must be set to 1 bx before the target one.
   * @param aStop Data valid starting point. It must be set to 1 bx before the target one.
   */
  void overrideValid( const orbit::Point& aStart, const orbit::Point& aStop ) const;

  void enableValidOverride( bool aEnable ) const;

  /**
   * Select what BX to tag as BC0 in S1 formatters.
   * 
   * @param aBx Bx when to tag BC0. IT must be ser 2 bx ahead of the desidered one.
   */
  void tagBC0( const orbit::Point& aBx ) const;

  /**
   * Enables/Disable BC0 tag for S1 formatters
   * 
   * @param aEnable [description]
   */
  void enableBC0Tag( bool aEnable ) const;
  
private:

};

} // namespace mp7

#endif	/* __MP7_FORMATTERNODE_HPP__ */

