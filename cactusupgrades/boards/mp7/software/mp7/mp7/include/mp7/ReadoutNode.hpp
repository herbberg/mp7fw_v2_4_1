/**
 * @file ReadoutControlNode.hpp
 * @author Alessandro Thea
 * @date 2015
 */

#ifndef MP7READOUT_NODE_HPP
#define MP7READOUT_NODE_HPP

#include "uhal/DerivedNode.hpp"
#include "mp7/exception.hpp"
#include "definitions.hpp"

// C++ Headers
#include <vector>

namespace mp7 {

class ReadoutCtrlNode;

/**
 * @brief      TTS counters containers.
 */
struct TTSStateCounters {
  uint64_t uptime;
  uint64_t busy;
  uint64_t ready;
  uint64_t warn;
  uint64_t oos;
};


class ReadoutNode : public uhal::Node {
  UHAL_DERIVEDNODE(ReadoutNode);
public:

  enum EventSource {
    kReadoutEventSource,
    kFakeEventSource
  };

  /**
   * @brief      Constructuctor.
   *
   * @param[in]  aNode  Raw uhal::Node.
   */
  ReadoutNode(const uhal::Node& aNode);
  
  /**
   * @brief      Destroys the object.
   */
  virtual ~ReadoutNode();

  /**
   * @brief      Control node getter.
   *
   * @return     Reference to the ReadoutControlNode.
   */
  const ReadoutCtrlNode& getControl() const;

  void selectEventSource(EventSource aSource) const;

  void enableAMC13Output(bool aEnable = true) const;

  void enableAutoDrain(bool aEnable = true, uint32_t aRate = 0x3) const;

  void forceTTSState( bool aForce, uint32_t aState = 0x0 ) const;
  
  void setBxOffset( uint32_t aOffset ) const;
  
  void start() const;

  void stop() const;

  /**
   * @brief      Set fake event size in 64 bit workds
   *
   * @param      aSize  Size in 64 bit word units
   */
  void configureFakeEventSize( uint32_t aSize ) const;

  /**
   * @brief      Set the Readout fifo watermarks
   *
   * The values are in some units I still have to figure out. 64 = 100%
   *
   * @param      aLowWM   Fifo low water mark in some strange units
   * @param      aHighWM  Fifo high water mark in some strange units
   */
  void setFifoWaterMarks( uint32_t aLowWM, uint32_t aHighWM ) const;

  /**
   * @brief      Resets AMC13 core in the Mp7
   */
  void resetAMC13Block() const;

  /**
   * @brief      Status of the AMC13 connection
   *
   * @return     True if the connection to AMC13 is established
   */
  bool isAMC13LinkReady() const;

  uint32_t readEventCounter() const;
  
  TTSStateCounters readTTSCounters() const;

  uint64_t readUptimeCounts() const;
  
  uint64_t readBusyCounts() const;

  uint64_t readReadyCounts() const;

  uint64_t readWarnCounts() const;

  uint64_t readOOSCounts() const;

  TTSState readTTSState() const;
  
  /**
   * @brief Checks the emptiness status of the fifo
   * @return True if the readout Fifo is empty
   */
  bool isFifoEmpty() const;
  
  bool isFifoFull() const;
  
  uint32_t readFifoOccupancy() const;

  /**
   * @brief Reads the full Fifo content, until it reports Fifo empty
   * @return Vector of 64bits words
   */
  std::vector<uint64_t> readFifo() const;

  std::vector<uint64_t> readEvent() const;

protected:

  struct FifoEntry {
    uint64_t data;

    // data flags  
    bool dataStart;
    bool dataVal;
    bool dataStartDlyd;
    bool dataValDlyd;
    bool dataHdr;
    bool dataTrl;

    // fifo flags
    bool fifoValid;
    bool fifoEmpty;
    bool fifoWarning;
    bool fifoFull;
  };

  FifoEntry readFifoEntry() const;

};

MP7ExceptionClass(FifoError, "Exception class to handle Fifo Exceptions");


} // namespace mp7



#endif /* MP7READOUT_CONTROL_NODE_HPP */