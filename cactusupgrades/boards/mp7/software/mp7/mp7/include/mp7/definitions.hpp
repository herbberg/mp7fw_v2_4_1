/* 
 * File:   Regions.hpp
 * Author: ale
 *
 * Created on November 16, 2014, 7:50 PM
 */

#ifndef __MP7_DEFINITIONS_HPP__
#define	__MP7_DEFINITIONS_HPP__

#include <map>
#include <stdint.h>
#include <string>
#include <vector>

namespace mp7 {

enum MP7Kind {
  kMP7Xe = 0x12,
  kMP7R1 = 0x10,
  kMP7Sim = 0x11,
  kMP7Unknown = 0xffffffff
};

static const std::vector<MP7Kind> kKnownMP7s = {kMP7Xe, kMP7R1, kMP7Sim};

//---
enum MGTKind {
    kNoMGT        = 0x0,
    kGth10g       = 0x1,
    kGth5g        = 0x2,
    kGth3g        = 0x3,
    kGthCalo      = 0x4,
    kGthCaloTest  = 0x5,
    kGth10gStdLat = 0x6,
    kGtx10g       = 0x7,
    kUnknownMGT   = 0xffffffff
};

static const std::vector<MGTKind> kKnownMGTs = {kNoMGT, kGth10g, kGth5g, kGthCalo, kGthCaloTest, kGth10gStdLat, kGtx10g};

//---
enum CheckSumKind {
    kNoCheckSum      = 0,
    kOlogicCrc32     = 1,
    kGct             = 2,
    kF64             = 3,
    kUCrc32          = 4,
    kUnknownCheckSum = 0xffffffff
};

static const std::vector<CheckSumKind> kKnownCheckSums = {kNoCheckSum, kOlogicCrc32, kGct, kF64, kUCrc32};


//---
enum BufferKind {
    kNoBuffer      = 0x0,
    kBuffer        = 0x1,
    kUnknownBuffer = 0xffffffff
};

static const std::vector<BufferKind> kKnownBuffers = {kNoBuffer, kBuffer};

//---
enum FormatterKind {
    kNoFormatter      = 0x0,
    kTDRFormatter     = 0x1,
    kStage1Formatter  = 0x2,
    kDemuxFormatter   = 0x3,
    kUnknownFormatter = 0xffffffff
};


static const std::vector<FormatterKind> kKnownFormatters = {kNoFormatter, kTDRFormatter, kStage1Formatter, kDemuxFormatter};

//---
enum RxTxSelector {
    kRx = 0x0,
    kTx = 0x1
};
    
enum TTCBCommand {
    kBC0 = 0x01,
    kEC0 = 0x02,
    kResync = 0x04,
    kOC0 = 0x08,
    kTest = 0x0c,
    kStart = 0x10,
    kStop = 0x14,
    kTestEnable = 0x24,
    kHardReset = 0x4c
};

enum TTSState {
  kDisconnectedLow = 0x0,
  kWarningOverflow = 0x1,
  kOutOfSync = 0x2,
  kBusy = 0x4,
  kReady = 0x8,
  kError = 0xc,
  kDisconnectedHigh = 0xf
};

struct Generics {
  uint32_t nRegions;
  uint32_t bunchCount;
  uint32_t clockRatio;
  uint32_t roChunks;
};

/*!
 * @class RegionInfo
 *      mgtIn  = MGTKind.kNoMGT
        chkiN  = CheckSumKind.kNoChk
        bufIn  = BufferSelector.kNoBuffer
        fmt    = FormatterKind.kNoFmt
        bufOut = BufferSelector.kNoBuffer
        chkOut = CheckSumKind.kNoChk
        mgtOut = MGTKind.kNoMGT
 */
struct RegionInfo {
    MGTKind mgtIn;
    CheckSumKind chkIn;
    BufferKind bufIn;
    FormatterKind fmt;
    BufferKind bufOut;
    CheckSumKind chkOut;
    MGTKind mgtOut;
};

typedef std::map<std::string, uint32_t> Snapshot;

} // namespace mp7

#endif	/* __MP7_DEFINITIONS_HPP__ */

