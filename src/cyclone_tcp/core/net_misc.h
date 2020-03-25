/**
 * @file net_misc.h
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

#ifndef _NET_MISC_H
#define _NET_MISC_H

//Forward declaration of NetAncillaryData structure
struct _NetAncillaryData;
#define NetAncillaryData struct _NetAncillaryData

//Dependencies
#include "core/net.h"
#include "core/ethernet.h"

//C++ guard
#ifdef __cplusplus
extern "C" {
#endif


/**
 * @brief Additional options passed to the stack
 **/

struct _NetAncillaryData
{
   uint8_t ttl;      ///<Time-to-live value
   bool_t dontRoute; ///<Do not send the packet via a router
#if (ETH_VLAN_SUPPORT == ENABLED)
   int8_t vlanPcp;   ///<VLAN priority (802.1Q)
   int8_t vlanDei;   ///<Drop eligible indicator
#endif
#if (ETH_VMAN_SUPPORT == ENABLED)
   int8_t vmanPcp;   ///<VMAN priority (802.1ad)
   int8_t vmanDei;   ///<Drop eligible indicator
#endif
#if (ETH_PORT_TAGGING_SUPPORT == ENABLED)
   uint8_t port;     ///<Switch port identifier
#endif
};


//C++ guard
#ifdef __cplusplus
}
#endif

#endif
