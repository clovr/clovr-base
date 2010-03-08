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
 * @file globus_gsi_callback.h
 * @author Sam Lang
 * @author Sam Meder
 *
 * $RCSfile: globus_gsi_callback.h,v $
 * $Revision: 1.12 $
 * $Date: 2008/07/21 20:02:28 $
 */
#endif

#ifndef _GLOBUS_GSI_CALLBACK_H_
#define _GLOBUS_GSI_CALLBACK_H_

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

#include "globus_common.h"
#include "globus_gsi_cert_utils.h"
#include "openssl/x509.h"

/**
 * @mainpage Globus GSI Callback
 *
 * The Globus GSI Callback library. This library contains functions that extend
 * OpenSSL path validation.
 *
 * - @ref globus_gsi_callback_activation
 * - @ref globus_gsi_callback
 * - @ref globus_gsi_callback_data
 */


/** 
 * @defgroup globus_gsi_callback_activation Activation
 *
 * Globus GSI Callback uses standard Globus module activation and
 * deactivation.  Before any Globus GSI Callback functions are called, the
 * following function must be called:
 *
 * @code
 *      globus_module_activate(GLOBUS_GSI_CALLBACK_MODULE)
 * @endcode
 *
 *
 * This function returns GLOBUS_SUCCESS if Globus GSI Callback was
 * successfully initialized, and you are therefore allowed to
 * subsequently call Globus GSI Callback functions.  Otherwise, an error
 * code is returned, and Globus GSI Credential functions should not be
 * subsequently called. This function may be called multiple times.
 *
 * To deactivate Globus GSI Callback, the following function must be called:
 *
 * @code
 *    globus_module_deactivate(GLOBUS_GSI_CALLBACK_MODULE)
 * @endcode
 *
 * This function should be called once for each time Globus GSI Callback
 * was activated. 
 *
 */

/**
 * Module descriptor
 * @ingroup globus_gsi_callback_activation
 * @hideinitializer
 */
#define GLOBUS_GSI_CALLBACK_MODULE    (&globus_i_gsi_callback_module)

extern 
globus_module_descriptor_t              globus_i_gsi_callback_module;

#define _CLS(s) globus_common_i18n_get_string(GLOBUS_GSI_CALLBACK_MODULE,\
		s)
/**
 * @defgroup globus_gsi_callback Callback Functions
 * 
 * Functions that plug into various plug points in the OpenSSL path validation
 * mechanism. These functions add CRL checking, X509 Extension handling and
 * proxy validation.
 */

/**
 * @defgroup globus_gsi_callback_data Callback Data Functions
 *
 * Functions that deal with the data structure that contains state associated
 * with the path validation callback. 
 */


/**
 * Callback data typedef
 * @ingroup globus_gsi_callback_data
 */
typedef struct globus_l_gsi_callback_data_s *
                                        globus_gsi_callback_data_t;

/**
 * Typedef for a callback that may be registered for dealing with unhandled X.509 extension
 * @ingroup globus_gsi_callback
 */
typedef int (*globus_gsi_extension_callback_t)(
    globus_gsi_callback_data_t          callback_data,
    X509_EXTENSION *                    extension);

#ifndef DOXYGEN

globus_result_t
globus_gsi_callback_get_X509_STORE_callback_data_index(
    int *                               index);

globus_result_t
globus_gsi_callback_get_SSL_callback_data_index(
    int *                               index);

int
globus_gsi_callback_create_proxy_callback(
    int                                 preverify_ok,
    X509_STORE_CTX *                    x509_context);

int
globus_gsi_callback_handshake_callback(
    int                                 preverify_ok,
    X509_STORE_CTX *                    x509_context);

int globus_gsi_callback_check_issued(
    X509_STORE_CTX *                    context,
    X509 *                              cert,
    X509 *                              issuer);

int 
globus_gsi_callback_X509_verify_cert(
    X509_STORE_CTX *                    context,
    void *                              arg);

globus_result_t
globus_gsi_callback_data_init(
    globus_gsi_callback_data_t *        callback_data);

