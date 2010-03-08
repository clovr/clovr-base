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
 * @file globus_xio_gsi.h
 * @author Sam Meder
 * 
 * $RCSfile: globus_xio_gsi.h,v $
 * $Revision: 1.2 $
 * $Date: 2006/04/21 19:10:34 $
 */
#endif

#ifndef GLOBUS_XIO_GSI_DRIVER_INCLUDE
#define GLOBUS_XIO_GSI_DRIVER_INCLUDE

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
#include "globus_common.h"

/**
 * @defgroup gsi_driver Globus XIO GSI Driver
 * The GSI driver.
 */

/**
 * @defgroup gsi_driver_instance Opening/Closing
 * @ingroup gsi_driver
 * 
 * An XIO handle with the gsi driver can be created with either
 * @ref globus_xio_handle_create() or @ref globus_xio_server_register_accept().
 *
 * If the handle is created with
 * @ref globus_xio_server_register_accept(), the
 * @ref globus_xio_register_open() call will proceed to accept a GSSAPI
 * security context. Upon successful completion of the open, ie after
 * the open callback has been called, the application may
 * proceed to read or write data associated with the GSI session.
 *
 * If the handle is created with @ref globus_xio_handle_create(), then
 * the XIO handle will implement the client-side (init) of the GSSAPI call
 * sequence and establish a security context with the accepting side indicated
 * by the contact_string passed to @ref globus_xio_register_open().
 */
 
/**
 * @defgroup gsi_driver_io Reading/Writing
 * @ingroup gsi_driver
 * The GSI driver behaves similar to the underlying transport driver with
 * respect to reads and writes, except for the try-read and try-write
 * operations (ie. waitforbytes ==0) which always return immediately. This is
 * due to the fact that the security layer needs to read and write tokens of a
 * certain minimal size and thus needs to rely on the underlying transport to
 * handle greater than 0 reads/write which is not possible in "try" mode.
 */

/**
 * @defgroup gsi_driver_server Server
 * @ingroup gsi_driver
 *
 * @ref globus_xio_server_create() causes a new transport-specific
 * listener socket to be created to handle new GSI connections.
 * @ref globus_xio_server_register_accept() will accept a new
 * connection for processing. @ref globus_xio_server_register_close()
 * cleans up the internal resources associated with the http server
 * and calls close on the listener.
 *
 * All accepted handles inherit all gsi specific attributes set in the attr to
 * @ref globus_xio_server_create(), but can be overridden with the attr to 
 * @ref globus_xio_register_open(). Furthermore, accepted handles will use the
 * GSSAPI accept security context call unless explicitly overriden during the
 * @ref globus_xio_register_open() call (@ref
 * GLOBUS_XIO_GSI_FORCE_SERVER_MODE).
 */

/**
 * @defgroup gsi_driver_envs Env Variables
 * @ingroup gsi_driver
 * 
 * The gsi driver uses the following environment variables
 * - X509_USER_PROXY 
 * - X509_USER_CERT
 * - X509_USER_KEY
 * - X509_CERT_DIR
 *
 * For details see
 * <a href="http://www.globus.org/security/v2.0/env_variables.html">
 * Globus: GSI Environment Variables</a>
 */

/**
 * @defgroup gsi_driver_cntls Attributes and Cntls
 * @ingroup gsi_driver
 * 
 * GSI driver specific attrs and cntls.
 * 
 * @see globus_xio_attr_cntl()
 * @see globus_xio_handle_cntl()
 */

/**
 * @defgroup gsi_driver_types Types
 * @ingroup gsi_driver
 */
/**
 * @defgroup gsi_driver_errors Error Types
 * @ingroup gsi_driver
 * 
 * The GSI driver uses mostly GSSAPI calls, so it generally just wraps the
 * underlying GSSAPI errors or uses generic xio errors.
 * 
 * @see globus_xio_driver_error_match()
 * @see globus_error_gssapi_match()
 * @see globus_error_match_openssl_error()
 */

/**
 * GSI driver specific error types
 * @ingroup gsi_driver_errors
 */
