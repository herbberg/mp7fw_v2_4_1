MP7_ROOT:=$(shell pwd)/..

include  $(MP7_ROOT)/config/mfCommonDefs.mk

PACKAGE_VER_MAJOR = 1
PACKAGE_VER_MINOR = 0
PACKAGE_VER_PATCH = 0
PACKAGE_RELEASE = 0

export CACTUS_ROOT 
export PACKAGE_VER_MAJOR PACKAGE_VER_MINOR PACKAGE_VER_PATCH

PYTHON_VERSION = $(shell python -c "import platform;print platform.python_version()")

.PHONY: all _all clean _cleanall build _buildall install _installall rpm _rpmall test _testall 

default: build

clean: _cleanall
_cleanall:
	rm -rf ${RPMBUILD_DIR}
	rm -rf build dist MANIFEST

all: _all
build: _all
buildall: _all

_all:
	python setup.py build

rpm: _rpmall
_rpmall:
	rm -rf /var/tmp/cactus* 

	python setup.py bdist_rpm --release ${PACKAGE_RELEASE}.${CACTUS_OS}.python${PYTHON_VERSION} --binary-only --force-arch=`uname -m`


install: _install
_install:
	sudo rpm -ev cactusboard-mp7-gui &>/dev/null; exit 0
	find . -name "*.rpm" -exec sudo rpm -iv {} \;
