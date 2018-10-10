/*
 * File: mp7/MmcManager.hpp
 * Author: tsw
 *
 * Date: November 2014
 */

#ifndef __MP7_MMCMANAGER_HPP__
#define __MP7_MMCMANAGER_HPP__


#include <string>
#include <vector>

#include "mp7/MmcPipeInterface.hpp"
#include "mp7/Measurement.hpp"


namespace mp7{

  ///! Provides higher-level API for MMC-related control (i.e. board/FPGA reboots, and SD card)
  class MmcManager {
  private:
    MmcManager(const mp7::MmcPipeInterface& aMmcNode);
  public:
    ~MmcManager();

    /**
     * @brief      Issue an MMC Hard reset
     */
    void hardReset();

    /**
     * @brief      Reboot the FPGA to the selected image from the sd card.
     *
     * @param[in]  aSdFilename  A sd filename
     */
    void rebootFPGA(const std::string& aSdFilename);

    void setDummySensorValue(const uint8_t aValue);

    /**
     * @brief      List files on the sd card.
     *
     * @return     List of files on the SD card.
     */
    std::vector<std::string> filesOnSD();

    void copyFileToSD(const std::string& aLocalPath, const std::string& aSdFilename);

    void copyFileFromSD(const std::string& aLocalPath, const std::string& aSdFilename);

    void deleteFileFromSD(const std::string& aSdFilename);

    void replaceGoldenImage(const std::string& aLocalPath);

    std::map<std::string, mp7::Measurement> readSensorInfo();

  private:
    mp7::MmcPipeInterface mMmcNode;

    void unsafeCopyFileToSD(const std::string& aLocalPath, const std::string& aSdFilename);
    void unsafeDeleteFileFromSD(const std::string& aSdFilename);
    
    friend class MP7Controller;
    friend class MmcController;

  };

}

#endif /* __MP7_MMCMANAGER_HPP__ */
