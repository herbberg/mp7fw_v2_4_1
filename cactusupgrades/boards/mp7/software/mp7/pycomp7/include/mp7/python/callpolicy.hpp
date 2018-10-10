#ifndef __MP7_PYTHON_CALLPOLICY_HPP__
#define __MP7_PYTHON_CALLPOLICY_HPP__

#include <boost/python/module.hpp>
#include <boost/python/class.hpp>
#include <boost/thread/thread.hpp>
#include <boost/unordered_map.hpp>



// 
// Usage:  .def("rebootFPGA", make_function(&mp7::MmcController::rebootFPGA, release_gil_policy()))
// 

namespace pycomp7 {

struct release_gil_policy
{
  // Ownership of this argument tuple will ultimately be adopted by
  // the caller.
  template <class ArgumentPackage>
  static bool precall(ArgumentPackage const&)
  {
    // Release GIL and save PyThreadState for this thread here
    PyThreadState* state = PyEval_SaveThread();

    std::cout << boost::this_thread::get_id() << std::endl;

    _theHorribleMap[boost::this_thread::get_id()] = state;
    return true;
  }
 
  // Pass the result through
  template <class ArgumentPackage>
  static PyObject* postcall(ArgumentPackage const&, PyObject* result)
  {
    // Reacquire GIL using PyThreadState for this thread here
    std::cout << boost::this_thread::get_id() << std::endl;
 
    PyEval_RestoreThread(_theHorribleMap.at(boost::this_thread::get_id()));
    return result;
  }
 
  typedef boost::python::default_result_converter result_converter;
  typedef PyObject* argument_package;
 
  template <class Sig> 
  struct extract_return_type : boost::mpl::front<Sig>
  {
  };
 
private:
  // Retain pointer to PyThreadState on a per-thread basis here
  static boost::unordered_map<boost::thread::id, PyThreadState*> _theHorribleMap;
};

}

#endif  /* __MP7_PYTHON_CALLPOLICY_HPP__ */
