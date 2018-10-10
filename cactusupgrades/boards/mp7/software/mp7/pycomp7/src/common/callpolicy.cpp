#include "mp7/python/callpolicy.hpp"

boost::unordered_map<boost::thread::id, PyThreadState*> pycomp7::release_gil_policy::_theHorribleMap;