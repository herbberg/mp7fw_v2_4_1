#ifndef __MP7_CLOCKINGR1NODE_HPP__
#define	__MP7_CLOCKINGR1NODE_HPP__


// MP7 Headers
#include "mp7/ClockingNode.hpp"

// uHAL Headers
#include "uhal/DerivedNode.hpp"
#include "ClockingXENode.hpp"

// C++ Headers
#include <map>

namespace mp7 {

class SI5326Node;

/*!
 * @class ClockingR1Node
 * @brief Specialised Node to control the Xpoint switches
 *
 * @author Alessandro Thea
 * @date August 2013
 */

class ClockingR1Node : public ClockingNode {
    UHAL_DERIVEDNODE(ClockingR1Node);
public:

    enum Clk40Select {
        kExternalAMC13,
        kExternalMCH,
        kDisconnected
    };

    enum RefClkSelect {
        kOscillator,
        kClockCleaner
    };
    
    struct ConfigParams {
        std::string name;
        std::string clkSrc;

        bool si5326_cfg;
        std::string si5326_file;

        enum ClkInput {
            kSI5326 = 0,
            kTclkc = 1,
            kTclka = 2,
            kFclka = 3
        };

        enum RefClk {
            kOsc = 1,
            kClkcln = 3
        };

        ClkInput xpoint_clk40sel;
        RefClk xpoint_refclksel;
    };
    
    // PUBLIC METHODS
    ClockingR1Node(const uhal::Node&);
    virtual ~ClockingR1Node();

    /// Configure the routing by logical states
//    virtual void configure(const std::string& aFilePath, const std::string& aRequiresClock) const;
    virtual void configure(const ConfigParams& aConfig ) const;

    /// Configure the routing by logical states
    void configureXpoint(Clk40Select aClk40Src, RefClkSelect aRefSrc) const;

    /// Configure the U3 switch
    void configureU3(uint SelForOut0, uint SelForOut1, uint SelForOut2, uint SelForOut3) const;

    /// Configure the U15 switch
    void configureU15(uint SelForOut0, uint SelForOut1, uint SelForOut2, uint SelForOut3) const;

    /// Configure the U36 switch
    void configureU36(uint SelForOut0, uint SelForOut1, uint SelForOut2, uint SelForOut3) const;

    /// Reset the SI5326
    void si5326Reset() const;

    // Wait for SI5326 configuration to complete
    void si5326WaitConfigured(uint32_t aMaxTries = 1000) const;

    /// Check the SI5326 loss of lock
    bool si5326LossOfLock() const;

    /// What is this?
    bool si5326Interrupt() const;

protected:

    // PROTECTED METHODS
    void configureUX(const std::string& aChip, uint SelForOut0, uint SelForOut1, uint SelForOut2, uint SelForOut3) const;

};

class ClockingR1Configurator {
public:
    ClockingR1Configurator(const std::string& aFileName, const std::string& kind, const std::string& aPrefix);
    virtual ~ClockingR1Configurator();
    
    void configure( const ClockingR1Node& aClkR1Node ) const;
    
    const ClockingR1Node::ConfigParams& getConfig() const;
    
    static ClockingR1Node::ConfigParams parseFromXML(const std::string& aFileName);

private:
    ClockingR1Node::ConfigParams mConfig;
};


std::ostream& operator<<(std::ostream& out, mp7::ClockingR1Node::ConfigParams::ClkInput value);
std::istream& operator>>(std::istream& in, mp7::ClockingR1Node::ConfigParams::ClkInput& value);

std::ostream& operator<<(std::ostream& out, mp7::ClockingR1Node::ConfigParams::RefClk value);
std::istream& operator>>(std::istream& in, mp7::ClockingR1Node::ConfigParams::RefClk& value);

}



#endif	/* __MP7_CLOCKINGR1NODE_HPP__ */


