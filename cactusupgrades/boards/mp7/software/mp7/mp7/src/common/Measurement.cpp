/**
 * @file    Measurement.cpp
 * @author  Aaron Bundock
 * @brief   Brief description
 * @date 
 */

#include "mp7/Measurement.hpp"

namespace mp7 {

const double Measurement::kNaN = std::numeric_limits<double>::quiet_NaN();

std::ostream& operator<<(std::ostream& aStream, const Measurement& aMeasurement) {
    if (isnan(aMeasurement.value)) {
        aStream << "{undefined}";
    } else {
        aStream << std::dec << aMeasurement.value << " " << aMeasurement.units;

        if (not isnan(aMeasurement.tolerence)) {
            aStream << " (+/-" << aMeasurement.tolerence << "" << aMeasurement.tolerence_units << ")";
        }
    }

    return aStream;
}

} // namespace mp7