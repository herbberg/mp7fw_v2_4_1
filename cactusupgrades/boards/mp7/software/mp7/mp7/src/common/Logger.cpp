#include "mp7/Logger.hpp"


// Boost Headers
#include <boost/assign.hpp>

// C++ Headers
#include <iostream>
#include "boost/date_time/posix_time/posix_time.hpp"

// uHAL includes
#include "uhal/ValMem.hpp"

namespace mp7 {
namespace logger {

namespace ansi {
  const char *const kEsc       = "\033[";
  const char *const kReset     = "\033[0m";
  const char *const kBlack     = "\033[30m";
  const char *const kRed       = "\033[31m";
  const char *const kGreen     = "\033[32m";
  const char *const kYellow    = "\033[33m";
  const char *const kBlue      = "\033[34m";

  const char *const kMagenta   = "\033[35m";
  const char *const kCyan      = "\033[36m";
  const char *const kWhite     = "\033[37m";

  const char *const kBckBlack  = "\033[40m";
  const char *const kBckRed    = "\033[41m";
  const char *const kBckGreen  = "\033[42m";
  const char *const kBckYellow = "\033[43m";
  const char *const kBckBlue   = "\033[44m";
  const char *const kBckMagenta= "\033[45m";
  const char *const kBckCyan   = "\033[46m";
  const char *const kBckWhite  = "\033[47m";

  const char *const kUnderline = "\033[4m";
  const char *const kBlink     = "\033[5m";
  const char *const kBright    = "\033[1m";
  const char *const kDark      = "\033[2m";
}

LogLevel Log::logThreshold_ = kInfo;

const char* Log::logNames_[] = {
    "ERROR",
    "WARNING",
    "NOTICE",
    "INFO",
    "DEBUG",
    "DEBUG1",
    "DEBUG2",
    "DEBUG3",
    "DEBUG4"
};

const char* logColors[] = {
    ansi::kRed,
    ansi::kYellow,
    ansi::kGreen,
    ansi::kBlue,
    ansi::kCyan,
    ansi::kCyan,
    ansi::kCyan,
    ansi::kCyan,
    ansi::kCyan
    };

Log::Log() {
}

Log::Log(const Log&) {
}

Log::~Log() {
    if (messageLevel_ <= logThreshold()) {
        os_ << std::endl;
        push(messageLevel_, "mp7", os_.str().c_str());
    }
}

//Log&
//Log::operator=(const Log&) {
//}

std::ostringstream&
Log::get(LogLevel level) {
    messageLevel_ = level;
    return os_;
}

void
Log::push(LogLevel level, const std::string& source, const std::string& message) {
      // Standard, simple date & time (up to seconds) formatting from ctime.h
    time_t now = time(NULL);
    char timeText[20];
    strftime(timeText, 20, "%Y-%m-%d %H:%M:%S", localtime(&now));

    // Get milliseconds offset from boost::posix_time
    const boost::posix_time::time_duration td = boost::posix_time::microsec_clock::local_time().time_of_day();
    const long hours = td.hours();
    const long minutes = td.minutes();
    const long seconds = td.seconds();
    const long millisec = td.total_milliseconds() - ((hours * 3600 + minutes * 60 + seconds) * 1000);


    fprintf(stdout, "%s%s.%03ld %s %-8s | %s%s", logColors[level], timeText, millisec, source.c_str(), logNames_[level], message.c_str(),ansi::kReset);
    fflush(stdout);
}

LogLevel& Log::logThreshold() {
    return logThreshold_;
}

void
Log::setLogThreshold(LogLevel level) {
    logThreshold_ = level;
}


// const std::string&
// Log::toString(LogLevel level) {
//     std::map<LogLevel, std::string>::const_iterator it = logNames_.find(level);
//     return it->second;
// }

std::string boolFmt(const bool value)
{
  if(value)
    return std::string("true");
  else
    return std::string("false");
}


std::string hexFmt(const uint32_t value)
{
  std::ostringstream oss;
  oss << "0x" << std::hex << value;
  return oss.str();
}


std::string hexFmt(const uhal::ValWord<uint32_t>& valWord)
{
  std::ostringstream oss;
  oss << "0x" << std::hex << valWord.value();
  return oss.str();
}

template <typename T>
std::string vecFmt(const std::vector<T>& aVec)
{
  std::ostringstream oss;
  oss << "[";

  for(typename std::vector<T>::const_iterator it=aVec.begin(); it != aVec.end(); it++)
    oss << *it << ",";
  oss.seekp(oss.tellp()-1l);
  oss << "]";

  return oss.str();
}


template <typename T>
std::string shortVecFmt(const std::vector<T>& aVec)
{
  if (aVec.size() == 0)
    return "[]";
  else if (aVec.size() == 1)
    return "[" + boost::lexical_cast<std::string>(aVec.at(0)) + "]";

  std::ostringstream oss;
  oss << "[";

  // Initial search range
  T first = aVec.at(0);
  T last   = first;
  for(typename std::vector<T>::const_iterator it=aVec.begin()+1; it != aVec.end(); it++)
  {
    // if *it is contiguous to last, carry on searching
    if((*it) == (last + 1))
    {
      last = *it;
      continue;
    }

    if (first == last)
      // if first and last are the same, this is an isolated number
      oss << first << ",";
    else
      // otherwise it's a range
      oss << first << "-" << last << ",";

    // *it is the first value of the new range
    first = *it;
    last = *it;
  }

  // Process the last range
  if (first == last)
    oss << first << ",";
  else
    oss << first << "-" << last << ",";

  // Is this actually necessary?
  // Replace final "," with a "]"
  oss.seekp(oss.tellp()-1l);
  oss << "]";

  return oss.str();
}

} // logger
} // mp7


template std::string mp7::logger::vecFmt<uint32_t>(const std::vector<uint32_t>& aVec);
template std::string mp7::logger::shortVecFmt<uint32_t>(const std::vector<uint32_t>& aVec);

