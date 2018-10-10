# MP7 Package Software Guidelines

## Coding convention
Largely inspired to the uHAL package.

 * Indentation: 2 spaces
 * Braces placement: inline 

 * Arguments: name starts with `a`:  `aArgument`
 * Data members: name starts with `m`: `mMemberName`
 * Methods: `getData`, `sendData`
 * Enumerators and constants: Use a k followed by mixed case, e.g., `kDaysInAWeek`

## Naming conventions

 * Channels
 * Links 

## Maps

Two types of maps are used.

 * `boost::unordered_map<std::string, T>`
 * `std::map<uint32_t, T>`
