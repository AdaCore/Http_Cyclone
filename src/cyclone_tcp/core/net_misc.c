/**
 * @file net_misc.c
 * @brief Helper functions for TCP/IP stack
 *
 * @section License
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Copyright (C) 2010-2020 Oryx Embedded SARL. All rights reserved.
 *
 * This file is part of CycloneTCP Open.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * @author Oryx Embedded SARL (www.oryx-embedded.com)
 * @version 1.9.7b
 **/

//Switch to the appropriate trace level
#define TRACE_LEVEL NIC_TRACE_LEVEL

//Dependencies
#include "core/net.h"
#include "core/net_mem.h"
#include "debug.h"

//Default options passed to the stack
const NetAncillaryData NET_DEFAULT_ANCILLARY_DATA =
{
   0,     ///<Hop Limit
   FALSE, ///<Do not send the packet via a router
#if (ETH_VLAN_SUPPORT == ENABLED)
   -1,    ///<VLAN priority (802.1Q)
   -1,    ///<Drop eligible indicator
#endif
#if (ETH_VMAN_SUPPORT == ENABLED)
   -1,    ///<VMAN priority (802.1ad)
   -1,    ///<Drop eligible indicator
#endif
#if (ETH_PORT_TAGGING_SUPPORT == ENABLED)
   0,     ///<Switch port identifier
#endif
};
