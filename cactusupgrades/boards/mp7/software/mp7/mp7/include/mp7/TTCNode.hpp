#ifndef _mp7_TTCNode_hpp_
#define	_mp7_TTCNode_hpp_

// C++ Headers
#include <map>

// MP7 Headers
#include "uhal/DerivedNode.hpp"
#include "mp7/StateHistoryNode.hpp"
#include "mp7/definitions.hpp"

namespace mp7 {

class StateHistoryNode;

class TTCHistoryEntry {
public:
  //uint32_t cyc;
  uint32_t bx;
  uint32_t orbit;
  uint32_t event;
  bool l1a;
  uint32_t cmd;
};

/*!
 * @class TTCNode
 * @brief Derived class to for the TTC control block.
 *
 * ** Signals and resets
 * Here are reset all those signals which have to be synchronous with the ttc.
 * For this reason ~algo_rst~ belongs to TTC and not to the CSR (as other clock40 async resets)

 * - ~ttc_enable~: enables external TTC inputs (from the AMC13)
 * - ~int_bc0_enable~: generate internal BC0 signals

 * ** Frequency measurement
 * Managed within: ~ttc.ttc_freq~
 * Meaning of subnodes
 * - ~chan_sel~: Selection of the clock to measure. Values in the range [0-3] are allowed. When 'single channel' is specified, the frequency measured belongs to the channel selected in the top CSR node.
 *   + 0: Clock 40
 *   + 1: Reference clock [single channel]
 *   + 2: rx clock [single channel]
 *   + 3: tx clock [single channel]

 * @author Alessandro Thea
 * @date August 2013
 */


class TTCNode : public uhal::Node {
  UHAL_DERIVEDNODE(TTCNode)

  // const static uint32_t mBTestCode;
public:
  TTCNode(const uhal::Node& aNode);
  virtual ~TTCNode();

  enum FreqClockChannel {
    kClock40 = 0x0,
    kRefClock = 0x1,
    kTxClock = 0x2,
    kRxClock = 0x3
  };

  struct ConfigParams {
    std::string name;
    std::string clkSrc;
    bool enable;
    bool generateBC0;
    uint32_t phase;
  };

  //! 
  void configure(const ConfigParams& aConfig) const;

  /// Enable the TTC block
  void enable(bool aEnable = true) const;

  /// Enable internal BC0s
  void generateInternalBC0(bool aEnable = true) const;

  ///
  void setPhase(uint32_t aPhase) const;

  /// Clears counters
  void clear() const;

  /// Clears error counters
  void clearErrors() const;

  ///
  void forceL1A() const;
  
  ///
  void forceL1AOnBx( uint32_t aBx ) const;
  
  /// Send BGo
  void forceBCmd(uint32_t aCode) const;

  /// Send BGo
  void forceBCmdOnBx(uint32_t aCode, uint32_t aBx) const;
  
  /// Send test Bgo (Btest)
  void forceBTest() const;
  
  void maskHistoryBC0L1a( bool aMask = 0 /* True masks BC0 */ ) const;
  
  std::vector<TTCHistoryEntry> captureHistory() const;

  /// wait for BC0Lock
  void waitBC0Lock() const;

  /// wait for BC0Lock
  void waitGlobalBC0Lock() const;

  /// Return the locking status of the BC0 signal
  bool readBC0Locked() const;

  /// measurement of clock frequencies
  /**
   * @brief [brief description]
   * @details [long description]
   * 
   * @param aFreqChan [description]
   * @param aCrap [description]
   * 
   * @return [description]
   */
  double measureClockFreq(FreqClockChannel aFreqChan, bool aCrap = false) const;

  /**
   * Generate random triggers internally. 
   * 
   * Controls the interal random trigger generator. 
   * @param aRate Desired trigger rate. Maximum rate = 5 Mhz ( = 40 Mhz/8 )
   */
  void generateRandomL1As( float aRate ) const;

  /**
   * Applies the trigger rules to the internally generated random triggers
   * 
   * @param aEnable true to turn the trigger rules on, false otherwise.
   */
  void enableL1ATrgRules( bool aEnable = true ) const;
  
  /**
   * Enable L1A throttling
   * 
   * @param aEnable throttle L1A generator based on the board TTS state
   */
  void enableL1AThrottling( bool aEnable = true ) const;

  ///
  uint32_t readBunchCounter() const;

  ///
  uint32_t readOrbitCounter() const;

  ///
  uint32_t readEventCounter() const;

  ///
  uint32_t readSingleBitErrorCounter() const;

  ///
  uint32_t readDoubleBitErrorCounter() const;

  ///
  uint32_t readBCmdCounter( TTCBCommand aCommand ) const;

  ///
  std::map<std::string, std::string> report() const;
  
private:
  static const float kClockRate;
  static const std::vector<TTCBCommand> kCtrIndexes;

};

class TTCConfigurator {
public:
  TTCConfigurator(const std::string aFilePath, const std::string& kind, const std::string& aPrefix);
  virtual ~TTCConfigurator();

  void configure(const TTCNode& aTTC);

  const TTCNode::ConfigParams& getConfig();

  static TTCNode::ConfigParams parseFromXML(const std::string& aFilePath);

private:
  TTCNode::ConfigParams mConfig;
  
};
}
#endif	/* _mp7_TTCNode_hpp_ */


