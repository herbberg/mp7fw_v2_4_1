#include "mp7/ZeroSuppressionNode.hpp"

//---
std::string printhex( const std::vector<uint32_t>& v) {

    if ( v.empty() ) return "";

    std::ostringstream ss;

    ss << "[" << std::showbase << std::hex << "'" << v.front() << "'";
    for( std::vector<uint32_t>::const_iterator it(next(v.begin())); it != v.end(); ++it) {
        ss << ", '" << std::showbase << std::hex << *it << "'";
    }

    ss << "]";

    return ss.str();
}
//---


//---
std::string printhex( const mp7::ZeroSuppressionMenu::Mask& aMask) {
    std::ostringstream ss;
    
    ss << "{ "
        << "enable: " << aMask.enable << ", "
        << "invert: " << aMask.invert << ", "
        << "data: " << printhex(aMask.data)
        << " }";

    return ss.str();
}

//---

int main(int argc, char const *argv[])
{
    /* code */

    { // RAW -> Mask -> RAW
        mp7::ZeroSuppressionMenu::Mask lMaskA;
        std::vector<uint32_t> lRawA(mp7::ZeroSuppressionNode::kBxMaskSize * 2), lRawB;

        lRawA[0] = 0x1;
        lRawA[1] = 0x2 | (1 << 19);

        std::cout << "RMR: raw mask data: " << printhex(lRawA) <<  std::endl;
        lMaskA = mp7::ZeroSuppressionNode::raw2Mask(lRawA.cbegin());

        std::cout << "RMR: mask data: " << printhex(lMaskA) <<  std::endl;

        lRawB = mp7::ZeroSuppressionNode::mask2Raw(lMaskA);

        std::cout << "RMR: raw mask data: " << printhex(lRawB) <<  std::endl;

        assert(lRawA == lRawB);
    }

    { // Mask -> RAW -> MASK

        mp7::ZeroSuppressionMenu::Mask lMaskA, lMaskB;
        std::vector<uint32_t> lRawA;

        lMaskA.invert = true;
        lMaskA.data[1] = 5;

        std::cout << "MRM: mask data: " << printhex(lMaskA) <<  std::endl;

        lRawA = mp7::ZeroSuppressionNode::mask2Raw(lMaskA);

        printhex(lRawA);

        lMaskB = mp7::ZeroSuppressionNode::raw2Mask(lRawA.begin());

        std::cout << "MRM: mask data: " << printhex(lMaskB) <<  std::endl;

        printhex(lMaskB);

    }


    return 0;
}