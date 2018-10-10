/* 
 * File:   ReadoutControlNode.hpp
 * Author: ale
 *
 * Created on May 18, 2015, 1:37 PM
 */

#ifndef __MP7_READOUTCONTROLNODE_HPP__
#define	__MP7_READOUTCONTROLNODE_HPP__

#include "uhal/DerivedNode.hpp"
#include "mp7/exception.hpp"
#include "mp7/ReadoutMenu.hpp"


namespace mp7 {

/**
 * @class ReadoutCtrlNode
 */
class ReadoutCtrlNode : public uhal::Node {
  UHAL_DERIVEDNODE(ReadoutCtrlNode);

public:
  
  /**
   * @brief      Default constructor
   *
   * @param[in]  aNode  Raw uhal::Node
   */
  ReadoutCtrlNode(const uhal::Node& aNode);

  virtual ~ReadoutCtrlNode();

  /**
   * @brief      Reads number banks.
   *
   * @return     { description_of_the_return_value }
   */
  uint32_t readNumBanks() const;

  /**
   * @brief      Reads back the number modes instantiated in firmware.
   *
   * @return     Number of trigger mode blocks in firmware.
   */
  uint32_t readNumModes() const;
  
  /**
   * @brief      Reads back the number captures instantiated in firmware.
   *
   * @return     Number of capture mode blocks in firmware.
   */
  uint32_t readNumCaptures() const;
  
  /**
   * @brief      Select a specific bank id.
   *
   * @param[in]  aBank  Bank id to select.
   */
  void selectBank( uint32_t aBank ) const;
  
  /**
   * @brief      Select a specific trigger mode.
   *
   * @param[in]  aMode  Trigger mode to select.
   */
  void selectMode( uint32_t aMode ) const;
  
  /**
   * @brief      Select a specific capture mode.
   *
   * @param[in]  aCapture  Capture mode to select.
   */
  void selectCapture( uint32_t aCapture ) const;
    
  /**
   * @brief      Reset the readout control configuration.
   */
  void reset() const;
  
  /**
   * @brief      Uploads a readout configuration into the readout block.
   *
   * @param[in]  aMenu  The readout menu.
   */
  void configureMenu( const ReadoutMenu& aMenu ) const;

  /**
   * @brief      Reads the readout menu configuration from hardware.
   *
   * @return     ReadoutMenu object containing the current configuration.
   */
  ReadoutMenu readMenu() const;
  
  /**
   * Set the Readout derandomisers watermarks
   *
   * The values are in some units I still have to figure out. 64 = 100%
   *
   * @param      aLowWM   Derandomiser low water mark in some strange units
   * @param      aHighWM  Derandomiser high water mark in some strange units
   */
  void setDerandWaterMarks( uint32_t aLowWM, uint32_t aHighWM ) const;

private:

};



} // namespace mp7

#endif	/* __MP7_READOUTCONTROLNODE_HPP__ */

