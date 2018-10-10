#include "mp7/python/registrators.hpp"


// Boost Headers
#include <boost/python/def.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/class.hpp>
#include <boost/python/enum.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>
#include <boost/python/operators.hpp>

#include "mp7/I2CMasterNode.hpp"
#include "mp7/MiniPODMasterNode.hpp"
#include "mp7/SI5326Node.hpp"
#include "mp7/SI570Node.hpp"

// Namespace resolution
using namespace boost::python;

namespace pycomp7 {

void register_i2c() {

  // Wrap opencores::I2CMasterNode
  class_<mp7::opencores::I2CBaseNode, bases<uhal::Node> > ("I2CBaseNode", init<const uhal::Node&>())
      .def("getI2CClockPrescale", &mp7::opencores::I2CBaseNode::getI2CClockPrescale)
      .def("readI2C", &mp7::opencores::I2CBaseNode::readI2C)
      .def("writeI2C", &mp7::opencores::I2CBaseNode::writeI2C)
      .def("getSlaves", &mp7::opencores::I2CBaseNode::getSlaves)
      ;

  class_<mp7::opencores::I2CMasterNode, bases<mp7::opencores::I2CBaseNode> > ("I2CMasterNode", init<const uhal::Node&>())
      .def("getSlave", &mp7::opencores::I2CMasterNode::getSlave, return_internal_reference<>())
      ;

  // Wrap opencores::I2CSlave    
  class_<mp7::opencores::I2CSlave, boost::noncopyable>("I2CSlave", no_init)
      .def("getI2CAddress", &mp7::opencores::I2CSlave::getI2CAddress)
      .def("readI2C", &mp7::opencores::I2CSlave::readI2C)
      .def("writeI2C", &mp7::opencores::I2CSlave::readI2C)
      ;

  // Wrap MiniPODMasterNode
  class_<mp7::MiniPODMasterNode, bases<mp7::opencores::I2CBaseNode> > ("MiniPODMasterNode", init<const uhal::Node&>())
      .def("getRxPOD", &mp7::MiniPODMasterNode::getRxPOD, return_internal_reference<>())
      .def("getTxPOD", &mp7::MiniPODMasterNode::getTxPOD, return_internal_reference<>())
      .def("getRxPODs", &mp7::MiniPODMasterNode::getRxPODs)
      .def("getTxPODs", &mp7::MiniPODMasterNode::getTxPODs)
      ;

  // Wrap MiniPODSlave
  class_<mp7::MiniPODSlave, bases<mp7::opencores::I2CSlave>, boost::noncopyable >("MiniPODSlave", no_init)
      .def("readI2C", &mp7::MiniPODSlave::readI2C)
      .def("writeI2C", &mp7::MiniPODSlave::readI2C)
      .def("get3v3", &mp7::MiniPODSlave::get3v3)
      .def("get2v5", &mp7::MiniPODSlave::get2v5)
      .def("getTemp", &mp7::MiniPODSlave::getTemp)
      .def("getOnTime", &mp7::MiniPODSlave::getOnTime)
      .def("getOpticalPower", &mp7::MiniPODSlave::getOpticalPower)
      .def("getOpticalPowers", &mp7::MiniPODSlave::getOpticalPowers)
      .def("setChannelPolarity", &mp7::MiniPODSlave::setChannelPolarity)
      .def("disableChannel", &mp7::MiniPODSlave::disableChannel)
      .def("disableSquelch", &mp7::MiniPODSlave::disableSquelch)
      .def("getAlarmTemp", &mp7::MiniPODSlave::getAlarmTemp)
      .def("getAlarm3v3", &mp7::MiniPODSlave::getAlarm3v3)
      .def("getAlarm2v5", &mp7::MiniPODSlave::getAlarm2v5)
      .def("getAlarmLOS", &mp7::MiniPODSlave::getAlarmLOS)
      .def("getAlarmOpticalPower", &mp7::MiniPODSlave::getAlarmOpticalPower)
      .def("getInfo", &mp7::MiniPODSlave::getInfo)
      ;

  class_<mp7::MiniPODRxSlave, bases<mp7::MiniPODSlave>, boost::noncopyable >("MiniRxPODSlave", no_init);
  class_<mp7::MiniPODTxSlave, bases<mp7::MiniPODSlave>, boost::noncopyable >("MiniTxPODSlave", no_init);

  // Wrap SI570Slave
  class_<mp7::SI570Slave, bases<mp7::opencores::I2CSlave>, boost::noncopyable > ("SI570Slave", no_init)
      .def("configure", &mp7::SI570Slave::configure)
      ;

  // Wrap SI570Node
  class_<mp7::SI570Node, bases<mp7::SI570Slave, mp7::opencores::I2CBaseNode> > ("SI570Node", init<const uhal::Node&>())
      ;

  // Wrap SI5326Slave
  class_<mp7::SI5326Slave, bases<mp7::opencores::I2CSlave>, boost::noncopyable > ("SI5326Slave", no_init)
      .def("configure", &mp7::SI5326Slave::configure)
      .def("reset", &mp7::SI5326Slave::reset)
      .def("intcalib", &mp7::SI5326Slave::intcalib)
      .def("sleep", &mp7::SI5326Slave::sleep)
      .def("debug", &mp7::SI5326Slave::debug)
      .def("registers", &mp7::SI5326Slave::registers)
      ;

  // Wrap SI570Node
  class_<mp7::SI5326Node, bases<mp7::SI5326Slave, mp7::opencores::I2CBaseNode> > ("SI5326Node", init<const uhal::Node&>())
      ;


}
}
