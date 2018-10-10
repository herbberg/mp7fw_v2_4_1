/*
 * File: mp7/CppMP7Controller.hpp
 * Author: thea
 *
 * Date: March 2016
 */

#ifndef __MP7_MP7BASECONTROLLER_HPP__
#define __MP7_MP7BASECONTROLLER_HPP__

// uHal Headers
#include "uhal/HwInterface.hpp"

// MP7 Headers
#include "mp7/ChannelManager.hpp"
#include "mp7/DatapathDescriptor.hpp"


namespace mp7 {

// Forward declarations
class TTCNode;
class CtrlNode;
class DatapathNode;
class FormatterNode;

class MP7MiniController : public boost::noncopyable {
public:
    //!
    MP7MiniController(const uhal::HwInterface& aHw);

    //!
    virtual ~MP7MiniController();

    /**
     * MP7Controller build status
     * @return True if the Controller was built, false otherwise.
     */
    bool isBuilt() const;

    /**
     * Controller identifier
     * @return Board id
     */
    std::string id() const;

    /**
     * Prints a summary of the board main parameters on screen
     */
    void identify() const;

    /**
     * Access to the underlying HwInterface. To be used for debugging purposes ONLY!
     * @return Reference to the controller's hw interface
     */
    uhal::HwInterface& hw();
    
    /**
     * Generics
     * @return MP7 Generic parameters as retrieved from the firmware
     */
    const Generics& getGenerics() const;

    /**
     * Metric defined according to the board built-in parameters
     * @details [long description]
     * @return [description]
     */
    orbit::Metric getMetric() const;
    
    /**
     * 
     * @return 
     */
    ChannelGroup getChannelIDs( ) const;

    /**
     * Prints a summary report of the current TTC status
     */
    virtual void checkTTC();

    /**
     * Checks which values of the TTC phase from range [aStart,aStop) do not result in any errors, and returns these phases as a vector 
     * 
     * 
     * @param aStart [description]
     * @param aStop [description]
     * 
     * @return [description]
     */
    std::vector<uint32_t> scanTTCPhase(const uint32_t aStart = 0x0, const uint32_t aStop = 0x540);

    //! Control Node getter
    const mp7::CtrlNode& getCtrl() const;

    //! TTC Node getter
    const mp7::TTCNode& getTTC() const;

    //! Datapath Node getter
    const mp7::DatapathNode& getDatapath() const;

    //! Buffer Node getter
    const mp7::ChanBufferNode& getBuffer() const;

    //! Alignment Monitoring Node getter
    const mp7::AlignMonNode& getAlignmentMonitor() const;

    //! Alignment Monitoring Node getter
    const mp7::FormatterNode& getFormatter() const;
    
    //! ChannelManager getter
    ChannelManager channelMgr() const;  

    //! ChannelManager with additional chennel selection getter.
    ChannelManager channelMgr( const std::vector<uint32_t>& aSelection ) const;

private:

    bool mBuilt;

protected:

    //! IPBus interface to the MP7 board
    uhal::HwInterface mHw;

    //! MP7 Control node reference
    const CtrlNode& mCtrl;
    
    //! MP7 TTC node reference
    const TTCNode& mTTC;

    //! MP7 Datapath master node
    const DatapathNode& mDatapath;

    static std::string getDefaultSharePath();

    static const std::string sharePath;

private:

    void populateIDs();
    
    //!
    const FormatterNode& mFmtNode;
    
    //!
    const MGTRegionNode& mMGTs;
    
    //!
    const ChanBufferNode& mBuffer;

    //!
    const AlignMonNode& mAlignMon;
    
    //!
    DatapathDescriptor mDescriptor;

    //!
    Generics mGenerics;


    static const size_t maxQuads;
    
    static const size_t maxNchans;

    friend class ChannelManager;
};

} // namespace mp7

#endif /* __MP7_MP7BASECONTROLLER_HPP__ */