RESULT ?= http_client_demo

DEFINES = \
	-DSTM32F769xx \
	-DUSE_HAL_DRIVER \
	-DUSE_STM32F769I_DISCO \
	-D_WINSOCK_H \
	-D__error_t_defined

INCLUDES = \
	-I./src \
	-I./src/third_party/cmsis/include \
	-I./src/third_party/st/devices/stm32f7xx \
	-I./src/third_party/st/drivers/stm32f7xx_hal_driver/inc \
	-I./src/third_party/st/boards/stm32f769i_discovery \
	-I./src/third_party/freertos/include \
	-I./src/third_party/freertos/portable/gcc/arm_cm7/r0p1 \
	-I./src/common \
	-I./src/cyclone_tcp \
	-I./src/cyclone_ssl \
	-I./src/cyclone_crypto

ASM_SOURCES = \
	./src/startup_stm32f769xx.S

C_SOURCES = \
	./src/system_stm32f7xx.c \
	./src/stm32f7xx_it.c \
	./src/syscalls.c \
	./src/main.c \
	./src/debug.c \
	./src/common/cpu_endian.c \
	./src/common/os_port_freertos.c \
	./src/common/date_time.c \
	./src/common/str.c \
	./src/cyclone_tcp/core/net.c \
	./src/cyclone_tcp/core/net_mem.c \
	./src/cyclone_tcp/core/net_misc.c \
	./src/cyclone_tcp/drivers/mac/stm32f7xx_eth_driver.c \
	./src/cyclone_tcp/drivers/phy/lan8742_driver.c \
	./src/cyclone_tcp/core/nic.c \
	./src/cyclone_tcp/core/ethernet.c \
	./src/cyclone_tcp/core/ethernet_misc.c \
	./src/cyclone_tcp/ipv4/arp.c \
	./src/cyclone_tcp/ipv4/ipv4.c \
	./src/cyclone_tcp/ipv4/ipv4_frag.c \
	./src/cyclone_tcp/ipv4/ipv4_misc.c \
	./src/cyclone_tcp/ipv4/icmp.c \
	./src/cyclone_tcp/ipv4/igmp.c \
	./src/cyclone_tcp/ipv6/ipv6.c \
	./src/cyclone_tcp/ipv6/ipv6_frag.c \
	./src/cyclone_tcp/ipv6/ipv6_misc.c \
	./src/cyclone_tcp/ipv6/ipv6_pmtu.c \
	./src/cyclone_tcp/ipv6/icmpv6.c \
	./src/cyclone_tcp/ipv6/mld.c \
	./src/cyclone_tcp/ipv6/ndp.c \
	./src/cyclone_tcp/ipv6/ndp_cache.c \
	./src/cyclone_tcp/ipv6/ndp_misc.c \
	./src/cyclone_tcp/ipv6/slaac.c \
	./src/cyclone_tcp/core/ip.c \
	./src/cyclone_tcp/core/tcp.c \
	./src/cyclone_tcp/core/tcp_fsm.c \
	./src/cyclone_tcp/core/tcp_misc.c \
	./src/cyclone_tcp/core/tcp_timer.c \
	./src/cyclone_tcp/core/udp.c \
	./src/cyclone_tcp/core/socket.c \
	./src/cyclone_tcp/core/bsd_socket.c \
	./src/cyclone_tcp/core/raw_socket.c \
	./src/cyclone_tcp/dns/dns_cache.c \
	./src/cyclone_tcp/dns/dns_client.c \
	./src/cyclone_tcp/dns/dns_common.c \
	./src/cyclone_tcp/dns/dns_debug.c \
	./src/cyclone_tcp/mdns/mdns_client.c \
	./src/cyclone_tcp/mdns/mdns_responder.c \
	./src/cyclone_tcp/mdns/mdns_common.c \
	./src/cyclone_tcp/netbios/nbns_client.c \
	./src/cyclone_tcp/netbios/nbns_responder.c \
	./src/cyclone_tcp/netbios/nbns_common.c \
	./src/cyclone_tcp/llmnr/llmnr_client.c \
	./src/cyclone_tcp/llmnr/llmnr_responder.c \
	./src/cyclone_tcp/llmnr/llmnr_common.c \
	./src/cyclone_tcp/dhcp/dhcp_client.c \
	./src/cyclone_tcp/dhcp/dhcp_common.c \
	./src/cyclone_tcp/dhcp/dhcp_debug.c \
	./src/cyclone_tcp/ftp/ftp_client.c \
	./src/cyclone_tcp/ftp/ftp_client_transport.c \
	./src/cyclone_tcp/ftp/ftp_client_misc.c \
	./src/third_party/freertos/portable/gcc/arm_cm7/r0p1/port.c \
	./src/third_party/freertos/croutine.c \
	./src/third_party/freertos/list.c \
	./src/third_party/freertos/queue.c \
	./src/third_party/freertos/tasks.c \
	./src/third_party/freertos/timers.c \
	./src/third_party/freertos/portable/memmang/heap_3.c \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery.c \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_audio.c \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_eeprom.c \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_lcd.c \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_qspi.c \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_sd.c \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_sdram.c \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_ts.c \
	./src/third_party/st/boards/components/ft6x06/ft6x06.c \
	./src/third_party/st/boards/components/otm8009a/otm8009a.c \
	./src/third_party/st/boards/components/wm8994/wm8994.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_adc.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_adc_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_can.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_cec.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_cortex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_crc.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_crc_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_cryp.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_cryp_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_dac.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_dac_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_dcmi.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_dcmi_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_dfsdm.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_dma.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_dma_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_dma2d.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_dsi.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_eth.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_flash.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_flash_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_gpio.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_hash.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_hash_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_hcd.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_i2c.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_i2c_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_i2s.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_irda.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_iwdg.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_jpeg.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_lptim.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_ltdc.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_ltdc_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_mdios.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_nand.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_nor.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_pcd.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_pcd_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_pwr.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_pwr_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_qspi.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_rcc.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_rcc_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_rng.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_rtc.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_rtc_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_sai.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_sai_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_sd.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_sdram.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_smartcard.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_smartcard_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_spdifrx.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_spi.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_sram.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_tim.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_tim_ex.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_uart.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_usart.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_hal_wwdg.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_ll_fmc.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_ll_sdmmc.c \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/src/stm32f7xx_ll_usb.c

