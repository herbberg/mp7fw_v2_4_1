
#include <cassert>
#include <iostream>
#include <iomanip>

#include "mp7/BoardData.hpp"
#include "mp7/Logger.hpp"

using std::cout;
using std::endl;
namespace l7 = mp7::logger;

int main(int argc, char * argv[]) {

  if (argc != 2) {
    cout << "ERROR: This test exe should take one argument - the URL for generating the BoardData object" << endl;
    return 1;
  }

  std::string url(argv[1]);
  cout << "Board data will be generated with URL \"" << url << "\"" << endl;

  l7::Log::setLogThreshold(l7::kDebug);


  mp7::BoardData data1 = mp7::BoardDataFactory::generate(url);

  std::string path("testBoardData.txt");
  mp7::BoardDataFactory::saveToFile(data1, path);

  mp7::BoardData data2 = mp7::BoardDataFactory::generate("file://" + path);

  assert(data1.size() == data2.size());

  assert(data1.depth() == data2.depth());

  assert(data1.name() == data2.name());

  mp7::BoardData::const_iterator it1 = data1.begin();
  mp7::BoardData::const_iterator it2 = data2.begin();

  mp7::Frame a, b;
  assert(a == b);
  for (; it1 != data1.end(); it1++, it2++) {
    for (size_t i = 0; i < data1.depth(); i++) {
      const mp7::Frame& f1 = it1->second.at(i);
      const mp7::Frame& f2 = it2->second.at(i);

      if (f1 != f2) {


        std::cout << "ERROR: Data mismatch at frame " << i
            << " ... orig value:"
            << std::setw(1) << f1.valid << "v" << std::setw(8) << std::hex << (f1.data) << std::dec
            << "  from file:"
            << std::setw(1) << f2.valid << "v" << std::setw(8) << std::hex << (f2.data) << std::dec;
        return 1;
      }
    }
  }

  return 0;
}

