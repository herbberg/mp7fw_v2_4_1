/* 
 * File:   converters_exceptions.hxx
 * Author: ale
 *
 * Created on March 22, 2015, 11:54 AM
 */

#ifndef MP7_PYTHON_CONVERTERS_HXX
#define	MP7_PYTHON_CONVERTERS_HXX

namespace pycomp7 {

//------------------------------------------//
// ---  Converter_std_vector_from_list  --- //
//------------------------------------------//

//---
template<class T>
Converter_std_vector_from_list<T>::Converter_std_vector_from_list() {
    boost::python::converter::registry::push_back ( &convertible, &construct, boost::python::type_id< std::vector<T> >() );
} 


//---
template <class T>
void* 
Converter_std_vector_from_list<T>::convertible ( PyObject* obj_ptr ) {
  if ( !PyList_Check ( obj_ptr ) ) {
    return 0;
  } else {
    return obj_ptr;
  }
}


//---
template <class T>
void 
Converter_std_vector_from_list<T>::construct ( PyObject* obj_ptr, boost::python::converter::rvalue_from_python_stage1_data* data ) {
  namespace bpy = boost::python;
  // Grab pointer to memory in which to construct the new vector
  void* storage = ( ( bpy::converter::rvalue_from_python_storage< std::vector<T> >* ) data )->storage.bytes;
  // Grab list object from obj_ptr
  bpy::list py_list ( bpy::handle<> ( bpy::borrowed ( obj_ptr ) ) );
  // Construct vector in requested location, and set element values.
  // boost::python::extract will throw appropriate exception if can't convert to type T ; boost::python will then call delete itself as well.
  size_t nItems = bpy::len ( py_list );
  std::vector<T>* vec_ptr = new ( storage ) std::vector<T> ( nItems );

  for ( size_t i = 0; i < nItems; i++ ) {
    vec_ptr->at ( i ) = bpy::extract<T> ( py_list[i] );
  }

  // If successful, then register memory chunk pointer for later use by boost.python
  data->convertible = storage;
}


//------------------------------------------//
// ---  Converter_std_map_from_dict     --- //
//------------------------------------------//

//---
template <class K, class V>
Converter_std_map_from_dict<K,V>::Converter_std_map_from_dict(){
    boost::python::converter::registry::push_back ( &convertible, &construct, boost::python::type_id< std::map<K,V> >() );
}


//---
template <class K, class V>
void*
Converter_std_map_from_dict<K,V>::convertible ( PyObject* obj_ptr ) {
  if ( !PyDict_Check ( obj_ptr ) ) {
    return 0;
  } else {
    return obj_ptr;
  }
}


//---
template <class K, class V>
void
Converter_std_map_from_dict<K,V>::construct ( PyObject* obj_ptr, boost::python::converter::rvalue_from_python_stage1_data* data ) {
  namespace bpy = boost::python;
  // Grab pointer to memory in which to construct the new vector
  void* storage = ( ( bpy::converter::rvalue_from_python_storage< std::map<K,V> >* ) data )->storage.bytes;
  // Grab list object from obj_ptr
  bpy::dict py_dict ( bpy::handle<> ( bpy::borrowed ( obj_ptr ) ) );
  // Construct vector in requested location, and set element values.
  // boost::python::extract will throw appropriate exception if can't convert to type T ; boost::python will then call delete itself as well.
  // size_t nItems = bpy::len ( py_dict );
  bpy::list keys = py_dict.keys();
  size_t nKeys = bpy::len( py_dict );

  std::map<K,V>* map_ptr = new ( storage ) std::map<K,V> ();

  for ( size_t i = 0; i < nKeys; i++ ) {
    bpy::object key = keys[i];
    std::pair<K,V> item( bpy::extract<K>(key), bpy::extract<V>(py_dict.get(key)) ); 
    map_ptr->insert( item );
  }

  // If successful, then register memory chunk pointer for later use by boost.python
  data->convertible = storage;
}

//----------------------------------------//
// ---  Converter_std_vector_to_list  --- //
//----------------------------------------//

//---
template <class T>
PyObject*
Converter_std_vector_to_list<T>::convert ( const std::vector<T>& vec ) {
  namespace bpy = boost::python;
  bpy::list theList;

  for ( typename std::vector<T>::const_iterator it = vec.begin(); it != vec.end(); it++ ) {
    theList.append ( bpy::object ( *it ) );
  }

  return bpy::incref ( theList.ptr() );
}


//----------------------------------------//
// ---  Converter_std_map_to_dict     --- //
//----------------------------------------//

template <class U, class T>
PyObject* Converter_std_map_to_dict<U,T>::convert ( const std::map<U, T>& m ) {
  namespace bpy = boost::python;
  bpy::dict theDict;

  for ( typename std::map<U, T>::const_iterator it = m.begin(); it != m.end(); it++ ) {
    theDict[it->first] = bpy::object ( it->second );
  }

  return bpy::incref ( theDict.ptr() );
}


//----------------------------------------//
// ---  Converter_std_pair_to_tuple  --- //
//----------------------------------------//

//---
template<class T1, class T2>
PyObject* 
PairToTupleConverter<T1, T2>::convert ( const std::pair<T1, T2>& pair ) {
  namespace bpy = boost::python;
  return bpy::incref ( bpy::make_tuple ( pair.first, pair.second ).ptr() );
}


}


#endif	/* CONVERTERS_EXCEPTIONS_HXX */

