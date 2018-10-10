
#include "mp7/MmcManager.hpp"

#include <fstream>

#include "boost/filesystem.hpp"
#include <boost/assign/std/vector.hpp>
#include <boost/assign/list_inserter.hpp>

#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/Firmware.hpp"

namespace l7 = mp7::logger;

namespace mp7 {
//---
MmcManager::MmcManager(const mp7::MmcPipeInterface& aMmcNode) :
  mMmcNode(aMmcNode) {
}


//---
MmcManager::~MmcManager() {
}


//---
void MmcManager::hardReset() {
  MP7_LOG(l7::kInfo) << "MP7 board is being rebooted";
  mMmcNode.BoardHardReset("RuleBritannia");
}


//---
void MmcManager::rebootFPGA(const std::string& aSdFilename) {
  mMmcNode.RebootFPGA(aSdFilename, "RuleBritannia");
  mp7::millisleep(3000);

  std::string textSpace = mMmcNode.GetTextSpace();
  if (textSpace == aSdFilename) {
    MP7_LOG(l7::kInfo) << "FPGA has rebooted with firmware image " << aSdFilename;
  } else
    MP7_LOG(l7::kWarning) << "FPGA failed to boot with image '" << aSdFilename << "'. Rebooted to 'GoldenImage.bin'";
}


//---
void MmcManager::setDummySensorValue(const uint8_t aValue) {
  mMmcNode.SetDummySensor(aValue);
}


//---
std::vector<std::string> MmcManager::filesOnSD() {
  return mMmcNode.ListFilesOnSD();
}


//-----------------------------------------------------------------------------
void MmcManager::copyFileToSD(const std::string& aLocalPath, const std::string& aSdFilename) {

  std::string lExtSd = boost::filesystem::path(aSdFilename).extension().c_str();
  if (aSdFilename.size() > 31) {
    mp7::SDCardError e("'" + aSdFilename + "' exceeds the maximum number of characters allowed for SD card filenames.");
    MP7_LOG(l7::kError) << e.what();
    throw e;
  } else if (lExtSd != ".bin" ) {
    mp7::SDCardError e("File extension "+lExtSd+" not allowed. SD Card files must have .bin extension");
    MP7_LOG(l7::kError) << e.what();
    throw e;
  } else if (aSdFilename == "GoldenImage.bin") {
    mp7::SDCardError e("MmcManager cannot upload MP7 firmware image 'GoldenImage.bin'");
    MP7_LOG(l7::kError) << e.what();
    throw e;
  }

  unsafeCopyFileToSD(aLocalPath, aSdFilename);
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void MmcManager::unsafeCopyFileToSD(const std::string& aLocalPath, const std::string& aSdFilename) {

  MP7_LOG(l7::kInfo) << "Uploading file '" << aLocalPath << "' to SD card (SD filename '" << aSdFilename << "')";

  std::string ext = boost::filesystem::path(aLocalPath).extension().c_str();
  if (ext == ".bin") {
    mp7::XilinxBinFile firmware(aLocalPath);
    MP7_LOG(l7::kInfo) << firmware;
    mMmcNode.FileToSD(aSdFilename, firmware);
  } else if (ext == ".bit") {
    mp7::XilinxBitFile firmware(aLocalPath);
    MP7_LOG(l7::kInfo) << firmware;
    mMmcNode.FileToSD(aSdFilename, firmware);
  } else {
    mp7::InvalidExtension e("Local file path '" + aLocalPath + "' has invalid extension (must be '.bin' or '.bit')");
    MP7_LOG(l7::kError) << e.what();
    throw e;
  }
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void MmcManager::copyFileFromSD(const std::string& aLocalPath, const std::string& aSdFilename) {

  MP7_LOG(l7::kInfo) << "Copying SD card file '" << aSdFilename << "' to local path '" << aLocalPath << "'";

  mp7::XilinxBitStream firmware = mMmcNode.FileFromSD(aSdFilename);

  MP7_LOG(l7::kDebug) << "Creating local file '" << aLocalPath << "'";

  //TODO: Create directory if it doesn't exist already.

  std::ofstream localFile(aLocalPath, std::ios::binary);
  const std::vector<uint8_t>& bitstream(firmware.Bitstream());
  localFile.write((char*) (&bitstream.front()), bitstream.size());
  localFile.close();

  MP7_LOG(l7::kInfo) << "Finished downloading bitstream '" << aSdFilename << "' to local path: " << aLocalPath;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void MmcManager::deleteFileFromSD(const std::string& aSdFilename) {
  if (aSdFilename == "GoldenImage.bin") {
    mp7::SDCardError e("MmcManager cannot delete MP7 firmware image 'GoldenImage.bin'");
    MP7_LOG(l7::kError) << e.what();
    throw e;
  }
  unsafeDeleteFileFromSD(aSdFilename);
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void MmcManager::unsafeDeleteFileFromSD(const std::string& aSdFilename) {
  MP7_LOG(l7::kInfo) << "Deleting file '" << aSdFilename << "' from SD Card)";

  mMmcNode.DeleteFromSD(aSdFilename, "RuleBritannia");
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
void MmcManager::replaceGoldenImage(const std::string& aLocalPath) {

  unsafeDeleteFileFromSD("GoldenImage.bin");

  unsafeCopyFileToSD(aLocalPath, "GoldenImage.bin");

}
//-----------------------------------------------------------------------------


//---

//-----------------------------------------------------------------------------
std::map<std::string, mp7::Measurement> MmcManager::readSensorInfo() {

  std::map<std::string, mp7::Measurement> sensorInfo;
  std::vector<float> sensData = mMmcNode.ReadSensorData();
  MP7_LOG(l7::kInfo) << "Retrieved sensor info from MMC successfully. Displaying now...";

  std::vector<std::string> sensNames = {"Imperial MP7", "MP7 HS\t", "Humidity\t", "FPGA Temp", "+1.0 V\t", "+1.0 I\t",
    "+1.5 V\t", "+1.5 I\t", "+1.8 V\t", "+1.8 I\t", "+2.5 V\t", "+2.5 I\t", "+3.3 V\t", "+3.3 I\t", "MP+3.3 V\t", "MP+3.3 I\t",
    "+12 V\t", "+12 I\t", "+1.0 V GTX T", "+1.0 I GTX T", "+1.2 V GTX T", "+1.2 I GTX T",
    "+1.8 V GTX T", "+1.8 I GTX T", "+1.0 V GTX B", "+1.0 I GTX B", "+1.2 V GTX B",
    "+1.2 I GTX B", "+1.8 V GTX B", "+1.8 I GTX B"};
  std::vector<std::string> sensUnits = {"", "", "", "C", "V", "A", "V", "A", "V", "A", "V", "A", "V", "A", "V", "A",
    "V", "A", "V", "A", "V", "A", "V", "A", "V", "A", "V", "A", "V", "A"};


  for (uint i = 0; i < sensData.size(); ++i) {
    boost::assign::insert(sensorInfo)
        (sensNames[i], mp7::Measurement(sensData[i], sensUnits[i]));
  }

  return sensorInfo;
}
//-----------------------------------------------------------------------------

} // namespace mp7