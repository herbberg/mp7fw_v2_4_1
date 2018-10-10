#ifndef __MP7_ZEROSUPPRESSIONNODE_HPP__
#define __MP7_ZEROSUPPRESSIONNODE_HPP__ 


#include "uhal/DerivedNode.hpp"
#include "mp7/exception.hpp"

namespace mp7 {

/**
 * @class ZeroSuppressionMenu
 */
class ZeroSuppressionMenu {
public:

  class Mask {
  public:
    Mask();

    bool enable;
    bool invert;
    std::vector<uint32_t> data;
  };

  typedef std::vector<Mask>::iterator iterator;
  typedef std::vector<Mask>::const_iterator const_iterator;

  ZeroSuppressionMenu();
  ~ZeroSuppressionMenu() {};

  size_t numCapIds() const { return mNumCapIds; }

  void setValidationMode(uint32_t aValMode);
  uint32_t validationMode() const;

  Mask& operator[]( uint32_t aCapId );
  const Mask& operator[]( uint32_t aCapId ) const;

  iterator begin() { return mMasks.begin(); }
  const_iterator begin() const { return mMasks.begin(); }
  iterator end() { return mMasks.end(); }
  const_iterator end() const { return mMasks.end(); }

private:
  const size_t mNumCapIds;

  uint32_t mValidationMode;
  std::vector<Mask> mMasks;
  
  friend std::ostream& operator<<( std::ostream& oStream, const ZeroSuppressionMenu& aZSMenu );
};

std::ostream& operator<<( std::ostream& oStream, const ZeroSuppressionMenu& aZSMenu );

/**
 * @class ZeroSuppressionNode
 */
class ZeroSuppressionNode : public uhal::Node {
  UHAL_DERIVEDNODE(ZeroSuppressionNode);

public:
  enum MainState {
    kMainIDLE, kMainHDR, kMainINIT, kMainDATA, kMainDONE
  };

  enum FifoTransferState {
    kFifoIDLE, kFifoBLK, kFifoDONE
  };

  enum OutputState {
    kOutIDLE, kOutHDR, kOutDATA, kOutDONE
  };

  ZeroSuppressionNode(const uhal::Node& aNode);
  virtual ~ZeroSuppressionNode() {}

  bool isAvailable() const;

  bool isEnabled() const;

  MainState readMainState() const;

  FifoTransferState readFifoTransferState() const;
  
  OutputState readOutputState() const;

  void enable(bool aEnable=true) const;

  void configureMenu( const ZeroSuppressionMenu& aMenu ) const;
  ZeroSuppressionMenu readMenu() const;

  // std::vector<uint32_t> readRawMasks() const;
  // void writeRawMasks( const std::vector<uint32_t>& aMask ) const;

  static const uint32_t kNumCapIds;
  static const uint32_t kBxMaskSize;
  
  static std::vector<uint32_t> mask2Raw( const ZeroSuppressionMenu::Mask& aMask );
  static ZeroSuppressionMenu::Mask raw2Mask( std::vector<uint32_t>::const_iterator aBegin );

protected:

  void throwIfNotAvailable() const;
};

}
#endif