
#include "mp7/exception.hpp"


mp7::exception::exception()
{
}


mp7::exception::exception(const std::string& infoString) : 
 mInfo(infoString)
{
}


mp7::exception::~exception() throw()
{
}


const char* mp7::exception::what() const throw()
{
  return mInfo.c_str();
}


void mp7::exception::append(const std::string& aString)
{
  mInfo += "  \n";
  mInfo += aString;
}

