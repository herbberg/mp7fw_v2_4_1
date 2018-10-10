#include "mp7/python/registrators.hpp"

// Boost Headers
#include <boost/python/def.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/class.hpp>
#include <boost/python/enum.hpp>
#include <boost/python/copy_const_reference.hpp>
#include "boost/python/suite/indexing/vector_indexing_suite.hpp"


// MP7 Headers
#include "mp7/MmcController.hpp"
#include "mp7/MmcPipeInterface.hpp"
#include "mp7/Firmware.hpp"

// Namespace resolution
using namespace boost::python;

void
pycomp7::register_mmc() {

  class_<mp7::MmcController, boost::noncopyable >("MmcController", init<const uhal::HwInterface&>())
      .def("id", &mp7::MmcController::id)
      .def("hardReset", &mp7::MmcController::hardReset)
      .def("rebootFPGA", &mp7::MmcController::rebootFPGA)
      .def("setDummySensorValue", &mp7::MmcController::setDummySensorValue)
      .def("filesOnSD", &mp7::MmcController::filesOnSD)
      .def("copyFileToSD", &mp7::MmcController::copyFileToSD)
      .def("copyFileFromSD", &mp7::MmcController::copyFileFromSD)
      .def("deleteFileFromSD", &mp7::MmcController::deleteFileFromSD)
      .def("replaceGoldenImage", &mp7::MmcController::replaceGoldenImage)
      ;



  //Wrap MmcpipeInterface
  class_<mp7::MmcPipeInterface, bases<uhal::Node> > ("MmcPipeInterface", init<const uhal::Node&>())
      .def("SetDummySensor", &mp7::MmcPipeInterface::SetDummySensor)
      .def("FileToSD", &mp7::MmcPipeInterface::FileToSD)
      .def("FileFromSD", &mp7::MmcPipeInterface::FileFromSD)
      .def("RebootFPGA", &mp7::MmcPipeInterface::RebootFPGA)
      .def("BoardHardReset", &mp7::MmcPipeInterface::BoardHardReset)
      .def("DeleteFromSD", &mp7::MmcPipeInterface::DeleteFromSD)
      .def("ListFilesOnSD", &mp7::MmcPipeInterface::ListFilesOnSD)
      .def("GetTextSpace", &mp7::MmcPipeInterface::GetTextSpace)
      .def("ReadSensorData", &mp7::MmcPipeInterface::ReadSensorData)
      .def("UpdateCounters", &mp7::MmcPipeInterface::UpdateCounters)
      .def("FPGAtoMMCDataAvailable", &mp7::MmcPipeInterface::FPGAtoMMCDataAvailable, return_value_policy<copy_const_reference>())
      .def("FPGAtoMMCSpaceAvailable", &mp7::MmcPipeInterface::FPGAtoMMCSpaceAvailable, return_value_policy<copy_const_reference>())
      .def("MMCtoFPGADataAvailable", &mp7::MmcPipeInterface::MMCtoFPGADataAvailable, return_value_policy<copy_const_reference>())
      .def("MMCtoFPGASpaceAvailable", &mp7::MmcPipeInterface::MMCtoFPGASpaceAvailable, return_value_policy<copy_const_reference>())
      ;

  //Vector indexing for uint8_t
  class_<std::vector<uint8_t> >("vec_uint8_t")
      .def(vector_indexing_suite< std::vector<uint8_t> >())
      ;

  //Wrap Firmware
  class_<mp7::Firmware> ("Firmware", init<const std::string&>())
      .def("Bitstream", &mp7::Firmware::Bitstream, return_value_policy<copy_const_reference>())
      .def("FileName", &mp7::Firmware::FileName, return_value_policy<copy_const_reference>())
      .def("isBitSwapped", &mp7::Firmware::isBitSwapped, return_value_policy<copy_const_reference>())
      .def("BitSwap", &mp7::Firmware::BitSwap)
      ;


  //Wrap Xilinx stuff
  class_<mp7::XilinxBitStream, bases<mp7::Firmware> > ("XilinxBitStream")
      .def("BigEndianAppend", &mp7::XilinxBitStream::BigEndianAppend)
      ;
  class_<mp7::XilinxBitFile, bases<mp7::Firmware> > ("XilinxBitFile", init<const std::string&>())
      .def("DesignName", &mp7::XilinxBitFile::DesignName, return_value_policy<copy_const_reference>())
      .def("DeviceName", &mp7::XilinxBitFile::DeviceName, return_value_policy<copy_const_reference>())
      .def("TimeStamp", &mp7::XilinxBitFile::TimeStamp, return_value_policy<copy_const_reference>())
      .def("StandardizedFileName", &mp7::XilinxBitFile::StandardizedFileName)
      ;
  class_<mp7::XilinxBinFile, bases<mp7::Firmware> > ("XilinxBinFile", init<const std::string&>())
      ;
}
