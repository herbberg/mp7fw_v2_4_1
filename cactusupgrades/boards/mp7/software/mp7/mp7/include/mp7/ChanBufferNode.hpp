/* 
 * File:   BufferManager.hpp
 * Author: ale
 *
 * Created on May 5, 2014, 11:04 AM
 */

#ifndef __MP7_CHANBUFFERNODE_HPP__
#define	__MP7_CHANBUFFERNODE_HPP__

// uHAL Headers
#include "uhal/DerivedNode.hpp"
#include "mp7/BoardData.hpp"
#include "mp7/Orbit.hpp"

namespace mp7 {


class ChanBufferNode : public uhal::Node {
    UHAL_DERIVEDNODE(ChanBufferNode);
public:

    // PUBLIC ENUMS

    enum BufMode {
        kLatency = 0, // Latency buffer
        kCapture = 1, // Capture buffer
        kPlayOnce = 2, // Playback
        kPlayLoop = 3 // Repeating playback
    };

    enum DataSrc {
        kInputData = 0, // input data
        kBufferData = 1, // buffer playback
        kPatternData = 2, // Hard-coded pattern
        kZeroData = 3 // 
    };

    enum StrobeSrc {
        kInputStrobe = 0,
        kBufferStrobe = 1,
        kPatternStrobe = 2,
        kOverrideStrobe = 3
    };

    struct Configuration {
      BufMode mode;
      DataSrc datasrc;
      StrobeSrc stbsrc;
      uint32_t patternValidMask;
      uint32_t captureStrobeOverride;
      uint32_t strobePattern;
    };

    ChanBufferNode(const uhal::Node& aNode);
    virtual ~ChanBufferNode();

    /// returns the current buffer size
    size_t getBufferSize() const;

    /// Get current buffer mode
    BufMode readBufferMode() const;

    /** 
     * Get datasrc for the current buffer
     * @return [description]
     */
    DataSrc readDataSrc() const;

    /** 
     * Get stbsrc for the current buffer
     * @return [description]
     */
    StrobeSrc readStrobeSrc() const;

    
    /**
     *  Wait for the buffer capture to be completed
     */
    void waitCaptureDone() const;
    
    /**
     * Queries the capture status
     * @return true if a capture was performed
     */
    bool hasCaptured() const;

    /**
     * Configures the buffer/datapath
     * @param aConfig Configuration object
     */
    void configure( const Configuration& aConfig ) const;
    
    /**
     * Reads the current configuration from file
     * @return 
     */
    Configuration readConfiguration() const;

    uint32_t readDAQBank() const;

    uint32_t readMaxWord() const;

    void writeDAQBank( uint32_t aBank ) const;

    void writeMaxWord( uint32_t aMaxWord ) const;
    
    void writeTrigPoint( const orbit::Point& aTrigPoint ) const;
    
    /**
     * Clears the buffer RAM by filling it with zeroes
     */
    void clear() const;

    void upload(const mp7::LinkData& aData) const;

    LinkData download(size_t aSize) const;
    
    std::vector<uint32_t> readRaw(size_t aSize) const;
    
    void writeRaw(std::vector<uint32_t> aRawData) const;

private:

    size_t mSize;

};


}

#endif	/* __MP7_CHANBUFFERNODE_HPP__ */

