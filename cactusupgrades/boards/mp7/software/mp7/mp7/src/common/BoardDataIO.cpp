
#include "mp7/BoardDataIO.hpp"


#include <stdexcept>
#include <iomanip>

#include "boost/algorithm/string/classification.hpp"
#include "boost/algorithm/string/split.hpp"
#include "boost/algorithm/string/trim.hpp"
#include "boost/lexical_cast.hpp"

//#include <boost/foreach.hpp>

#include "mp7/Logger.hpp"

// Namespace Resolution
namespace l7 = mp7::logger;

namespace mp7 {
boost::regex BoardDataReader::mReBoard("^Board (.+)");
boost::regex BoardDataReader::mReLink("^Link : (.*)");
boost::regex BoardDataReader::mReKind("^Kind : (.*)");
boost::regex BoardDataReader::mReQuadChan("^Quad/Chan : (.*)");
boost::regex BoardDataReader::mReFrame("^Frame (\\d{4}) : (.*)");
// boost::regex BoardDataReader::mReValid("(([01])s)?(([01])v)([0-9a-fA-F]{8})");
boost::regex BoardDataReader::mReValid("([01]s)?([01]v)([0-9a-fA-F]{8})");

BoardDataReader::BoardDataReader(const std::string& path) :
  mValid(false),
  mPath(path) {
  std::ifstream file(path);
  if (!file.is_open()) {
    MP7_LOG(l7::kError) << "File \"" << path << "\" not found";
    return;
  }

  load(file);
}

BoardDataReader::~BoardDataReader() {
}

BoardData
BoardDataReader::get(size_t iBoard) {
  return mBuffers.at(iBoard);
}

void
BoardDataReader::load(std::ifstream& file) {
  MP7_LOG(l7::kInfo) << "Loading board data from file \"" << mPath << "\"";

  while (file.good()) {
    std::string id(searchBoard(file));

    MP7_LOG(l7::kInfo) << "Loading data - Id: " << id;
    std::vector<std::string> qchs = searchQuadChans(file);
    std::vector<std::string> kinds = searchKinds(file);
    std::vector<uint32_t> links = searchLinks(file);

    MP7_LOG(l7::kDebug) << "    BoardData Links (" << links.size() << ") : " << l7::vecFmt(links);

    std::vector< std::vector<mp7::Frame> > dataRows = readRows(file);

    // Id, link # and Data loaded
    MP7_LOG(l7::kDebug) << "    BoardData loaded (" << dataRows.size() << " frames)";

    // Transpose
    std::vector< std::vector<mp7::Frame> > chans(links.size(), std::vector<mp7::Frame>(dataRows.size()));
    for (size_t i = 0; i < links.size(); i++)
      for (size_t j = 0; j < dataRows.size(); j++)
        chans.at(i).at(j) = dataRows.at(j).at(i);

    // Pack
    BoardData s(id);
    for (size_t i = 0; i < links.size(); i++)
      s.mLinks[links.at(i)] = chans.at(i);
    mBuffers.push_back(s);
  }

  // File successfully read
  mValid = true;
}


//---
std::string
BoardDataReader::searchBoard(std::ifstream& file) {
  std::string line, id;
  boost::smatch what;

  while (getline(file, line)) {
    // Trim and skip empties and comments
    boost::trim(line);
    if (line.empty())
      continue;
    if (line[0] == '#')
      continue;
    if (boost::regex_match(line, what, mReBoard)) {
      // Create a new buffer snapshot
      id = what[1];
      return id;
    } else 
      throw std::logic_error("Unexpected line found!\n"+line);
  }
  throw std::logic_error("No board found");
}


//---
std::vector<std::string>
BoardDataReader::searchAndTokenize(std::ifstream& aFile, const boost::regex& aRegex) {
  std::string line;
  boost::smatch what;

  while (getline(aFile, line)) {
    boost::trim(line);

    if (line.empty()) {

      continue;

    } else if (line[0] == '#') {

      continue;
    } else if (boost::regex_match(line, what, aRegex)) {
      std::vector<std::string> tokens;
      std::string tmp(what[1]);
      // Trim the line
      boost::trim(tmp);
      // Split the line into tokens
      boost::split(tokens, tmp, boost::is_any_of(" \t"), boost::token_compress_on);
      return tokens;
    } else
      throw std::logic_error("Unexpected line found!\n"+line);
  }
  throw std::logic_error("Couldn't find any line matching: " + aRegex.str());
}


//---
std::vector<std::string>
BoardDataReader::searchQuadChans(std::ifstream& aFile) {
  return searchAndTokenize(aFile, mReQuadChan);
}


//---
std::vector<std::string>
BoardDataReader::searchKinds(std::ifstream& aFile) {
  int pos = aFile.tellg();
  try {
    return searchAndTokenize(aFile, mReKind);
  } catch (std::logic_error & e) {
    // If there is not such a line, return an empty vector
    aFile.seekg(pos);
    return std::vector<std::string>();
  }
}


//---
std::vector<uint32_t>
BoardDataReader::searchLinks(std::ifstream& aFile) {

  std::vector<std::string> tokens = searchAndTokenize(aFile, mReLink);
  std::vector<uint32_t> links;
  std::transform(tokens.begin(), tokens.end(), std::back_inserter(links), boost::lexical_cast<uint32_t, const std::string&>);
  return links;
}


//---
std::vector< std::vector<mp7::Frame> >
BoardDataReader::readRows(std::ifstream& file) {
  std::string rawline,line;
  boost::smatch what;
  std::vector< std::vector<mp7::Frame> > data;
  int place = file.tellg();
  while (getline(file, rawline)) {
    
    line = rawline;

    // bit of cleanup
    boost::trim(line);

    if (line.empty() || line[0] == '#') {
      // do nothing
    } else if (boost::regex_match(line, what, mReBoard)) {
      // Oops, next board found. Go back by one line
      file.seekg(place);
      return data;
    } else if (boost::regex_match(line, what, mReFrame)) {
      // ok, it's a new frame, wint all bells and whistles
      uint32_t n = boost::lexical_cast<uint32_t>(what[1].str());

      if (n != data.size()) {
        std::stringstream ss;
        ss << "Frame misalignment! (expected " << data.size() << " found " << n;
        throw std::logic_error(ss.str());
      }

      std::vector<std::string> tokens;
      std::string tmp(what[2].str());
      boost::trim(tmp);
      boost::split(tokens, tmp, boost::is_any_of(" \t"), boost::token_compress_on);

      std::vector<mp7::Frame> row;
      std::transform(tokens.begin(), tokens.end(), std::back_inserter(row), validStrToFrame);

      data.push_back(row);
    } else
      throw std::logic_error("Unexpected line found!\n"+rawline);
    

    place = file.tellg();
  }

  return data;
}


//---
mp7::Frame
BoardDataReader::validStrToFrame(const std::string& token) {
  boost::smatch what;
  if (!boost::regex_match(token, what, mReValid))
    throw std::logic_error("Token '" + token + "' doesn't match the valid format");

  mp7::Frame value;
  // Import strobe if the strobe group is matched
  if ( what[1].matched ) {
    // value.strobe = (what[2] == "1");
    value.strobe = (what[1] == "1s");

  }

  // value.valid = (what[4] == "1");
  // value.valid = (what[3] == "1v");
  value.valid = (what[2] == "1v");

  // value.data = std::stoul(what[5].str(), 0x0, 16);
  value.data = std::stoul(what[3].str(), 0x0, 16);

  return value;
}


//---
BoardDataWriter::BoardDataWriter(const std::string& aPath) :
  mPath(aPath),
  mFile(aPath) {
  if (!mFile.is_open()) {
    MP7_LOG(l7::kError) << "File \"" << aPath << "\" not found";
    return;
  }
}


//---
BoardDataWriter::~BoardDataWriter() {
}


//---
void 
BoardDataWriter::put(const BoardData& aBoardData) {
  MP7_LOG(l7::kDebug) << "Writing board data \"" << aBoardData.name() << "\" to file \"" << mPath << "\"";

  mFile << std::setfill('0');

  // Board name/id
  mFile << "Board " << aBoardData.name() << std::endl;

  // Quad/chan header
  mFile << " Quad/Chan :";
  for( const BoardData::value_type& p : aBoardData) {
    if ( p.second.strobed() ) mFile << " ";

    mFile << "    q" << std::setw(2) << (p.first) / 4 << 'c' << std::setw(1) << (p.first) % 4 << "  ";
    if ( p.second.strobed() ) mFile << " ";

  }
  mFile << std::endl;

  // Link header
  mFile << "      Link :";
  for( const BoardData::value_type& p : aBoardData) {
    if ( p.second.strobed() ) mFile << " ";

    mFile << "     " << std::setw(2) << p.first << "    ";
    if ( p.second.strobed() ) mFile << " ";


  }
  mFile << std::endl;

  // Frames
  for (size_t i = 0; i < aBoardData.depth(); i++) {
    mFile << "Frame " << std::setw(4) << i << " :";
    for (BoardData::const_iterator linkIt = aBoardData.begin(); linkIt != aBoardData.end(); linkIt++) {
      const mp7::Frame& dataWord = linkIt->second.at(i);
      mFile << " "; 
      if ( linkIt->second.strobed() ) {
        mFile << std::setw(1) << (dataWord.strobe) << "s";
      }
      mFile << std::setw(1) << (dataWord.valid) << "v" << std::setw(8) << std::hex << (dataWord.data) << std::dec;
    }
    mFile << std::endl;
  }
}

} // namespace mp7
