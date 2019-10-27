#!/bin/bash

##############################################################################
#  generic.sh - This script handles the installation of needed prerequisites
#  and Linpack for generic systems
##############################################################################

############################################################
# Install GCC prerequisites if needed for generic systems
############################################################
function prerequisitesGeneric {
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
    sudo -E apt-get install git -y
    # ARM
    if [[ $MARCH == *'arm'* || $CPU == *"AArch"* || $CPU == *"aarch"* || $CPU == *'ARM'* || $CPU == *'arm'* ]]; then
      sudo -E apt-get build-dep crossbuild-essential-arm64 -y
      sudo -E apt-get build-dep binutils-aarch64-linux-gnu -y
      # update to GCC 5
      if [ ! -f '/etc/apt/sources.list.d/ubuntu-toolchain-r-test-trusty.list' ]; then
        sudo -E add-apt-repository ppa:ubuntu-toolchain-r/test -y
        sudo -E apt-get update -y
      fi
      sudo -E apt-get install gcc-5 -y
      sudo -E apt-get install g++-5 -y
      sudo -E apt-get install gfortran-5 -y
      # Remove the previous GCC version from the default applications list (if already exists)
      sudo update-alternatives --remove-all gcc
      sudo update-alternatives --remove-all g++
      sudo update-alternatives --remove-all gfortran
      # Make GCC 5 the default compiler on the system
      sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 20
      sudo update-alternatives --config gcc
      sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-5 20
      sudo update-alternatives --config g++
      sudo update-alternatives --install /usr/bin/gfortran gfortran /usr/bin/gfortran-5 20
      sudo update-alternatives --config gfortran
    else
      # if not ARM
      sudo -E apt-get install gcc -y
      sudo -E apt-get install g++ -y
      sudo -E apt-get install gfortran -y
    fi
  # If yum is installed
  elif hash yum &>/dev/null; then
    sudo -E yum check-update -y
    sudo -E yum update -y
    sudo -E yum groupinstall "Development Tools" "Development Libraries" -y
    sudo -E yum install gcc -y
    sudo -E yum install gfortran -y
    sudo -E yum install git -y
  else
    echo
    echo "*************************************************************************"
    echo "We couldn't find the appropriate package manager for your system. Please"
    echo "try manually installing the following and rerun this program:"
    echo
    echo "gcc 4.9+"
    echo "g++ 4.9+"
    echo "gfortran 4.9+"
    echo "git"
    echo "*************************************************************************"
    echo
  fi
}


function buildOpenMPI {
  cd "$HOME" || exit

  if [ ! -d "$HOME/openmpi" ]; then
    if [ ! -f "$HOME/openmpi-1.10.2.tar.gz" ]; then
      wget http://www.open-mpi.org/software/ompi/v1.10/downloads/openmpi-1.10.2.tar.gz
    fi
    tar xf openmpi-1.10.2.tar.gz
    mv openmpi-1.10.2 openmpi
    cd openmpi/ || exit
    if [ ! -d "$HOME/openmpi/build" ]; then
      mkdir build
    fi
    cd build/ || exit
    ../configure --prefix="$HOME"/openmpi/build
    make all install
  fi

  openmpi_path=$(echo "$PATH" | grep -q "$HOME/openmpi/build/bin" || echo "n")

  if [[ "$openmpi_path" == "n" ]]; then
    export "PATH=$PATH:$HOME/openmpi/build/bin"
    echo "export PATH=\$PATH:$HOME/openmpi/build/bin" >> ~/.bashrc
  fi
}

function buildOpenBLAS {
  cd "$HOME" || exit

  if [ ! -d "$HOME/OpenBLAS" ]; then
    git clone https://github.com/xianyi/OpenBLAS.git
    cd OpenBLAS/ || exit
    make FC=mpifort CC=mpicc USE_OPENMP=1 USE_THREAD=1
  fi
}

