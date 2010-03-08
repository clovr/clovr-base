/*
 * Copyright 1999-2006 University of Chicago
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 *  Defines the macros and typedefs common to all globus_common
 *  components.
 */
#if !defined(GLOBUS_COMMON_INCLUDE_H)
#define GLOBUS_COMMON_INCLUDE_H 1

#include "globus_config.h"
#ifdef WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

#ifdef __GNUC__
#define GlobusFuncName(func) static const char * _globus_func_name \
    __attribute__((__unused__)) = #func
#else
#define GlobusFuncName(func) static const char * _globus_func_name = #func
#endif

extern const char * _globus_func_name;

#define _GCSL(s) globus_common_i18n_get_string(GLOBUS_COMMON_MODULE,\
		               s)

/** GET IPv6 compatible types (at least with GNU) **/
#ifndef __USE_POSIX
#define __USE_POSIX
#endif

/*
 * include system files if we have them
 */
#ifdef HAVE_STDINT_H
#   include <stdint.h>
#endif
#ifdef HAVE_SYS_TYPES_H
#   include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
#   include <sys/stat.h>
#endif
#ifdef HAVE_IO_H
#   include <io.h>
#endif
#ifdef HAVE_SYS_SIGNAL_H
#   include <sys/signal.h>
#endif
#ifdef HAVE_SIGNAL_H
#include <signal.h>
#endif
#ifdef HAVE_UNISTD_H
#   include <unistd.h>
#endif
#ifdef HAVE_PWD_H
#   include <pwd.h>
#endif
#ifdef HAVE_NETDB_H
#   include <netdb.h>
#endif
#ifdef HAVE_NETINET_IN_H
#   include <netinet/in.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#   include <sys/param.h>
#endif
#if HAVE_FCNTL_H
#   include <fcntl.h>
#endif
#ifdef HAVE_STRING_H
#  include <string.h>
#endif
#if HAVE_CTYPE_H
#   include <ctype.h>
#endif

#ifdef HAVE_SYS_SOCKET_H
#   include <sys/socket.h>
#endif

#if defined(TARGET_ARCH_WIN32)
#   include <Winsock2.h>
#   include <process.h>
#   include <io.h>
#   include <sys/timeb.h>
#   include <signal.h>
#   include <malloc.h>
#endif

/*
 *  all windows specific includes  
 */
#include <stdarg.h>

#if defined(TIME_WITH_SYS_TIME) && !defined(HAVE_SOCKAPI_H)
#    include <sys/time.h>
#    include <time.h>
#else
#    if HAVE_SYS_TIME_H
#        include <sys/time.h>
#    else
#        include <time.h>
#    endif
#endif

#if HAVE_SOCKAPI_H
/* Net+OS 6.x's sockapi.h has a redefinition of timezone and timeval unless
 * B42 is defined
 */
#define B42 1
#include <sockapi.h>
#include <tcpip/socket.h>

/*
 * Net+OS does not implement any address families besides TCP/IP
 */
#define sockaddr sockaddr_in
#define sa_family sin_family
#define sockaddr_storage sockaddr_in

/* Also, the headers define some macros we don't want to use generally */
#undef boolean
#undef critical
#undef skip
#undef local

#endif

#include <errno.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef HAVE_FCNTL_H
#   include <fcntl.h>
#endif

#if HAVE_DIR
#  if defined(HAVE_DIRENT_H)
#   include <dirent.h>
#   define NAMLEN(dirent) strlen((dirent)->d_name)
#  else
#   define dirent direct
#   define NAMLEN(dirent) (dirent)->d_namlen
#   define HAVE_DIRENT_NAMELEN 1
#   if defined(HAVE_SYS_NDIR_H)
#       include <sys/ndir.h>
#   endif
#   if defined(HAVE_SYS_DIR_H)
#       include <sys/dir.h>
#   endif
#   if defined(HAVE_NDIR_H)
#       include <ndir.h>
#   endif
#  endif
#elif defined TARGET_ARCH_NETOS
#include "globus_netos_libc.h"
#else
typedef void * DIR;
#endif

#if defined(HAVE_SYS_UIO_H)
#   include <sys/uio.h>
#endif

#ifndef HAVE_OPENDIR
#define HAVE_OPENDIR 1
#define GLOBUS_IMPLEMENT_OPENDIR 1
extern DIR * opendir(const char *filename);
#endif /* !HAVE_OPENDIR */

#ifndef HAVE_READDIR
#define HAVE_READDIR 1
#define GLOBUS_IMPLEMENT_READDIR 1
extern struct dirent * readdir(DIR *dir); 
#endif /* !HAVE_READDIR */

#ifndef HAVE_CLOSEDIR
#define HAVE_CLOSEDIR 1
#define GLOBUS_IMPLEMENT_CLOSEDIR 1
extern int closedir(DIR *dir);
#endif /* !HAVE_CLOSEDIR */

#ifndef HAVE_REWINDDIR
#define HAVE_REWINDDIR 1
#define GLOBUS_IMPLEMENT_REWINDDIR 1
extern void rewinddir(DIR *dir);
#endif /* !HAVE_REWINDDIR */

