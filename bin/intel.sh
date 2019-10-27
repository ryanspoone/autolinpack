#!/bin/bash

##############################################################################
#  generic.sh - This script handles the installation of needed prerequisites
#  and Linpack for generic systems
##############################################################################


############################################################
# Install GCC prerequisites if needed for Intel systems
############################################################
function prerequisitesIntel {
  if hash apt-get &>/dev/null; then
    sudo -E apt-get update

    # make sure that aptitude is installed
    # "aptitude safe-upgrade" will upgrade the kernel
    if hash aptitude &>/dev/null; then
      sudo -E aptitude safe-upgrade
    else
      sudo -E apt-get aptitude -y
      sudo -E aptitude safe-upgrade
    fi

    sudo -E apt-get install build-essential -y
    sudo -E apt-get install gcc -y
    sudo -E apt-get install gfortran -y
  # If yum is installed
  elif hash yum &>/dev/null; then
    sudo -E yum check-update -y
    sudo -E yum update -y
    sudo -E yum groupinstall "Development Tools" "Development Libraries" -y
    sudo -E yum install gcc -y
    sudo -E yum install gfortran -y
  else
    echo
    echo "*************************************************************************"
    echo "We couldn't find the appropriate package manager for your system. Please"
    echo "try manually installing the following and rerun this program:"
    echo
    echo "gcc"
    echo "gfortran"
    echo "*************************************************************************"
    echo
  fi
}


############################################################
# Setting up Intel Linpack
############################################################
function buildLinpack {
  cd "$HOME" || exit
  if [ ! -d "$HOME/l_lpk_p_11.2.2.010" ]; then
    if [ ! -f "$HOME/l_lpk_p_11.2.2.010.tgz" ]; then
      wget http://registrationcenter.intel.com/irc_nas/5232/l_lpk_p_11.2.2.010.tgz
    fi
    tar xf l_lpk_p_11.2.2.010.tgz
  fi
  cd "$HOME/l_lpk_p_11.2.2.010/linpack_11.2.2/benchmarks/linpack/" || exit
  echo "Sample Intel(R) Optimized LINPACK Benchmark data file (lininput_xeon64)
Intel(R) Optimized LINPACK Benchmark data
$NUMBER_OF_TESTS
$PROBLEM_SIZE
$LEADING_DIMENSION
$ITERATION
$ALIGNMENT" > "$HOME/l_lpk_p_11.2.2.010/linpack_11.2.2/benchmarks/linpack/lininput_xeon64"
}


############################################################
# Run Intel Linpack
############################################################
function runLinpack {
  cd "$HOME/l_lpk_p_11.2.2.010/linpack_11.2.2/benchmarks/linpack/" || exit
  ./runme_xeon64 2>&1 | tee linpack.txt
}


############################################################
# Setting up Intel MP Linpack
############################################################
function buildMPLinpack {
  cd "$HOME" || exit
  if [ ! -d "$HOME/l_lpk_p_11.2.2.010" ]; then
    if [ ! -f "$HOME/l_lpk_p_11.2.2.010.tgz" ]; then
      wget http://registrationcenter.intel.com/irc_nas/5232/l_lpk_p_11.2.2.010.tgz
    fi
    tar xf l_lpk_p_11.2.2.010.tgz
  fi
  cd "$HOME/l_lpk_p_11.2.2.010/linpack_11.2.2/benchmarks/mp_linpack/" || exit
  cp HPL.dat bin_intel/intel64/
}


############################################################
# Run Intel MP Linpack
############################################################
function runMPLinpack {
  cd "$HOME/l_lpk_p_11.2.2.010/linpack_11.2.2/benchmarks/mp_linpack/bin_intel/intel64/" || exit
  ./xhpl_offload_intel64 -n 45000 -b 256 -p 1 -q 1 2>&1 | tee mp_linpack.txt
}
