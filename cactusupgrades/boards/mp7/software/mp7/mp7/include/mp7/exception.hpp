/*
 * File:   exception.h
 * Author: ale
 *
 * Created on August 21, 2013, 2:29 PM
 */

#ifndef __MP7_EXCEPTION_HPP__
#define	__MP7_EXCEPTION_HPP__


#include <exception>
#include <string>
#include <vector>

#define MP7ExceptionImpl(ClassName, ClassDescription)\
public:\
  virtual ~ClassName() throw () {}\
\
  std::string description() const { return std::string(ClassDescription); }


#define MP7ExceptionClass(ClassName, ClassDescription)\
class ClassName : public mp7::exception {\
public:\
  ClassName() : mp7::exception() {}\
  ClassName(const std::string& aString) : mp7::exception(aString) {}\
  MP7ExceptionImpl(ClassName, ClassDescription)\
};


namespace mp7 {

///! MP7 base exception class

class exception : public std::exception {
public:
    exception();
    exception(const std::string& aExc);
    virtual ~exception() throw ();

    const char* what() const throw ();

    void append(const std::string& aExc);

    virtual std::string description() const = 0;

private:
    std::string mInfo;
};


MP7ExceptionClass(MP7HelperException, "Exception class to handle MP7 specific exceptions");

// Generic exceptions
MP7ExceptionClass(ArgumentError,"Exception class to handle argument errors")
MP7ExceptionClass(WrongFileExtension, "File has the wrong file-extension for the class trying to open it");
MP7ExceptionClass(FileNotFound, "File was not found");
MP7ExceptionClass(CorruptedFile, "File was corrupted");
MP7ExceptionClass(InvalidExtension, "Invalid extension");
MP7ExceptionClass(InvalidConfigFile, "Exception class to handle invalid configuration files.")
MP7ExceptionClass(UnmatchedRequirement, "Exception class to handle invalid unmatched configuration requirements.")
MP7ExceptionClass(EntryNotFoundError, "Entry not found");

    
MP7ExceptionClass(IdentificationError, "MP7 board model cannot be detected");

// MMC Exceptions
MP7ExceptionClass(SDCardError, " Exception class to handle errors related to SDCard access");

// Ctrl Exceptions
MP7ExceptionClass(RegionKindError, "Exception class to handle region kind readout errors");
MP7ExceptionClass(Clock40NotInReset, "Exception class to handle cases where the clock source is change without keeping the line in reset");
MP7ExceptionClass(Clock40LockFailed, "Exception class to handle failure of clock 40 locking");
MP7ExceptionClass(XpointConfigTimeout, "Exception class to handle Xpoint configuration timeout");
MP7ExceptionClass(SI5326ConfigurationTimeout, "Exception class to handle si5326 configuration timeout");

// TTC Exceptions
MP7ExceptionClass(BC0LockFailed, "Exception class to handle failure of BC0 lock");
MP7ExceptionClass(TTCFrequencyInvalid, "Exception class to handle TTC invalid frequency readings");
MP7ExceptionClass(TTCPhaseError, "Exception class to handle TTC phase errors");

// Alingment Exceptions
MP7ExceptionClass(AlignmentTimeout, "Exception class to handle alignment timeout errors");
MP7ExceptionClass(AlignmentShiftFailed, "Failure to apply alignment shift");
MP7ExceptionClass(AlignmentErrorsDetected, "Exception class to handle alignment errors");
// MP7ExceptionClass(AlignmentError, "Exception class to handle alignment errors");


// Custom exception for alignment errors
class AlignmentFailed : public mp7::exception {
public:\
  AlignmentFailed() : mp7::exception() {}
  AlignmentFailed(const std::string& aString, const std::vector<uint32_t>& aChannels ) : mp7::exception(aString), mChannels(aChannels) {}

  MP7ExceptionImpl(AlignmentFailed, "Exception class to handle alignment errors");

  const std::vector<uint32_t>& channels() const {return mChannels; }

private:
  std::vector<uint32_t> mChannels;
};

MP7ExceptionClass(FormatterError, "Exception class to handle formatter errors");
MP7ExceptionClass(LinkError, "Exception class to handle link errors (e.g. alignment/CRC errors)")
MP7ExceptionClass(CaptureFailed, "Capture operation failed")

// MGTs Exceptions
MP7ExceptionClass(MGTFSMResetTimeout, "Exception class to handle failure to reset the transciever's FSMs");
MP7ExceptionClass(MGTChannelIdOutOfBounds, "Exception class to out of bounds channel ids");

MP7ExceptionClass(BufferLockFailed, "Exception class to handle failure of Buffer lock");
MP7ExceptionClass(BufferConfigError, "Exception class to handle buffer misconfiguration");
MP7ExceptionClass(BufferSizeExceeded, "Exception class to handle buffer size errors");

MP7ExceptionClass(I2CSlaveNotFound, "Exception class to handle missing I2C slaves");
MP7ExceptionClass(I2CException, "Exception class to handle I2C Exceptions");
MP7ExceptionClass(MinipodChannelNotFound, "Requested MiniPOD channel does not exist");

// Readout exceptions
MP7ExceptionClass(ZeroSuppressionNotAvailable, "Zero Suppression module not implemented");
MP7ExceptionClass(InvalidCaptureId, "Invalid capture id");
MP7ExceptionClass(CaptureNumberMismatch, "Expected number of capture ides doesn't match");
MP7ExceptionClass(MaskSizeError, "Zero suppression Mask size error");
MP7ExceptionClass(ReadoutMenuInconsistentWithFirmware, "Mismatch between readout menu and firmware error");
MP7ExceptionClass(ReadoutMenuConsistencyCheckFailed, "Mismatch between readout menu and firmware error");

        
}


#endif	/* __MP7_EXCEPTION_HPP__ */


