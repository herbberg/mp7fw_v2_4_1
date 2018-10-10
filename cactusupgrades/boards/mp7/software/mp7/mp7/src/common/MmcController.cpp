#include "mp7/MmcController.hpp"

#include "mp7/MmcManager.hpp"
// #include <fstream>

// #include "boost/filesystem.hpp"
// #include <boost/assign/std/vector.hpp>
// #include <boost/assign/list_inserter.hpp>

// #include "mp7/Logger.hpp"
// #include "mp7/Utilities.hpp"

// namespace l7 = mp7::logger;

namespace mp7 {

//-----------------------------------------------------------------------------
MmcController::MmcController(const uhal::HwInterface& aHw) :
  noncopyable(),
  mHw(aHw),
  mMmcNode(mHw.getNode<mp7::MmcPipeInterface>("uc") ){
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
MmcController::~MmcController() {
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
std::string
MmcController::id() const {
  return mHw.id(); 
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
MmcController::hardReset() {
  // MP7_LOG(l7::kInfo) << "MP7 board is being rebooted";
  // mMmcNode.BoardHardReset("RuleBritannia");
  MmcManager mgr(mMmcNode);

  mgr.hardReset(); 
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
MmcController::rebootFPGA(const std::string& aSdFilename) {
  // mMmcNode.RebootFPGA(aSdFilename, "RuleBritannia");
  // mp7::millisleep(3000);

  // std::string textSpace = mMmcNode.GetTextSpace();
  // if (textSpace == aSdFilename)
  //   MP7_LOG(l7::kInfo) << "FPGA has rebooted with firmware image " << aSdFilename;
  // else
  //   MP7_LOG(l7::kWarning) << "FPGA failed to boot with image \"" << aSdFilename << "\". Rebooted with GoldenImage.bin";
  MmcManager mgr(mMmcNode);

  mgr.rebootFPGA(aSdFilename); 
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
MmcController::setDummySensorValue(const uint8_t aValue) {
  // mMmcNode.SetDummySensor(aValue);

  MmcManager mgr(mMmcNode);

  mgr.setDummySensorValue(aValue);
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
std::vector<std::string>
MmcController::filesOnSD() {

  MmcManager mgr(mMmcNode);

  return mgr.filesOnSD();
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
MmcController::copyFileToSD(const std::string& aLocalPath, const std::string& aSdFilename) {

  MmcManager mgr(mMmcNode);

  mgr.copyFileToSD(aLocalPath, aSdFilename);
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
MmcController::copyFileFromSD(const std::string& aLocalPath, const std::string& aSdFilename) {

  MmcManager mgr(mMmcNode);

  mgr.copyFileFromSD(aLocalPath,aSdFilename);
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void
MmcController::deleteFileFromSD(const std::string& aSdFilename) {

  
  MmcManager mgr(mMmcNode);

  mgr.deleteFileFromSD(aSdFilename);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
void
MmcController::replaceGoldenImage(const std::string& aSdFilename) {
  MmcManager mgr(mMmcNode);

  mgr.replaceGoldenImage(aSdFilename);
}
//-----------------------------------------------------------------------------

} // namespace mp7
