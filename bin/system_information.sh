#!/bin/bash

##############################################################################
#  system_info.sh - This script handles the gathering the system information
#  and setting the appropriate flags for GCC or binary for ICC.
##############################################################################


##############################################################################
# Will display make, type, and model number
# ARM64 X-Gene1 Example: AArch64 Processor rev 0 (aarch64)
# Intel Example: Intel Xeon D-1540
# Power8 Example: ppc64le
##############################################################################
function getCPU {
  local arch

  CPU=$(grep -m 1 'model name' /proc/cpuinfo | sed 's/model name\s*\:\s*//g;s/(R)//g;s/ @.*//g;s/CPU //g;s/Genuine //g')

  if [ -z "$CPU" ]; then
    CPU=$(lscpu | grep -m 1 "Model name:" | sed 's/Model name:\s*//g;s/(R)//g;s/ @.*//g;s/CPU //g;s/Genuine //g')
  fi

  if [ -z "$CPU" ]; then
    CPU=$(lscpu | grep -m 1 "CPU:" | sed 's/CPU:\s*//g;s/(R)//g;s/ @.*//g;s/CPU //g;s/Genuine //g')
  fi

  if [ -z "$CPU" ]; then
    arch=$(lscpu | grep -m 1 "Architecture:" | sed 's/Architecture:\s*//g;s/x86_//;s/i[3-6]86/32/')

    if [[ $arch == *'aarch'* || $arch == *'arm'* ]]; then
      CPU="Unknown ARM"
    elif [[ $arch == *'ppc'* ]]; then
      CPU="Unknown PowerPC"
    elif [[ $arch == *'x86_64'* || $arch == *'32'* ]]; then
      CPU="Unknown Intel"
    else
      CPU="Unknown CPU"
    fi
  fi

  export CPU
}


############################################################
# Get OS and version
# Example OS: Ubuntu
# Example VER: 14.04
############################################################
function getOS {
  if [ -f /etc/lsb-release ]; then
    # shellcheck disable=SC1091,SC1090
    . /etc/lsb-release
    OS=$DISTRIB_ID
    VER=$DISTRIB_RELEASE
  elif [ -f /etc/debian_version ]; then
    OS='Debian'
    VER=$(cat /etc/debian_version)
  elif [ -f /etc/redhat-release ]; then
    OS='Redhat'
    VER=$(cat /etc/redhat-release)
  else
    OS=$(uname -s)
    VER=$(uname -r)
  fi

  export OS
  export VER
}


############################################################
# Detect os architecture, os distribution, and os version
# Displays bits, either 64 or 32
############################################################
function getArch {
  ARCH=$(lscpu | grep -m 1 "Architecture:" | sed 's/Architecture:\s*//g;s/x86_//;s/i[3-6]86/32/')

  # If it is an ARM system
  if [[ $ARCH == *'arm'* ]]; then
    # Get the ARM version number
    ARM_V=$(echo "$ARCH" | sed 's/armv//g' | head -c1)
    # If ARMv8 or greater, set to 62 bit
    if [[ "$ARM_V" -ge 8 ]]; then
      ARCH='64'
    else
      ARCH='32'
    fi
  fi
  if [[ $ARCH == *'aarch64'* || $ARCH == *'ppc64le'* ]]; then
    ARCH='64'
  fi

  export ARCH
}


############################################################
# Virtual cores / logical cores / threads
############################################################
function getThreads {
  PHYSICAL_PROCESSORS=$(lscpu | grep -m 1 "Socket(s):" | sed 's/Socket(s):\s*//g')
  THREADS_PER_CORE=$(lscpu | grep -m 1 "Thread(s) per core:" | sed 's/Thread(s) per core:\s*//g')
  CORES=$(lscpu | grep -m 1 "Core(s) per socket:" | sed 's/Core(s) per socket:\s*//g')
  TOTAL_CORES=$((PHYSICAL_PROCESSORS * CORES))
  LOGICAL_CORES=$((THREADS_PER_CORE * TOTAL_CORES))
  OMP_NUM_THREADS="$LOGICAL_CORES"

  export PHYSICAL_PROCESSORS
  export LOGICAL_CORES
  export CORES
  export TOTAL_CORES
  export OMP_NUM_THREADS
}


############################################################
# Get the machine's RAM amount
############################################################
function getMachineRAM {
  # Get RAM in KB
  RAM_KB=$(grep -m 1 "MemTotal:" /proc/meminfo | sed "s/MemTotal:\s*//g;s/kB//g"| tr -d "\t\n\r[:space:]")

  # Convert RAM to GB
  RAM_GB=$((RAM_KB / 1000 / 1000))

  export RAM_GB
}


############################################################
# Get the appropriate GCC flags
############################################################
function getCompilerInfo {
  MARCH=$(gcc -march=native -Q --help=target 2> /dev/null | grep -m 1 '\-march=' | sed "s/-march=//g" | tr -d "\t\n\r[:space:]")
  if [ $? -ne 0 ] || [[ "$MARCH" == *"native"* ]] || [[ "$MARCH" == "" ]]; then
    echo
    echo "The system couldn't detect the compiler machine architecture."
    echo
    echo -n "What is the appropriate '-march=' flag? "
    read -r MARCH
    MARCH=$(echo -e "${MARCH}" | tr -d "\t\n\r[:space:]")
    echo
  fi

  MTUNE=$(gcc -march="$MARCH" -mtune=native -Q --help=target 2> /dev/null | grep -m 1 '\-mtune=' | sed "s/-mtune=//g" | tr -d "\t\n\r[:space:]")
  if [ $? -ne 0 ] || [[ "$MTUNE" == *"native"* ]] || [[ "$MTUNE" == "" ]]; then
    echo
    echo "The system couldn't detect the compiler machine tuning."
    echo
    echo -n "What is the appropriate '-mtune=' flag? "
    read -r MTUNE
    MTUNE=$(echo -e "${MTUNE}" | tr -d "\t\n\r[:space:]")
    echo
  fi

  GCC_VER=$(gcc --version | sed -rn 's/gcc\s\(.*\)\s([0-9]*\.[0-9]*\.[0-9]*)/\1/p')

  export GCC_VER
  export MARCH
  export MTUNE
}


############################################################
# Function to get all system information
############################################################
function getSystemInfo {
  getOS
  getArch
  getThreads
  getMachineRAM
  getCompilerInfo
  # Display system information
  echo
  echo '*************************** System Information **************************'
  echo
  echo "CPU:                         $CPU"
  echo "Architecture:                $ARCH bit"
  echo "OS:                          $OS $VER"
  echo
  echo "Physical Processors:         $PHYSICAL_PROCESSORS"
  echo "Total Logical Processors:    $LOGICAL_CORES"
  echo "Cores Per Processor:         $CORES"
  echo "System Core Count:           $TOTAL_CORES"
  echo
  echo "Total RAM:                   $RAM_GB GB"
  echo
  echo '************************** Compiler Information *************************'
  echo
  echo "Compiler:           GNU Compiler Collection (GCC) $GCC_VER"
  echo "Compiler flags:     -march=$MARCH -mtune=$MTUNE"
  echo
  echo '*************************************************************************'
  echo
  sleep 10
}
