
/*
 *
 * File: mp7/python/src/commmon/exceptions.cpp
 * Author: Tom Williams
 * Date: March 2015
 *  (Largely copy of corresponding file in uHAL Python bindings)
 */

#include "mp7/python/exceptions.hpp"


#include "boost/python/extract.hpp"

#include "mp7/exception.hpp"


using namespace pycomp7;
namespace bpy = boost::python ;


PyObject* pycomp7::create_exception_class(const std::string& aExceptionName, PyObject* aBaseExceptionPyType)
{
  std::string scopeName = bpy::extract<std::string> ( bpy::scope().attr ( "__name__" ) );
  std::string qualifiedExcName = scopeName + "." + aExceptionName;
  PyObject* typeObj = PyErr_NewException ( const_cast<char*> ( qualifiedExcName.c_str() ) , aBaseExceptionPyType, 0 );

  if ( !typeObj )
  {
    bpy::throw_error_already_set();
  }

  bpy::scope().attr ( aExceptionName.c_str() ) = bpy::handle<> ( bpy::borrowed ( typeObj ) );
  return typeObj;
}



void pycomp7::wrap_exceptions() {
    // Base mp7 exception (fallback for derived exceptions not wrapped)
    PyObject* baseExceptionPyType = wrap_exception_class<mp7::exception>("exception", PyExc_Exception);

    // Derived mp7 exceptions
    wrap_exception_class<mp7::MP7HelperException> ("MP7HelperException", baseExceptionPyType);
    wrap_exception_class<mp7::ArgumentError> ("ArgumentError", baseExceptionPyType);
    wrap_exception_class<mp7::AlignmentFailed> ("AlignmentFailed", baseExceptionPyType);
    wrap_exception_class<mp7::AlignmentTimeout> ("AlignmentTimeout", baseExceptionPyType);
    wrap_exception_class<mp7::AlignmentShiftFailed> ("AlignmentShiftFailed", baseExceptionPyType);
    wrap_exception_class<mp7::AlignmentErrorsDetected> ("AlignmentErrorsDetected", baseExceptionPyType);
    wrap_exception_class<mp7::BC0LockFailed> ("BC0LockFailed", baseExceptionPyType);
    wrap_exception_class<mp7::BufferConfigError> ("BufferConfigError", baseExceptionPyType);
    wrap_exception_class<mp7::BufferLockFailed> ("BufferLockFailed", baseExceptionPyType);
    wrap_exception_class<mp7::BufferSizeExceeded> ("BufferSizeExceeded", baseExceptionPyType);
    wrap_exception_class<mp7::Clock40LockFailed> ("Clock40LockFailed", baseExceptionPyType);
    wrap_exception_class<mp7::CaptureFailed> ("CaptureFailed", baseExceptionPyType);
    wrap_exception_class<mp7::Clock40NotInReset> ("Clock40NotInReset", baseExceptionPyType);
    wrap_exception_class<mp7::CorruptedFile> ("CorruptedFile", baseExceptionPyType);
    wrap_exception_class<mp7::FileNotFound> ("FileNotFound", baseExceptionPyType);
    wrap_exception_class<mp7::FormatterError> ("FormatterError", baseExceptionPyType);
    wrap_exception_class<mp7::I2CException> ("I2CException", baseExceptionPyType);
    wrap_exception_class<mp7::I2CSlaveNotFound> ("I2CSlaveNotFound", baseExceptionPyType);
    wrap_exception_class<mp7::IdentificationError> ("IdentificationError", baseExceptionPyType);
    wrap_exception_class<mp7::InvalidConfigFile> ("InvalidConfigFile", baseExceptionPyType);
    wrap_exception_class<mp7::InvalidExtension> ("InvalidExtension", baseExceptionPyType);
    wrap_exception_class<mp7::MGTFSMResetTimeout> ("MGTFSMResetTimeout", baseExceptionPyType);
    wrap_exception_class<mp7::MGTChannelIdOutOfBounds> ("MGTChannelIdOutOfBounds", baseExceptionPyType);
    wrap_exception_class<mp7::SDCardError> ("SDCardError", baseExceptionPyType);
    wrap_exception_class<mp7::SI5326ConfigurationTimeout> ("SI5326ConfigurationTimeout", baseExceptionPyType);
    wrap_exception_class<mp7::TTCFrequencyInvalid> ("TTCFrequencyInvalid", baseExceptionPyType);
    wrap_exception_class<mp7::UnmatchedRequirement> ("XpointConfigTimeout", baseExceptionPyType);
    wrap_exception_class<mp7::WrongFileExtension> ("WrongFileExtension", baseExceptionPyType);
    wrap_exception_class<mp7::XpointConfigTimeout> ("XpointConfigTimeout", baseExceptionPyType);
    wrap_exception_class<mp7::ZeroSuppressionNotAvailable> ("ZeroSuppressionNotAvailable", baseExceptionPyType);
    wrap_exception_class<mp7::ReadoutMenuInconsistentWithFirmware> ("ReadoutMenuInconsistentWithFirmware", baseExceptionPyType);
    wrap_exception_class<mp7::ReadoutMenuConsistencyCheckFailed> ("ReadoutMenuConsistencyCheckFailed", baseExceptionPyType);
}