typedef enum
{
    /** Indicates that the established context does not meet the required
     * protecetion level
     */
    GLOBUS_XIO_GSI_ERROR_INVALID_PROTECTION_LEVEL,
    /** Wraps a GSSAPI error */
    GLOBUS_XIO_GSI_ERROR_WRAP_GSSAPI,
    /** Indicates that GLOBUS_XIO_GSI_IDENTITY_AUTHORIZATION is set but that
     *  the target name is empty
     */
    GLOBUS_XIO_GSI_ERROR_EMPTY_TARGET_NAME,
    /** Indicates that GLOBUS_XIO_GSI_HOST_AUTHORIZATION is set but that
     *  no host name is available
     */
    GLOBUS_XIO_GSI_ERROR_EMPTY_HOST_NAME,
    /** Indicates that the peer is not authorized */       
    GLOBUS_XIO_GSI_AUTHORIZATION_FAILED,
    /** Indicates the the token being read is too big. Usually happens
     *  when someone tries to establish a non secure session with a
     *  endpoint that expects security*/
    GLOBUS_XIO_GSI_ERROR_TOKEN_TOO_BIG
} globus_xio_gsi_error_t;

/** doxygen varargs filter stuff
 * GlobusVarArgDefine(
 *      attr, globus_result_t, globus_xio_attr_cntl, attr, driver)
 * GlobusVarArgDefine(
 *      handle, globus_result_t, globus_xio_handle_cntl, handle, driver)
 */


/**
 * GSI driver specific cntls
 * @ingroup gsi_driver_cntls
 */