HEADERS = \
	./src/os_port_config.h \
	./src/net_config.h \
	./src/FreeRTOSConfig.h \
	./src/stm32f7xx_hal_conf.h \
	./src/stm32f7xx_it.h \
	./src/common/cpu_endian.h \
	./src/common/os_port.h \
	./src/common/os_port_freertos.h \
	./src/common/date_time.h \
	./src/common/str.h \
	./src/common/error.h \
	./src/common/debug.h \
	./src/cyclone_tcp/core/net.h \
	./src/cyclone_tcp/core/net_mem.h \
	./src/cyclone_tcp/core/net_misc.h \
	./src/cyclone_tcp/drivers/mac/stm32f7xx_eth_driver.h \
	./src/cyclone_tcp/drivers/phy/lan8742_driver.h \
	./src/cyclone_tcp/core/nic.h \
	./src/cyclone_tcp/core/ethernet.h \
	./src/cyclone_tcp/core/ethernet_misc.h \
	./src/cyclone_tcp/ipv4/arp.h \
	./src/cyclone_tcp/ipv4/ipv4.h \
	./src/cyclone_tcp/ipv4/ipv4_frag.h \
	./src/cyclone_tcp/ipv4/ipv4_misc.h \
	./src/cyclone_tcp/ipv4/icmp.h \
	./src/cyclone_tcp/ipv4/igmp.h \
	./src/cyclone_tcp/ipv6/ipv6.h \
	./src/cyclone_tcp/ipv6/ipv6_frag.h \
	./src/cyclone_tcp/ipv6/ipv6_misc.h \
	./src/cyclone_tcp/ipv6/ipv6_pmtu.h \
	./src/cyclone_tcp/ipv6/icmpv6.h \
	./src/cyclone_tcp/ipv6/mld.h \
	./src/cyclone_tcp/ipv6/ndp.h \
	./src/cyclone_tcp/ipv6/ndp_cache.h \
	./src/cyclone_tcp/ipv6/ndp_misc.h \
	./src/cyclone_tcp/ipv6/slaac.h \
	./src/cyclone_tcp/core/ip.h \
	./src/cyclone_tcp/core/tcp.h \
	./src/cyclone_tcp/core/tcp_fsm.h \
	./src/cyclone_tcp/core/tcp_misc.h \
	./src/cyclone_tcp/core/tcp_timer.h \
	./src/cyclone_tcp/core/udp.h \
	./src/cyclone_tcp/core/socket.h \
	./src/cyclone_tcp/core/bsd_socket.h \
	./src/cyclone_tcp/core/raw_socket.h \
	./src/cyclone_tcp/dns/dns_cache.h \
	./src/cyclone_tcp/dns/dns_client.h \
	./src/cyclone_tcp/dns/dns_common.h \
	./src/cyclone_tcp/dns/dns_debug.h \
	./src/cyclone_tcp/mdns/mdns_client.h \
	./src/cyclone_tcp/mdns/mdns_responder.h \
	./src/cyclone_tcp/mdns/mdns_common.h \
	./src/cyclone_tcp/netbios/nbns_client.h \
	./src/cyclone_tcp/netbios/nbns_responder.h \
	./src/cyclone_tcp/netbios/nbns_common.h \
	./src/cyclone_tcp/llmnr/llmnr_client.h \
	./src/cyclone_tcp/llmnr/llmnr_responder.h \
	./src/cyclone_tcp/llmnr/llmnr_common.h \
	./src/cyclone_tcp/dhcp/dhcp_client.h \
	./src/cyclone_tcp/dhcp/dhcp_common.h \
	./src/cyclone_tcp/dhcp/dhcp_debug.h \
	./src/cyclone_tcp/ftp/ftp_client.h \
	./src/cyclone_tcp/ftp/ftp_client_transport.h \
	./src/cyclone_tcp/ftp/ftp_client_misc.h \
	./src/third_party/freertos/portable/gcc/arm_cm7/r0p1/portmacro.h \
	./src/third_party/freertos/include/croutine.h \
	./src/third_party/freertos/include/FreeRTOS.h \
	./src/third_party/freertos/include/list.h \
	./src/third_party/freertos/include/mpu_wrappers.h \
	./src/third_party/freertos/include/portable.h \
	./src/third_party/freertos/include/projdefs.h \
	./src/third_party/freertos/include/queue.h \
	./src/third_party/freertos/include/semphr.h \
	./src/third_party/freertos/include/stack_macros.h \
	./src/third_party/freertos/include/task.h \
	./src/third_party/freertos/include/timers.h \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery.h \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_audio.h \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_eeprom.h \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_lcd.h \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_qspi.h \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_sd.h \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_sdram.h \
	./src/third_party/st/boards/stm32f769i_discovery/stm32f769i_discovery_ts.h \
	./src/third_party/st/boards/components/adv7533/adv7533.h \
	./src/third_party/st/boards/components/ft6x06/ft6x06.h \
	./src/third_party/st/boards/components/mx25l512/mx25l512.h \
	./src/third_party/st/boards/components/otm8009a/otm8009a.h \
	./src/third_party/st/boards/components/wm8994/wm8994.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_adc.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_adc_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_can.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_cec.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_cortex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_crc.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_crc_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_cryp.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_cryp_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_dac.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_dac_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_dcmi.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_dcmi_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_def.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_dfsdm.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_dma.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_dma_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_dma2d.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_dsi.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_eth.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_flash.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_flash_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_gpio.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_gpio_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_hash.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_hash_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_hcd.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_i2c.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_i2c_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_i2s.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_irda.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_irda_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_iwdg.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_jpeg.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_lptim.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_ltdc.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_ltdc_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_mdios.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_nand.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_nor.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_pcd.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_pcd_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_pwr.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_pwr_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_qspi.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_rcc.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_rcc_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_rng.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_rtc.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_rtc_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_sai.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_sai_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_sd.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_sdram.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_smartcard.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_smartcard_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_spdifrx.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_spi.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_sram.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_tim.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_tim_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_uart.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_uart_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_usart.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_usart_ex.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_hal_wwdg.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_ll_fmc.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_ll_sdmmc.h \
	./src/third_party/st/drivers/stm32f7xx_hal_driver/inc/stm32f7xx_ll_usb.h

