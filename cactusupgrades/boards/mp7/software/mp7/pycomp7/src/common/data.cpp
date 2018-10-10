
#include "mp7/python/registrators.hpp"

// Boost Headers
#include <boost/python/def.hpp>
#include <boost/python/wrapper.hpp>
#include <boost/python/overloads.hpp>
#include <boost/python/class.hpp>
#include <boost/python/enum.hpp>
#include <boost/python/copy_const_reference.hpp>
#include <boost/python/copy_non_const_reference.hpp>
#include <boost/python/suite/indexing/vector_indexing_suite.hpp>
#include <boost/python/operators.hpp>

// MP7 Headers
#include "mp7/definitions.hpp"
#include "mp7/python/indexing.hpp"
#include "mp7/BoardData.hpp"
#include "mp7/BoardDataIO.hpp"

using namespace boost::python;

namespace pycomp7 {

BOOST_PYTHON_FUNCTION_OVERLOADS(mp7_BoardDataFactory_generate_overloads, mp7::BoardDataFactory::generate, 1, 3)
BOOST_PYTHON_FUNCTION_OVERLOADS(mp7_BoardDataFactory_readFromFile_overloads, mp7::BoardDataFactory::readFromFile, 1,2)

void
register_data() {


    class_<mp7::Frame> ("Frame", init<>())
            .def_readwrite("strobe",&mp7::Frame::strobe)
            .def_readwrite("valid",&mp7::Frame::valid)
            .def_readwrite("data",&mp7::Frame::data)
            .def(/*__str__*/ self_ns::str(self))
            .def(/*__eq__*/ self == self)
            .def(/*__neq__*/ self != self)

    ;

    class_<mp7::LinkData>("LinkData")
        .def(init<const std::vector<mp7::Frame>&>())
        .def(init<mp7::LinkData::size_type>())
        .def("size", &mp7::LinkData::size)
        .def("resize", &mp7::LinkData::resize)
        .def("append", &mp7::LinkData::push_back)
        .def("strobed", &mp7::LinkData::strobed)
        .def("setStrobed", &mp7::LinkData::setStrobed)
        .def("__len__", &mp7::LinkData::size)
        .def("__getitem__", &pycomp7::IndexingSuite<mp7::LinkData,mp7::Frame>::get, return_internal_reference<>())
        .def("__setitem__", &pycomp7::IndexingSuite<mp7::LinkData,mp7::Frame>::set)
        .def("__iter__", iterator<mp7::LinkData>())
        .def(/*__str__*/ self_ns::str(self))
        // .def("__iter__", range< return_value_policy< reference_existing_object> >(
        //        static_cast<mp7::LinkData::iterator (mp7::LinkData::*)() >(&mp7::LinkData::begin),
        //        static_cast<mp7::LinkData::iterator (mp7::LinkData::*)() >(&mp7::LinkData::end)
        //        )
        // )
        ;


  { 
    scope mp7_BoardData_scope = class_<mp7::BoardData>("BoardData", init<const std::string&>())
      //        .def ( /*__str__*/ self_ns::str ( self ) )
        .def("name", &mp7::BoardData::name, return_value_policy<copy_const_reference>())
        .def("size", &mp7::BoardData::size)
        .def("links", &mp7::BoardData::links)
        .def("add", &mp7::BoardData::add)
        .def("depth", &mp7::BoardData::depth)
        .def("frame", &mp7::BoardData::frame)
        .def("__eq__", &mp7::BoardData::operator==)
        .def("__len__", &mp7::BoardData::size)
        .def("__getitem__", &pycomp7::MapIndexingSuite<mp7::BoardData,uint32_t,mp7::LinkData>::get, return_internal_reference<>())
        .def("__setitem__", &pycomp7::MapIndexingSuite<mp7::BoardData,uint32_t,mp7::LinkData>::set)
        .def("__iter__", iterator<mp7::BoardData>())
       //  .def("__iter__", range< return_value_policy< reference_existing_object > >(
       //         static_cast<mp7::BoardData::iterator (mp7::BoardData::*)() >(&mp7::BoardData::begin),
       //         static_cast<mp7::BoardData::iterator (mp7::BoardData::*)() >(&mp7::BoardData::end)
       //         )
       // )
      ;

    class_<std::pair<const uint32_t, mp7::LinkData> >("pair", no_init)
        .def_readonly("first", &std::pair<const uint32_t, mp7::LinkData>::first)
        .def_readonly("second", &std::pair<const uint32_t, mp7::LinkData>::second);
  }

  class_<mp7::BoardDataFactory>("BoardDataFactory", no_init)
    .def("generate", mp7::BoardDataFactory::generate, mp7_BoardDataFactory_generate_overloads())
    .staticmethod("generate")
    .def("saveToFile", &mp7::BoardDataFactory::saveToFile)
    .staticmethod("saveToFile")
    .def("readFromFile", &mp7::BoardDataFactory::readFromFile, mp7_BoardDataFactory_readFromFile_overloads())
    .staticmethod("readFromFile");
    ;

  class_<mp7::BoardDataWriter, boost::noncopyable>("BoardDataWriter", init<const std::string&>())
    .def("put", &mp7::BoardDataWriter::put)
    ;
}


} // namespace pycomp7

