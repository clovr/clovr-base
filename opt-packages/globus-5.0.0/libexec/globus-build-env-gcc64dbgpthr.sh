

# 
# Copyright 1999-2006 University of Chicago
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 

MP=""
MP_INCLUDES=""
MP_LIBS=""

CC="/usr/bin/gcc"
CPP="/usr/bin/gcc -E"
CPPFLAGS=" -I/opt/opt-packages/globus-5.0.0/include -I/opt/opt-packages/globus-5.0.0/include/gcc64dbgpthr"
CFLAGS="-g   -m64  -Wall"


LDFLAGS=" -L/opt/opt-packages/globus-5.0.0/lib -m64 "
LIBS="  -lpthread"
STATIC_LDFLAGS="@STATIC_LDFLAGS@" 

CXX="/usr/bin/c++"
CXXCPP="/usr/bin/c++ -E"
CXXFLAGS="-g   -m64 "

INSURE=""

F77="f95"
F77FLAGS=" "

F90=""
F90FLAGS=" "

AR="/usr/bin/ar"
ARFLAGS="ruv"
RANLIB="/usr/bin/ranlib"

NM="/usr/bin/nm -B"

PERL="/usr/bin/perl"

OBJEXT="o"
EXEEXT=""

OBJECT_MODE=""

CROSS="no"
cross_compiling=${CROSS}

GLOBUS_THREADS="pthreads"
GLOBUS_HOST="x86_64-unknown-linux-gnu"
GLOBUS_DEBUG="yes"