function buildHPL {
  local make_arch
  local make_file
  make_arch=$(arch)
  make_file="Make.$make_arch"

  cd "$HOME" || exit

  if [ ! -d "$HOME/hpl" ]; then
    if [ ! -f "$HOME/hpl-2.1.tar.gz" ]; then
      wget http://www.netlib.org/benchmark/hpl/hpl-2.1.tar.gz
    fi
    tar xf hpl-2.1.tar.gz
    mv hpl-2.1 hpl
  fi

  cd "$HOME"/hpl || exit

  touch "$make_file"

  cat << "EOF" > "$make_file"
#
#  -- High Performance Computing Linpack Benchmark (HPL)
#     HPL - 2.1 - October 26, 2012
#     Antoine P. Petitet
#     University of Tennessee, Knoxville
#     Innovative Computing Laboratory
#     (C) Copyright 2000-2008 All Rights Reserved
#
#  -- Copyright notice and Licensing terms:
#
#  Redistribution  and  use in  source and binary forms, with or without
#  modification, are  permitted provided  that the following  conditions
#  are met:
#
#  1. Redistributions  of  source  code  must retain the above copyright
#  notice, this list of conditions and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce  the above copyright
#  notice, this list of conditions,  and the following disclaimer in the
#  documentation and/or other materials provided with the distribution.
#
#  3. All  advertising  materials  mentioning  features  or  use of this
#  software must display the following acknowledgement:
#  This  product  includes  software  developed  at  the  University  of
#  Tennessee, Knoxville, Innovative Computing Laboratory.
#
#  4. The name of the  University,  the name of the  Laboratory,  or the
#  names  of  its  contributors  may  not  be used to endorse or promote
#  products  derived   from   this  software  without  specific  written
#  permission.
#
#  -- Disclaimer:
#
#  THIS  SOFTWARE  IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,  INCLUDING,  BUT NOT
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE UNIVERSITY
#  OR  CONTRIBUTORS  BE  LIABLE FOR ANY  DIRECT,  INDIRECT,  INCIDENTAL,
#  SPECIAL,  EXEMPLARY,  OR  CONSEQUENTIAL DAMAGES  (INCLUDING,  BUT NOT
#  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
#  DATA OR PROFITS; OR BUSINESS INTERRUPTION)  HOWEVER CAUSED AND ON ANY
#  THEORY OF LIABILITY, WHETHER IN CONTRACT,  STRICT LIABILITY,  OR TORT
#  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# ######################################################################
#
# ----------------------------------------------------------------------
# - shell --------------------------------------------------------------
# ----------------------------------------------------------------------
#
SHELL        = /bin/sh
#
CD           = cd
CP           = cp
LN_S         = ln -s
MKDIR        = mkdir
RM           = /bin/rm -f
TOUCH        = touch
#
# ----------------------------------------------------------------------
# - Platform identifier ------------------------------------------------
# ----------------------------------------------------------------------
#
EOF
echo "ARCH         = $make_arch" >> "$make_file"
cat << "EOF" >> "$make_file"
#
# ----------------------------------------------------------------------
# - HPL Directory Structure / HPL library ------------------------------
# ----------------------------------------------------------------------
#
TOPdir       = $(HOME)/hpl
INCdir       = $(TOPdir)/include
BINdir       = $(TOPdir)/bin/$(ARCH)
LIBdir       = $(TOPdir)/lib/$(ARCH)
#
HPLlib       = $(LIBdir)/libhpl.a
#
# ----------------------------------------------------------------------
# - Message Passing library (MPI) --------------------------------------
# ----------------------------------------------------------------------
# MPinc tells the  C  compiler where to find the Message Passing library
# header files,  MPlib  is defined  to be the name of  the library to be
# used. The variable MPdir is only used for defining MPinc and MPlib.
#
MPdir        =
MPinc        =
MPlib        =
#
# ----------------------------------------------------------------------
# - Linear Algebra library (BLAS or VSIPL) -----------------------------
# ----------------------------------------------------------------------
# LAinc tells the  C  compiler where to find the Linear Algebra  library
# header files,  LAlib  is defined  to be the name of  the library to be
# used. The variable LAdir is only used for defining LAinc and LAlib.
#
LAdir        = $(HOME)/OpenBLAS
LAlib        = $(LAdir)/libopenblas.a -lpthread
#
# ----------------------------------------------------------------------
# - F77 / C interface --------------------------------------------------
# ----------------------------------------------------------------------
# You can skip this section  if and only if  you are not planning to use
# a  BLAS  library featuring a Fortran 77 interface.  Otherwise,  it  is
# necessary  to  fill out the  F2CDEFS  variable  with  the  appropriate
# options.  **One and only one**  option should be chosen in **each** of
# the 3 following categories:
#
# 1) name space (How C calls a Fortran 77 routine)
#
# -DAdd_              : all lower case and a suffixed underscore  (Suns,
#                       Intel, ...),                           [default]
# -DNoChange          : all lower case (IBM RS6000),
# -DUpCase            : all upper case (Cray),
# -DAdd__             : the FORTRAN compiler in use is f2c.
#
# 2) C and Fortran 77 integer mapping
#
# -DF77_INTEGER=int   : Fortran 77 INTEGER is a C int,         [default]
# -DF77_INTEGER=long  : Fortran 77 INTEGER is a C long,
# -DF77_INTEGER=short : Fortran 77 INTEGER is a C short.
#
# 3) Fortran 77 string handling
#
# -DStringSunStyle    : The string address is passed at the string loca-
#                       tion on the stack, and the string length is then
#                       passed as  an  F77_INTEGER  after  all  explicit
#                       stack arguments,                       [default]
# -DStringStructPtr   : The address  of  a  structure  is  passed  by  a
#                       Fortran 77  string,  and the structure is of the
#                       form: struct {char *cp; F77_INTEGER len;},
# -DStringStructVal   : A structure is passed by value for each  Fortran
#                       77 string,  and  the  structure is  of the form:
#                       struct {char *cp; F77_INTEGER len;},
# -DStringCrayStyle   : Special option for  Cray  machines,  which  uses
#                       Cray  fcd  (fortran  character  descriptor)  for
#                       interoperation.
#
F2CDEFS      =
#
# ----------------------------------------------------------------------
# - HPL includes / libraries / specifics -------------------------------
# ----------------------------------------------------------------------
#
HPL_INCLUDES = -I$(INCdir) -I$(INCdir)/$(ARCH) $(LAinc) $(MPinc)
HPL_LIBS     = $(HPLlib) $(LAlib) $(MPlib) $(LAlibAT) -lgomp
#
# - Compile time options -----------------------------------------------
#
# -DHPL_COPY_L           force the copy of the panel L before bcast;
# -DHPL_CALL_CBLAS       call the cblas interface;
# -DHPL_CALL_VSIPL       call the vsip  library;
# -DHPL_DETAILED_TIMING  enable detailed timers;
#
# By default HPL will:
#    *) not copy L before broadcast,
#    *) call the BLAS Fortran 77 interface,
#    *) not display detailed timing information.
#
HPL_OPTS     = -DHPL_CALL_CBLAS
#
# ----------------------------------------------------------------------
#
HPL_DEFS     = $(F2CDEFS) $(HPL_OPTS) $(HPL_INCLUDES)
#
# ----------------------------------------------------------------------
# - Compilers / linkers - Optimization flags ---------------------------
# ----------------------------------------------------------------------
#
CC           = mpicc
CCNOOPT      = $(HPL_DEFS)
CCFLAGS      = $(HPL_DEFS) -O2
#
# On some platforms,  it is necessary  to use the Fortran linker to find
# the Fortran internals used in the BLAS library.
#
LINKER       = mpicc
LINKFLAGS    = $(CCFLAGS) $(HPL_LIBS)
#
ARCHIVER     = ar
ARFLAGS      = r
RANLIB       = echo
#
# ----------------------------------------------------------------------
EOF

  # Edit makefile here
  sed -i "s/CC           = mpicc/CC           = mpicc -march=$MARCH -mtune=$MTUNE -lgomp -fopenmp/g" "$make_file"
  sed -i "s/LINKER       = mpicc/LINKER       = mpicc -march=$MARCH -mtune=$MTUNE -lgomp -fopenmp/g" "$make_file"

  make arch="$make_arch"

  cd "$HOME/hpl/bin/$make_arch" || exit

  mv HPL.dat HPL.dat.old

  touch HPL.dat

  cat << "EOL" > HPL.dat
HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
10000        Ns
1            # of NBs
256          NBs
1            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
1            Ps
1            Qs
16.0         threshold
1            # of panel fact
0 1 2          PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
8            NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
0 1 2       RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
0            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM,6=Psh,7=Psh2)
1            # of lookahead depth
0            DEPTHs (>=0)
0            SWAP (0=bin-exch,1=long,2=mix)
1           swapping threshold
1            L1 in (0=transposed,1=no-transposed) form
1            U  in (0=transposed,1=no-transposed) form
0            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)
EOL
}

############################################################
# Manually building and installing generic Linpack
############################################################
function buildGeneric {
  buildOpenMPI
  buildOpenBLAS
  buildHPL
}


############################################################
# Run generic Linpack
############################################################
function runGeneric {
  local make_arch
  make_arch=$(arch)

  openmpi_path=$(echo "$PATH" | grep -q "$HOME/openmpi/build/bin" && echo "y" || echo "n")

  if [[ "$openmpi_path" == "n" ]]; then
    export "PATH=$PATH:$HOME/openmpi/build/bin"
  fi
  cd "$HOME/hpl/bin/$make_arch" || exit

  ./xhpl | tee HPL.out
}
