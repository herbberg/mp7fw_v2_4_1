
#include "mp7/BoardData.hpp"


#include <stdexcept>
#include <iomanip>

// Boost Headers
#include <boost/algorithm/string/classification.hpp>
#include <boost/algorithm/string/split.hpp>
#include <boost/algorithm/string/trim.hpp>
#include <boost/lexical_cast.hpp>
//#include <boost/foreach.hpp>
#include <boost/range/algorithm/copy.hpp>
#include <boost/range/adaptors.hpp>

// MP7 Headers
#include "mp7/BoardDataIO.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"

// Namespace Resolution
namespace l7 = mp7::logger;


// LinkData experimental area
namespace mp7 {

LinkData::LinkData() : 
  mStrobed(false) {
}

LinkData::LinkData(const std::vector<Frame>& aData)  :
  mStrobed(false),
  mData(aData) {
}

LinkData::LinkData(bool aStrobed, const std::vector<Frame>& aData) : 
  mStrobed(aStrobed),
  mData(aData) {
}

LinkData::LinkData(size_type n) :
  mStrobed(false),
  mData(n) {
}

LinkData::~LinkData() {

}


bool
LinkData::strobed() const {
  return mStrobed;
}

void
LinkData::setStrobed(bool aStrobed) {
  mStrobed = aStrobed;
}

void LinkData::resize(size_t aSize) {
  mData.resize(aSize);
}

size_t LinkData::size() const {
  return mData.size();
}

LinkData::value_type& LinkData::at(size_type n) {
  return mData.at(n);
}

const LinkData::value_type& LinkData::at(size_type n) const {
  return mData.at(n);
}

LinkData::value_type& LinkData::operator[](size_type n) {
  return mData.at(n);
}

const LinkData::value_type& LinkData::operator[](size_type n) const {
  return mData.at(n);
}

void LinkData::push_back(value_type item) {
  mData.push_back(item);
}

LinkData::iterator LinkData::begin() {
  return mData.begin();
}

LinkData::iterator LinkData::end() {
  return mData.end();
}

LinkData::const_iterator LinkData::begin() const {
  return mData.begin();
}

LinkData::const_iterator LinkData::end() const {
  return mData.end();
}


std::ostream& operator<<(std::ostream& theStream, const mp7::LinkData& data) {
  theStream << "[";

  for (size_t i = 0; i < data.size(); i++) {
    theStream << data.at(i);

    if (i != (data.size() - 1)) {
      theStream << ", ";
    }
  }

  theStream << "]";
  return theStream;
}

std::vector<uint32_t>
BoardData::links() const {
  std::vector<uint32_t> links;
  // Retrieve all keys
  boost::copy(mLinks | boost::adaptors::map_keys, std::back_inserter(links));
  return links;
}

const LinkData&
BoardData::link( uint32_t i) const {
  return mLinks.at(i);
}

LinkData&
BoardData::link( uint32_t i) {
  return mLinks.at(i);
}

LinkData&
BoardData::operator[]( uint32_t i) {
  return mLinks[i];
}

BoardData::BoardData(const std::string& name) :
  mName(name) {
}

bool 
BoardData::operator==(const BoardData& aRHS) const {
  bool equal = true;
  
  equal &= (
    size() == aRHS.size() and
    depth() == aRHS.depth() and
    name() == aRHS.name()
      );

  if ( !equal ) return false;

  mp7::BoardData::const_iterator it1 = begin();
  mp7::BoardData::const_iterator it2 = aRHS.begin();

  for (; it1 != end(); it1++, it2++) {
    for (size_t i = 0; i < depth(); i++) {
      const mp7::Frame& f1 = it1->second.at(i);
      const mp7::Frame& f2 = it2->second.at(i);

      if (f1 != f2) return false;
    }
  }

  return true;
}

const std::string&
BoardData::name() const {
  return mName;
}


//---
size_t
BoardData::size() const {
  return mLinks.size();
}


//---
size_t
BoardData::depth() const {
  size_t depth = ( size() != 0 ? mLinks.begin()->second.size() : 0 );

  
//  for (const_iterator it = mLinks.begin(); it != mLinks.end(); it++) {
//    if (depth != mLinks.begin()->second.size())
//      throw std::runtime_error("MP7 BoardData frame vectors do not have the same length for each link");
//  }

  return depth;
}


//---
void
BoardData::add(uint32_t i, const LinkData& aLink) {
  if ( find(i) != end()) {
    throw std::invalid_argument("Link " +to_string(i)+  " already present");
  }
  
  if ( size() != 0 and aLink.size() != depth() ) {
    throw std::length_error("Link size " + to_string(aLink.size()) + " differs from BoardData depth " + to_string(depth()));
  }
  
  mLinks[i] = aLink;
}


//---
std::vector<Frame>
BoardData::frame(uint32_t i) const {
  
  if ( i > depth() ) {
    throw std::out_of_range("Index " + to_string(i) + " out of range (0,"+to_string(depth())+")");
  }
  
  std::vector<Frame> frames;
  for( const LinkMap::value_type& p : mLinks ) {
    frames.push_back(p.second.at(i));
  }
  
  return frames;
  
  
}


//---
BoardData::const_iterator
BoardData::begin() const {
  return mLinks.begin();
}

BoardData::const_iterator
BoardData::end() const {
  return mLinks.end();
}

BoardData::iterator
BoardData::begin() {
  return mLinks.begin();
}

BoardData::iterator
BoardData::end() {
  return mLinks.end();
}

BoardData::const_iterator
BoardData::find(uint32_t i) const {
  return mLinks.find(i);
}


BoardData::iterator
BoardData::find(uint32_t i) {
  return mLinks.find(i);
}

void
BoardData::truncate(size_t depth) {
  for (BoardData::LinkMap::iterator it = this->mLinks.begin(); it != mLinks.end(); it++) {
    if (it->second.size() > depth)
      it->second.resize(depth);
  }
}



BoardData BoardDataFactory::generate(const std::string& uri, size_t depth, bool truncate) {
  BoardData data("");

  if (uri == "generate://empty") {
    data = BoardDataFactory::getEmptyEvent(depth);
  } else if (uri == "generate://pattern") {
    data = BoardDataFactory::getPatternEvent(depth);
  } else if (uri == "generate://3gpattern") {
    data = BoardDataFactory::get3gPatternEvent(depth);
  } else if (uri == "generate://orbitpattern") {
    data = BoardDataFactory::getOrbitPatternEvent();
  } else if (uri.find("generate://random") == 0) {
    std::vector<std::string> tokens;
    boost::split(tokens, uri, boost::is_any_of(":"));

    size_t packetSize = (tokens.size() > 2 ? boost::lexical_cast<size_t>(tokens.at(2)) : 0x80);
    size_t gapSize = (tokens.size() > 3 ? boost::lexical_cast<size_t>(tokens.at(3)) : packetSize);

    data = BoardDataFactory::getRandomEvent(depth, packetSize, gapSize);
  } else if (uri.find("file://") == 0) {
    std::vector<std::string> tokens;
    std::string suffix = uri.substr(7);
    boost::split(tokens, suffix, boost::is_any_of("?"));

    size_t iboard(tokens.size() > 1 ? boost::lexical_cast<size_t>(tokens.at(1)) : 0);

    data = BoardDataFactory::readFromFile(tokens.at(0), iboard);
  } else
    throw std::runtime_error(std::string("BoardDataFactory - \"") + uri + "\" is not a valid URI");

  if (truncate)
    data.truncate(depth);

  return data;
}



void BoardDataFactory::saveToFile(const BoardData& aData, const std::string& aPath) {
  MP7_LOG(l7::kInfo) << "Saving one board data object to file: " << aPath;
  BoardDataWriter writer(aPath);
  writer.put(aData);
}


BoardData BoardDataFactory::getEmptyEvent(size_t depth) {
  MP7_LOG(l7::kInfo) << "--Data: empty";
  BoardData dataEvent("empty");

  //TODO: Update so that nlinks is a const global / static member var of some central MP7 class (or of this factory class)
  const size_t nlinks = 72;
  for (size_t i = 0; i < nlinks; i++)
    dataEvent.add(i,LinkData(depth));
  return dataEvent;
}

BoardData BoardDataFactory::getPatternEvent(size_t depth) {
  // pattern is
  // Ipp, Channel, Frame
  // - 0xICCCFFFF
  MP7_LOG(l7::kInfo) << "--Data: pattern";
  BoardData dataEvent("pattern");

  //TODO: Update so that nlinks is a const global / static member var of some central MP7 class (or of this factory class)
  const size_t nlinks = 72;

  for (size_t c = 0; c < nlinks; c++) {
    LinkData link(depth);
    
    for (size_t k = 0; k < depth; k++) {
      link.at(k).valid = 1;
      link.at(k).data = (c << 16) | (k & 0xFFFF);
    }
    
    dataEvent.add(c, link);
  }

  return dataEvent;
}


//---
BoardData BoardDataFactory::get3gPatternEvent(size_t depth) {
  // pattern is
  // Ipp, Channel, Frame
  // - 0xICCCFFFF
  MP7_LOG(l7::kInfo) << "--Data: 3gpattern";
  BoardData dataEvent("pattern");

  //TODO: Update so that nlinks is a const global / static member var of some central MP7 class (or of this factory class)
  const size_t nlinks = 72;

  for (size_t c = 0; c < nlinks; c++) {
    LinkData link(depth);

    // Any decent 3G pattern should have the strobe logic enabled
    link.setStrobed(true);
    for (size_t k = 0; k < depth; k++) {
      link.at(k).strobe = 0;
      // Strobe low all the time. Use the strobe generator in the buffers
      // Data valid high everywhere
      link.at(k).valid = 1;
      // flipping bit 15, channel, cycle
      uint32_t data = ( ( (k+1)%2 ) << 15) | ((c & 0x7f) << 8) | (k & 0xFF);
      
      // put bc0 here
      data |= ( k<2) << 15;
      link.at(k).data = data;
      
      
    }
    
    dataEvent.add(c, link);
  }

  return dataEvent;
}

BoardData BoardDataFactory::getOrbitPatternEvent() {
  // pattern is
  // Ipp, Channel, Frame
  // - 0xICCCFFFF

  //TODO: In case used elsewhere, make static data/values within some central MP7 file (either const w/i mp7 namespace, parameters sub-namespace, or MP7Controller class)
  const size_t nquads = 18;
  const size_t nlinks = nquads * 4;

  MP7_LOG(l7::kInfo) << "--Data: orbitpattern";
  BoardData data("orbitpattern");

  // parameters
  size_t cycles = 9; // 9 MP tmt cycle
  size_t clockRatio = 6;
//  size_t orbitLen = 0xdec; //TODO: Check with Alessandro -- unused both here and in Python
  size_t cycleLen = cycles * clockRatio;
  size_t bufLen = 0x400;

  // # over-riding cyclelen
  // # cycle_len=0x400

  // ingredients
//  uint64_t valid = (uint64_t(1) << 32);
//  uint64_t hdr = 0xc0de0000 + valid;
//  uint64_t firstHdr = hdr + (1 << 12); // TODO: Check with Alessandro. The use of "+" here could push 13th bit to be high, and 12th bit low, in case 12th bit was already high - do we actually just want 12th bit high?? i.e. "&" instead

//    uint64_t valid = (uint64_t(1) << 32);
    Frame hdr, firstHdr;
    hdr.valid = true;
    hdr.data = 0xc0de0000;
    firstHdr.valid = true;
    firstHdr.data = (hdr.data | (1 << 12));

  
  size_t offset = 17;
  size_t payloadLen = 40;

  if ((payloadLen + 1) > cycleLen)
    throw std::runtime_error("Cannot fit payload in the cycle");

  for (size_t l = 0; l < nlinks; l++) {

  std::vector<Frame> cycle(cycleLen);
  // add the headers
  cycle.at(0) = hdr;
  // add the payload
  for (size_t i = 0; i < payloadLen; i++) {
    Frame& frame = cycle.at(i + 1);
    frame.data = (l<<24)+i;
    frame.valid = true;
  }

  // build the buffer
  std::vector<Frame> buf(offset);
  for (size_t i = 0; i < (bufLen / cycleLen); i++)
    buf.insert(buf.end(), cycle.begin(), cycle.end());

  // hack the header in the first bunch
  buf.at(offset) = firstHdr;

  if (buf.size() > bufLen)
    buf.resize(bufLen);

  // for (size_t l = 0; l < nlinks; l++)
    data.add(l,buf);
}
  return data;
}


//---
BoardData BoardDataFactory::getRandomEvent(size_t depth, size_t packetSize, size_t gapSize) {
  MP7_LOG(l7::kInfo) << "--Data: random";
  BoardData data("random");

  //TODO: Update so that nlinks is a const global / static member var of some central MP7 class (or of this factory class)
  const size_t nlinks = 72;

  for (size_t c = 0; c < nlinks; c++) {

    LinkData link(depth);

    // uint64_t should be equal to zero in gap, so can just skip assignment there
    for (size_t i = 0; i < depth; i += (packetSize + gapSize)) {
      for (size_t j = i; j < i + packetSize; j++) {
        if (j >= depth)
          break;
        Frame& frame = link.at(j);
        frame.valid = true;
        frame.data = ((rand() & 0xFFFF) << 16) | (rand() & 0xFFFF);
        
//        buf.at(j) = (uint64_t(1) << 32) | ((uint64_t(rand()) & 0xFFFF) << 16) | (uint64_t(rand()) & 0xFFFF);
      }
    }
    
    data.add(c, link);
  }

  return data;
}

BoardData BoardDataFactory::readFromFile( const std::string& filename, size_t iboard) {
  BoardDataReader fileReader(filename);

  return fileReader.get(iboard);
}

}
