
/*
 *
 * File: mp7/python/exceptions.hxx
 * Author: Tom Williams
 * Date: March 2015
 *   (Largely copy of corresponding file in uHAL Python bindings)
 */

#ifndef MP7_PYTHON_EXCEPTIONS_HXX
#define MP7_PYTHON_EXCEPTIONS_HXX


#include "boost/python/object.hpp"
#include "boost/python/scope.hpp"



template<class ExceptionType>
pycomp7::ExceptionTranslator<ExceptionType>::ExceptionTranslator(PyObject* aExceptionPyType) : 
 mExceptionPyType(aExceptionPyType) { 
}


template<class ExceptionType>
void pycomp7::ExceptionTranslator<ExceptionType>::operator() (const ExceptionType& e) const {
  namespace bpy = boost::python;
  bpy::object pyException(bpy::handle<> (bpy::borrowed(mExceptionPyType)));

  // Add exception::what() string as ".what" attribute of Python exception
  pyException.attr("what") = e.what();

  PyErr_SetObject(mExceptionPyType, pyException.ptr());
}


template<class ExceptionType>
PyObject* pycomp7::wrap_exception_class(const std::string& aExceptionName, PyObject* aBaseExceptionPyType)
{
  PyObject* exceptionPyType = pycomp7::create_exception_class(aExceptionName, aBaseExceptionPyType);
  boost::python::register_exception_translator<ExceptionType>(pycomp7::ExceptionTranslator<ExceptionType>(exceptionPyType));

  return exceptionPyType;
}


#endif
