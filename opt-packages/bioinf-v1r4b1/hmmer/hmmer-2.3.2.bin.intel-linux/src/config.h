/* src/config.h.  Generated by configure.  */
/* @configure_input@
 *
 * config.h.in -> config.h
 *
 * Configurable compile-time parameters and options in HMMER.
 * config.h is generated from config.h.in by the ./configure script.
 * DO NOT EDIT config.h; only edit config.h.in.
 *
 * Because this header may configure the behavior of system headers
 * (for example, LFS support), it must be included before any other
 * header file.
 *
 * CVS $Id: config.h.in,v 1.3 2003/05/23 15:24:08 eddy Exp $
 */

#ifndef CONFIGH_INCLUDED
#define CONFIGH_INCLUDED

/*****************************************************************
 * This first section can be edited and configured manually
 * before compilation.
 *****************************************************************/

/* RAMLIMIT determines the point at which we switch from fast,
 * full dynamic programming to slow, linear-memory divide and conquer
 * dynamic programming algorithms. It is the minimum amount of available
 * RAM on the systems the package will run on. It can be overridden
 * from the Makefile.
 * By default, we assume we have 32 Mb RAM available (per thread).
 */
#ifndef RAMLIMIT
#define RAMLIMIT 32
#endif

/* HMMER_NCPU determines the number of threads/processors that
 * a multithreaded version will parallelize across. This can be overridden
 * by -DHMMER_NCPU=x in the Makefile, and by a setenv HMMER_NCPU x
 * in the environment, and usually by a command line option.
 * By default, we detect the number of processors dynamically, and use
 * them all.
 *
 * However, on some systems (FreeBSD and older Linuxen, notably), we
 * can't autodetect the available # of cpus. On these systems we
 * assume 2 processors by default - dual processor Intel servers
 * are common. That assumption can be overridden
 * here if HMMER_NCPU is uncommented.
 */
/* #define HMMER_NCPU 4 */


/*****************************************************************
 * The following section probably shouldn't be edited, unless
 * you really know what you're doing. It controls some fundamental
 * parameters in HMMER that occasionally get reconfigured in
 * experimental versions, or for variants of HMMER that work on
 * non-biological alphabets.
 *****************************************************************/

#define INTSCALE    1000.0      /* scaling constant for floats to integer scores   */
#define MAXABET     20	        /* maximum size of alphabet (4 or 20)              */
#define MAXCODE     24	        /* maximum degenerate alphabet size (17 or 24)     */
#define MAXDCHLET   200	        /* maximum # Dirichlet components in mixture prior */
#define NINPUTS     4	        /* number of inputs into structural prior          */
#define INFTY       987654321   /* infinity for purposes of integer DP cells       */
#define NXRAY       4           /* number of structural inputs                */
#define LOGSUM_TBL  20000       /* controls precision of ILogsum()            */
#define ALILENGTH   50		/* length of displayed alignment lines        */


/*****************************************************************
 * The following section is configured automatically
 * by the ./configure script. DO NOT EDIT.
 *****************************************************************/

/* Version info - set once for whole package in configure.ac
 */
#define PACKAGE_NAME "HMMER"
#define PACKAGE_VERSION "2.3.2"
#define PACKAGE_DATE "Oct 2003"
#define PACKAGE_COPYRIGHT "Copyright (C) 1992-2003 HHMI/Washington University School of Medicine"
#define PACKAGE_LICENSE "Freely distributed under the GNU General Public License (GPL)"

/*****************************************************************
 * The following section is configured automatically by options
 * enabled in the ./configure script. DO NOT EDIT.
 *****************************************************************/
/* --enable-altivec      Altivec vectorizations for PowerPCs
 */
/* #undef ALTIVEC */

/* --enable-debugging=x  debugging diagnostics (development versions only)
 */
#ifndef DEBUGLEVEL
/* #undef DEBUGLEVEL */
#endif

/* --enable-lfs          Large File Summit (LFS) support for >2Gb files
 */
#define _LARGEFILE_SOURCE 1
#define _LARGEFILE64_SOURCE 1
#define _FILE_OFFSET_BITS 64

/* --enable-pvm          Parallel Virtual Machine (PVM)
 */
#define HMMER_PVM 1

/* --enable-threads      POSIX multithreading
 */
#define HMMER_THREADS 1
/* #undef HAVE_PTHREAD_ATTR_SETSCOPE */
/* #undef HAVE_PTHREAD_SETCONCURRENCY */


#endif /*CONFIGH_INCLUDED*/