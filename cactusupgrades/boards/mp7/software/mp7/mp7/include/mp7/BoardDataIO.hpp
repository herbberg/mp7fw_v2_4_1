/**
 * @file    BoardDataIO.hpp
 * @author  Tom Williams
 * @date    November 2014
 */

#ifndef __MP7_BOARDDATAIO_HPP__
#define __MP7_BOARDDATAIO_HPP__

#include <fstream>
#include <stdint.h>
#include <string>
#include <vector>

#include <boost/regex.hpp>
#include <boost/noncopyable.hpp>

#include "mp7/BoardData.hpp"


namespace mp7{

  //TODO: Definitely needs review. Current version is largely just copy-paste from Alessandro's RawReader class (github.com/alessandrothea)
  class BoardDataReader{
  public:
    BoardDataReader(const std::string& path);
    virtual ~BoardDataReader();

    mp7::BoardData get(size_t iBoard);

  private:
    void load(std::ifstream& file);

    std::string searchBoard(std::ifstream& file);

    std::vector<uint32_t> searchLinks(std::ifstream& file);
    std::vector<std::string> searchKinds(std::ifstream& file);
    std::vector<std::string> searchQuadChans(std::ifstream& file);

    std::vector< std::vector<mp7::Frame> > readRows(std::ifstream& file);

    std::vector<std::string> searchAndTokenize(std::ifstream& aFile, const boost::regex& aRegex);
    static mp7::Frame validStrToFrame(const std::string& token);

    bool mValid;
    const std::string mPath;
    std::vector<mp7::BoardData> mBuffers;

    static boost::regex mReBoard;
    static boost::regex mReLink;
    static boost::regex mReKind;
    static boost::regex mReQuadChan;
    static boost::regex mReFrame;
    static boost::regex mReValid;
  };


  class BoardDataWriter : public boost::noncopyable {
  public:
    BoardDataWriter(const std::string& aPath);
    virtual ~BoardDataWriter();

    void put(const BoardData& aBoardData);

  private:
    const std::string mPath;
    std::ofstream mFile;
  };

}


#endif /* __MP7_BOARDDATA_HPP__ */

