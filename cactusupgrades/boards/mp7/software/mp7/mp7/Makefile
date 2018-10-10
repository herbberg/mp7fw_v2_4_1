MP7_ROOT= $(shell pwd)/..

BUILD_HOME = $(MP7_ROOT)
include ${MP7_ROOT}/config/mfCommonDefs.mk

Project = mp7
Package = mp7

PackagePath = $(MP7_ROOT)/mp7
PackageName = cactusboards-mp7-mp7

Packager = Alessandro Thea

PACKAGE_VER_MAJOR = 2
PACKAGE_VER_MINOR = 4
PACKAGE_VER_PATCH = 0
PACKAGE_RELEASE = 0

PackageRequires = cactuscore-uhal-uhal >= 2.5.0, cactuscore-uhal-uhal < 2.6.0
PackageBuildRequires = ${PackageRequires}

Library = cactus_mp7_mp7

Includes = \
    include \
    $(CACTUS_ROOT)/include 

Libraries = \
    boost_date_time \
    cactus_uhal_log \
    cactus_uhal_uhal

LibraryPaths = \
  $(CACTUS_ROOT)/lib 

include ${MP7_ROOT}/config/mfRules.mk
include ${MP7_ROOT}/config/mfRPMRules.mk

CxxFlags += \
		-D'MP7_ETC_DEFAULT="/opt/cactus/etc/mp7"'

