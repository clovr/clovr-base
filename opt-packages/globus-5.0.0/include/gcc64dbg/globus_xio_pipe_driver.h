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

#ifndef GLOBUS_XIO_PIPE_DRIVER_INCLUDE
#define GLOBUS_XIO_PIPE_DRIVER_INCLUDE
#include "globus_xio_system.h"

typedef enum
{
    GLOBUS_XIO_PIPE_SET_BLOCKING_IO,
    GLOBUS_XIO_PIPE_SET_IN_HANDLE,
    GLOBUS_XIO_PIPE_SET_OUT_HANDLE
} globus_xio_pipe_attr_cmd_t;

#endif
