#include "mp7/ReadoutMenu.hpp"

#include "mp7/exception.hpp"
#include "mp7/Utilities.hpp"

namespace mp7 {

//-----------------------------------------------------------------------------
ReadoutMenu::ReadoutMenu(size_t aNBanks, size_t aNModes, size_t aNCaptures) :
  mNumBanks(aNBanks),
  mNumModes(aNModes), 
  mNumCaptures(aNCaptures),
  mBanks(aNBanks) {

    for( uint32_t i(0); i<mNumModes; ++i)
      mModes.emplace_back( Mode(mNumCaptures) );
  }


//-----------------------------------------------------------------------------
ReadoutMenu::~ReadoutMenu() {
}


//-----------------------------------------------------------------------------
size_t
ReadoutMenu::numBanks() const {
  return mNumBanks;
}


//-----------------------------------------------------------------------------
size_t
ReadoutMenu::numModes() const {
  return mNumModes;
}


//-----------------------------------------------------------------------------
size_t
ReadoutMenu::numCaptures() const {
  return mNumCaptures;
}

ReadoutMenu::Bank& 
ReadoutMenu::bank(size_t i) {
  return mBanks.at(i);
}


const ReadoutMenu::Bank& 
ReadoutMenu::bank(size_t i) const {
  return const_cast<ReadoutMenu*>(this)->bank(i);
}


//-----------------------------------------------------------------------------
ReadoutMenu::Mode&
ReadoutMenu::mode(size_t aMode) {
  return mModes.at(aMode);
}


//-----------------------------------------------------------------------------
const ReadoutMenu::Mode&
ReadoutMenu::mode(size_t aMode) const {
  return const_cast<ReadoutMenu*>(this)->mode(aMode);
}


//-----------------------------------------------------------------------------
void 
ReadoutMenu::setMode(uint32_t aMode, const Mode& aOther) {
  Mode& m = mModes.at(aMode);
  if ( m.size() != aOther.size() ) {
    throw ReadoutMenuInconsistentWithFirmware("ReadoutMenu::Mode size mismatch!");
  }
  m = aOther;
}


//-----------------------------------------------------------------------------
ReadoutMenu::Mode::Mode(size_t aSize) : 
  eventSize(0x0),
  eventToTrigger(0x0),
  eventType(0x0),
  // tokenDelay(0x0),
  mCaptures(aSize) {
}


//-----------------------------------------------------------------------------
void
ReadoutMenu::Mode::operator=(const ReadoutMenu::Mode& aOther) {
  if (size() != aOther.size()) {
    throw ReadoutMenuInconsistentWithFirmware("ReadoutMenu::Mode assignment error: size mismatch");
  }
  
  eventSize = aOther.eventSize;
  eventToTrigger = aOther.eventToTrigger;
  eventType = aOther.eventType;
  mCaptures = aOther.mCaptures;
}


//-----------------------------------------------------------------------------
ReadoutMenu::Capture&
ReadoutMenu::Mode::operator[]( size_t i ) {
  return mCaptures.at(i);
}


//-----------------------------------------------------------------------------
const ReadoutMenu::Capture&
ReadoutMenu::Mode::operator[]( size_t i ) const {
  return const_cast<ReadoutMenu::Mode*>(this)->operator [](i);
}


//-----------------------------------------------------------------------------
size_t
ReadoutMenu::Mode::size() const {
  return mCaptures.size();
}


//-----------------------------------------------------------------------------
ReadoutMenu::Capture&
ReadoutMenu::capture(size_t aMode, size_t aCapture) {
//  return mCaptures.at(aTrgMode * mNumCaptures + aCapMode);
  return this->mode(aMode)[aCapture];
}


//-----------------------------------------------------------------------------
const ReadoutMenu::Capture&
ReadoutMenu::capture(size_t aTrgMode, size_t aCapMode) const {
  return const_cast<ReadoutMenu*>(this)->capture(aTrgMode, aCapMode);
}


//-----------------------------------------------------------------------------
std::ostream& operator<<( std::ostream& oStream, const ReadoutMenu::Bank& aBank ) {
  auto fmt = oStream.flags();
  oStream << std::showbase
          << "{wordsPerBx: " << aBank.wordsPerBx << "}";
  oStream.flags(fmt);
  return oStream;
}


//-----------------------------------------------------------------------------
std::ostream& operator<<( std::ostream& oStream, const ReadoutMenu::Mode& aMode ) {
  auto fmt = oStream.flags();
  oStream << std::showbase
          << "{eventSize: " << aMode.eventSize 
          << ", eventToTrigger: " << aMode.eventToTrigger
          << ", eventType: " << std::hex << aMode.eventType
          // << ", tokenDelay: " << aMode.tokenDelay
          << "}";
  oStream.flags(fmt);
  return oStream;
}


//-----------------------------------------------------------------------------
std::ostream& operator<<( std::ostream& oStream, const ReadoutMenu::Capture& aCapture ) {
  auto fmt = oStream.flags();
  oStream << std::showbase
          << "{enable: " << aCapture.enable
          << ", captureId: " << std::hex << aCapture.id
          << ", bankId: " << aCapture.bankId 
          << ", length: " << aCapture.length
          << ", delay: " << aCapture.delay 
          << ", readoutLength: " << aCapture.readoutLength
          << "}";
  oStream.flags(fmt);
  return oStream;
}


//-----------------------------------------------------------------------------
std::ostream& operator<<( std::ostream& oStream, const ReadoutMenu& aMenu ) {

  for( uint32_t iB(0); iB < aMenu.numBanks(); ++iB) {
    oStream << "bank " << iB << ": " << aMenu.bank(iB) << "\n";

  }

  for( uint32_t iM(0); iM < aMenu.numModes(); ++iM) {
    oStream << "mode " << iM << ": " << aMenu.mode(iM) << "\n";

    for (uint32_t iC(0); iC < aMenu.numCaptures(); iC++) {
        oStream << "  capture " << iC <<": " << aMenu.capture(iM,iC) << "\n";
    }
  }
  return oStream;
}

//-----------------------------------------------------------------------------
ReadoutMenuValidator::ReadoutMenuValidator( const ReadoutMenu& aMenu ) :
  mMenu(aMenu) {

}

//-----------------------------------------------------------------------------
void ReadoutMenuValidator::verify() const {

  // For each trigger more, capture modes must be enabled sequentially. If c
  // captures out of C are enabled, they have to be capture modes 0 to c-1.
  // Enabled capture modes cannot be preceded by disabled capture modes.
  std::ostringstream lErrors;

  for (uint32_t iM(0); iM < mMenu.numModes(); iM++) {
    bool anyDisabled = false;
    std::vector<uint32_t> lInvalidCaptures;
    for (uint32_t iC(0); iC < mMenu.numCaptures(); iC++) {
      const ReadoutMenu::Capture& c = mMenu.capture(iM, iC);

      // Track presence of disabled captures 
      anyDisabled |= !c.enable;

      // Flag the current mode as faulty, if the current capture is enabled and
      // is preceded by disabled captures
      if ( c.enable && anyDisabled )
        lInvalidCaptures.push_back(iC);

      // std::cout << iC << " | " <<  anyDisabled << " | " << lInvalidCaptures.size() << " | " << c << std::endl;
    }

    if ( !lInvalidCaptures.empty() ) {

      lErrors << "Mode " << iM << ": captures " << join(lInvalidCaptures);
      // std::cout << "msg: " << lErrors.str() << std::endl;
    }
  }

  // std::cout << "lErrors '" << lErrors.str() << "'" << std::endl;
  // std::cout << "is empty " << lErrors.str().empty() << std::endl;

  if ( !lErrors.str().empty() ) {
    // This is likely going to be the least understandable and most exotic exception message 
    throw ReadoutMenuConsistencyCheckFailed("Menu consistency check failed. Capture modes are enabled but preceded by a disabled capture modes." + lErrors.str());
  }

}

} // namespace mp7