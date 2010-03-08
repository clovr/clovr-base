

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

#
# source this file to properly set up your environment for globus applications
# this requires that GLOBUS_LOCATION be set.
# GLOBUS_PATH will be set by this script to save the current location,
# should you decide to change GLOBUS_LOCATION to a different location and
# re source this script, the old GLOBUS_PATH information will be removed from
# your environment before applying the new GLOBUS_LOCATION
#

if ( ! $?GLOBUS_LOCATION ) then
    echo "ERROR: environment variable GLOBUS_LOCATION not defined"
    exit 1
endif

if ( ! $?LD_LIBRARY_PATH ) then
    setenv LD_LIBRARY_PATH ''
endif

if ( ! $?DYLD_LIBRARY_PATH ) then
    setenv DYLD_LIBRARY_PATH ''
endif

if ( ! $?LIBPATH ) then
    setenv LIBPATH '/usr/lib:/lib'
endif

if ( ! $?SHLIB_PATH ) then
    setenv SHLIB_PATH ''
endif

if ( -d ${GLOBUS_LOCATION}/lib/sasl && ! $?SASL_PATH ) then
    setenv SASL_PATH ''
endif

if ( $?GLOBUS_PATH ) then
    setenv PATH `echo "${PATH}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    setenv LD_LIBRARY_PATH `echo "${LD_LIBRARY_PATH}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    setenv DYLD_LIBRARY_PATH `echo "${DYLD_LIBRARY_PATH}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    setenv LIBPATH `echo "${LIBPATH}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    setenv SHLIB_PATH `echo "${SHLIB_PATH}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    if ( $?SASL_PATH ) then
        setenv SASL_PATH `echo "${SASL_PATH}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    endif
    if ( $?MANPATH ) then
        setenv MANPATH `echo "${MANPATH}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    endif
    if ( $?LD_LIBRARYN32_PATH ) then
        setenv LD_LIBRARYN32_PATH `echo "${LD_LIBRARYN32_PATH}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    endif
    if ( $?LD_LIBRARY64_PATH ) then
        setenv LD_LIBRARY64_PATH `echo "${LD_LIBRARY64_PATH}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    endif
    if ( $?PERL5LIB ) then
        setenv PERL5LIB `echo "${PERL5LIB}" | sed -e "s%:${GLOBUS_PATH}[^:]*%%g" -e "s%^${GLOBUS_PATH}[^:]*:\{0,1\}%%"`
    endif
endif

setenv PATH `echo "${PATH}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
setenv LD_LIBRARY_PATH `echo "${LD_LIBRARY_PATH}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
setenv DYLD_LIBRARY_PATH `echo "${DYLD_LIBRARY_PATH}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
setenv LIBPATH `echo "${LIBPATH}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
setenv SHLIB_PATH `echo "${SHLIB_PATH}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
if ( $?SASL_PATH ) then
    setenv SASL_PATH `echo "${SASL_PATH}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
endif
if ( $?MANPATH ) then
    setenv MANPATH `echo "${MANPATH}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
endif
if ( $?LD_LIBRARYN32_PATH ) then
    setenv LD_LIBRARYN32_PATH `echo "${LD_LIBRARYN32_PATH}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
endif
if ( $?LD_LIBRARY64_PATH ) then
    setenv LD_LIBRARY64_PATH `echo "${LD_LIBRARY64_PATH}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
endif
if ( $?PERL5LIB ) then
    setenv PERL5LIB `echo "${PERL5LIB}" | sed -e "s%:${GLOBUS_LOCATION}[^:]*%%g" -e "s%^${GLOBUS_LOCATION}[^:]*:\{0,1\}%%"`
endif


setenv GLOBUS_PATH "${GLOBUS_LOCATION}"
setenv PATH "${GLOBUS_LOCATION}/bin:${GLOBUS_LOCATION}/sbin:${PATH}";

if ( $?MANPATH ) then
    set DELIM
    if ( "X${MANPATH}" != "X" ) then
        set DELIM=:
    endif
    setenv MANPATH "${GLOBUS_LOCATION}/man${DELIM}${MANPATH}"
endif

set DELIM=
if ( "X${LD_LIBRARY_PATH}" != "X" ) then
    set DELIM=:
endif
setenv LD_LIBRARY_PATH "${GLOBUS_LOCATION}/lib${DELIM}${LD_LIBRARY_PATH}"

set DELIM=
if ( "X${DYLD_LIBRARY_PATH}" != "X" ) then
    set DELIM=:
endif
setenv DYLD_LIBRARY_PATH "${GLOBUS_LOCATION}/lib${DELIM}${DYLD_LIBRARY_PATH}"

set DELIM=
if ( "X${LIBPATH}" != "X" ) then
    set DELIM=:
endif
setenv LIBPATH "${GLOBUS_LOCATION}/lib${DELIM}${LIBPATH}"

set DELIM=
if ( "X${SHLIB_PATH}" != "X" ) then
    set DELIM=:
endif
setenv SHLIB_PATH "${GLOBUS_LOCATION}/lib${DELIM}${SHLIB_PATH}"

if ( -d ${GLOBUS_LOCATION}/lib/sasl ) then
    set DELIM=
    if ( "X${SASL_PATH}" != "X" ) then
	set DELIM=:
    endif
    setenv SASL_PATH "${GLOBUS_LOCATION}/lib/sasl${DELIM}${SASL_PATH}"
endif

if ( $?LD_LIBRARYN32_PATH ) then
    set DELIM
    if ( "X${LD_LIBRARYN32_PATH}" != "X" ) then
        set DELIM=:
    endif
    setenv LD_LIBRARYN32_PATH "${GLOBUS_LOCATION}/lib${DELIM}${LD_LIBRARYN32_PATH}"
endif

if ( $?LD_LIBRARY64_PATH ) then
    set DELIM
    if ( "X${LD_LIBRARY64_PATH}" != "X" ) then
        set DELIM=:
    endif
    setenv LD_LIBRARY64_PATH "${GLOBUS_LOCATION}/lib${DELIM}${LD_LIBRARY64_PATH}"
endif

if ( -d ${GLOBUS_LOCATION}/lib/perl ) then
    set DELIM
    if ( $?PERL5LIB ) then
        set DELIM=:
    else
        setenv PERL5LIB ''
        DELIM=:
    endif
    setenv PERL5LIB "${GLOBUS_LOCATION}/lib/perl${DELIM}${PERL5LIB}"
endif
