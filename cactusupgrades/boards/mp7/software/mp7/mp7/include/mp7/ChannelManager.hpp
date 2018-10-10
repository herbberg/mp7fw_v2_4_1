/**
 * @file    ChannelManager.cpp
 * @author  Alessandro Thea
 * @brief   Brief description
 * @date    December 2014
 */


#ifndef __MP7_CHANNELMANAGER_HPP__
#define	__MP7_CHANNELMANAGER_HPP__

// C++ Headers
#include <stdint.h>
#include <vector>

// Boost Headers
#include <boost/optional.hpp>
 
// MP7 Headers
#include "mp7/definitions.hpp"
#include "mp7/BoardData.hpp"
#include "mp7/DatapathDescriptor.hpp"
#include "mp7/ChanBufferNode.hpp"
#include "mp7/Measurement.hpp"
#include "mp7/AlignMonNode.hpp"
#include "mp7/MGTRegionNode.hpp"
#include "mp7/ReadoutCtrlNode.hpp"

namespace mp7 {

// Forward declaration
class MP7MiniController;
class PathConfigurator;

class ChannelManager {
private:
  ChannelManager(const MP7MiniController& aController );
  ChannelManager(const MP7MiniController& aController, const std::vector<uint32_t> aChannels );
public:
  typedef std::map<uint32_t, orbit::Point> PointMap_t;

  virtual ~ChannelManager();
  
  /**
   * Datapath descriptor getter
   * @return const reference to the DatapathDescriptor used
   */
  const DatapathDescriptor& getDescriptor() const;

  /**
   * Reads the status of selected Rx channels.
   * @return 
   */
  std::map<uint32_t, RxChannelStatus> readRxStatus() const;

  /**
   * Reads the status of selected Tx channels.
   * @return 
   */
  std::map<uint32_t, TxChannelStatus> readTxStatus() const;

  /**
   * Reads the alignment status of selected channels.
   * @return 
   */
  std::map<uint32_t, AlignStatus> readAlignmentStatus() const;

  /**
   * Human-readable report of MGT clock readings
   * 
   * @param aCrap Clock measuremente precision. Performs a low precision measurement if true.
   * @return Map of clock measurements
   */
  std::map<std::string, mp7::Measurement> refClkReport(bool aCrap = false);

  /**
   * Link reset.
   * 
   * Resets Rx and Tx links. The links 
   */
  void resetMGTs() const;
  
  /**
   * Clears crc, error and alignment counters on all links
   * @details [long description]
   */
  void clearRxCounters() const;

  /**
   * Configures the MP7 buffers for Tx->Rx pattern
   */
  void setupTx2RxPattern();

  /**
   * Configures tx buffers with 3G pattern
   */
  void setupTx2Rx3GPattern();

  /**
   * Configures tx buffers with orbittag pattern
   */
  void setupTx2RxOrbitPattern();
  
  /**
   * Configure Rx channels
   * 
   * @param aInvPolarity Enable loopback mode
   * @param aOrbittag Enable orbittag mode
   * @param aInvPolarity Inverts channel polarity
   */
  void configureRxMGTs(bool aInvPolarity, bool aOrbittag) const;

    /**
   * Configure Rx channels

   * @details [long description]
   * 
   * @param aInvPolarity Enable loopback mode
   */
  void configureTxMGTs(bool aInvPolarity, bool aLoop) const;

  /**
   * Test MGTs for CRC and alignment errors.
   */
  void checkMGTs();

  
  
  /**
   * Resets link alignment to poweron values
   */  
  void resetAlignment() const;
  
  /**
   */
  PointMap_t findMinimaAlignmentPoints() const;
  
  /**
   * Minimise aligns inputs by minimizing the latency
   * 
   * @param aMargin 
   */
  orbit::Point minimizeAndAlign(uint32_t aMargin = 3) const;
  
  
  orbit::Point minimizeAndAlign( const std::map<uint32_t, uint32_t>& aDelays, uint32_t aMargin = 3) const;
  
  /**
   * Align input channels to a specific point in the orbit
   * 
   * @param aPoint
   */
  void align( const orbit::Point& aPoint ) const;
  
  /**
   * Align rx channels to a point in the orbit with per-channel offsets
   * 
   * @param aPoint Target link alignment point
   * @param aDelays Map of delays
   */
  void align( const orbit::Point& aPoint, const std::map<uint32_t, uint32_t>& aDelays ) const;
  

  /**
   * Locks alignment monitor to the current alignment marker position
   * 
   * @param aFreeze Desired freezing status: true - frozen, false - free
   */
  void freezeAlignment( bool aFreeze=true ) const;

  /**
   * 
   * @return
   */
  std::map<uint32_t, orbit::Point> readAlignmentPoints() const;
  
  void checkAlignment() const;
  
//   /**
//    * 
//    * @param strip
//    * @param insert
//    */
   virtual void configureHdrFormatters( FormatterKind aFmtKind, uint32_t aStrip,  uint32_t aInsert );

   virtual void configureDVFormatters( const orbit::Point& aStart, const orbit::Point& aStop);

   virtual void disableDVFormatters();
   /**
    * 
    * @param aKind Buffer kind, can be kRxBuffer or kTxBuffer.
    * @param aConfigurator
    */
   void configureBuffers( RxTxSelector aSelection, const PathConfigurator& aConfigurator ) const;

  /*!
   * Clears Rx/Tx buffers
   *
   * @param aKind  Buffer kind to clear
   */
  void clearBuffers(mp7::RxTxSelector aSelection) const;
  
  /**
   * Clears Rx/Tx buffers of a specific kind and in a specific mode.
   * 
   * @param aKind Buffer kind, can be kRxBuffer or kTxBuffer.
   * @param aMode Mode of the buffers to be cleared.
   */

  void clearBuffers(mp7::RxTxSelector aSelection, ChanBufferNode::BufMode aMode) const;

  /**
   * Read the buffer content onto a BoardData object.
   * 
   * @param aKind Buffer kind, can be kRxBuffer or kTxBuffer.
   * @return Content of the buffers.
   */

  mp7::BoardData readBuffers(mp7::RxTxSelector aSelection) const;

  /**
   * Load BoardData pattern into the buffers.
   * 
   * @param aKind Buffer kind, can be kRxBuffer or kTxBuffer.
   * @param aData Data to load in the buffer.
   */
  void loadPatterns(mp7::RxTxSelector aKind, const mp7::BoardData& aData) const;

  /**
   * Waits for capture done signal high on all buffers in capture mode
   * 
   */
  void waitCaptureDone() const;

  /**
   * @brief [brief description]
   * @details [long description]
   * @return [description]
   */
  std::map<uint32_t, uint32_t> readBankSummary() const;

  std::map<uint32_t, uint32_t> readBankDetails( RxTxSelector aSelection ) const;


  
  ChannelGroup pickBufferIDs( RxTxSelector aSelection ) const;
 
  ChannelGroup pickMGTIDs() const;

  ChannelGroup pickMGTIDs( RxTxSelector aSelection ) const;

  
private:
  
  //! Reference to the MP7 controller
  const MP7MiniController& mController;

  //!
  const DatapathDescriptor mDescriptor;

  friend class MP7MiniController;


};

} //namespace mp7

#endif	/* __MP7_CHANNELMANAGER_HPP__ */

