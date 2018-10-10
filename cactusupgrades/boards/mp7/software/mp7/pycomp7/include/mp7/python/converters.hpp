/*
 * File:   converters.h
 * Author: ale
 *
 * Created on August 20, 2013, 4:28 AM
 */

#ifndef __MP7_PYTHON_CONVERTERS_HPP__
#define	__MP7_PYTHON_CONVERTERS_HPP__

// C++ Headers
#include <vector>
#include <map>

// Boost Headers
#include <boost/python/object.hpp>
#include <boost/python/dict.hpp>
#include <boost/python/converter/rvalue_from_python_data.hpp>


namespace pycomp7 {

  // CONVERTERS
  template<class T>
  struct Converter_std_vector_from_list {

    // Default CTOR. Registers this converter to boost::python
    Converter_std_vector_from_list();

    // Determine if obj_ptr can be converted to vector<T>
    static void* convertible ( PyObject* obj_ptr );

    // Convert obj_ptr to a C++ vector<T>
    static void construct ( PyObject* obj_ptr, boost::python::converter::rvalue_from_python_stage1_data* data );
  };


  template<class K, class V>
  struct Converter_std_map_from_dict {

    // Default CTOR. Registers this converter to boost::python
    Converter_std_map_from_dict();

    // Determine if obj_ptr can be converted to vector<T>
    static void* convertible ( PyObject* obj_ptr );

    // Convert obj_ptr to a C++ vector<T>
    static void construct ( PyObject* obj_ptr, boost::python::converter::rvalue_from_python_stage1_data* data );
  };

  //------------------//
  template <class T>
  struct Converter_std_vector_to_list {
    static PyObject* convert ( const std::vector<T>& v );
  };

  //------------------//
  template <class U, class T>
  struct Converter_std_map_to_dict {
    static PyObject* convert ( const std::map<U, T>& m );
  };

  //------------------//
  template<class T1, class T2>
  struct PairToTupleConverter {
    static PyObject* convert ( const std::pair<T1, T2>& pair );
  };

  
  void register_converters();


}

#include "mp7/python/converters.hxx"

#endif	/* __MP7_PYTHON_CONVERTERS_HPP__ */


