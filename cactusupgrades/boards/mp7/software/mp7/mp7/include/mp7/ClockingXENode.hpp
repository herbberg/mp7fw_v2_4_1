#ifndef __MP7_CLOCKINGXENODE_HPP__
#define	__MP7_CLOCKINGXENODE_HPP__

// MP7 Headers
#include "mp7/ClockingNode.hpp"

// uHAL Headers
#include "uhal/DerivedNode.hpp"

// C++ Headers
#include <map>

namespace mp7 {

/*!
 * @class ClockingXENode
 * @brief Specialised Node to control the Xpoint switches
 *
 * @author Alessandro Thea
 * @date August 2013
 */


class ClockingXENode : public ClockingNode {
    UHAL_DERIVEDNODE(ClockingXENode);
public:

    enum Clk40Select {
        kExternalAMC13,
        kExternalMCH,
        kDisconnected
    };

    struct ConfigParams {
        std::string name;
        std::string clkSrc;

        bool si570_cfg;
        std::string si570_file;

        bool si5326_cfgtop;
        bool si5326_cfgbot;
        std::string si5326_filetop;
        std::string si5326_filebot;

        bool si53314_basetop;
        bool si53314_exttop;
        bool si53314_basebot;
        bool si53314_extbot;
        uint32_t si53314_clkselbot;

        enum ClkInput {
            kFPGA,
            kTclkc,
            kTclka,
            kFclka
        };

        ClkInput xpoint_tclkb;
        ClkInput xpoint_fpga;
        ClkInput xpoint_clk2;
        ClkInput xpoint_clk1;
        
        
    };
    
    
    // PUBLIC METHODS
    ClockingXENode(const uhal::Node&);
    virtual ~ClockingXENode();

    /// Configure the routing by logical states
    virtual void configure(const ConfigParams& aConfig ) const;

    /// Configure the routing by logical states
    void configureXpoint(Clk40Select aClk40Src) const;

    /// Configure the U36 switch
    void configureU36(uint SelForOut0, uint SelForOut1, uint SelForOut2, uint SelForOut3) const;

    /// Reset the SI5326
    void si5326TopReset() const;

    // Wait for SI5326 configuration to complete
    void si5326TopWaitConfigured(bool aMustLock = true, uint32_t aMaxTries = 1000) const;

    /// Check the SI5326 loss of lock
    bool si5326TopLossOfLock() const;

    /// What is this?
    bool si5326TopInterrupt() const;

    /// Reset the SI5326
    void si5326BottomReset() const;

    // Wait for SI5326 configuration to complete
    void si5326BottomWaitConfigured(bool aMustLock = true, uint32_t aMaxTries = 1000) const;

    /// Check the SI5326 loss of lock
    bool si5326BottomLossOfLock() const;

    /// What is this?
    bool si5326BottomInterrupt() const;

protected:

    // PROTECTED METHODS
    void configureUX(const std::string& chip, uint SelForOut0, uint SelForOut1, uint SelForOut2, uint SelForOut3) const;

    /// Reset the SI5326
    void si5326ChipReset(const std::string& aChip) const;

    // Wait for SI5326 configuration to complete
    void si5326ChipWaitConfigured(const std::string& aChip, bool aMustLock = true, uint32_t aMaxTries = 1000) const;

    /// Check the SI5326 loss of lock
    bool si5326ChipLossOfLock(const std::string& aChip) const;

    /// What is this?
    bool si5326ChipInterrupt(const std::string& aChip) const;

};

class ClockingXEConfigurator {
public:
    ClockingXEConfigurator(const std::string& aFileName, const std::string& kind, const std::string& aPrefix);
    virtual ~ClockingXEConfigurator();
    
    static ClockingXENode::ConfigParams parseFromXML(const std::string& aFilePath);

    const ClockingXENode::ConfigParams& getConfig() const;
    
    void configure( const ClockingXENode& aClkR1Node ) const;

private:
    ClockingXENode::ConfigParams mConfig;
};


std::ostream& operator<<(std::ostream&, mp7::ClockingXENode::ConfigParams::ClkInput);
std::istream& operator>>(std::istream&, mp7::ClockingXENode::ConfigParams::ClkInput&);

}



#endif	/* __MP7_CLOCKINGXENODE_HPP__ */


