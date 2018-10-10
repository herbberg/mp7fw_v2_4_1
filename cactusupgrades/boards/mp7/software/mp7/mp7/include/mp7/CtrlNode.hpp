#ifndef __MP7_CSRNODE_HPP__
#define	__MP7_CSRNODE_HPP__


#include <iosfwd>

#include "uhal/DerivedNode.hpp"

#include "mp7/definitions.hpp"


namespace mp7 {

// Forward declaration
class TransactionQueue;
class CtrlSequencer;

/*!
 * @class CtrlNode
 * @brief Specialised node that provides the basic control over the MP7 board
 * 
 * Some notes about the registers
 * Tx/Rx buffer selection: rx = 0,  tx = 1 (as in BufferSelect enum)
 * Region Info register:
 * 0 = empty
 * 1 = buffer only
 * 2 = gth_10g
 * 
 * @author Alessandro Thea
 * @date  2013
 */

class CtrlNode : public uhal::Node {
    UHAL_DERIVEDNODE(CtrlNode);

public:

    /*!
     * @class Clock40Sentry
     * @brief Class to release
     */
    class Clock40Guard {
    public:
        Clock40Guard(const CtrlNode& aCtrl, double aMilliSleep = 1000);

        virtual ~Clock40Guard();

    private:
        const CtrlNode& mCtrl;
        bool mReset;
        double mMilliSleep;
        friend class CtrlNode;
    };

    // PUBLIC METHODS
    CtrlNode(const uhal::Node&);
    virtual ~CtrlNode();
    
    uint32_t readDesign() const;
    
    uint32_t readFwRevision() const;
    
    uint32_t readAlgoRevision() const;
    
    /// Returns the overall list of regions
    std::vector<uint32_t> readRegions() const;

    /// 
    Snapshot readGenerics() const;
    
    /// 
    void writeBoardID( uint32_t aSubsystem, uint32_t aCrate, uint32_t aBoard) const;
    
    /// Nuke the board and reset the 40 Mhz clock
    void hardReset(double aMilliSleep = 1000) const;

    /// Soft reset
    void softReset() const;

    /// Reset Clock 40
    void resetClock40(bool aReset = true) const;

    /// Return the locking status of the 40Mhz clock
    bool clock40Locked() const;

    /// wait (up to 100 ms) for the clock lock
    void waitClk40Lock(uint32_t aMaxTries = 1000) const;

    /// Select the clock
    void selectClk40Source(bool aExternalClock = true) const;


};

}

#endif	/* __MP7_CSRNODE_HPP__ */

