:: ============================================================
::  MCU Configuration: CH32V307 (rv32imafc, FPU, 6-axis)
::  Board: CH32V307VCT6 LQFP100
::  Flash: 128K   RAM: 64K    Clock: 144MHz HSE
:: ============================================================
set MCU_NAME=CH32V307
set MCU_FOLDER=mcu\CH32V307
set OUTPUT_NAME=GRBL_CH32V307

:: ---- Architecture ----
set ARCH=-march=rv32imafc -mabi=ilp32f
set EXTRA_CFLAGS=-fsingle-precision-constant

:: ---- Defines ----
set DEFINES=-DCH32V307 -DABC_AXIS_EXAMPLE -DAB_AXIS

:: ---- Toolchain (1=GCC8 riscv-none-embed-, 2=GCC12 riscv-wch-elf-) ----
set TOOLCHAIN_CHOICE=1

:: ---- Memory ----
set FLASH_TOTAL=131072
set RAM_TOTAL=65536

:: ---- Startup Assembly ----
set STARTUP_ASM=startup_ch32v30x_D8.S

:: ---- USB Device Source (leave empty to disable USB) ----
set USB_SOURCE=ch32v30x_usbhs_device.c

:: ---- Camera Overlay (leave empty to disable) ----
set OV_SOURCE=ov.c