ASM_OBJECTS = $(patsubst %.S, %.o, $(ASM_SOURCES))

C_OBJECTS = $(patsubst %.c, %.o, $(C_SOURCES))

OBJ_DIR = obj

LINKER_SCRIPT = src/stm32f769_flash.ld

CFLAGS += -fno-common -Wall -Os -g3
CFLAGS += -mcpu=cortex-m7 -mthumb -mfpu=fpv5-d16 -mfloat-abi=hard
CFLAGS += -ffunction-sections -fdata-sections -Wl,--gc-sections
CFLAGS += $(DEFINES)
CFLAGS += $(INCLUDES)

CROSS_COMPILE ?= arm-none-eabi-
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
OBJDUMP = $(CROSS_COMPILE)objdump
OBJCOPY = $(CROSS_COMPILE)objcopy
SIZE = $(CROSS_COMPILE)size

THIS_MAKEFILE := $(lastword $(MAKEFILE_LIST))

all: build size

install: build size program

build: $(RESULT).elf $(RESULT).lst $(RESULT).bin $(RESULT).hex
	
$(RESULT).elf: $(ASM_OBJECTS) $(C_OBJECTS) $(HEADERS) $(LINKER_SCRIPT) $(THIS_MAKEFILE)
	$(CC) -Wl,-M=$(RESULT).map -Wl,-T$(LINKER_SCRIPT) $(CFLAGS) $(addprefix $(OBJ_DIR)/, $(notdir $(ASM_OBJECTS))) $(addprefix $(OBJ_DIR)/, $(notdir $(C_OBJECTS))) -o $@

$(ASM_OBJECTS): | $(OBJ_DIR)

$(C_OBJECTS): | $(OBJ_DIR)

$(OBJ_DIR):
	mkdir -p $@

%.o: %.c $(HEADERS) $(THIS_MAKEFILE)
	$(CC) $(CFLAGS) -c $< -o $(addprefix $(OBJ_DIR)/, $(notdir $@))

%.o: %.S $(HEADERS) $(THIS_MAKEFILE)
	$(CC) $(CFLAGS) -c $< -o $(addprefix $(OBJ_DIR)/, $(notdir $@))

%.lst: %.elf
	$(OBJDUMP) -x -S $(RESULT).elf > $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.hex: %.elf
	$(OBJCOPY) -O ihex $< $@

size: $(RESULT).elf
	$(SIZE) $(RESULT).elf

flash:
	openocd -f board/stm32f7discovery.cfg -c "init; reset halt; flash write_image erase $(RESULT).bin 0x08000000; reset run; shutdown"

clean:
	rm -f $(RESULT).elf
	rm -f $(RESULT).bin
	rm -f $(RESULT).map
	rm -f $(RESULT).hex
	rm -f $(RESULT).lst
	rm -f $(OBJ_DIR)/*.o
