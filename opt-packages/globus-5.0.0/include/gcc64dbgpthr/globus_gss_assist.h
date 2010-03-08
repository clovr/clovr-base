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

#ifndef GLOBUS_DONT_DOCUMENT_INTERNAL
/**
 * @file globus_gss_assist.h
 * GSS Assist Header
 *
 * $RCSfile: globus_gss_assist.h,v $
 * $Revision: 1.13 $
 * $Date $
 */
#endif
 
#ifndef _GLOBUS_GSS_ASSIST_H
#define _GLOBUS_GSS_ASSIST_H

#ifndef EXTERN_C_BEGIN
#    ifdef __cplusplus
#        define EXTERN_C_BEGIN extern "C" {
#        define EXTERN_C_END }
#    else
#        define EXTERN_C_BEGIN
#        define EXTERN_C_END
#    endif
#endif

EXTERN_C_BEGIN

#include "gssapi.h"
#include <stdio.h>
#include <stdlib.h>

/**
 * @defgroup globus_gsi_gss_assist_activation Activation
 *
 * Globus GSI GSS Assist uses standard Globus module activation and
 * deactivation.  Before any Globus GSS Assist functions are called,
 * the following function must be called:
 *
 * @code
 *      globus_module_activate(GLOBUS_GSI_GSS_ASSIST_MODULE);
 * @endcode
 *
 * This function returns GLOBUS_SUCCESS if Globus GSI GSS Assist was
 * successfully initialized, and you are therefore allowed to
 * call GSS Assist functions.  Otherwise, an error code is returned,
 * and GSS Assist functions should not be subsequently called.  
 * This function may be called multiple times.
 *
 * To deactivate Globus GSS Assist, the following function must be called:
 * 
 * @code
 *    globus_module_deactivate(GLOBUS_GSI_GSS_ASSIST_MODULE)
 * @endcode
 *
 * This function should be called once for each time Globus GSI GSS Assist
 * was activated.
 */

/**
 * Module descriptor
 * @ingroup globus_gsi_gss_assist_activation
 * @hideinitializer
 */
#define GLOBUS_GSI_GSS_ASSIST_MODULE  (&globus_i_gsi_gss_assist_module)

extern
globus_module_descriptor_t              globus_i_gsi_gss_assist_module;

/**
 * @defgroup globus_gsi_gss_assist Utility Functions
 *
 * Utility functions for GSSAPI
 */
#define _GASL(s) globus_common_i18n_get_string( \
		    GLOBUS_GSI_GSS_ASSIST_MODULE, \
		    s)
#include "globus_gss_assist_constants.h"


#define GLOBUS_GSS_ASSIST_TOKEN_ERR_MALLOC		1
#define GLOBUS_GSS_ASSIST_TOKEN_ERR_BAD_SIZE	        2
#define GLOBUS_GSS_ASSIST_TOKEN_EOF			3
#define GLOBUS_GSS_ASSIST_TOKEN_NOT_FOUND		4

/* for kerberos v5.1.0.5 compatability we need this */
#ifndef GSS_C_NO_NAME
#define GSS_C_NO_NAME ((gss_name_t *) 0)
#define GSS_ASSIST_KRB5_HACK
#endif

/* for the globus_gss_assist_ex flags: */

#define GLOBUS_GSS_ASSIST_EX_SEND_WITHOUT_LENGTH  1

typedef struct globus_gss_assist_ex_st
{
	void * arg;
	int    flags;
} globus_gss_assist_ex;

/* 
 * Get and send gss tokens using verious methods
 * These are used by the gss_assist_init_sec_context
 * gss_assist_accept_sec_context, gss_assist_get_unwrap
 * and gss_assist_wrap_send
 * Arg depends on the method being used,
 * FILE * for a fd, socket * for the nexus version
 * You may provide your own versions as well. 
 * The _ex versions accept a globus_gss_assist_ex structure
 * which has in addition the arg, some flags. 
 */
extern int
globus_gss_assist_token_get_fd(
    void *                              arg, 
    void **                             bufp, 
    size_t *                            sizep);

extern int
globus_gss_assist_token_send_fd(
    void *                              arg, 
    void *                              buf, 
    size_t                              size);

