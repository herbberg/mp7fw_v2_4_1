#include "mp7/ClockingXENode.hpp"

// C++ Headers
#include <stdexcept>

// MP7 Headers
#include "mp7/exception.hpp"
#include "mp7/Logger.hpp"
#include "mp7/Utilities.hpp"

// uHal headers
#include "uhal/ValMem.hpp"
#include "mp7/SI570Node.hpp"
#include "mp7/SI5326Node.hpp"

// Boost Headers
#include <boost/filesystem.hpp>

// Namespace resolution
using namespace std;
namespace l7 = mp7::logger;

namespace mp7 {

// DerivedNode registration
UHAL_REGISTER_DERIVED_NODE(ClockingXENode);

ClockingXENode::ClockingXENode(const uhal::Node& node) :
ClockingNode(node) {
}

ClockingXENode::~ClockingXENode() {
}

const ClockingXENode::ConfigParams& ClockingXEConfigurator::getConfig() const {
    return mConfig;
}


//---
void
ClockingXENode::configure(const ConfigParams& cfg ) const {

    
    // -- clocking configuration is pure routing
    MP7_LOG(l7::kInfo) << "Configuring clocking";

    //configure xpoint according to xml config
    // In0 = FPGA      Out0 = TCLKB
    // In1 = TCLK-C    Out1 = FPGA
    // In2 = TCLK-A    Out2 = clk2 (Top)
    // In3 = FCLKA     Out3 = clk1 (Bot)

    //TODO //FIXME : Should modify to not rely on implicit enum -> int casting
    configureU36(cfg.xpoint_tclkb, cfg.xpoint_fpga, cfg.xpoint_clk2, cfg.xpoint_clk1);

    // SI570 free run
    if (cfg.si570_cfg) {
        
        const SI570Node& si570bot(getNode<mp7::SI570Node>("i2c_si570_bot"));
        std::string si570filename(cfg.si570_file);
        MP7_LOG(l7::kInfo) << "Configuring SI570 bottom, using file: " << si570filename;

        getNode("csr.ctrl.clk_i2c_sel").write(0x1);
        getClient().dispatch();
        si570bot.configure(mp7::shellExpandPath(si570filename));
    }

    if (cfg.si5326_cfgbot) {
        const SI5326Node& si5326bot(getNode<mp7::SI5326Node>("i2c_si5326_bot"));
        
        std::string si5326filename(cfg.si5326_filebot);
        MP7_LOG(l7::kInfo) << "Configuring SI5326 bottom, using file: " << si5326filename;

        // select bottom i2c line
        getNode("csr.ctrl.clk_i2c_sel").write(0x1);
        getClient().dispatch();

        // reset the chip
        si5326BottomReset();
        mp7::millisleep(1000);

        // and then configure
        si5326bot.configure(mp7::shellExpandPath(si5326filename));
        mp7::millisleep(500);

        //bot_lol = clk.getNode('csr.stat.si5326_bot_lol').read()
        //bot_int = clk.getNode('csr.stat.si5326_bot_int').read()
        //clk.getClient().dispatch()
        //print "bot_lol=",bot_lol.value()
        //print "bot_int=",bot_int.value()

        //Wait the si5326 to recover
        //clk.si5326BottomWaitConfigured(False)

        si5326bot.debug();
    }

    if (cfg.si5326_cfgtop) {
        
        const SI5326Node& si5326top(getNode<mp7::SI5326Node>("i2c_si5326_top"));
        
        std::string si5326filename(cfg.si5326_filetop);
        MP7_LOG(l7::kInfo) << "Configuring SI5326 top, using file: " << si5326filename;

        // select top i2c line
        getNode("csr.ctrl.clk_i2c_sel").write(0x0);
        getClient().dispatch();

        // reset the chip
        si5326TopReset();

        // sleep
        mp7::millisleep(1000);

        // and thn configure
        si5326top.configure(mp7::shellExpandPath(si5326filename));

        mp7::millisleep(500);

        //top_lol = clk.getNode('csr.stat.si5326_top_lol').read()
        //top_int - clk.getNode('csr.stat.si5326_top_int').read()
        //clk.getClient().dispatch()
        //print "top_lol=",top_lol.value()
        //print "top_int=",top_int.value()

        //// Wait the si5326 to recover
        //clk.si5326TopWaitConfigured(False)

        si5326top.debug();
    }

    //configure top/bottom si53314 fan outs

    //reset fan out chips
    getNode("csr.ctrl.si53314_top_enable_base").write(0x0);
    getNode("csr.ctrl.si53314_top_enable_ext").write(0x0);
    getNode("csr.ctrl.si53314_top_clk_sel").write(0x0);
    getNode("csr.ctrl.si53314_bot_enable_base").write(0x0);
    getNode("csr.ctrl.si53314_bot_enable_ext").write(0x0);
    getNode("csr.ctrl.si53314_bot_clk_sel").write(0x0);
    getClient().dispatch();

    if (cfg.si570_cfg || cfg.si5326_cfgbot) {
        getNode("csr.ctrl.si53314_bot_enable_base").write(uint32_t(cfg.si53314_basebot));
        getNode("csr.ctrl.si53314_bot_enable_ext").write(uint32_t(cfg.si53314_extbot));
        getNode("csr.ctrl.si53314_bot_clk_sel").write(uint32_t(cfg.si53314_clkselbot)); // 0 for SI570, 1 for SI5326
        getClient().dispatch();

    }
    if (cfg.si5326_cfgtop) {
        getNode("csr.ctrl.si53314_top_enable_base").write(uint32_t(cfg.si53314_basetop));
        getNode("csr.ctrl.si53314_top_enable_ext").write(uint32_t(cfg.si53314_exttop));
        getNode("csr.ctrl.si53314_top_clk_sel").write(0x1); //always 1 for top 5326
        getClient().dispatch();
    }
}


void
ClockingXENode::configureXpoint(Clk40Select aClk40Src) const {

    switch (aClk40Src) {
        case kExternalAMC13:
            // Clock 40 routing from AMC13 to FPGA and both SI5326
            this->configureU36(3, 3, 3, 3);
            break;
        case kExternalMCH:
            // Clock 40 routing from MCH, external clock generator
            this->configureU36(1, 1, 0, 0);
            break;
        case kDisconnected:
            // From internal oscillator
            // U36 don't matter. Best to have a default anyway?
            // 0,0,0,0 is the poweron value
            this->configureU36(0, 0, 0, 0);
            break;
        default:
            throw runtime_error("Invalid clock 40 source");
    }

}

void
ClockingXENode::configureUX(const std::string& aChip, uint SelForOut0, uint SelForOut1, uint SelForOut2, uint SelForOut3) const {

    const Node& ctrl = this->getNode("csr.ctrl");
    ctrl.getNode("selforout1_" + aChip).write(SelForOut0);
    ctrl.getNode("selforout2_" + aChip).write(SelForOut1);
    ctrl.getNode("selforout3_" + aChip).write(SelForOut2);
    ctrl.getNode("selforout4_" + aChip).write(SelForOut3);

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
        oss << "Timed out while waiting for Xpoint " << aChip << " to complete configuration (100 tries)";
        MP7_LOG(l7::kError) << oss.str() << std::endl;
        throw mp7::XpointConfigTimeout(oss.str());
    }
}

