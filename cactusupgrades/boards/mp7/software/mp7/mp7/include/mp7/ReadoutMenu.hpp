#ifndef __MP7__READOUTMENU__HPP__
#define __MP7__READOUTMENU__HPP__

#include <stddef.h>
#include <stdint.h>
#include <vector>
#include <sstream>


namespace mp7 {

/**
 * @class ReadoutMenu
 */
class ReadoutMenu {
public:

  /**
   * @brief      Back configuration descriptor.
   */
  class Bank {
  public:
    uint32_t wordsPerBx;
  };
  

  /**
   * @brief      Capture configuration descriptor.
   */
  class Capture {
  public:
    bool enable;
    uint32_t id;
    uint32_t bankId;
    uint32_t length;
    uint32_t delay;
    uint32_t readoutLength;
  };

  /**
    * @brief      Trigger mode configuration descriptor 
    */ 
  class Mode {
  public:
    typedef std::vector<Capture>::iterator iterator;
    typedef std::vector<Capture>::const_iterator const_iterator;

    /**
     * @brief      Constructor
     *
     * @param[in]  aSize  Number of caputure modes in this mode.
     */
    Mode( size_t aSize );

    //! Size of the event
    uint32_t eventSize;

    //! Event number to trigger on
    uint32_t eventToTrigger;
    
    //! Event type tag
    uint32_t eventType;

    /**
     * @brief      Comparison operator
     *
     * @param[in]  aOther  Object to compare this to
     */
    void operator=( const Mode& aOther );
    
    /**
     * @brief      Capture mode access operator.
     *
     * @param[in]  i     Capture mdoe index.
     *
     * @return     Capture mode object.
     */
    Capture& operator[]( size_t i );

    /**
     * @brief      Capture mode const access operator.
     *
     * @param[in]  i     Capture mdoe index.
     *
     * @return     Capture mode const object.
     */
    const Capture& operator[]( size_t i ) const;

    /**
     * @brief      Retunrs number of capture modes belonging to this trigger
     *             mode.
     *
     * @return     Number of capture modes.
     */
    size_t size() const;
    
    iterator begin() { return mCaptures.begin(); }
    const_iterator begin() const { return mCaptures.begin(); }
    iterator end() { return mCaptures.end(); }
    const_iterator end() const { return mCaptures.end(); }
    

  private:
    std::vector<Capture> mCaptures;

    friend class ReadoutMenu;
  };


  /**
   * @brief      Readout menu constructor.
   *
   * @param[in]  aNBanks     Number of banks
   * @param[in]  aNModes     Number of modes
   * @param[in]  aNCaptures  Number of captures
   */
  ReadoutMenu(size_t aNBanks, size_t aNModes, size_t aNCaptures);

  ~ReadoutMenu();

  size_t numBanks() const;

  size_t numModes() const;
  
  size_t numCaptures() const;  

  Bank& bank( size_t i );

  const Bank& bank( size_t i ) const;

  Mode& mode( size_t i );
  
  const Mode& mode( size_t i ) const;
  
  Capture& capture( size_t aMode, size_t aCap );

  const Capture& capture( size_t aMode, size_t aCap ) const;

  void setMode(uint32_t aMode, const Mode& aOther);

private:
  //! Number of Banks used by the menu
  const size_t mNumBanks;

  //! Number of trigger modes in the menu
  const size_t mNumModes;

  //! Number of capture mode per trigger mode
  const size_t mNumCaptures;

  std::vector<Mode> mModes;

  std::vector<Bank> mBanks;
  
};

std::ostream& operator<<( std::ostream& oStream, const ReadoutMenu::Bank& aBank );
std::ostream& operator<<( std::ostream& oStream, const ReadoutMenu::Mode& aMode );
std::ostream& operator<<( std::ostream& oStream, const ReadoutMenu::Capture& aCapture );
std::ostream& operator<<( std::ostream& oStream, const ReadoutMenu& aMenu );

class ReadoutMenuValidator
{
public:
    ReadoutMenuValidator( const ReadoutMenu& aMenu );
    void verify() const;

private:
    const ReadoutMenu& mMenu;
};
} // namespace mp7

#endif /* __MP7__READOUTMENU__HPP__ */