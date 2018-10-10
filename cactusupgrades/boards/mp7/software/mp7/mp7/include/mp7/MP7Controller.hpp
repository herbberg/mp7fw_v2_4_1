/*
 * File: mp7/CppMP7Controller.hpp
 * Author: tsw
 *
 * Date: October 2014
 */

#ifndef __MP7_MP7CONTROLLER_HPP__
#define __MP7_MP7CONTROLLER_HPP__

// uHal Headers
#include "uhal/HwInterface.hpp"

// MP7 Headers
#include "MP7MiniController.hpp"
#include "mp7/CommandSequence.hpp"
#include "mp7/CtrlNode.hpp"
#include "mp7/MmcManager.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/Measurement.hpp"
#include "mp7/ChannelManager.hpp"
#include "mp7/DatapathDescriptor.hpp"
#include "mp7/Orbit.hpp"
#include "mp7/ReadoutNode.hpp"

// forward declarations
namespace pugi {
class xml_node;
}

namespace mp7 {
class AlignMonNode;
class BoardData;
class ChanBufferNode;
class ClockingNode;
class ClockingR1Node;
class ClockingXENode;
class FormatterNode;
class MGTRegionNode;
class SI5326Node;
class SI570Node;
class TTCNode;
class DatapathNode;
class ReadoutNode;
class MiniPODMasterNode;


class MP7Controller : public MP7MiniController {
public:

    //!
    MP7Controller(const uhal::HwInterface& aHw);
    
    //!
    virtual ~MP7Controller();

    /**
     * MP7Controller build status
     * @return True if the Controller was built, false otherwise.
     */
    // bool isBuilt() const;

    /**
     * Controller identifier
     * @return Board id
     */
    // std::string id() const;

    /**
     * Detects the MP7 kind
     * @return the kind of MP7 the controller is connected to. Can be "xe", "r1" or "unknown"
     */
    MP7Kind kind() const;

    /**
     * Prints a summary of the board main parameters on screen
     */
    virtual void identify() const;

    /**
     * Resets the board and cofigures the clocking
     * @param aClkSrc Clock source configuration. Can be internal/external
     * @param aRefClkCfg Ref clock configuration
     * @param aTTCCfg TTC configuration
     */
    void reset(const std::string& aClkSrc, const std::string& aRefClkCfg = "default", const std::string& aTTCCfg = "default");

    /**
     * Resets the algorithm payload, if any
     */
    virtual void resetPayload();

    //! Readout Node getter
    const mp7::ReadoutNode& getReadout() const;
    
    //! MMC manager getter
    MmcManager mmcMgr();
      
    std::map<uint32_t,uint32_t> computeEventSizes( const ReadoutMenu& aMenu ) const;

protected:
    
    //! MP7 ClockingNode reference
    const ClockingNode& mClocking;
    
    //! MP7 readout node
    const ReadoutNode& mReadout;

    //! Bottom minipod node
    const MiniPODMasterNode& mMiniPODTop;

    //! Top minipod node
    const MiniPODMasterNode& mMiniPODBottom;



private:
    
    //!
    MP7Kind mKind;
    
    /*
    Experimental section :)
    "Hic Sunt Leones"
     */
public:
    TransactionQueue createQueue();
private:

    friend class ChannelManager;
};

}



#endif /* __MP7_MP7CONTROLLER_HPP__ */

