// Boost Headers
#include <boost/python/module.hpp>
#include <boost/python/def.hpp>
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/enum.hpp>
#include <boost/python/operators.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <boost/python/overloads.hpp>
//#include <boost/python.hpp>

// C++ Headers
#include "map"

// uHal Headers
#include "uhal/uhal.hpp"

// MP7 Headers

#include "mp7/CtrlNode.hpp"

#include "mp7/StateHistoryNode.hpp"

#include "mp7/CommandSequence.hpp"
#include "mp7/PPRamNode.hpp"
#include "mp7/AlignMonNode.hpp"
#include "mp7/Measurement.hpp"

#include "mp7/Logger.hpp"

// Custom Python Headers
#include "mp7/python/converters.hpp"
#include "mp7/python/exceptions.hpp"
#include "mp7/python/registrators.hpp"


using namespace boost::python;

//BOOST_PYTHON_MEMBER_FUNCTION_OVERLOADS(mp7_AlignmentNode_align_overloads, align, 0, 1)


// *** N.B: The argument of this BOOST_PYTHON_MODULE macro MUST be the same as the name of the library created, i.e. if creating library file my_py_binds_module.so , imported in python as:
//                import my_py_binds_module
//          then would have to put
//                BOOST_PYTHON_MODULE(my_py_binds_module)
//          Otherwise, will get the error message "ImportError: dynamic module does not define init function (initmy_py_binds_module)
BOOST_PYTHON_MODULE(_pycomp7) {

  // CONVERTERS
  pycomp7::register_converters();

  // EXCEPTIONS
  pycomp7::wrap_exceptions();

  // REGISTRATORS
  pycomp7::register_enums();

  pycomp7::register_data();

  pycomp7::register_controller();

  pycomp7::register_ctrl();

  pycomp7::register_ttc();

  pycomp7::register_i2c();

  pycomp7::register_clocking();
  
  pycomp7::register_ro();

  pycomp7::register_datapath();

  pycomp7::register_mmc();

  enum_<mp7::logger::LogLevel> ("LogLevel")
      .value("kDebug1", mp7::logger::kDebug1)
      .value("kDebug", mp7::logger::kDebug)
      .value("kInfo", mp7::logger::kInfo)
      .value("kNotice", mp7::logger::kNotice)
      .value("kWarning", mp7::logger::kWarning)
      .value("kError", mp7::logger::kError)
      .export_values()
      ;

  def("setLogThreshold", &mp7::logger::Log::setLogThreshold);


  // Wrap Measurement
  class_<mp7::Measurement> ("Measurement", init< const double&, const std::string&, const double&, const std::string&>())
      .def(self_ns::str(self))
      .def_readwrite("value", &mp7::Measurement::value)
      .def_readwrite("units", &mp7::Measurement::units)
      .def_readwrite("tolerence", &mp7::Measurement::tolerence)
      .def_readwrite("tolerence_units", &mp7::Measurement::tolerence_units)
      ;

  // Wrap Generics
  class_<mp7::Generics> ("Generics")
      .def_readwrite("nRegions",&mp7::Generics::nRegions)
      .def_readwrite("bunchCount",&mp7::Generics::bunchCount)
      .def_readwrite("clockRatio",&mp7::Generics::clockRatio)
      .def_readwrite("roChunks",&mp7::Generics::roChunks)
  ;

  // Wrap HistoryEntry
  class_<mp7::HistoryEntry>("HistoryEntry")
      .def_readwrite("cyc", &mp7::HistoryEntry::cyc)
      .def_readwrite("bx", &mp7::HistoryEntry::bx)
      .def_readwrite("orbit", &mp7::HistoryEntry::orbit)
      .def_readwrite("event", &mp7::HistoryEntry::event)
      .def_readwrite("data", &mp7::HistoryEntry::data)
      ;

  class_<mp7::StateHistoryNode, bases<uhal::Node> >("StateHistoryNode", init<const uhal::Node&>())
      .def("clear", &mp7::StateHistoryNode::clear)
      .def("capture", &mp7::StateHistoryNode::capture)
      ;

  // Wrap the PPRamNode
  class_<mp7::PPRamNode, bases<uhal::Node> > ("PPRamNode", init<const uhal::Node&>())
      .def("upload", &mp7::PPRamNode::upload)
      //  .def( "writePayload", &mp7::PPRamNode::writePayload )
      .def("dumpRam", &mp7::PPRamNode::dumpRAM)
      .def("upload64", &mp7::PPRamNode::upload64)
      ;


}