#ifndef HAVE_INET_PTON
#define HAVE_INET_PTON 1
#define GLOBUS_IMPLEMENT_INET_PTON 1
int inet_pton(int af, const char *src, void *dst);
#endif /* !HAVE_INET_PTON */

#ifndef HAVE_INET_ADDR
#define HAVE_INET_ADDR 1
#define GLOBUS_IMPLEMENT_INET_ADDR 1
extern uint32_t inet_addr(const char * cp);
#endif /* !HAVE_INET_ADDR */


#include <limits.h>
#include <assert.h>

/* Net+OS 6.x */
#ifdef HAVE_TX_API_H
#include <tx_api.h>
#endif

/******************************************************************************
				 Define macros
******************************************************************************/

/*
 * Various macro definitions for assertion checking
 */
#if 0
	void globus_dump_stack();
	#define GLOBUS_DUMP_STACK() globus_dump_stack() 
#else
	#define GLOBUS_DUMP_STACK()
#endif

#if defined(BUILD_DEBUG)
#   define globus_assert(assertion)					    \
    do {							            	    \
        if (!(assertion))						        \
        {								                \
            fprintf(stderr, "Assertion " #assertion 	\
		    " failed in file %s at line %d\n",			\
		    __FILE__, __LINE__);				        \
	    GLOBUS_DUMP_STACK();						    \
	    abort();                                        \
         }								                \
    } while(0)

#   define globus_assert_string(assertion, string)      \
    do {								                \
    	if (!(assertion))					      	    \
    	{								                \
    	    fprintf(stderr, "Assertion " #assertion		\
		    " failed in file %s at line %d: %s",    	\
		    __FILE__, __LINE__, string);			    \
	    GLOBUS_DUMP_STACK();						    \
	    abort();                                        \
    	}								                \
    } while(0)
#else /* BUILD_DEBUG */
#   define globus_assert(assertion)
#   define globus_assert_string(assertion, string)
#endif /* BUILD_DEBUG */

#define GLOBUS_MAX(V1,V2) (((V1) > (V2)) ? (V1) : (V2))
#define GLOBUS_MIN(V1,V2) (((V1) < (V2)) ? (V1) : (V2))

#ifndef EXTERN_C_BEGIN
#ifdef __cplusplus
#define EXTERN_C_BEGIN extern "C" {
#define EXTERN_C_END }
#else
#define EXTERN_C_BEGIN
#define EXTERN_C_END
#endif
#endif

#ifdef HAVE_PTHREAD
#   define GLOBUS_THREAD_INCLUDE "globus_thread_pthreads.h"
#endif

#ifdef HAVE_SOLARISTHREADS
#   define GLOBUS_THREAD_INCLUDE "globus_thread_solaristhreads.h"
#endif

#ifdef HAVE_EXTERNALTHREADS
#   define GLOBUS_THREAD_INCLUDE "globus_thread_external.h"
#endif

#ifdef HAVE_SPROC
#   define GLOBUS_THREAD_INCLUDE "globus_thread_sproc.h"
#endif

#ifdef HAVE_WINDOWS_THREADS
#   define GLOBUS_THREAD_INCLUDE "globus_thread_windows.h"
#endif

#ifdef BUILD_LITE
#   define GLOBUS_THREAD_INCLUDE "globus_thread_none.h"
#endif

#if !defined(TARGET_ARCH_WIN32)
    typedef size_t                                      globus_size_t;
    typedef ssize_t                                     globus_ssize_t;
#else
    typedef unsigned long                               globus_size_t;
    typedef long                                        globus_ssize_t;
#endif

#ifdef HAVE_SOCKLEN_T
    typedef socklen_t                                   globus_socklen_t;
#else
    typedef int                                         globus_socklen_t;
#endif

#if !defined(HAVE_STRUCT_IOVEC)
/* The ordering of the fields must match those in WSABUF */
    struct  iovec  
    {
        unsigned long      iov_len;  /* Length in bytes.  */
        char *             iov_base;  /* Starting address.  */
    };
#endif 

/* POSIX error code remapping */
#ifdef TARGET_ARCH_WIN32
	#define EWOULDBLOCK EAGAIN
	#define ETIMEDOUT 145 /* according to POSIX */
	#define EINPROGRESS 150 /* according to POSIX */
#endif

#if defined(HAVE_INTTYPES_H) && !defined(TARGET_ARCH_CYGWIN)
#    include <inttypes.h>
#elif defined(HAVE_SYS_INTTYPES_H)
#    include <sys/inttypes.h>
#endif

#if defined(TARGET_ARCH_WIN32)
#    define HAVE_UINT32_T 1
#    define uint32_t ULONG32
#    define vsnprintf _vsnprintf
#endif

#ifndef MAXHOSTNAMELEN
#define MAXHOSTNAMELEN 64
#endif

typedef unsigned char	                                globus_byte_t;
typedef int		                                globus_bool_t;
typedef uint32_t                                        globus_result_t;
typedef GLOBUS_OFF_T                                    globus_off_t;

#define GLOBUS_TRUE    1
#define GLOBUS_FALSE   0
#define GLOBUS_NULL    0
#define GLOBUS_SUCCESS 0
#define GLOBUS_FAILURE  -1

#endif  /* GLOBUS_COMMON_INCLUDE_H */

