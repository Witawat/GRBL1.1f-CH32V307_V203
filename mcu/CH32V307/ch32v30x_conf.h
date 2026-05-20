/********************************** (C) COPYRIGHT *******************************
* File Name          : ch32v30x_conf.h
* Author             : WCH
* Version            : V1.0.0
* Date               : 2021/06/06
* Description        : Library configuration file.
* Copyright (c) 2021 Nanjing Qinheng Microelectronics Co., Ltd.
* SPDX-License-Identifier: Apache-2.0
*******************************************************************************/ 
#ifndef __CH32V30x_CONF_H
#define __CH32V30x_CONF_H

// ====================================================================
// CH32V30x / CH32V203 Peripheral Library Configuration
// ====================================================================
// For CH32V307: use ch32v30x_*.h headers (WCH V30x SDK)
// For CH32V203: use ch32v20x_*.h headers (WCH V20x SDK)
// ====================================================================

#ifdef CH32V203_RBT6_3AXIS
  // --- CH32V203 Peripheral Headers (WCH V20x SDK) ---
  #include "ch32v20x_adc.h"
  #include "ch32v20x_bkp.h"
  #include "ch32v20x_can.h"
  #include "ch32v20x_crc.h"
  #include "ch32v20x_dac.h"
  #include "ch32v20x_dbgmcu.h"
  #include "ch32v20x_dma.h"
  #include "ch32v20x_exti.h"
  #include "ch32v20x_flash.h"
  #include "ch32v20x_gpio.h"
  #include "ch32v20x_i2c.h"
  #include "ch32v20x_iwdg.h"
  #include "ch32v20x_pwr.h"
  #include "ch32v20x_rcc.h"
  #include "ch32v20x_rtc.h"
  #include "ch32v20x_spi.h"
  #include "ch32v20x_tim.h"
  #include "ch32v20x_usart.h"
  #include "ch32v20x_wwdg.h"
  #include "ch32v20x_it.h"
  #include "ch32v20x_misc.h"
#else
  // --- CH32V30x Peripheral Headers (WCH V30x SDK) ---
  #include "ch32v30x_adc.h"
  #include "ch32v30x_bkp.h"
  #include "ch32v30x_can.h"
  #include "ch32v30x_crc.h"
  #include "ch32v30x_dac.h"
  #include "ch32v30x_dbgmcu.h"
  #include "ch32v30x_dma.h"
  #include "ch32v30x_exti.h"
  #include "ch32v30x_flash.h"
  #include "ch32v30x_fsmc.h"
  #include "ch32v30x_gpio.h"
  #include "ch32v30x_i2c.h"
  #include "ch32v30x_iwdg.h"
  #include "ch32v30x_pwr.h"
  #include "ch32v30x_rcc.h"
  #include "ch32v30x_rtc.h"
  #include "ch32v30x_sdio.h"
  #include "ch32v30x_spi.h"
  #include "ch32v30x_tim.h"
  #include "ch32v30x_usart.h"
  #include "ch32v30x_wwdg.h"
  #include "ch32v30x_it.h"
  #include "ch32v30x_misc.h"
#endif

#endif /* __CH32V30x_CONF_H */


	
	
	
