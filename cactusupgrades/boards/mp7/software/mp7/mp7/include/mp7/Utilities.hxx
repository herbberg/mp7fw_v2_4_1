#ifndef __mp7_helpers_hxx__
#define __mp7_helpers_hxx__

#include "Utilities.hpp"

#include <boost/lexical_cast.hpp>

namespace mp7 {


//-----------------------------------------------------------------------------
template < typename T >
struct stoul {
    BOOST_STATIC_ASSERT((boost::is_unsigned<T>::value));
    T value;

    operator T() const {
        return value;
    }

    friend std::istream& operator>>(std::istream& in, stoul& out) {
        std::string buf;
        in>>buf;
        out.value = strtoul(buf.c_str(), NULL, 0);
        return in;
    }
};
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
template < typename T >
struct stol {
    BOOST_STATIC_ASSERT((boost::is_signed<T>::value));
    T value;

    operator T() const {
        return value;
    }

    friend std::istream& operator>>(std::istream& in, stol& out) {
        std::string buf;
        in>>buf;
        out.value = strtol(buf.c_str(), NULL, 0);
        return in;
    }
};
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
template < typename T >
std::string
to_string(const T& v) {
    return boost::lexical_cast<std::string>(v);
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
template < typename M >
bool map_value_comparator( typename M::value_type &p1, typename M::value_type &p2){
    return p1.second < p2.second;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
template< typename T>
std::vector<T> sanitize( const std::vector<T>& vec ) {
  // Sanitise the inputs, by copying
  std::vector<uint32_t> sorted(vec);
 
  // ...sorting...
  std::sort(sorted.begin(), sorted.end());
  
  // and delete the duplicates (erase+unique require a sorted vector to delete duplicates)
  sorted.erase( std::unique(sorted.begin(), sorted.end()), sorted.end());

  return sorted;
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
template< typename T, typename U>
T safe_enum_cast(const U& value, const std::vector<T>& valid, const T& def) {
    typename std::vector<T>::const_iterator it = std::find(valid.begin(), valid.end(), static_cast<T>(value));
    return ( it != valid.end() ? *it : def );
}
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
template<typename C>
std::string join(const C& aStrings, const std::string& aDelimiter)
{

  if ( aStrings.empty() ) return "";

  std::ostringstream lString;

  lString << *aStrings.begin();

  for(auto iStr = std::next(aStrings.begin()); iStr != aStrings.end(); ++iStr) {
    lString << aDelimiter; 
    lString << *iStr;
  }

  return lString.str();
}
//-----------------------------------------------------------------------------


}


#endif /* _mp7_helpers_hpp_ */
