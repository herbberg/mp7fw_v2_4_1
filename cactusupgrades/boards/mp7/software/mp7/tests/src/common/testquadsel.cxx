#include <cstdlib>

#include "uhal/uhal.hpp"
//#include "uhal/log/log.hpp"

#include "mp7/CtrlNode.hpp"

#include "mp7/CommandSequence.hpp"
#include "mp7/MGTRegionNode.hpp"
#include "mp7/Utilities.hpp"
#include "mp7/MP7Controller.hpp"


using namespace std;

/*
 *
 */
int main(int argc, char** argv) {
    uhal::setLogLevelTo(uhal::Warning());
    uhal::ConnectionManager cm("file://${MP7_TESTS}/etc/mp7/connections-904.xml;file://${MP7_TESTS}/etc/mp7/connections-test.xml");
    // uhal::HwInterface board = cm.getDevice("MP7_CERN_MAC93_CH_MYMGT");
    mp7::MP7Controller board(cm.getDevice("MP7XE_TUNNEL_CH_MAC95"));
    uhal::setLogLevelTo(uhal::Info());

//    std::cout << board.getLinkIDs().available().size() << endl;
//    mp7::getLogger(mp7::kNotice) <<  "Reset Clocking" << mp7::push;
//    board.reset("si570", false, true);
    

}


