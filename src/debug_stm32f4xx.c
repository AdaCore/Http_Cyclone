/**
 * @file debug.c
 * @brief Debugging facilities
 *
 * @section License
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * Copyright (C) 2010-2020 Oryx Embedded SARL. All rights reserved.
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
 * @version 1.9.8
 **/

//Dependencies
#include "stm32f4xx.h"
#include "debug.h"

//Variable declaration
static UART_HandleTypeDef UART_Handle;


/**
 * @brief Debug UART initialization
 * @param[in] baudrate UART baudrate
 **/

void debugInit(uint32_t baudrate)
{
   GPIO_InitTypeDef GPIO_InitStructure;

   //Enable GPIOC clock
   __HAL_RCC_GPIOC_CLK_ENABLE();
   //Enable USART6 clock
   __HAL_RCC_USART6_CLK_ENABLE();

   //Configure USART6_TX (PC6)
   GPIO_InitStructure.Pin = GPIO_PIN_6;
   GPIO_InitStructure.Mode = GPIO_MODE_AF_PP;
   GPIO_InitStructure.Pull = GPIO_PULLUP;
   GPIO_InitStructure.Speed = GPIO_SPEED_FREQ_MEDIUM;
   GPIO_InitStructure.Alternate = GPIO_AF8_USART6;
   HAL_GPIO_Init(GPIOC, &GPIO_InitStructure);

   //Configure USART6_RX (PC7)
   GPIO_InitStructure.Pin = GPIO_PIN_9;
   GPIO_InitStructure.Mode = GPIO_MODE_AF_PP;
   GPIO_InitStructure.Pull = GPIO_PULLUP;
   GPIO_InitStructure.Speed = GPIO_SPEED_FREQ_MEDIUM;
   GPIO_InitStructure.Alternate = GPIO_AF8_USART6;
   HAL_GPIO_Init(GPIOC, &GPIO_InitStructure);

   //Configure USART6
   UART_Handle.Instance = USART6;
   UART_Handle.Init.BaudRate = baudrate;
   UART_Handle.Init.WordLength = UART_WORDLENGTH_8B;
   UART_Handle.Init.StopBits = UART_STOPBITS_1;
   UART_Handle.Init.Parity = UART_PARITY_NONE;
   UART_Handle.Init.HwFlowCtl = UART_HWCONTROL_NONE;
   UART_Handle.Init.Mode = UART_MODE_TX_RX;
   HAL_UART_Init(&UART_Handle);
}


/**
 * @brief Display the contents of an array
 * @param[in] stream Pointer to a FILE object that identifies an output stream
 * @param[in] prepend String to prepend to the left of each line
 * @param[in] data Pointer to the data array
 * @param[in] length Number of bytes to display
 **/

void debugDisplayArray(FILE *stream,
   const char_t *prepend, const void *data, size_t length)
{
   uint_t i;

   for(i = 0; i < length; i++)
   {
      //Beginning of a new line?
      if((i % 16) == 0)
         fprintf(stream, "%s", prepend);
      //Display current data byte
      fprintf(stream, "%02" PRIX8 " ", *((uint8_t *) data + i));
      //End of current line?
      if((i % 16) == 15 || i == (length - 1))
         fprintf(stream, "\r\n");
   }
}


/**
 * @brief Write character to stream
 * @param[in] c The character to be written
 * @param[in] stream Pointer to a FILE object that identifies an output stream
 * @return On success, the character written is returned. If a writing
 *   error occurs, EOF is returned
 **/

int_t fputc(int_t c, FILE *stream)
{
   //Standard output or error output?
   if(stream == stdout || stream == stderr)
   {
      //Character to be written
      uint8_t ch = c;

      //Transmit data
      HAL_UART_Transmit(&UART_Handle, &ch, 1, HAL_MAX_DELAY);

      //On success, the character written is returned
      return c;
   }
   //Unknown output?
   else
   {
      //If a writing error occurs, EOF is returned
      return EOF;
   }
}

void debugString (char* str, int length) {
   osSuspendAllTasks();
   if (str == NULL) return;
   str[length+1] = '\0'; 
   fprintf(stderr, "%s", str);
   osResumeAllTasks();
}
