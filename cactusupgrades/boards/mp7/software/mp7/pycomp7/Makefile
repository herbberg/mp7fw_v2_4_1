MP7_ROOT= $(shell pwd)/..

BUILD_HOME = $(MP7_ROOT)
include ${MP7_ROOT}/config/mfCommonDefs.mk

# CxxFlags := $(filter-out -std=c++0x,$(CxxFlags))
CxxFlags += \
		-ftemplate-depth-128 \
		-O0 -rdynamic -finline-functions \
		-Wno-inline -DNDEBUG

Project = mp7
Package = pycomp7

PackagePath = $(MP7_ROOT)/pycomp7
PackageName = cactusboards-mp7-pycomp7
PythonModules = ["mp7","mp7.tools","mp7.cmds"]
$(info PythonModules=${PythonModules})

Packager = Alessandro Thea

PACKAGE_VER_MAJOR = 2
PACKAGE_VER_MINOR = 4
PACKAGE_VER_PATCH = 0
PACKAGE_RELEASE = 0

PackageRequires = cactuscore-uhal-uhal >= 2.5.0, cactuscore-uhal-uhal < 2.6.0
PackageBuildRequires=${PackageRequires}

Library = cactus_mp7_pycomp7
# The leading undescore is meant to be there
LibraryTarget = pkg/mp7/_pycomp7.so

Includes = \
    include \
    $(PYTHON_INCLUDE_PREFIX) \
    $(MP7_ROOT)/mp7/include \
    $(CACTUS_ROOT)/include 

Libraries = \
	boost_python \
	cactus_mp7_mp7 

LibraryPaths = \
	$(MP7_ROOT)/mp7/lib \
    $(CACTUS_ROOT)/lib 


include ${MP7_ROOT}/config/mfRules.mk
include ${MP7_ROOT}/config/mfPythonRPMRules.mk
