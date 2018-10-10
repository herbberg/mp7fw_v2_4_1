/**
 * @file    operators.cpp
 * @author  Alessandro Thea
 * @date    December 2014
 */
#include "mp7/operators.hpp"
#include "mp7/exception.hpp"

// C++ Headers
#include <stdexcept>

namespace mp7 {

std::ostream& 
operator<<(std::ostream& oStream, const MP7Kind& aKind) {
  switch (aKind) {
    case kMP7Xe:
      return (oStream << "xe");
    case kMP7R1:
      return (oStream << "r1");
    case kMP7Sim:
      return (oStream << "sim");
    default:
      return (oStream << "unknown");
  }
}

std::ostream& 
operator<<(std::ostream& oStream, const MGTKind& aKind) {
  switch (aKind) {
    case kNoMGT:
      return (oStream << "nomgt");
    case kGth10g:
      return (oStream << "10g");
    case kGth5g:
      return (oStream << "5g");
    case kGthCalo:
      return (oStream << "calo");
    case kGthCaloTest:
      return (oStream << "calotest");
    case kGth10gStdLat:
      return (oStream << "10gStdLat");
        case kGtx10g:
      return (oStream << "10gGtx");
    default:
      throw ArgumentError("Invalid value for mp7::MGTKind in ostream << operator");
  }
}

std::ostream& 
operator<<(std::ostream& oStream, const CheckSumKind& aKind) {
  switch (aKind) {
    case kNoCheckSum:
      return (oStream << "nochk");
    case kOlogicCrc32:
      return (oStream << "ologiccrc32");
    case kGct:
      return (oStream << "gct");
    case kF64:
      return (oStream << "f64");
    case kUCrc32:
      return (oStream << "ucrc32");
    default:
      throw ArgumentError("Invalid value for mp7::CheckSumKind in ostream << operator");
  }
}

std::ostream& 
operator<<(std::ostream& oStream, const BufferKind& aKind) {
  switch (aKind) {
    case kNoBuffer:
      return (oStream << "nobuf");
    case kBuffer:
      return (oStream << "buf");
    default:
      throw ArgumentError("Invalid value for mp7::BufferKind in ostream << operator");
  }
}

std::ostream& 
operator<<(std::ostream& oStream, const FormatterKind& aKind) {
  switch (aKind) {
    case kNoFormatter:
      return (oStream << "nofmt");
    case kTDRFormatter:
      return (oStream << "tdr");
    case kStage1Formatter:
      return (oStream << "s1");
    case kDemuxFormatter:
      return (oStream << "dmx");
    default:
      throw ArgumentError("Invalid value for mp7::BufferKind in ostream << operator");
  }
}



std::ostream& 
operator<<(std::ostream& oStream, const RxTxSelector& aKind) {
  switch (aKind) {
    case mp7::kRx:
      return (oStream << "Rx");
    case mp7::kTx:
      return (oStream << "Tx");
    default:
      throw ArgumentError("Invalid value for mp7::BufferSelector in ostream << operator");
      return (oStream << "Invalid mp7::BufferSelection value");
  }
}


} // namespace mp7
