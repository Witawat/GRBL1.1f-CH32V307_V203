:: ============================================================
::  MCU Configuration: CH32V203RBT6 (rv32imac, no FPU, 3-axis)
::  Board: CH32V203RBT6 LQFP64
::  Flash: 128K   RAM: 64K    Clock: 144MHz HSE
::
::  SDK: mcu/CH32V203RBT6/ — V20x SDK files ready
::  Pin map: grbl/cpu_map.h — CH32V203_RBT6_3AXIS section ready
::  Toolchain: TOOLCHAIN_CHOICE=2 (GCC12 riscv-wch-elf-)
::  USB: Disabled (USB_SOURCE empty) — uses USART2 serial
:: ============================================================
set MCU_NAME=CH32V203RBT6
set MCU_FOLDER=mcu\CH32V203RBT6
set OUTPUT_NAME=GRBL_CH32V203

:: ---- Architecture ----
set ARCH=-march=rv32imac -mabi=ilp32
set EXTRA_CFLAGS=-flto

:: ---- Defines ----
set DEFINES=-DCH32V203_RBT6_3AXIS

:: ---- Toolchain (1=GCC8 riscv-none-embed-, 2=GCC12 riscv-wch-elf-) ----
set TOOLCHAIN_CHOICE=2

:: ---- Memory ----
set FLASH_TOTAL=131072
set RAM_TOTAL=65536

:: ---- Startup Assembly ----
set STARTUP_ASM=startup_ch32v20x_D6.S

:: ---- USB Device Source (leave empty to disable USB) ----
set USB_SOURCE=

:: ---- Camera Overlay (leave empty to disable) ----
set OV_SOURCE=
