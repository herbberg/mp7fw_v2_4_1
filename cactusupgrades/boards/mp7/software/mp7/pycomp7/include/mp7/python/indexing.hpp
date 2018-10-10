/* 
 * File:   indexing.hpp
 * Author: ale
 *
 * Created on June 12, 2015, 1:46 PM
 */

#ifndef __MP7_PYTHON_INDEXING_HPP__
#define	__MP7_PYTHON_INDEXING_HPP__

namespace pycomp7 {

template <typename Container, typename Payload>
struct IndexingSuite {

  static void raiseIndexError() {
    PyErr_SetString(PyExc_IndexError, "Index out of range");
    boost::python::throw_error_already_set();
  }

  static Payload& get(Container& aData, int i) {
    // std::cout << "container:" << &aData << std::endl;
    if (i < 0) {
      i += aData.size();
    }

    if (i < 0 || i >= int ( aData.size())) {
      raiseIndexError();
    }

    Payload& pl = aData.at(i);
    // std::cout << "obj:" << &pl << std::endl;
    return pl;
  }

  static void set(Container& aData, int i, const Payload& aFrame) {
    if (i < 0) {
      i += aData.size();
    }

    if (i < 0 || i >= int ( aData.size())) {
      raiseIndexError();
    }

    aData.at(i) = aFrame;
  }
};

template <typename Container, typename Key, typename Value>
struct MapIndexingSuite {

  static void raiseKeyError() {
    PyErr_SetString(PyExc_KeyError, "Key not found");
    boost::python::throw_error_already_set();
  }

  static Value& get(Container& aData, const Key& aKey) {
    // std::cout << "map:" << &aData << std::endl;

    typename Container::iterator it = aData.find( aKey );
    if ( it == aData.end() ) {
      raiseKeyError();
    }
    // std::cout << "obj:" << &it->second << std::endl;

    return it->second;
  }

  static void set(Container& aData, const Key& aKey, const Value& aValue) {
    aData[aKey] = aValue;
  }
};

}

#endif	/* __MP7_PYTHON_INDEXING_HPP__ */

