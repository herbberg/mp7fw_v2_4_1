#ifndef __MP7_MMCPIPEINTERFACE_HPP__
#define __MP7_MMCPIPEINTERFACE_HPP__


#include <string>

#include "uhal/DerivedNode.hpp"

#include "mp7/exception.hpp"
#include "mp7/Firmware.hpp"



namespace mp7
{
  MP7ExceptionClass ( TextExceedsSpaceAvailable , "Text exceeds space available for it in the MMC" );
  MP7ExceptionClass ( ReplyIndicatesError , "Reply value from MMC indicates an error" );
  MP7ExceptionClass ( GoldenImageIsInvolateError , "An attempt was made to modify the inviolate boot image" );
}

namespace mp7
{

  //FIXME: Fill in doxygen tags for MmcPipeInterfaceNode class, and its methods
  //TODO: Update method & member data names to match convention
  //TODO: Review whether methods used in MP7Controller can be made const, so that don't have to const_cast in MP7controller constructor
  /*!
   * @class MmcPipeInterfaceNode
   * @brief
   *
   * To fill
   *
   * @author Andrew Rose
   * @date February 2014
   */

  class MmcPipeInterface : public uhal::Node
  {
      UHAL_DERIVEDNODE ( MmcPipeInterface );
    public:

      // PUBLIC METHODS
      MmcPipeInterface ( const uhal::Node& ) ;
      virtual ~MmcPipeInterface();

    public:
      void SetDummySensor ( const uint8_t& aValue );

      void FileToSD ( const std::string& aFilename, Firmware& aFirmware );
      XilinxBitStream FileFromSD ( const std::string& aFilename );

      void RebootFPGA ( const std::string& aFilename , const std::string& aPassword );
      void BoardHardReset ( const std::string& aPassword );
      void DeleteFromSD ( const std::string& aFilename , const std::string& aPassword );

      std::vector< std::string > ListFilesOnSD ( );
      std::string GetTextSpace ( );
      std::vector<float> ReadSensorData ( );

    public:
      void UpdateCounters();

      const uint16_t& FPGAtoMMCDataAvailable();
      const uint16_t& FPGAtoMMCSpaceAvailable();
      const uint16_t& MMCtoFPGADataAvailable();
      const uint16_t& MMCtoFPGASpaceAvailable();

    private:
      void Send ( const uint32_t& aHeader );
      void Send ( const uint32_t& aHeader , const uint32_t& aSizeInWords , const uint32_t* aPayload );
      void Send ( const uint32_t& aHeader , const uint32_t& aSizeInBytes , const char* aPayload );

      std::vector< uint32_t > Receive ( );

      std::string ConvertString ( std::vector< uint32_t >::const_iterator aStart , const std::vector< uint32_t >::const_iterator& aEnd );

    private:
      void SetTextSpace ( const std::string& aStr );
      void EnterSecureMode ( const std::string& aPassword );

    private:
      uint16_t mFPGAtoMMCDataAvailable;
      uint16_t mFPGAtoMMCSpaceAvailable;
      uint16_t mMMCtoFPGADataAvailable;
      uint16_t mMMCtoFPGASpaceAvailable;

      static const uint32_t kPipeMaxTries;
      static const uint32_t kPipeSleep;

      struct DMAPipeCommands {
        static const uint32_t kEnterSecureMode;
        static const uint32_t kSetTextSpace   ;
        static const uint32_t kSetDummySensor ;
        static const uint32_t kFileFromSD     ;
        static const uint32_t kFileToSD       ;
        static const uint32_t kRebootFPGA     ;
        static const uint32_t kDeleteFromSD   ;
        static const uint32_t kListFilesOnSD  ;
        static const uint32_t kNuclearReset   ;
        static const uint32_t kGetTextSpace   ;
        static const uint32_t kHotswapReset   ;
        static const uint32_t kGetSensorData  ;
        
      };
  };

}

#endif  /* __MP7_MMCPIPEINTERFACE_HPP__ */