void
ClockingXENode::configureU36(uint SelForOut0, uint SelForOut1, uint SelForOut2, uint SelForOut3) const {
    // Inputs to xpoint_u36           	 Outputs to xpoint_u36
    // Input 0 = clock from FPGA   	         Output 0 = TCLKB 
    // Input 1 = TCLK-C               	 Output 1 = clk3 (clk40 to fpga)
    // Input 2 = TCLK-A               	 Output 2 = clk2 (top)
    // Input 3 = FCLK-A               	 Output 3 = clk1 (bot)
    // ---------------------------------------------------------------------
    // Wish to send MCH TCLK-A (input-2) to si5326 (output-0) and for all
    // other outputs to be driven by si5326 (input-0)
    // ---------------------------------------------------------------------
    this->configureUX("u36", SelForOut0, SelForOut1, SelForOut2, SelForOut3);
}

void
ClockingXENode::si5326TopReset() const {
    this->si5326ChipReset("top");
}

void
ClockingXENode::si5326TopWaitConfigured(bool aMustLock, uint32_t aMaxTries) const {
    this->si5326ChipWaitConfigured("top", aMustLock, aMaxTries);
}

bool
ClockingXENode::si5326TopLossOfLock() const {
    return this->si5326ChipLossOfLock("top");
}

bool
ClockingXENode::si5326TopInterrupt() const {
    return this->si5326ChipInterrupt("top");
}

void
ClockingXENode::si5326BottomReset() const {
    this->si5326ChipReset("bot");
}

void
ClockingXENode::si5326BottomWaitConfigured(bool aMustLock, uint32_t aMaxTries) const {
    this->si5326ChipWaitConfigured("bot", aMustLock, aMaxTries);
}

bool
ClockingXENode::si5326BottomLossOfLock() const {
    return this->si5326ChipLossOfLock("bot");
}

bool
ClockingXENode::si5326BottomInterrupt() const {
    return this->si5326ChipInterrupt("bot");
}

