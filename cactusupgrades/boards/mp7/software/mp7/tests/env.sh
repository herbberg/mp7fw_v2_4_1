function pathadd() {
  # TODO add check for empty path
  # and what happens if $1 == $2
  # Copy into temp variables
  PATH_NAME=$1
  PATH_VAL=${!1}
  if [[ ":$PATH_VAL:" != *":$2:"* ]]; then
    PATH_VAL="$2${PATH_VAL:+":$PATH_VAL"}"
    echo "- $1 += $2"

    # use eval to reset the target
    eval "$PATH_NAME=$PATH_VAL"
  fi

}


CACTUS_ROOT=/opt/cactus
MP7_TESTS=$( readlink -f $(dirname $BASH_SOURCE)/ )
MP7_ROOT=$( readlink -f ${MP7_TESTS}/.. )
MP7_ETC=$( readlink -f ${MP7_ROOT}/mp7/etc)


pathadd LD_LIBRARY_PATH "${CACTUS_ROOT}/lib"

# add to path
#PATH="${MP7_ROOT}/tests/scripts:${PATH}"
pathadd PATH "${MP7_ROOT}/tests/bin"
pathadd PATH "${MP7_ROOT}/tests/scripts"
pathadd PATH "${MP7_ROOT}/tests/scripts/tmt"
pathadd PATH "${MP7_ROOT}/tests/scripts/daq"
pathadd PATH "${MP7_ROOT}/tests/scripts/dev"
pathadd PATH "${MP7_ROOT}/tests/scripts/tests"
pathadd PATH "${MP7_ROOT}/tests/scripts/utests"
pathadd PATH "${MP7_ROOT}/tests/scripts/eyescans"
pathadd LD_LIBRARY_PATH "${MP7_ROOT}/tests/lib"

# add python path
pathadd PYTHONPATH "${MP7_ROOT}/pycomp7/pkg"
pathadd PYTHONPATH "${MP7_ROOT}/tests/python"

# add libary path
#pathadd LD_LIBRARY_PATH "${MP7_ROOT}/mp7/lib/${XDAQ_OS}/${XDAQ_PLATFORM}"
pathadd LD_LIBRARY_PATH "${MP7_ROOT}/mp7/lib"

if [ -n "${AMC13_STANDALONE_ROOT}" ]; then
    pathadd PATH "${AMC13_STANDALONE_ROOT}/tools/bin"
    pathadd LD_LIBRARY_PATH "${AMC13_STANDALONE_ROOT}/amc13/lib"
    pathadd LD_LIBRARY_PATH "${AMC13_STANDALONE_ROOT}/tools/lib"
    pathadd PYTHONPATH "${AMC13_STANDALONE_ROOT}/python/pkg"
fi
#export XDAQ_ROOT XDAQ_OS XDAQ_PLATFORM CACTUS_ROOT MP7_ROOT LD_LIBRARY_PATH PYTHONPATH
export CACTUS_ROOT MP7_TESTS MP7_ROOT MP7_ETC LD_LIBRARY_PATH PYTHONPATH
