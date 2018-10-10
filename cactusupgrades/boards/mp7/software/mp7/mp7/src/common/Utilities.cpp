#include "mp7/Utilities.hpp"

// C++ Headers
#include <time.h>
#include <cstdarg>
#include <cstdlib>
#include <stdio.h>
#include <stdint.h>
#include <vector>
#include <wordexp.h>
#include <stdexcept>

// Boost Headers
#include "boost/foreach.hpp"
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>

// uHAL Headers
#include "uhal/ValMem.hpp"

// MP7 Headers
#include "mp7/Firmware.hpp"
#include "mp7/Logger.hpp"

using namespace std;
namespace l7 = mp7::logger;


namespace mp7 {


//-----------------------------------------------------------------------------
Snapshot
snapshot(const uhal::Node& aNode) {
    /// snapshot( node ) -> { subnode:value }
    std::map<string, uhal::ValWord<uint32_t> > valWords;

    for(string n :  aNode.getNodes()) {
        valWords.insert(make_pair(n, aNode.getNode(n).read()));
    }
    aNode.getClient().dispatch();

    Snapshot vals;
    std::map<string, uhal::ValWord<uint32_t> >::iterator it;
    for (it = valWords.begin(); it != valWords.end(); ++it)
        vals.insert(make_pair(it->first, it->second.value()));

    return vals;
}


//-----------------------------------------------------------------------------
Snapshot
snapshot(const uhal::Node& aNode, const std::string& aRegex) {
    std::map<string, uhal::ValWord<uint32_t> > valWords;

    for(string n :  aNode.getNodes(aRegex)) {
        valWords.insert(make_pair(n, aNode.getNode(n).read()));
    }
    aNode.getClient().dispatch();

    Snapshot vals;
    std::map<string, uhal::ValWord<uint32_t> >::iterator it;
    for (it = valWords.begin(); it != valWords.end(); ++it)
        vals.insert(make_pair(it->first, it->second.value()));

    return vals;
}


//-----------------------------------------------------------------------------
void
millisleep(const double& aTimeInMilliseconds) {
    //  using namespace uhal;
    //  logging();
    double lTimeInSeconds(aTimeInMilliseconds / 1e3);
    int lIntegerPart((int) lTimeInSeconds);
    double lFractionalPart(lTimeInSeconds - (double) lIntegerPart);
    struct timespec sleepTime, returnTime;
    sleepTime.tv_sec = lIntegerPart;
    sleepTime.tv_nsec = (long) (lFractionalPart * 1e9);
    nanosleep(&sleepTime, &returnTime);
}


//-----------------------------------------------------------------------------
std::string
strprintf(const char* fmt, ...) {
    char* ret;
    va_list ap;
    va_start(ap, fmt);
    vasprintf(&ret, fmt, ap);
    va_end(ap);
    std::string str(ret);
    free(ret);
    return str;
}


//-----------------------------------------------------------------------------
std::vector<std::string>
shellExpandPaths(const std::string& aPath) {

    std::vector<std::string> lPaths;
    wordexp_t lSubstitutedPath;
    int code = wordexp(aPath.c_str(), &lSubstitutedPath, WRDE_NOCMD);
    if (code) throw runtime_error("Failed expanding path: " + aPath);

    for (std::size_t i = 0; i != lSubstitutedPath.we_wordc; i++)
        lPaths.push_back(lSubstitutedPath.we_wordv[i]);

    wordfree(&lSubstitutedPath);

    return lPaths;
}


//-----------------------------------------------------------------------------
std::string
shellExpandPath(const std::string& aPath) {
    std::vector<std::string> lPaths = shellExpandPaths(aPath);

    if (lPaths.size() > 1) throw runtime_error("Failed to expand: multiple matches found");

    return lPaths[0];
}


//-----------------------------------------------------------------------------
void
fileExists(const std::string& aPath) {

    // FIXME: Review the implementation. The function never returns 
    namespace fs = boost::filesystem;

    // Check that the path exists and that it's not a directory
    fs::path cfgFile(aPath);
    if (!fs::exists(cfgFile)) {
        mp7::FileNotFound lExc(aPath + " does not exist!");
        throw lExc;
    } else if (fs::is_directory(cfgFile)) {
        mp7::CorruptedFile lExc(aPath + " is a directory!");
        throw lExc;
    }

    //    return true;
}


namespace xml {

//-----------------------------------------------------------------------------
pugi::xml_node
get_valid_node(const pugi::xml_node& aNode, const std::string& aPath) {
    pugi::xml_node node = aNode.first_element_by_path(aPath.c_str());

    if (node.empty()) {
        mp7::InvalidConfigFile e("Could not find node with path \"" + aNode.path() + "/" + aPath + "\" in xml config file");
        MP7_LOG(l7::kError) << e.what();
        throw e;
    } else
        return node;
}


//-----------------------------------------------------------------------------
bool
node_text_as_bool(const pugi::xml_node& node) {
    if (node.text().get() == std::string("true"))
        return true;
    else if (node.text().get() == std::string("false"))
        return false;
    else {
        std::ostringstream oss;
        oss << "Could not convert text \"" << node.text().get() << "\" for node \"" << node.path() << "\"";
        MP7_LOG(l7::kError) << oss.str();
        throw std::runtime_error(oss.str());
    }
}

} // namespace xml

} // namespace mp7


//-----------------------------------------------------------------------------
uint32_t locate(float xx[], unsigned long n, float x) {
    uint32_t j, ju, jm, jl;
    int ascnd;
    jl = 0; //Initialize lower
    ju = n + 1; //and upper limits.
    ascnd = (xx[n] >= xx[1]);

    while (ju - jl > 1) //If we are not yet done,
    {
        jm = (ju + jl) >> 1; //compute a midpoint,

        if ((x >= xx[jm]) == ascnd) // added additional parenthesis
        {
            jl = jm; //and replace either the lower limit
        } else {
            ju = jm; //or the upper limit, as appropriate.
        }
    } //Repeat until the test condition is satisﬁed.

    if (x == xx[1]) {
        j = 1; //Then set the output
    } else if (x == xx[n]) {
        j = n - 1;
    } else {
        j = jl;
    }

    return j;
}