void
ClockingXENode::si5326ChipReset(const std::string& aChip) const {
    const uhal::Node& nReset = this->getNode("csr.ctrl.rst_" + aChip + "_si5326");

    // Reset the si5326
    nReset.write(0);
    nReset.getClient().dispatch();
    // minimum reset pulse width is 1 microsecond, we go for 5
    usleep(5);
    nReset.write(1);
    nReset.getClient().dispatch();
}

void
ClockingXENode::si5326ChipWaitConfigured(const std::string& aChip, bool aMustLock, uint32_t aMaxTries) const {
    const uhal::Node& nLol = this->getNode("csr.stat.si5326_" + aChip + "_lol");
    const uhal::Node& nInt = this->getNode("csr.stat.si5326_" + aChip + "_int");

    uint32_t countdown(aMaxTries);
    while (countdown > 0) {
        uhal::ValWord<uint32_t> si5326_lol = nLol.read();
        uhal::ValWord<uint32_t> si5326_int = nInt.read();
        this->getClient().dispatch();

        if ((si5326_lol.value() != (uint32_t) aMustLock) && si5326_int.value() == 0) {
            break;
        }

        millisleep(1);
        --countdown;
    }

    if (countdown == 0) {
        std::ostringstream oss;
        oss << "Timed out while waiting for SI5326 to complete configuration (" << aMaxTries << " ms)";
        MP7_LOG(l7::kError) << oss.str();
        throw mp7::SI5326ConfigurationTimeout(oss.str());
    } else {
        MP7_LOG(l7::kNotice) << "SI5326 finished configuring after " << (aMaxTries - countdown) << " ms";
    }
}

bool
ClockingXENode::si5326ChipLossOfLock(const std::string& aChip) const {
    uhal::ValWord<uint32_t> si5326_lol = this->getNode("csr.stat.si5326_" + aChip + "_lol").read();
    this->getClient().dispatch();
    return ( bool) si5326_lol;
}


//---
bool
ClockingXENode::si5326ChipInterrupt(const std::string& aChip) const {
    uhal::ValWord<uint32_t> si5326_int = this->getNode("csr.stat.si5326_" + aChip + "_int").read();
    this->getClient().dispatch();
    return ( bool) si5326_int;
}

//---
ClockingXEConfigurator::ClockingXEConfigurator(const std::string& aFilename, const std::string& kind, const std::string& aPrefix) {
    boost::filesystem::path prefix, file;
    
    if ( aPrefix.size() != 0 )
        prefix /= aPrefix;
    
    // R1 files are in {aPrefix}/ref-clk/r1/
    file = prefix / kind / "refclk" / aFilename;
    
    // This is the configuration
    ClockingXENode::ConfigParams cfg = parseFromXML(file.string());
    
    cfg.si5326_filebot = (prefix / "sicfg/si5326" / cfg.si5326_filebot).string();
    cfg.si5326_filetop = (prefix / "sicfg/si5326" / cfg.si5326_filetop).string();
    cfg.si570_file = (prefix / "sicfg/si570" / cfg.si570_file).string();
    
    mConfig = cfg;
   
}

//---
ClockingXEConfigurator::~ClockingXEConfigurator() {
}


//---
void 
ClockingXEConfigurator::configure(const ClockingXENode& aClkR1Node) const {
    aClkR1Node.configure(mConfig);
}