extern int
globus_gss_assist_token_send_fd_ex(
    void *                              arg, 
    void *                              buf, 
    size_t                              size);

extern int
globus_gss_assist_token_send_fd_without_length(
    void *                              arg, 
    void *                              buf, 
    size_t                              size);

extern int
globus_gss_assist_token_get_nexus(
    void *                              arg, 
    void **                             bufp, 
    size_t *                            sizep);

extern int
globus_gss_assist_token_send_nexus(
    void *                              arg, 
    void *                              bufp, 
    size_t                              sizep);

extern int
globus_gss_assist_token_send_nexus_ex(
    void *                              arg, 
    void *                              bufp, 
    size_t                              sizep);

extern int
globus_gss_assist_token_send_nexus_without_length(
    void *                              arg, 
    void *                              bufp, 
    size_t                              sizep);

/* 
 * globus_gss_assist_acquire_cred, assist with the gss_acquire_cred
 */
extern OM_uint32
globus_gss_assist_acquire_cred(
    OM_uint32 *,             /*  minor_status */
    gss_cred_usage_t,        /* cred_usage */
    gss_cred_id_t *          /* output_cred_handle */);

/*
 * globus_gss_assist_acquire_cred_ext, assist with the gss_acquire_cred
 */
extern OM_uint32
globus_gss_assist_acquire_cred_ext(
    OM_uint32 *,             /* minor_status */
    char *,                  /* desired_name_char */
    OM_uint32,               /* time_req */
    const gss_OID_set,       /* desired_mechs */
    gss_cred_usage_t,        /* cred_usage */
    gss_cred_id_t *,         /* output_cred_handle */
    gss_OID_set *,           /* actual_mechs */
    OM_uint32 *              /* time_rec */);

/*
 * gss_assist_accept_sec_context - takes care of looping
 * over multiple tokens using the get and send tokens
 * routines
 */
extern OM_uint32
globus_gss_assist_accept_sec_context(
    OM_uint32 *,                        /* minor_status */
    gss_ctx_id_t *,                     /* context_handle */
    const gss_cred_id_t,                /* acceptor_cred_handle */
    char **,                            /* src_name as char ** */
    OM_uint32 *,                        /* ret_flags */
    int *,				/* user_to_user_flag */
    int *,                              /* token_status */
    gss_cred_id_t *,                    /* delegated_cred_handle */
    int (* get_token)(void *, void **, size_t *),
    void *                              get_context,
    int (* send_token)(void *, void *, size_t),
    void *                              send_context);

/*
 * globus_gss_assist_accept_sec_context_async - async version of
 * globus_gss_assist_accept_sec_context().
 */
extern OM_uint32
globus_gss_assist_accept_sec_context_async(
    OM_uint32 *			        minor_status,
    gss_ctx_id_t *			context_handle,
    const gss_cred_id_t		        cred_handle,
    char **			        src_name_char,
    OM_uint32 *			        ret_flags,
    int *				user_to_user_flag,
    void *				input_buffer,
    size_t				input_buffer_len,
    void **			        output_bufferp,
    size_t *			        output_buffer_lenp,
    gss_cred_id_t *                     delegated_cred_handle);

/*
 * globus_gss_assist_init_sec_context - takes care of looping
 * over multiple tokens using the get and send tokens
 * routines
 */
extern OM_uint32
globus_gss_assist_init_sec_context(
    OM_uint32 *,                        /* minor_status */
    const gss_cred_id_t,                /* initiator_cred_handle */
    gss_ctx_id_t *,                     /* context_handle */
    char *,                             /* target_name as char * */
    OM_uint32,                          /* req_flags */
    OM_uint32 *,                        /* ret_flags */
    int *,                              /* token_status */
    int (* get_token)(void *, void **, size_t *),
    void *                              get_arg,
    int (* send_token)(void *, void *, size_t),
    void *                              send_arg);

/*
 * globus_gss_assist_init_sec_context_async - async version of
 * globus_gss_assist_init_sec_context().
 */