globus_result_t
globus_gsi_callback_data_destroy(
    globus_gsi_callback_data_t          callback_data);

globus_result_t
globus_gsi_callback_data_copy(
    globus_gsi_callback_data_t     source,
    globus_gsi_callback_data_t *   dest);

globus_result_t
globus_gsi_callback_get_cert_depth(
    globus_gsi_callback_data_t          callback_data,
    int *                               cert_depth);

globus_result_t
globus_gsi_callback_set_cert_depth(
    globus_gsi_callback_data_t          callback_data,
    int                                 cert_depth);

globus_result_t
globus_gsi_callback_get_proxy_depth(
    globus_gsi_callback_data_t          callback_data,
    int *                               proxy_depth);

globus_result_t
globus_gsi_callback_set_proxy_depth(
    globus_gsi_callback_data_t          callback_data,
    int                                 proxy_depth);

globus_result_t
globus_gsi_callback_set_cert_type(
    globus_gsi_callback_data_t          callback_data,
    globus_gsi_cert_utils_cert_type_t   cert_type);

globus_result_t
globus_gsi_callback_get_cert_type(
    globus_gsi_callback_data_t          callback_data,
    globus_gsi_cert_utils_cert_type_t * cert_type);

globus_result_t
globus_gsi_callback_get_cert_chain(
    globus_gsi_callback_data_t          callback_data,
    STACK_OF(X509) **                   cert_chain);

globus_result_t
globus_gsi_callback_set_cert_chain(
    globus_gsi_callback_data_t          callback_data,
    STACK_OF(X509) *                    cert_chain);

globus_result_t
globus_gsi_callback_get_multiple_limited_proxy_ok(
    globus_gsi_callback_data_t          callback_data,
    int *                               multiple_limited_proxy_ok);

globus_result_t
globus_gsi_callback_set_multiple_limited_proxy_ok(
    globus_gsi_callback_data_t          callback_data,
    int                                 multiple_limited_proxy_ok);

globus_result_t
globus_gsi_callback_get_extension_oids(
    globus_gsi_callback_data_t          callback_data,
    void **                             extension_oids);

globus_result_t
globus_gsi_callback_set_extension_oids(
    globus_gsi_callback_data_t          callback_data,
    void *                              extension_oids);

globus_result_t
globus_gsi_callback_get_cert_dir(
    globus_gsi_callback_data_t          callback_data,
    char **                             cert_dir);

globus_result_t
globus_gsi_callback_set_cert_dir(
    globus_gsi_callback_data_t          callback_data,
    char *                              cert_dir);

globus_result_t
globus_gsi_callback_get_goodtill(
    globus_gsi_callback_data_t          callback_data,
    time_t *                            goodtill);

globus_result_t
globus_gsi_callback_set_goodtill(
    globus_gsi_callback_data_t          callback_data,
    time_t                              goodtill);

globus_result_t
globus_gsi_callback_get_extension_cb(
    globus_gsi_callback_data_t          callback_data,
    globus_gsi_extension_callback_t *   extension_cb);

globus_result_t
globus_gsi_callback_set_extension_cb(
    globus_gsi_callback_data_t          callback_data,
    globus_gsi_extension_callback_t     extension_cb);

globus_result_t
globus_gsi_callback_get_error(
    globus_gsi_callback_data_t          callback_data,
    globus_result_t *                   error);

globus_result_t
globus_gsi_callback_set_error(
    globus_gsi_callback_data_t          callback_data,
    globus_result_t                     error);

globus_result_t
globus_gsi_callback_get_check_policy_for_self_signed_certs(
    globus_gsi_callback_data_t          callback_data,
    globus_bool_t *                     check);

globus_result_t
globus_gsi_callback_set_check_policy_for_self_signed_certs(
    globus_gsi_callback_data_t          callback_data,
    globus_bool_t                       check);

#endif /* DOXYGEN */

EXTERN_C_END

#endif /* _GLOBUS_GSI_CALLBACK_H_ */
