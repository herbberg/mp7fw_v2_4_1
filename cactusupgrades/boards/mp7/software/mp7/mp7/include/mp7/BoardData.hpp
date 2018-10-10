/**
 * @file    BoardData.hpp
 * @author  Tom Williams
 * @date    October 2014
 */

#ifndef __MP7_BOARDDATA_HPP__
#define __MP7_BOARDDATA_HPP__

#include <map>
#include <stdint.h>
#include <string>
#include <vector>

#include "mp7/Frame.hpp"
#include "mp7/definitions.hpp"


namespace mp7 {

  // Forward declaration
  class BoardDataFactory;
  class BoardDataReader;
  class MP7Controller;

  /**
   * @class LinkData
   * @brief 12345
   */
  class LinkData {
  public:

    typedef std::vector<Frame> vector_type;
    // typedef vector_type::difference_type difference_type;
    typedef vector_type::size_type size_type;
    typedef vector_type::value_type value_type;
    typedef vector_type::iterator iterator;
    typedef vector_type::const_iterator const_iterator;

    LinkData();
    LinkData( const std::vector<Frame>& aData);
    LinkData( bool aStrobed, const std::vector<Frame>& aData);
    LinkData( size_type n );
    ~LinkData();
      
    virtual bool strobed() const;
    virtual void setStrobed( bool aStrobed = true );

    virtual size_t size() const;
    virtual void resize( size_t aSize );
    virtual void push_back( value_type item);
    virtual value_type& at( size_type n );
    virtual const value_type& at( size_type n ) const;
    virtual value_type& operator[]( size_type n );
    virtual const value_type& operator[]( size_type n ) const;

    // iterator insert (iterator position, const value_type& val) { return mData.insert(position, val);}
    // iterator erase (iterator position) { return mData.erase(position);}

    virtual iterator begin();
    virtual iterator end();
    virtual const_iterator begin() const;
    virtual const_iterator end() const;
  private:
    bool mStrobed;
    std::vector<Frame> mData;

    
  };

  std::ostream& operator<<(std::ostream& theStream, const mp7::LinkData& data);
  
  /**
   * @class BoardData
   * @brief Storage class for MP7 buffer data (buffer contents over multiple bx for each link)
   */
  class BoardData {
  public:
    typedef std::map<uint32_t, LinkData > LinkMap;
    typedef LinkMap::value_type value_type;
    typedef LinkMap::iterator iterator;
    typedef LinkMap::const_iterator const_iterator;

    const std::string& name() const;

    std::vector<uint32_t> links() const;
    
    //! Returns const reference to data for link of specified ID; throws if that link doesn't exist yet
    const LinkData& link( uint32_t i) const;

    //! Returns reference to data for link of specified ID; throws if that link doesn't exist yet
    LinkData& link( uint32_t i);

    //! Returns reference to data for link of specified ID, and creates new entry for that link if it doesn't exist yet
    LinkData& operator[]( uint32_t i);

    // Comparison
    bool operator==( const BoardData& aRHS ) const;
    
    iterator find( uint32_t i ); 
    const_iterator find( uint32_t i ) const; 

    void add( uint32_t i, const LinkData& aLink );

    ///! Returns number of links
    size_t size() const;

    ///! Returns number of words/frames of data on each link; throws if this number is not the same for each link
    size_t depth() const;

    std::vector<Frame> frame( uint32_t i ) const;

    const_iterator begin() const;
    const_iterator end() const;

    iterator begin();
    iterator end();

    BoardData(const std::string& name);

  private:
    void truncate(size_t depth);

    std::string mName;
    LinkMap mLinks;

    friend class BoardDataFactory;
    friend class BoardDataReader;
  };


  /**
   * @class BoardDataFactory
   * @brief Class to provide properly formatted data for the MP7 input buffers
   */
  class BoardDataFactory {
  public:
    /**
     * @brief Creates a BoardData filled with a user-defined pattern
     * @details [long description]
     * 
     * @param uri [description]
     * @param depth [description]
     * @param truncate [description]
     * @return [description]
     */
    static BoardData generate(const std::string& uri, size_t depth=0x400, bool truncate=false);

    static void saveToFile(const BoardData& aData, const std::string& aPath);
    static BoardData readFromFile( const std::string& filename, size_t iboard = 0);

  private:
    BoardDataFactory(){}

    /**
     * @brief Creates an empty event.
     * 
     * @param depth Size of the event in terms of frames
     * @return BoardData containing an empty event.
     */
    static BoardData getEmptyEvent(size_t depth);

    /**
     * @brief Creates an pattern event.
     * 
     * @param depth Size of the event in terms of frames
     * @return BoardData containing an pattern event.
     */
    static BoardData getPatternEvent(size_t depth);

    /**
     * @brief [Creates an 3G (strobed, 80Mhz) pattern event.
     * 
     * @param depth Size of the event in terms of frames
     * @return BoardData containing an 3G pattern event.
     */
    static BoardData get3gPatternEvent(size_t depth);

    static BoardData getOrbitPatternEvent();
    static BoardData getRandomEvent(size_t depth, size_t packetSize, size_t gapSize);
  };

}


#endif /* __MP7_BOARDDATA_HPP__ */

