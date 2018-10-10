/* 
 * File:   ReadoutCtrlNode.cpp
 * Author: ale
 * 
 * Created on May 18, 2015, 1:37 PM
 */

#include "mp7/ReadoutCtrlNode.hpp"

#include "mp7/Logger.hpp"

// Boost Headers
//#include <boost/foreach.hpp>

// Namespace declaration
namespace l7 = mp7::logger;

namespace mp7 {
UHAL_REGISTER_DERIVED_NODE(ReadoutCtrlNode);


//---
ReadoutCtrlNode::ReadoutCtrlNode(const uhal::Node& aNode) :
  uhal::Node(aNode) {
}


//---
ReadoutCtrlNode::~ReadoutCtrlNode() {
}

uint32_t ReadoutCtrlNode::readNumBanks() const {
  uhal::ValWord<uint32_t> banks = getNode("csr.stat.n_banks").read();
  getClient().dispatch();
  return banks;
}

//---
uint32_t
ReadoutCtrlNode::readNumModes() const {
  uhal::ValWord<uint32_t> modes = getNode("csr.stat.n_modes").read();
  getClient().dispatch();
  return modes;
}


//---
uint32_t
ReadoutCtrlNode::readNumCaptures() const {
  uhal::ValWord<uint32_t> caps = getNode("csr.stat.n_caps").read();
  getClient().dispatch();
  return caps;
}


//---
void
ReadoutCtrlNode::selectBank(uint32_t aBank) const {
  getNode("csr.ctrl.bank_sel").write(aBank);
  getClient().dispatch();
}


//---
void
ReadoutCtrlNode::selectMode(uint32_t aMode) const {
  getNode("csr.ctrl.mode_sel").write(aMode);
  getClient().dispatch();
}


//---
void
ReadoutCtrlNode::selectCapture(uint32_t aCapture) const {
  getNode("csr.ctrl.cap_sel").write(aCapture);
  getClient().dispatch();
}


//---
void
ReadoutCtrlNode::setDerandWaterMarks(uint32_t aLowWM, uint32_t aHighWM) const {
  getNode("csr.dr_ctrl.dr_hwm").write(aHighWM); //48 = 25% 
  getNode("csr.dr_ctrl.dr_lwm").write(aLowWM); //32 = 50%
  getClient().dispatch();
}


//---
void ReadoutCtrlNode::reset() const {
  uhal::ValWord<uint32_t> nbanks = getNode("csr.stat.n_banks").read();
  uhal::ValWord<uint32_t> nmodes = getNode("csr.stat.n_modes").read();
  uhal::ValWord<uint32_t> ncaps = getNode("csr.stat.n_caps").read();

  getClient().dispatch();

  for (uint32_t iM(0); iM < nmodes; iM++) {
    // Select
    getNode("csr.ctrl.mode_sel").write(iM);
    // Reset mode specific nodes

    for(const std::string& n :  getNodes("mode_csr\\.(ctrl\\..*|user_data)")) {
      getNode(n).write(0x0);
    }

    for (uint32_t iC(0); iC < ncaps; iC++) {
      getNode("csr.ctrl.cap_sel").write(iC);
      // Reset mode specific nodes

      for(const std::string& n :  getNodes("cap_csr\\.ctrl\\..*")) {
        getNode(n).write(0x0);
      }
    }

    getClient().dispatch();
  }

}


//---
void ReadoutCtrlNode::configureMenu(const ReadoutMenu& aMenu) const {

  // Read configurations
  uhal::ValWord<uint32_t> nbanks = getNode("csr.stat.n_banks").read();
  uhal::ValWord<uint32_t> nmodes = getNode("csr.stat.n_modes").read();
  uhal::ValWord<uint32_t> ncaps = getNode("csr.stat.n_caps").read();
  getClient().dispatch();

  if (
      aMenu.numBanks() != nbanks or
      aMenu.numModes() != nmodes or
      aMenu.numCaptures() != ncaps 
    ) {
    std::ostringstream lExc;
    lExc << "Menu mismatch detected: The readout menu does not the firmware resources.";
    lExc << "Firmware -  banks:" << nbanks << " modes:" << nmodes << " caps:" << ncaps;
    lExc << "Menu     -  banks:" << aMenu.numBanks() << " modes:" << aMenu.numModes() << " caps:" << aMenu.numCaptures();

    // Spme errors
    throw ReadoutMenuInconsistentWithFirmware("Menu mismatch detected: The readout menu does not the firmware resources. Expected (n");
  }

  ReadoutMenuValidator rmChecker(aMenu);
  rmChecker.verify();

  // Check that none of the captures uses bankids with 0 length
  reset();

  for( uint32_t iB(0); iB < nbanks; ++iB) {
    getNode("csr.ctrl.bank_sel").write(iB);
    getNode("bank_csr.ctrl.wp_bx").write(aMenu.bank(iB).wordsPerBx);

  }
  getClient().dispatch();

  for (uint32_t iM(0); iM < nmodes; iM++) {
    const ReadoutMenu::Mode& m = aMenu.mode(iM);

    // Select
    getNode("csr.ctrl.mode_sel").write(iM);

    // Set mode specific nodes
    getNode("mode_csr.ctrl.evt_trig").write(m.eventToTrigger);
    getNode("mode_csr.ctrl.evt_size").write(m.eventSize);
    getNode("mode_csr.hdr.event_type").write(m.eventType);
    // FIXME: token delay is not used anymore. Remove it
    // getNode("mode_csr.ctrl.token_delay").write(m.tokenDelay);

    for (uint32_t iC(0); iC < ncaps; iC++) {

      const ReadoutMenu::Capture& c = aMenu.capture(iM, iC);
      
      // Select
      getNode("csr.ctrl.cap_sel").write(iC);
      getClient().dispatch();
      // Set mode specific nodes
      getNode("cap_csr.ctrl.bank_id").write(c.bankId);
      getNode("cap_csr.ctrl.cap_en").write(c.enable);
      getNode("cap_csr.ctrl.cap_delay").write(c.delay);
      getNode("cap_csr.ctrl.cap_size").write(c.length);
      getNode("cap_csr.ctrl.cap_id").write(c.id);
      getNode("cap_csr.ctrl.readout_length").write(c.readoutLength);

      getClient().dispatch(); // stops sim from freezing up
    }

    // one dispatch per mode - why?
    getClient().dispatch();
  }

}


//---
ReadoutMenu
ReadoutCtrlNode::readMenu() const {

  uhal::ValWord<uint32_t> wpbx;
  uhal::ValWord<uint32_t> evTrig, evSize, eventType;
  // uhal::ValWord<uint32_t> evTrig, evSize, tokenDelay, eventType;
  uhal::ValWord<uint32_t> enable, bankId, capDelay, capSize, captureId, roLength;

  // Read configurations
  uhal::ValWord<uint32_t> nmodes = getNode("csr.stat.n_modes").read();
  uhal::ValWord<uint32_t> ncaps = getNode("csr.stat.n_caps").read();
  uhal::ValWord<uint32_t> nbanks = getNode("csr.stat.n_banks").read();
  getClient().dispatch();

  ReadoutMenu menu = ReadoutMenu(nbanks, nmodes, ncaps);

  for( uint32_t iB(0); iB < nbanks; ++iB) {
    getNode("csr.ctrl.bank_sel").write(iB);
    wpbx = getNode("bank_csr.ctrl.wp_bx").read();
    getClient().dispatch();

    menu.bank(iB).wordsPerBx = wpbx;
  }

  getClient().dispatch();

  for (size_t iM(0); iM < nmodes; iM++) {
    // Select
    getNode("csr.ctrl.mode_sel").write(iM);

    // Set mode specific nodes
    evTrig = getNode("mode_csr.ctrl.evt_trig").read();
    evSize = getNode("mode_csr.ctrl.evt_size").read();
    eventType = getNode("mode_csr.hdr.event_type").read();
    // FIXME: token delay is not used anymore. Remove it
    // tokenDelay = getNode("mode_csr.ctrl.token_delay").read();

    getClient().dispatch();

    auto & m = menu.mode(iM);
    m.eventToTrigger = evTrig;
    m.eventSize = evSize;
    m.eventType = eventType;
    // m.tokenDelay = tokenDelay;
    
    for (size_t iC(0); iC < ncaps; iC++) {
      // Select
      getNode("csr.ctrl.cap_sel").write(iC);

      // Set mode specific nodes
      bankId     = getNode("cap_csr.ctrl.bank_id").read();
      enable     = getNode("cap_csr.ctrl.cap_en").read();
      capDelay   = getNode("cap_csr.ctrl.cap_delay").read();
      capSize    = getNode("cap_csr.ctrl.cap_size").read();
      captureId  = getNode("cap_csr.ctrl.cap_id").read();
      roLength   = getNode("cap_csr.ctrl.readout_length").read();
      
      getClient().dispatch();
      
      auto & c = m[iC];
      
      c.enable = enable;
      c.id = captureId;
      c.bankId = bankId;
      c.length = capSize;
      c.delay = capDelay;
      c.readoutLength = roLength;      
    }
  }

  return menu;

}

}