//---
ClockingXENode::ConfigParams
ClockingXEConfigurator::parseFromXML(const std::string& aFilePath) {
        
    pugi::xml_document doc;

    if (!doc.load_file(shellExpandPath(aFilePath).c_str())) {
        mp7::InvalidConfigFile e("Could not load MP7 XE clock config file \"" + aFilePath + "\"");
        MP7_LOG(l7::kError) << e.what();
        throw e;
    }

    ClockingXENode::ConfigParams cfg;
    pugi::xml_node top = xml::get_valid_node(doc, "clkcfg");
    cfg.name = top.attribute("name").value();

    cfg.clkSrc = xml::get_valid_node(top, "clksrc").text().get();

    pugi::xml_node si570 = xml::get_valid_node(top, "si570");
    cfg.si570_cfg = xml::node_text_as_bool(xml::get_valid_node(si570, "cfg"));
    cfg.si570_file = xml::get_valid_node(si570, "file").text().get();

    pugi::xml_node si5326 = xml::get_valid_node(top, "si5326");
    cfg.si5326_cfgtop = xml::node_text_as_bool(xml::get_valid_node(si5326, "cfgtop"));
    cfg.si5326_cfgbot = xml::node_text_as_bool(xml::get_valid_node(si5326, "cfgbot"));
    cfg.si5326_filetop = xml::get_valid_node(si5326, "filetop").text().get();
    cfg.si5326_filebot = xml::get_valid_node(si5326, "filebot").text().get();

    pugi::xml_node si53314 = xml::get_valid_node(top, "si53314");
    cfg.si53314_basetop = xml::node_text_as_bool(xml::get_valid_node(si53314, "basetop"));
    cfg.si53314_exttop = xml::node_text_as_bool(xml::get_valid_node(si53314, "exttop"));
    cfg.si53314_basebot = xml::node_text_as_bool(xml::get_valid_node(si53314, "basebot"));
    cfg.si53314_extbot = xml::node_text_as_bool(xml::get_valid_node(si53314, "extbot"));
    cfg.si53314_clkselbot = boost::lexical_cast<uint32_t>(xml::get_valid_node(si53314, "clkselbot").text().get());

    pugi::xml_node xpoint = xml::get_valid_node(top, "xpoint");
    cfg.xpoint_tclkb = boost::lexical_cast<ClockingXENode::ConfigParams::ClkInput>(xml::get_valid_node(xpoint, "tclkb").text().get());
    cfg.xpoint_fpga = boost::lexical_cast<ClockingXENode::ConfigParams::ClkInput>(xml::get_valid_node(xpoint, "fpga").text().get());
    cfg.xpoint_clk2 = boost::lexical_cast<ClockingXENode::ConfigParams::ClkInput>(xml::get_valid_node(xpoint, "clk2").text().get());
    cfg.xpoint_clk1 = boost::lexical_cast<ClockingXENode::ConfigParams::ClkInput>(xml::get_valid_node(xpoint, "clk1").text().get());

    std::ostringstream oss;
    std::string prefix("                     > ");
    oss << "XE clocking configuration:" << std::endl;
    oss << prefix << "SI570      = " << l7::boolFmt(cfg.si570_cfg) << std::endl;
    oss << prefix << "SI5326 TOP = " << l7::boolFmt(cfg.si5326_cfgtop) << std::endl;
    oss << prefix << "SI5326 BOT = " << l7::boolFmt(cfg.si5326_cfgbot) << std::endl;
    oss << prefix << cfg.xpoint_tclkb << " -> TCLK-B" << std::endl;
    oss << prefix << cfg.xpoint_fpga << " -> FPGA" << std::endl;
    oss << prefix << cfg.xpoint_clk2 << " -> CLK2 (top)" << std::endl;
    oss << prefix << cfg.xpoint_clk1 << " -> CLK1 (bot)" << std::endl;
    oss << prefix << "SI53314 base bottom  = " << l7::boolFmt(cfg.si53314_basebot) << std::endl;
    oss << prefix << "SI53314 extra bottom = " << l7::boolFmt(cfg.si53314_extbot) << std::endl;
    oss << prefix << "SI53314 base top     = " << l7::boolFmt(cfg.si53314_basetop) << std::endl;
    oss << prefix << "SI53314 extra top    = " << l7::boolFmt(cfg.si53314_exttop) << std::endl;
    oss << prefix << "SI53314 bot clk sel  = " << l7::hexFmt(cfg.si53314_clkselbot) << std::endl;
    MP7_LOG(l7::kDebug) << oss.str();

    return cfg;
    // } else {
    //     mp7::InvalidConfigFile e("Could not load MP7 XE clock config file \"" + aFilePath + "\"");
    //     MP7_LOG(l7::kError) << e.what();
    //     throw e;
    // }
}


//---

std::ostream&
operator<<(std::ostream& out, ClockingXENode::ConfigParams::ClkInput e) {
    if (e == ClockingXENode::ConfigParams::kFPGA)
        return (out << "fpga");
    else if (e == ClockingXENode::ConfigParams::kTclkc)
        return (out << "tclkc");
    else if (e == ClockingXENode::ConfigParams::kTclka)
        return (out << "tclka");
    else if (e == ClockingXENode::ConfigParams::kFclka)
        return (out << "fclka");
    throw std::runtime_error("Invalid ClkInput enum value in ostream operator<<");
}


//---   

std::istream&
operator>>(std::istream& in, ClockingXENode::ConfigParams::ClkInput& e) {
    std::string str;
    in >> str;

    if (str == "fpga")
        e = ClockingXENode::ConfigParams::kFPGA;
    else if (str == "tclkc")
        e = ClockingXENode::ConfigParams::kTclkc;
    else if (str == "tclka")
        e = ClockingXENode::ConfigParams::kTclka;
    else if (str == "fclka")
        e = ClockingXENode::ConfigParams::kFclka;
    else
        throw std::runtime_error("Invalid string value \"" + str + "\" for MP7 ClkInput enum");

    return in;
}

} // namespace mp7

