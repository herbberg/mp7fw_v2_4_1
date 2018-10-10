MP7_ROOT= $(shell pwd)/..

BUILD_HOME = $(MP7_ROOT)
include ${MP7_ROOT}/config/mfCommonDefs.mk

Project = mp7
Package = tests

PackagePath = $(MP7_ROOT)/tests
PackageName = cactusboards-mp7-tests

Packager = Alessandro Thea

PACKAGE_VER_MAJOR = 2
PACKAGE_VER_MINOR = 4
PACKAGE_VER_PATCH = 0
PACKAGE_RELEASE = 0

PackageRequires = cactuscore-uhal-uhal >= 2.5.0, cactuscore-uhal-uhal < 2.6.0
PackageBuildRequires = ${PackageRequires}

Library = # cactus_mp7_tests

Includes = include \
    $(MP7_ROOT)/mp7/include \
    $(CACTUS_ROOT)/include 

Libraries = \
    boost_system \
    boost_program_options \
    boost_date_time \
    cactus_mp7_mp7 

LibraryPaths = \
    lib/ \
    $(MP7_ROOT)/mp7/lib \
    $(CACTUS_ROOT)/lib


ExecutableLibraries = ${Libraries} \
    cactus_uhal_log \
    cactus_uhal_uhal \
    cactus_uhal_grammars \
    cactus_extern_pugixml

ifdef USE_AMC13
$(info Compiling testDAQ)
ExecutableLibraries += cactus_amc13_amc13
ifdef AMC13_STANDALONE_ROOT

Includes = include \
    $(MP7_ROOT)/mp7/include \
    $(AMC13_STANDALONE_ROOT)/amc13/include \
    $(CACTUS_ROOT)/include

LibraryPaths = \
    lib/ \
    $(MP7_ROOT)/mp7/lib \
    $(AMC13_STANDALONE_ROOT)/amc13/lib \
    $(CACTUS_ROOT)/lib
endif
else
IgnoreSources = \
	src/common/testDAQ.cxx \
	src/common/testDAQP5.cxx 
	
$(info Ignoring ${IgnoreSources})
endif

include ${MP7_ROOT}/config/mfRules.mk
include ${MP7_ROOT}/config/mfRPMRules.mk
