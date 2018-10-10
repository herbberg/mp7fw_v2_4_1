/* 
 * File:   Frame.cpp
 * Author: ale
 * 
 * Created on December 1, 2014, 5:29 PM
 */

#include "mp7/Frame.hpp"

namespace mp7 {

Frame::Frame() : 
    strobe(true),
    valid(false),
    data(0x0) {
}

bool Frame::operator==(const Frame& o) const {
  return (
      this->strobe == o.strobe &&
      this->valid == o.valid &&
      this->data == o.data
      );
}

bool Frame::operator!=(const Frame& o) const {
  return !(this->operator ==(o));
}

std::ostream& operator<<(std::ostream& theStream, const mp7::Frame& aFrame) {
  theStream << "("
    << aFrame.strobe << ", "
    << aFrame.valid << ", "
    << "0x" << std::hex << aFrame.data;

  theStream << ")";
  return theStream;
}

}