typedef enum
{
    /** GlobusVarArgEnum(attr, handle)
     * Set the credential to be used 
     * @ingroup gsi_driver_cntls
     *
     * @param credential
     *      The credential to set. The credential structure
     *      needs to remain valid for the lifetime of any xio datastructure it
     *      is used by. 
     * @note If this is called with the handle_cntl, there must be no
     *       outstanding operations on the handle.
     */
    /* gss_cred_id_t                    credential */
    GLOBUS_XIO_GSI_SET_CREDENTIAL,

    /** GlobusVarArgEnum(attr, handle)
     * Get the credential to be used 
     * @ingroup gsi_driver_cntls
     *
     * @param credential
     *      The credential that is currently set. This will only
     *      return a credential if a credential was explicitly set prior to
     *      this call. It will not return any credential automatically acquired
     *      during context initizalization. 
     */
    /* gss_cred_id_t *                  credential */
    GLOBUS_XIO_GSI_GET_CREDENTIAL,

    /** GlobusVarArgEnum(attr)
     * Set the GSSAPI req_flags to be used
     * @ingroup gsi_driver_cntls
     *
     * @param req_flags
     *      The req_flags to set
     */
    /* OM_uint32                        req_flags */
    GLOBUS_XIO_GSI_SET_GSSAPI_REQ_FLAGS,

    /** GlobusVarArgEnum(attr)
     * Get the GSSAPI req_flags to be used
     * @ingroup gsi_driver_cntls
     *
     * @param req_flags
     *      The req flags currently in effect
     */
    /* OM_uint32 *                       req_flags */
    GLOBUS_XIO_GSI_GET_GSSAPI_REQ_FLAGS,
    
    /** GlobusVarArgEnum(attr)
     * Set the proxy mode
     * @ingroup gsi_driver_cntls
     *
     * @param proxy_mode
     *      The proxy mode to set
     * @note Changing the proxy mode changes the req_flags
     */
    /* globus_xio_gsi_proxy_mode_t      proxy_mode*/
    GLOBUS_XIO_GSI_SET_PROXY_MODE,

    /** GlobusVarArgEnum(attr)
     * Get the proxy mode
     * @ingroup gsi_driver_cntls
     *
     * @param proxy_mode
     *      The proxy mode that is currently in effect
     * @note Changing the proxy mode changes the req_flags
     */
    /* globus_xio_gsi_proxy_mode_t *    proxy_mode*/
    GLOBUS_XIO_GSI_GET_PROXY_MODE,

    /** GlobusVarArgEnum(attr)
     * Set the authorization mode
     * @ingroup gsi_driver_cntls
     *
     * @param authz_mode
     *      The authorization mode to set
     */
    /* globus_xio_gsi_authorization_mode_t      authz_mode*/
    GLOBUS_XIO_GSI_SET_AUTHORIZATION_MODE,

    /** GlobusVarArgEnum(attr)
     * Get the authorization mode
     * @ingroup gsi_driver_cntls
     *
     * @param authz_mode
     *      The authorization mode that is currently in effect
     */
    /* globus_xio_gsi_authorization_mode_t *    authz_mode*/
    GLOBUS_XIO_GSI_GET_AUTHORIZATION_MODE,

    /** GlobusVarArgEnum(attr)
     * Set the delegation mode
     * @ingroup gsi_driver_cntls
     *
     * @param delegation_mode
     *      The delegation mode to use
     * @note Changing the delegation mode changes the req_flags     
     */
    /* globus_xio_gsi_delegation_mode_t delegation_mode*/
    GLOBUS_XIO_GSI_SET_DELEGATION_MODE,

    /** GlobusVarArgEnum(attr)
     * Get the delegation mode
     * @ingroup gsi_driver_cntls
     *
     * @param delegation_mode
     *      The delegation mode currently in effect
     */
    /* globus_xio_gsi_delegation_mode_t *   delegation_mode*/
    GLOBUS_XIO_GSI_GET_DELEGATION_MODE,

    /** GlobusVarArgEnum(attr)
     * Make the on the wire protocol SSL compatible.
     * @ingroup gsi_driver_cntls
     *
     * This implies no wrapping of security tokens and no delegation
     * 
     * @param ssl_mode
     *      The ssl compatibility mode to use
     * @note Changing the ssl compatibility mode changes the req_flags     
     */
    /* globus_bool_t                    ssl_mode*/
    GLOBUS_XIO_GSI_SET_SSL_COMPATIBLE,

    /** GlobusVarArgEnum(attr)
     * Do anonymous authentication 
     * @ingroup gsi_driver_cntls
     *
     * @param anon_mode
     *      The ssl compatibility mode to use
     * @note Changing the ssl compatibility mode changes the req_flags and the
     * wrapping mode     
     */
    /* globus_bool_t                    anon_mode*/
    GLOBUS_XIO_GSI_SET_ANON,

    /** GlobusVarArgEnum(attr)
     * Set the wrapping mode
     * @ingroup gsi_driver_cntls
     *
     * This mode determines whether tokens will be
     * wrapped with a Globus IO style header or not.
     * 
     * @param wrap_mode
     *      The wrapping mode to use
     */
    /* globus_boolean_t                 wrap_mode*/
    GLOBUS_XIO_GSI_SET_WRAP_MODE,

    /** GlobusVarArgEnum(attr)
     * Get the wrapping mode
     * @ingroup gsi_driver_cntls
     *
     * This mode determines whether tokens will
     * be wrapped with a Globus IO style header or not.
     * 
     * @param wrap_mode
     *      The wrapping mode currently in use.
     */
    /* globus_boolean_t *               wrap_mode*/
    GLOBUS_XIO_GSI_GET_WRAP_MODE,

    /** GlobusVarArgEnum(attr)
     * Set the read buffer size
     * @ingroup gsi_driver_cntls
     *
     * The read buffer is used for buffering
     * wrapped data, is initialized with a default size of 128K and scaled
     * dynamically to always be able to fit whole tokens.
     * 
     * @param buffer_size
     *      The size of the read buffer
     */
    /* globus_size_t                    buffer_size*/
    GLOBUS_XIO_GSI_SET_BUFFER_SIZE,

    /** GlobusVarArgEnum(attr)
     * Get the read buffer size
     * @ingroup gsi_driver_cntls
     *
     * The read buffer is used for buffering
     * wrapped data, is initialized with a default size of 128K and scaled
     * dynamically to always be able to fit whole tokens.
     * 
     * @param buffer_size
     *      The size of the read buffer
     */
    /* globus_size_t *                   buffer_size*/
    GLOBUS_XIO_GSI_GET_BUFFER_SIZE,

    /** GlobusVarArgEnum(attr)
     * Set the protection level
     * @ingroup gsi_driver_cntls
     *
     * @param protection_level
     *      The protection level to set
     * @note Changing the proxy mode changes the req_flags
     */
    /* globus_xio_gsi_protection_level_t    protection_level*/
    GLOBUS_XIO_GSI_SET_PROTECTION_LEVEL,

    /** GlobusVarArgEnum(attr)
     * Get the protection level
     * @ingroup gsi_driver_cntls
     *
     * @param protection_level
     *      The current protection level
     */
    /* globus_xio_gsi_protection_level_t *  protection_level*/
    GLOBUS_XIO_GSI_GET_PROTECTION_LEVEL,

    /** GlobusVarArgEnum(attr)
     * Set the expected peer name
     * @ingroup gsi_driver_cntls
     *
     * @param target_name
     *      The expected peer name
     */
    /* gss_name_t *                     target_name */
    GLOBUS_XIO_GSI_GET_TARGET_NAME,

    /** GlobusVarArgEnum(attr)
     * Get the expected peer name
     * @ingroup gsi_driver_cntls
     *
     * @param target_name
     *      The expected peer name
     */
    /* gss_name_t                       target_name */
    GLOBUS_XIO_GSI_SET_TARGET_NAME,

    /** GlobusVarArgEnum(handle)
     * Get the GSS context
     * @ingroup gsi_driver_cntls
     *
     * @param context
     *      The GSS context
     */
    /* gss_ctx_id_t *                   context */
    GLOBUS_XIO_GSI_GET_CONTEXT,

    /** GlobusVarArgEnum(handle)
     * Get the delegated credential
     * @ingroup gsi_driver_cntls
     *
     * @param credential
     *      The delegated credential
     */
    /* gss_cred_id_t *                  credential */
    GLOBUS_XIO_GSI_GET_DELEGATED_CRED,

    /** GlobusVarArgEnum(handle)
     * Get the name of the peer 
     * @ingroup gsi_driver_cntls
     *
     * @param peer_name
     *      The GSS name of the peer.
     */
    /* gss_name_t *                     peer_name */
    GLOBUS_XIO_GSI_GET_PEER_NAME,

    /** GlobusVarArgEnum(handle)
     * Get the GSS name associated with the local credentials
     * @ingroup gsi_driver_cntls
     *
     * @param local_name
     *      The GSS name of the local credentials
     */
    /* gss_name_t *                     local_name */
    GLOBUS_XIO_GSI_GET_LOCAL_NAME,

    /** GlobusVarArgEnum(handle)
     * Initialize delegation-at-any-time process
     * @ingroup gsi_driver_cntls
     *
     * @param credential
     *      The GSS credential to delegate
     * @param restriction_oids
     *      The OIDS for X.509 extensions to embed in the delegated
     *      credential
     * @param restriction_buffers
     *      The corresponding bodies for the X.509 extensions
     * @param time_req
     *      The lifetime of the delegated credential
     */
    /* gss_cred_id_t                    credential,
       gss_OID_set                      restriction_oids,
       gss_buffer_set_t                 restriction_buffers,
       OM_uint32                        time_req */
    GLOBUS_XIO_GSI_INIT_DELEGATION,

    /** GlobusVarArgEnum(handle)
     * Initialize non-blocking delegation-at-any-time process
     * @ingroup gsi_driver_cntls
     *
     * @param credential
     *      The GSS credential to delegate
     * @param restriction_oids
     *      The OIDS for X.509 extensions to embed in the delegated
     *      credential
     * @param restriction_buffers
     *      The corresponding bodies for the X.509 extensions
     * @param time_req
     *      The lifetime of the delegated credential
     * @param callback
     *      The callback to call when the operation completes
     * @param callback_arg
     *      The arguments to pass to the callback
     */
    /* gss_cred_id_t                                credential,
       gss_OID_set                                  restriction_oids,
       gss_buffer_set_t                             restriction_buffers,
       OM_uint32                                    time_req,
       globus_xio_gsi_delegation_init_callback_t    callback,
       void *                                       callback_arg */
    GLOBUS_XIO_GSI_REGISTER_INIT_DELEGATION,
    /** GlobusVarArgEnum(handle)
     * Accept delegation-at-any-time process
     * @ingroup gsi_driver_cntls
     *
     * @param credential
     *      The delegated GSS credential
     * @param restriction_oids
     *      The OIDS for X.509 extensions to embed in the delegated
     *      credential 
     * @param restriction_buffers
     *      The corresponding bodies for the X.509 extensions
     * @param time_req
     *      The requested lifetime of the delegated credential
     */
    /* gss_cred_id_t *                  credential,
       gss_OID_set                      restriction_oids,
       gss_buffer_set_t                 restriction_buffers,
       OM_uint32                        time_req */
    GLOBUS_XIO_GSI_ACCEPT_DELEGATION,

    /** GlobusVarArgEnum(handle)
     * Accept non-blocking delegation-at-any-time process
     * @ingroup gsi_driver_cntls
     *
     * @param restriction_oids
     *      The OIDS for X.509 extensions to embed in the delegated
     *      credential
     * @param restriction_buffers
     *      The corresponding bodies for the X.509 extensions
     * @param time_req
     *      The lifetime of the delegated credential
     * @param callback
     *      The callback to call when the operation completes
     * @param callback_arg
     *      The arguments to pass to the callback
     */
    /* gss_OID_set                                  restriction_oids,
       gss_buffer_set_t                             restriction_buffers,
       OM_uint32                                    time_req,
       globus_xio_gsi_delegation_accept_callback_t  callback,
       void *                                       callback_arg */
    GLOBUS_XIO_GSI_REGISTER_ACCEPT_DELEGATION,

    /** GlobusVarArgEnum(attr)
     * Force the server mode setting.
     * @ingroup gsi_driver_cntls
     *
     * This explicitly sets the directionality of context establishment and
     * delegation. 
     *
     * @param server_mode
     *      The server mode.
     */
    /* globus_bool_t                    server_mode */
    GLOBUS_XIO_GSI_FORCE_SERVER_MODE
} globus_xio_gsi_cmd_t;

