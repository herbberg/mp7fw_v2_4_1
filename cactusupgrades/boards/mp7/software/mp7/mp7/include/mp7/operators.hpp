/**
 * @file    operators.hpp
 * @author  Alessandro Thea
 * @date    December 2014
 */

#ifndef __MP7_OPERATORS_HPP__
#define	__MP7_OPERATORS_HPP__

// C++ Headers
#include <ostream>

// MP7 Headers
#include "mp7/definitions.hpp"

namespace mp7 {

std::ostream& operator<<(std::ostream& oStream, const MP7Kind& seln);
std::ostream& operator<<(std::ostream& oStream, const MGTKind& seln);
std::ostream& operator<<(std::ostream& oStream, const CheckSumKind& seln);
std::ostream& operator<<(std::ostream& oStream, const BufferKind& seln);
std::ostream& operator<<(std::ostream& oStream, const FormatterKind& seln);


std::ostream& operator<<(std::ostream& oStream, const RxTxSelector& seln);


} // namespace mp7

#endif	/* __MP7_OPERATORS_HPP__ */

