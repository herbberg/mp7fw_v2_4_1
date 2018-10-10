/* 
 * File:   testRegionInfo.cxx
 * Author: ale
 *
 * Created on August 2, 2015, 3:38 PM
 */

#include <cstdlib>

#include "mp7/DatapathNode.hpp"
#include "mp7/Logger.hpp"
#include "mp7/MP7Controller.hpp"

//#include <boost/foreach.hpp>
#include <boost/bind.hpp>
#include <boost/lambda/lambda.hpp>
#include <boost/phoenix/bind/bind_member_variable.hpp>

#include <uhal/uhal.hpp>


using namespace std;


bool canDoLoopback( const mp7::RegionInfo& aInfo ) {
  return (aInfo.mgtIn == aInfo.mgtOut)
    and ( aInfo.chkIn == aInfo.chkOut ) 
    and aInfo.bufOut != mp7::kNoBuffer;
}

/*
 * 
 */
int main(int argc, char** argv) {

  uhal::setLogLevelTo(uhal::WarningLevel());
  mp7::logger::Log::setLogThreshold(mp7::logger::kDebug);
  
  if ( argc != 3 ) {
    return -1;
  }
  
  uhal::ConnectionManager cm(argv[1]);
  uhal::HwInterface hw = cm.getDevice(argv[2]);
  
  const mp7::CtrlNode& ctrl = hw.getNode<mp7::CtrlNode>("ctrl");
  const mp7::DatapathNode& dp = hw.getNode<mp7::DatapathNode>("datapath");
  
  auto regions = ctrl.readRegions();
  auto regMap = dp.readRegionInfoMap(regions);
  
  for( auto it :  regMap) {
    MP7_LOG(mp7::logger::kDebug) << it.first 
      << " iMGT=" << it.second.mgtIn 
      << " iChk=" << it.second.chkIn
      << " iBuf=" << it.second.bufIn 
      << " fmt=" << it.second.fmt 
      << " oBuf=" << it.second.bufOut 
      << " oChk=" << it.second.chkOut
      << " oMGT=" << it.second.mgtOut;
  }
  
  mp7::DatapathDescriptor sel( regMap );
  
  mp7::ChannelGroup noIMgt = sel.pickRxMGTIDs( mp7::kNoMGT );
  mp7::ChannelGroup noOMgt = sel.pickTxMGTIDs( mp7::kNoMGT );
  mp7::ChannelGroup iGth10 = sel.pickRxMGTIDs( mp7::kGth10g );
  mp7::ChannelGroup oGth10 = sel.pickTxMGTIDs( mp7::kGth10g );

  MP7_LOG(mp7::logger::kInfo) << "No iMGT :" 
      << " regions " << mp7::logger::shortVecFmt(noIMgt.regions())
      << " chans " << mp7::logger::shortVecFmt(noIMgt.channels())
      ;
    MP7_LOG(mp7::logger::kInfo) << "iMGT 10G :" 
      << " regions " << mp7::logger::shortVecFmt(iGth10.regions())
      << " chans " << mp7::logger::shortVecFmt(iGth10.channels())
      ;
  MP7_LOG(mp7::logger::kInfo) << "No oMGT :"
      << " regions " << mp7::logger::shortVecFmt(noOMgt.regions())
      << " chans " << mp7::logger::shortVecFmt(noOMgt.channels())
      ; 
  MP7_LOG(mp7::logger::kInfo) << "oMGT 10G :"
      << " regions " << mp7::logger::shortVecFmt(oGth10.regions())
      << " chans " << mp7::logger::shortVecFmt(oGth10.channels())
      ; 
  
  mp7::ChannelGroup loop = sel.pickIDs( 
    ( boost::bind(&mp7::RegionInfo::mgtIn, _1) == boost::bind(&mp7::RegionInfo::mgtOut, _1) ) and
    ( boost::bind(&mp7::RegionInfo::chkIn, _1) == boost::bind(&mp7::RegionInfo::chkOut, _1) ) and 
    ( boost::bind(&mp7::RegionInfo::bufIn, _1) != mp7::kNoBuffer )
    );

  // sel.pick( canDoLoopback );
  MP7_LOG(mp7::logger::kInfo) << "Loopback capable group:"
    << " regions " << mp7::logger::shortVecFmt(loop.regions())
    << " chans " << mp7::logger::shortVecFmt(loop.channels())
    ; 
  
  std::vector<uint32_t> lMask = {1};
  mp7::DatapathDescriptor sel2(sel, lMask);
  mp7::ChannelGroup loop2 = sel2.pickIDs( 
    ( boost::bind(&mp7::RegionInfo::mgtIn, _1) == boost::bind(&mp7::RegionInfo::mgtOut, _1) ) and
    ( boost::bind(&mp7::RegionInfo::chkIn, _1) == boost::bind(&mp7::RegionInfo::chkOut, _1) ) and 
    ( boost::bind(&mp7::RegionInfo::bufIn, _1) != mp7::kNoBuffer ));

  MP7_LOG(mp7::logger::kInfo) << "Loopback capable group:"
    << " regions " << mp7::logger::shortVecFmt(loop2.regions())
    << " chans " << mp7::logger::shortVecFmt(loop2.channels())
    ; 
}

