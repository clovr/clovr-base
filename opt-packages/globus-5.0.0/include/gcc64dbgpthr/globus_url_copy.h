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

#ifndef GLOBUS_GLOBUS_URL_COPY_H
#define GLOBUS_GLOBUS_URL_COPY_H 1

#define GLOBUS_URL_COPY_ARG_ASCII       1
#define GLOBUS_URL_COPY_ARG_BINARY      2
#define GLOBUS_URL_COPY_ARG_VERBOSE     4

#include "globus_ftp_client_plugin.h"
#include "gssapi.h"

typedef struct globus_guc_src_dst_pair_s
{
    char *                              src_url;
    char *                              dst_url;
} globus_guc_src_dst_pair_t;

typedef struct globus_guc_info_s
{
    globus_fifo_t *                     user_url_list;

    char *                              source_subject;
    char *                              dest_subject;
    unsigned long                       options;
    globus_size_t                       block_size;
    globus_size_t                       tcp_buffer_size;
    int                                 num_streams;
    int                                 conc;
    globus_bool_t                       no_3pt;
    globus_bool_t                       no_dcau;
    globus_bool_t                       data_safe;
    globus_bool_t                       data_private;
    globus_bool_t                       cancelled;
    globus_bool_t                       recurse;
    int                                 restart_retries;
    int                                 restart_interval;
    int                                 restart_timeout;
    int                                 stall_timeout;
    globus_size_t                       stripe_bs;
    globus_bool_t                       striped;
    globus_bool_t                       rfc1738;
    globus_bool_t                       create_dest;
    globus_off_t                        partial_offset;
    globus_off_t                        partial_length;
    globus_bool_t                       list_uses_data_mode;
    globus_bool_t                       ipv6;
    globus_bool_t                       gridftp2;
    globus_bool_t                       udt;
    globus_bool_t                       allo;
    char *                              src_net_stack_str;
    char *                              src_disk_stack_str;
    char *                              dst_net_stack_str;
    char *                              dst_disk_stack_str;
    char *                              src_authz_assert;
    char *                              dst_authz_assert;
    globus_bool_t                       cache_src_authz_assert;
    globus_bool_t                       cache_dst_authz_assert;
    gss_cred_id_t                       src_cred;
    gss_cred_id_t                       dst_cred;

    globus_bool_t                       verbose;
    globus_bool_t                       quiet;
    globus_bool_t                       delayed_pasv;
    globus_bool_t                       pipeline;
} globus_guc_info_t;

typedef struct globus_l_guc_plugin_op_s * globus_guc_plugin_op_t;

void
globus_guc_copy_performance_update(
    globus_off_t                        total_bytes,
    float                               instantaneous_throughput,
    float                               avg_throughput);

void
globus_guc_transfer_update(
    const char *                        src_url,
    const char *                        dst_url,
    const char *                        src_fname,
    const char *                        dst_fname);

void
globus_guc_plugin_finished(
    globus_guc_plugin_op_t              done_op,
    globus_result_t                     result);

typedef globus_result_t
(*globus_guc_plugin_start_t)(
    void **                             handle,
    globus_guc_info_t *                 guc_info,
    globus_guc_plugin_op_t              done_op,
    int                                 argc,
    char **                             argv);

typedef void
(*globus_guc_plugin_cancel_t)(
    void *                              handle);

typedef void
(*globus_guc_plugin_cleanup_t)(
    void *                              handle);

typedef struct globus_guc_plugin_funcs_s
{
    globus_guc_plugin_start_t           start_func;
    globus_guc_plugin_cancel_t          cancel_func;
    globus_guc_plugin_cleanup_t         cleanup_func;
} globus_guc_plugin_funcs_t;

typedef globus_result_t
(*globus_guc_client_plugin_init_t)(
    globus_ftp_client_plugin_t *        plugin,
    char *                              in_args);
    
typedef struct globus_guc_client_plugin_funcs_s
{   
    globus_guc_client_plugin_init_t     init_func;
} globus_guc_client_plugin_funcs_t;

extern globus_extension_registry_t      globus_guc_client_plugin_registry; 
extern globus_extension_registry_t      globus_guc_plugin_registry;

#define GUC_PLUGIN_FUNCS                "guc_funcs"

#endif