/**
 * Globus XIO GSI protection levels
 * @ingroup gsi_driver_types
 */
typedef enum
{
    /** No security */
    GLOBUS_XIO_GSI_PROTECTION_LEVEL_NONE,
    /** Messages are signed */
    GLOBUS_XIO_GSI_PROTECTION_LEVEL_INTEGRITY,
    /** Messages are signed and encrypted */
    GLOBUS_XIO_GSI_PROTECTION_LEVEL_PRIVACY
} globus_xio_gsi_protection_level_t;

/**
 * Globus XIO GSI delegation modes
 * @ingroup gsi_driver_types
 */
typedef enum
{
    /** No delegation */
    GLOBUS_XIO_GSI_DELEGATION_MODE_NONE,
    /** Delegate a limited proxy */
    GLOBUS_XIO_GSI_DELEGATION_MODE_LIMITED,
    /** Delegate a full proxy */
    GLOBUS_XIO_GSI_DELEGATION_MODE_FULL
} globus_xio_gsi_delegation_mode_t;

/**
 * Globus XIO GSI proxy modes
 * @ingroup gsi_driver_types
 */
typedef enum
{
    /** Accept only full proxies */
    GLOBUS_XIO_GSI_PROXY_MODE_FULL,
    /** Accept full proxies and limited proxies if they are
     *  the only limited proxy in the cert chain.
     */
    GLOBUS_XIO_GSI_PROXY_MODE_LIMITED,
    /** Accept both full and limited proxies unconditionally */
    GLOBUS_XIO_GSI_PROXY_MODE_MANY
} globus_xio_gsi_proxy_mode_t;


