/* 
 * File:   MMCController.hpp
 * Author: ale
 *
 * Created on April 22, 2015, 11:33 AM
 */

#ifndef __MP7_MMCCONTROLLER_HPP__
#define	__MP7_MMCCONTROLLER_HPP__

// Boost Headers
#include <boost/noncopyable.hpp>

// Uhal Headers
#include "uhal/HwInterface.hpp"

// MP7 Headers
#include "mp7/MmcPipeInterface.hpp"

namespace mp7 {

class MmcController : public boost::noncopyable {
public:

  /**
   * @brief      Constructor
   *
   * @param[in]  aHw   Hardware Interface object
   */
  MmcController( const uhal::HwInterface& aHw );

  /**
   * @brief      Destroys the object.
   */
  virtual ~MmcController();

  /**
   * Controller identifier
   *
   * @return     Board id
   */
  std::string id() const;

  /**
   * @brief      Issue an MMC Hard Reset
   */
  void hardReset();

  /**
   * @brief      Reboots the FPGA to the choosen image name
   *
   * @param[in]  aSdFilename  Name of the image on the SD card
   */
  void rebootFPGA(const std::string& aSdFilename);
  
  /**
   * @brief      Sets the dummy sensor value.
   *
   * @param[in]  aValue  A value
   */
  void setDummySensorValue(const uint8_t aValue);
  
  /**
   * @brief      List the files present on the SD card.
   *
   * @return     List of image files.
   */
  std::vector<std::string> filesOnSD();
  
  /**
   * @brief      Copy an image file to the SD card.
   *
   * @param[in]  aLocalPath   Path to the source image file
   * @param[in]  aSdFilename  Name of the image on the SD card
   */
  void copyFileToSD(const std::string& aLocalPath, const std::string& aSdFilename);
  
  /**
   * @brief     Copy an image file from the SD card.
   *
   * @param[in]  aLocalPath   Path to the destination image file
   * @param[in]  aSdFilename  Name of the image on the SD card
   */
  void copyFileFromSD(const std::string& aLocalPath, const std::string& aSdFilename);
  
  /**
   * @brief      Delete image from the SD card
   *
   * @param[in]  aSdFilename  Name of the image on the SD card
   */
  void deleteFileFromSD(const std::string& aSdFilename);
  
  /**
   * @brief      Replace the GoldenImage.bin file on the SD card.
   *
   * @param[in]  aLocalPath  Path to the source image file
   */
  void replaceGoldenImage(const std::string& aLocalPath);

private:
    //! IPBus interface to the MP7 board
    uhal::HwInterface mHw;
    mp7::MmcPipeInterface mMmcNode;

    
    
};

} // namespace mp7

#endif	/* __MP7_MMCCONTROLLER_HPP__ */

