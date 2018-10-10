/**
 * @file MGTRegionNode.hpp
 * @author Alessandro Thea
 * @date 2013
 */

#ifndef MGT_REGIONNODE_HPP
#define	MGT_REGIONNODE_HPP


// uHAL Headers
#include "uhal/DerivedNode.hpp"

// MP7 Headers
#include "mp7/definitions.hpp"
#include "mp7/CommandSequence.hpp"


// C++ Headers
#include <string>
#include <map>

namespace mp7 {

class TransactionQueue;
class MGTRegionSequencer;

/**
 * @class ChannelStatus
 * @author Alessandro Thea
 * @date April 2015
 */
struct RxChannelStatus {
  bool pllLocked;
  uint32_t crcChecked;
  uint32_t crcErrors;
  uint32_t trailerId;
  bool fsmResetDone;
  bool usrReset;
};


struct TxChannelStatus {
  bool pllLocked;
  bool fsmResetDone;
  bool usrReset;
};

/**
 * @class MGTRegionNode
 * @author Alessandro Thea
 * @date 2013
 */

class MGTRegionNode : public uhal::Node {
    UHAL_DERIVEDNODE( MGTRegionNode );
    
public:
    // Constants
    static const std::vector<uint32_t> kAllChannelIDs;

    // PUBLIC METHODS
    MGTRegionNode( const uhal::Node& );
    virtual ~MGTRegionNode( );

    /**
     * Retrieves the type of the current region
     * @return Type of region
     */
    MGTKind readRegionKind() const;

    bool usesQpll() const;
    
    /**
     * Issues a soft reset to the whole MGT region
     */
    void softReset( bool aReset = true ) const;

    void clearCRCs( const std::vector<uint32_t>& aChans = kAllChannelIDs  ) const;

    void resetRxFSM( bool aReset, const std::vector<uint32_t>& aChans = kAllChannelIDs ) const;
    
    void resetTxFSM( bool aReset, const std::vector<uint32_t>& aChans = kAllChannelIDs ) const;

    /**
     * Configure Receiver channels
     * 
     * @param aPolarity: True for standard polarity, false for inverted
     * @param aOrbitTag: True to enable orbittag mode, false otherwise
     * @param aLoop: True to enable loopback mode, false otherwise
     * @param aChans: List of channels
     */
    void configureRx( bool aOrbitTag, bool aPolarity, const std::vector<uint32_t>& aChans = kAllChannelIDs ) const;
    
    /**
     * Configure Transmitter channels
     * 
     * @param aPolarity: True for standard polarity, false for inverted
     * @param aChans: List of channels
     */
    void configureTx( bool aLoop,  bool aPolarity, const std::vector<uint32_t>& aChans = kAllChannelIDs ) const;
    
    /**
     * Wait for the Rx FSM reset to be completed.
     * @param aChannel: channel id, 0-3
     * @param aMaxTries: maximum number of attempts
     */
    void waitRxFMSResetDone(uint32_t aMaxTries, const std::vector<uint32_t>& aChans = kAllChannelIDs) const;
    
    /**
     * Wait for the Tx FSM reset to be completed.
     * @param aChannel: channel id, 0-3
     * @param aMaxTries: maximum number of attempts
     */
    void waitTxFMSResetDone(uint32_t aMaxTries, const std::vector<uint32_t>& aChans = kAllChannelIDs) const;

    /**
     * Checks the MGT's Rx channels overall status
     * 
     * @param aChans list of channels to check
     * @return True if no errors were found
     */
    bool checkRx( const std::vector<uint32_t>& aChans = kAllChannelIDs ) const;

        /**
     * Checks the MGT's Tx channels overall status
     * 
     * @param aChans list of channels to check
     * @return True if no errors were found
     */
    bool checkTx( const std::vector<uint32_t>& aChans = kAllChannelIDs ) const;
    
    /**
     * Reads the quad qpll lock status
     * 
     * @return True if the qpll is locked, false otherwise
     */
    bool isQpllLocked( ) const;

    /**
     * Reads Rx channel status
     * 
     * @param aChannel: channel id, 0-3
     * @return 
     */
    RxChannelStatus readRxChannelStatus( uint32_t aChannel ) const;

    /**
     * Reads Tx channel status
     * 
     * @param aChannel: channel id, 0-3
     * @return 
     */
    TxChannelStatus readTxChannelStatus( uint32_t aChannel ) const;
    
     /**
     * Performs a Rx channel status check.
     * 
     * 
     * @param aChannel: channel id, 0-3
     * @return True if no errors are found
     */
    bool checkRx( uint32_t aChannel ) const;

    /**
     * Performs a Tx channel status check
     * 
     * @param aChannel: channel id, 0-3
     * @return True if no errors are found
     */
    bool checkTx( uint32_t aChannel ) const;



    /// Experimental
    MGTRegionSequencer queue( TransactionQueue& aSequence ) const; 
private:
    // PRIVATE MEMBERS

    void checkBoundaries( const std::vector<uint32_t>& aChans ) const;
    
    void waitForFSMResetDone( const std::string& aGroup, uint32_t aMaxTries, const std::vector<uint32_t>& aChans = kAllChannelIDs ) const;

    // void waitForChannelFSMResetDone( const std::string& aGroup, uint32_t aChannel, uint32_t aMaxTries ) const;

};


class MGTRegionSequencer {
private:
    MGTRegionSequencer( const MGTRegionNode& aRegion, TransactionQueue& aSequence );
public:
    virtual ~MGTRegionSequencer();

    // --- Exp: Atomic Sequence based methods ---
    void softReset( bool aReset = 1) const;
    void resetRxFSM( uint32_t aChannel, bool aReset = 1) const;
    void resetTxFSM( uint32_t aChannel, bool aReset = 1) const;
    
private:
    const MGTRegionNode& mMGTs;
    TransactionQueue& mSequence;

    friend class MGTRegionNode;
};

}

#endif	/* MGT_REGIONNODE_HPP */