/**
 * Globus XIO GSI authorization modes
 * @ingroup gsi_driver_types
 */
typedef enum
{
    /** Do not perform any authorization. This will cause a error when used in
     *  conjunction with delegation on the init/client side.
     */
    GLOBUS_XIO_GSI_NO_AUTHORIZATION,
    /** Authorize the peer if the peer has the same identity as ourselves */
    GLOBUS_XIO_GSI_SELF_AUTHORIZATION,
    /** Authorize the peer if the peer identity matches the identity set in the
     *  target name.
     */ 
    GLOBUS_XIO_GSI_IDENTITY_AUTHORIZATION,
    /** Authorize the peer if the identity of the peer matches the identity of
     *  the peer hostname.
     */ 
    GLOBUS_XIO_GSI_HOST_AUTHORIZATION
} globus_xio_gsi_authorization_mode_t;

/**
 * Globus XIO GSI init delegation callback
 * @ingroup gsi_driver_types
 */
typedef void (* globus_xio_gsi_delegation_init_callback_t)(
    globus_result_t			result,
    void *				user_arg);

/**
 * Globus XIO GSI init delegation callback
 * @ingroup gsi_driver_types
 */
typedef void (* globus_xio_gsi_delegation_accept_callback_t)(
    globus_result_t			result,
    gss_cred_id_t                       delegated_cred,
    OM_uint32                           time_rec,
    void *				user_arg);

EXTERN_C_END

#endif
