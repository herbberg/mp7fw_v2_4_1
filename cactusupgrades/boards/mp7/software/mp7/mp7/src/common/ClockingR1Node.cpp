#include "mp7/ClockingR1Node.hpp"

// C++ Headers
#include <stdexcept>

// Boost Headers
#include <boost/unordered_map.hpp>
#include <boost/assign.hpp>

// MP7 Headers
#include "mp7/Logger.hpp"
#include "mp7/exception.hpp"
#include "mp7/Utilities.hpp"

// uHal headers
#include "uhal/ValMem.hpp"
#include "mp7/SI5326Node.hpp"

// Boost Headers
#include <boost/filesystem.hpp>

// Namespace resolution
using namespace std;
namespace l7 = mp7::logger;

namespace mp7 {

// DerivedNode registration
UHAL_REGISTER_DERIVED_NODE(ClockingR1Node);

//---

ClockingR1Node::ClockingR1Node(const uhal::Node& node) :
ClockingNode(node) {
}


//---

ClockingR1Node::~ClockingR1Node() {
}

void
ClockingR1Node::configure(const ConfigParams& aConfig) const {

    // configure U36 //FIXME: Should not rely on implicit enum -> int casting in next 3 lines !!!
    configureU36(aConfig.xpoint_clk40sel, aConfig.xpoint_clk40sel, 0, 0);
    configureU3(aConfig.xpoint_refclksel, aConfig.xpoint_refclksel, aConfig.xpoint_refclksel, aConfig.xpoint_refclksel);
    configureU15(aConfig.xpoint_refclksel, aConfig.xpoint_refclksel, aConfig.xpoint_refclksel, aConfig.xpoint_refclksel);

    if (aConfig.si5326_cfg) {
        const SI5326Node& si5326(getNode<mp7::SI5326Node>("i2c_si5326"));

        // Configure the si5326 clock only if in external mode
        MP7_LOG(l7::kInfo) << "Configuring SI5326, using file: " << aConfig.si5326_file;

        // reset the chip
        si5326Reset();

        // sleep
        mp7::millisleep(1000);

        // and then reconfigure
        si5326.configure(mp7::shellExpandPath(aConfig.si5326_file));

        mp7::millisleep(500);

        // Wait for the si5326 to recover
        try {
            si5326WaitConfigured();
        } catch (const mp7::SI5326ConfigurationTimeout& e) {
            MP7_LOG(l7::kError) << "Timeout in configuring si ";
            //TODO: Ask Alessandro/Aaron: Why no re-throw?
        }

        si5326.debug();
    }
}

//---

void
ClockingR1Node::configureXpoint(Clk40Select aClk40Src, RefClkSelect aRefSrc) const {

    switch (aClk40Src) {
        case kExternalAMC13:
            // Clock 40 routing from AMC13
            this->configureU36(3, 3, 0, 0);
            break;
        case kExternalMCH:
            // Clock 40 routing from MCH, external clock generator
            this->configureU36(1, 1, 0, 0);
            break;
        case kDisconnected:
            // From internal oscillator
            // U36 don't matter. Best to have a default anyway?
            // 0,0,0,0 is the poweron value
            this->configureU36(1, 1, 0, 0);
            break;
        default:
            throw runtime_error("Invalid clock 40 source");
    }

    switch (aRefSrc) {
        case kOscillator:
            // Refclock from the internal oscillator
            this->configureU3(1, 1, 1, 1);
            this->configureU15(1, 1, 1, 1);
            break;
        case kClockCleaner:
            // Refclock from clock chip
            this->configureU3(3, 3, 3, 3);
            this->configureU15(3, 3, 3, 3);
            break;
        default:
            throw runtime_error("Invalid reference clock source");
            break;
    }
}

void
ClockingR1Node::configureUX(const std::string& aChip, uint aSelForOut0, uint aSelForOut1, uint aSelForOut2, uint aSelForOut3) const {

    const Node& ctrl = this->getNode("csr.ctrl");
    ctrl.getNode("selforout1_" + aChip).write(aSelForOut0);
    ctrl.getNode("selforout2_" + aChip).write(aSelForOut1);
    ctrl.getNode("selforout3_" + aChip).write(aSelForOut2);
    ctrl.getNode("selforout4_" + aChip).write(aSelForOut3);

    ctrl.getNode("prog_" + aChip).write(1);
    this->getClient().dispatch();
    usleep(10);
    ctrl.getNode("prog_" + aChip).write(0);
    this->getClient().dispatch();
    // wait for the cross point switch to assert its done signal
    const string stat_done = "csr.stat.done_" + aChip;
    uhal::ValWord< uint32_t > done(0);
    int countdown = 100;

    while (countdown > 0) {
        done = this->getNode(stat_done).read();
        this->getClient().dispatch();

        if (done) {
            break;
        }

        --countdown;
    }

    if (countdown == 0) {
        std::ostringstream oss;
        MP7_LOG(l7::kError) << "Timed out while waiting for Xpoint " << aChip << " to complete configuration (100 tries)";
        throw mp7::XpointConfigTimeout(oss.str());
    }
}

void
ClockingR1Node::configureU3(uint aSelForOut0, uint aSelForOut1, uint aSelForOut2, uint aSelForOut3) const {
    // Inputs to xpoint_u3          	 Outputs to xpoint_u3
    // ===================          	 ===================
    // Input 0 = osc2               	 Output 0 = refclk0
    // Input 1 = osc1               	 Output 1 = refclk1
    // Input 2 = clk2               	 Output 2 = refclk2
    // Input 3 = clk1               	 Output 3 = refclk3
    this->configureUX("u3", aSelForOut0, aSelForOut1, aSelForOut2, aSelForOut3);
}

void
ClockingR1Node::configureU15(uint aSelForOut0, uint aSelForOut1, uint aSelForOut2, uint aSelForOut3) const {
    // Inputs to xpoint_u15            Outputs to xpoint_u15
    // ===================             ===================
    // Input 0 = osc2                  Output 0 = refclk4
    // Input 1 = osc1                  Output 1 = refclk5
    // Input 2 = clk2                  Output 2 = refclk6
    // Input 3 = clk1                  Output 3 = refclk7
    this->configureUX("u15", aSelForOut0, aSelForOut1, aSelForOut2, aSelForOut3);
}

void
ClockingR1Node::configureU36(uint aSelForOut0, uint aSelForOut1, uint aSelForOut2, uint aSelForOut3) const {
    // Inputs to xpoint_u36           	 Outputs to xpoint_u36
    // Input 0 = si5326 clk1 output   	 Output 0 = si5326 clk1 input
    // Input 1 = TCLK-C               	 Output 1 = clk3
    // Input 2 = TCLK-A               	 Output 2 = clk2
    // Input 3 = FCLK-A               	 Output 3 = clk1
    // ---------------------------------------------------------------------
    // Wish to send MCH TCLK-A (input-2) to si5326 (output-0) and for all
    // other outputs to be driven by si5326 (input-0)
    // ---------------------------------------------------------------------
    this->configureUX("u36", aSelForOut0, aSelForOut1, aSelForOut2, aSelForOut3);
}

void
ClockingR1Node::si5326Reset() const {
    // Reset the si5326
    this->getNode("csr.ctrl.rst_si5326").write(0);
    this->getClient().dispatch();
    // minimum reset pulse width is 1 microsecond, we go for 5
    usleep(5);
    this->getNode("csr.ctrl.rst_si5326").write(1);
    this->getClient().dispatch();
}

void
ClockingR1Node::si5326WaitConfigured(uint32_t aMaxTries) const {
    uint32_t countdown(aMaxTries);
    while (countdown > 0) {
        uhal::ValWord<uint32_t> si5326_lol = this->getNode("csr.stat.si5326_lol").read();
        uhal::ValWord<uint32_t> si5326_int = this->getNode("csr.stat.si5326_int").read();
        this->getClient().dispatch();

        if (si5326_lol.value() == 0 && si5326_int.value() == 0) {
            break;
        }

        millisleep(1);
        --countdown;
    }

    if (countdown == 0) {
        std::ostringstream oss;
        oss << "Timed out waiting for si5326 to recover from configuration (" << aMaxTries << "ms)";
        MP7_LOG(l7::kError) << oss.str();
        throw mp7::SI5326ConfigurationTimeout(oss.str());
    } else {
        MP7_LOG(l7::kNotice) << "SI5326 finished configuring after " << (aMaxTries - countdown) << " ms";
    }
}

bool
ClockingR1Node::si5326LossOfLock() const {
    uhal::ValWord<uint32_t> si5326_lol = this->getNode("csr.stat.si5326_lol").read();
    this->getClient().dispatch();
    return ( bool) si5326_lol;
}

bool
ClockingR1Node::si5326Interrupt() const {
    uhal::ValWord<uint32_t> si5326_int = this->getNode("csr.stat.si5326_int").read();
    this->getClient().dispatch();
    return ( bool) si5326_int;
}

//---
ClockingR1Configurator::ClockingR1Configurator(const std::string& aFilename, const std::string& kind, const std::string& aPrefix) {
    
    boost::filesystem::path prefix, file;
    
    if ( aPrefix.size() != 0 )
        prefix /= aPrefix;
    
    // R1 files are in {aPrefix}/ref-clk/r1/
    file = prefix / kind / "refclk" / aFilename;
    
    // This is the configuration
    ClockingR1Node::ConfigParams cfg = parseFromXML(file.string());
    
    // The prefix needs to be added to the files
    
    cfg.si5326_file = (prefix / "sicfg/si5326" / cfg.si5326_file).string();
    
    mConfig = cfg;
}


//---
ClockingR1Configurator::~ClockingR1Configurator() {

}

const ClockingR1Node::ConfigParams& ClockingR1Configurator::getConfig() const {
    return mConfig;
}


void
ClockingR1Configurator::configure(const ClockingR1Node& aClkR1Node) const {
    aClkR1Node.configure(mConfig);
}

//---
ClockingR1Node::ConfigParams
ClockingR1Configurator::parseFromXML(const std::string& aFilename  ) {
    pugi::xml_document doc;

    // Build the path object
    boost::filesystem::path p(shellExpandPath(aFilename));
  
    if ( !boost::filesystem::exists(p) ) {
        mp7::FileNotFound e("MP7 R1 clock config file \"" + p.string() + "\" not found");
        MP7_LOG(l7::kError) << e.what();
        throw e;
    }
    
    // Load file
    if (!doc.load_file(p.c_str())) {
        mp7::InvalidConfigFile e("Could not load MP7 R1 clock config file \"" + p.string() + "\"");
        MP7_LOG(l7::kError) << e.what();
        throw e;
    }

    ClockingR1Node::ConfigParams cfg;
    pugi::xml_node top = xml::get_valid_node(doc, "clkcfg");
    cfg.name = top.attribute("name").value();


    cfg.clkSrc = xml::get_valid_node(top, "clksrc").text().get();

    pugi::xml_node si5326 = xml::get_valid_node(top, "si5326");
    cfg.si5326_cfg = xml::node_text_as_bool(xml::get_valid_node(si5326, "cfg"));
    cfg.si5326_file = xml::get_valid_node(si5326, "file").text().get();

    pugi::xml_node xpoint = xml::get_valid_node(top, "xpoint");
    cfg.xpoint_clk40sel = boost::lexical_cast<ClockingR1Node::ConfigParams::ClkInput>(xml::get_valid_node(xpoint, "clk40sel").text().get());
    cfg.xpoint_refclksel = boost::lexical_cast<ClockingR1Node::ConfigParams::RefClk>(xml::get_valid_node(xpoint, "refclksel").text().get());

    std::ostringstream oss;
    std::string prefix("                     > ");
    oss << "R1 clocking configuration:" << std::endl;
    oss << prefix << "SI5326 = " << l7::boolFmt(cfg.si5326_cfg) << std::endl;
    oss << prefix << "Clk40 select  = " << cfg.xpoint_clk40sel << std::endl;
    oss << prefix << "Refclk select = " << cfg.xpoint_refclksel << std::endl;
    MP7_LOG(l7::kDebug) << oss.str();

    return cfg;
    
}


//---
std::ostream& operator<<(std::ostream& aOut, ClockingR1Node::ConfigParams::ClkInput aValue) {
    if (aValue == ClockingR1Node::ConfigParams::kSI5326)
        return (aOut << "si5326");
    else if (aValue == ClockingR1Node::ConfigParams::kTclkc)
        return (aOut << "tclkc");
    else if (aValue == ClockingR1Node::ConfigParams::kTclka)
        return (aOut << "tclka");
    else if (aValue == ClockingR1Node::ConfigParams::kFclka)
        return (aOut << "fclka");
    throw std::runtime_error("Invalid ClkInput enum value in ostream operator<<");
}


//---

std::istream& operator>>(std::istream& aIn, ClockingR1Node::ConfigParams::ClkInput& aValue) {
    std::string str;
    aIn >> str;

    if (str == "si5326")
        aValue = ClockingR1Node::ConfigParams::kSI5326;
    else if (str == "tclkc")
        aValue = ClockingR1Node::ConfigParams::kTclkc;
    else if (str == "tclka")
        aValue = ClockingR1Node::ConfigParams::kTclka;
    else if (str == "fclka")
        aValue = ClockingR1Node::ConfigParams::kFclka;
    else
        throw std::runtime_error("Invalid string value \"" + str + "\" for MP7 R1 ClkInput enum");

    return aIn;
}


//---

std::ostream&
operator<<(std::ostream& aOut, ClockingR1Node::ConfigParams::RefClk aValue) {
    if (aValue == ClockingR1Node::ConfigParams::kOsc)
        return (aOut << "osc");
    else if (aValue == ClockingR1Node::ConfigParams::kClkcln)
        return (aOut << "clkcln");
    throw std::runtime_error("Invalid RefClk enum value in ostream operator<<");
}


//---

std::istream&
operator>>(std::istream& aIn, ClockingR1Node::ConfigParams::RefClk& aValue) {
    std::string str;
    aIn >> str;

    if (str == "osc")
        aValue = ClockingR1Node::ConfigParams::kOsc;
    else if (str == "clkcln")
        aValue = ClockingR1Node::ConfigParams::kClkcln;
    else
        throw std::runtime_error("Invalid string value \"" + str + "\" for MP7 R1 RefClk enum");

    return aIn;
}

}