extern OM_uint32
globus_gss_assist_init_sec_context_async(
    OM_uint32 *			        minor_status,
    const gss_cred_id_t		        cred_handle,
    gss_ctx_id_t *			context_handle,
    char *				target_name_char,
    OM_uint32 			        req_flags,
    OM_uint32 *			        ret_flags,
    void *				input_buffer,
    size_t				input_buffer_len,
    void **			        output_bufferp,
    size_t *			        output_buffer_lenp);

/*
 * globus_gss_assist_display_status - used gss_display_status 
 */
extern OM_uint32
globus_gss_assist_display_status(
    FILE *,                             /* where to print */
    char *,				/* comment */
    OM_uint32,                          /* major_status */
    OM_uint32,                          /* minor_status */
    int                                 /* token_status */);

extern OM_uint32
globus_gss_assist_display_status_str(
    char **,                            /* string returned with newlines */
    char *,				/* comment */
    OM_uint32,                          /* major_status */
    OM_uint32,                          /* minor_status */
    int                                 /* token_status */);

/*
 * globus_gss_assist_wrap_send - used to wrap a 
 * simple message and send it
 */
extern OM_uint32
globus_gss_assist_wrap_send(
    OM_uint32 *                         minor_status,
    const gss_ctx_id_t                  context_handle,
    char *                              data,
    size_t                              length,
    int *                               token_status,
    int (*gss_assist_send_token)(void *, void *, size_t),
    void *                              gss_assist_send_context,
    FILE *                              fperr);

/*
 * globus_gss_assist_get_unwrap - used to get and unwrap a message
 */
extern OM_uint32
globus_gss_assist_get_unwrap(
    OM_uint32 *                         minor_status,
    const gss_ctx_id_t                  context_handle,
    char **                             data,
    size_t *                            length,
    int *                               token_status,
    int (*gss_assist_get_token)(void *, void **, size_t *),
    void *                              gss_assist_get_context,
    FILE *                              fperr);

/*
 * globus_gss_assist_will_handle_restrictions - used to tell openssl
 * that the application will deal with the restrictions extension
 */
OM_uint32
globus_gss_assist_will_handle_restrictions(
    OM_uint32 *                         minor_status,
    gss_ctx_id_t *                      context_handle);


/*
 * globus_gss_assist_import_sec_context - read a security context
 */
extern OM_uint32
globus_gss_assist_export_sec_context(
    OM_uint32 *                         minor_status,
    gss_ctx_id_t *                      context_handle,
    int *                               token_status,
    int                                 fdp,
    FILE *                              fperr);

/*
 * globus_gss_assist_import_sec_context - read a security context
 */
extern OM_uint32
globus_gss_assist_import_sec_context(
    OM_uint32 *                         minor_status,
    gss_ctx_id_t *                      context_handle,
    int *                               token_status,
    int                                 fdp,
    FILE *                              fperr);


globus_result_t
globus_gss_assist_authorization_host_name(
    char *                              hostname,
    gss_name_t *                        authorization_hostname);

/*
 * globus_gss_assist_gridmap - used to map a 
 * src_name to a local userid
 * This is not really part of authentication, 
 * but rather authorization. 
 */  
extern int
globus_gss_assist_gridmap(
    char *                              globusidp, 
    char **                             useridp);

extern int
globus_gss_assist_userok(
    char *                              globusid,
    char *                              userid);

extern int
globus_gss_assist_map_local_user(
    char *                              local_user,
    char **                             globusidp);

globus_result_t
globus_gss_assist_lookup_all_globusid(
    char *                                      username,
    char **                                     dns[],
    int *                                       dn_count);

globus_result_t
globus_gss_assist_map_and_authorize(
    gss_ctx_id_t                        context,
    char *                              service,
    char *                              desired_identity,
    char *                              identity_buffer,
    unsigned int                        identity_buffer_length);



#define GlobusGssAssistFreeDNArray(dn_a)                    \
{                                                           \
    int __ctr = 0;                                          \
    while(dn_a[__ctr] != NULL)                              \
    {                                                       \
        free(dn_a[__ctr]);                                  \
        __ctr++;                                            \
    }                                                       \
    free(dn_a);                                             \
}


EXTERN_C_END

#endif /* _GLOBUS_GSS_ASSIST_H */
