# GRBL 1.1f — CH32V307 / CH32V203RBT6

> **Multi-axis CNC Controller for WCH RISC-V MCUs**  
> GRBL 1.1f | Build 20230112 | 6-Axis Ready

[![MCU](https://img.shields.io/badge/MCU-CH32V307%2FV203RBT6-blue)](#)
[![Core](https://img.shields.io/badge/Core-RISC--V%20QingKe%20V4F%2FV4B-purple)](#)
[![License](https://img.shields.io/badge/License-GPLv3-green.svg)](LICENSE)
[![GRBL](https://img.shields.io/badge/GRBL-1.1f-orange)](#)

---

## 📖 Overview

This is **GRBL 1.1f** — the popular open-source CNC motion control firmware — ported to **WCH CH32V307** and **CH32V203RBT6** RISC-V microcontrollers. It supports up to **6 axes** (X, Y, Z, A, B, C) on CH32V307 and **3 axes** (X, Y, Z) on CH32V203RBT6.

### What is GRBL?

GRBL translates G-code into step/direction pulses to drive stepper motors. Features include:

- G-code parser (rs274/ngc)
- Trapezoidal motion planner with acceleration
- Spindle control (PWM + direction)
- Coolant control (M7 Mist / M8 Flood / M9 Off)
- Limit switch and probe detection
- Serial communication (USART / USB)
- Real-time jogging and overrides

### Supported MCUs

| Feature | CH32V307 | CH32V203RBT6 |
|---------|----------|--------------|
| Core | QingKe V4F + FPU | QingKe V4B (no FPU) |
| Max Clock | 144 MHz | 144 MHz |
| Flash | 128K / 168K | 128K |
| RAM | 64K / 128K | 64K |
| Package | LQFP100 | LQFP64 |
| Axes | 6 (X,Y,Z,A,B,C) | 3 (X,Y,Z) |
| USB | High-Speed | Full-Speed (or disabled) |
| Build Status | ✅ Working | ✅ Working |

---

## 🚀 Quick Start

### Prerequisites

- **MounRiver Studio 2.0** (includes RISC-V GCC toolchain and OpenOCD)
  - Download: https://www.mounriver.com/
  - Install to: `C:\MounRiver\MounRiver_Studio2\` (default)

### Build

```batch
:: Build for CH32V307 (default)
.\scripts\build.bat

:: Clean build artifacts
.\scripts\clean.bat

:: Clean + Build
.\scripts\rebuild.bat
```

### Switch MCU

Edit `scripts\build.bat` — comment/uncomment the config line:

```batch
:: For CH32V307 (6-axis)
call "%~dp0mcu_config_CH32V307.bat"

:: For CH32V203RBT6 (3-axis)
::call "%~dp0mcu_config_CH32V203.bat"
```

### Flash

```batch
.\scripts\upload.bat
```

Requires **WCH-Link** or **WCH-LinkE** connected via SWD (SWCLK, SWDIO, GND).

### Build Output

```
output/
├── GRBL_CH32V307.elf     # ELF executable (debugging)
├── GRBL_CH32V307.hex     # Intel HEX (flashing)
├── GRBL_CH32V307.bin     # Raw binary (flashing)
└── GRBL_CH32V307.map     # Linker map (memory layout)
```

---

## 📁 Project Structure

```
6-AXIS-CH32V307-GRBL/
│
├── grbl/                          # GRBL Core (MCU-independent)
│   ├── grbl.h                     #   Master include
│   ├── config.h                   #   Build configuration
│   ├── cpu_map.h                  #   Pin mapping (bridge to hardware)
│   ├── gcode.c/h                  #   G-code parser
│   ├── planner.c/h                #   Motion planner
│   ├── stepper.c/h                #   Step pulse generator
│   ├── motion_control.c/h         #   Motion control
│   ├── spindle_control.c/h        #   Spindle (PWM)
│   ├── coolant_control.c/h        #   Coolant (M7/M8/M9)
│   ├── limits.c/h                 #   Limit switches
│   ├── probe.c/h                  #   Probe (G38.x)
│   ├── jog.c/h                    #   Jogging
│   ├── protocol.c/h               #   Main protocol loop
│   ├── report.c/h                 #   Status reports
│   ├── serial.c/h                 #   Serial communication
│   ├── system.c/h                 #   System state machine
│   ├── settings.c/h               #   Settings management
│   ├── eeprom.c/h                 #   EEPROM emulation (Flash)
│   └── nuts_bolts.c/h             #   Utility functions
│
├── mcu/                           # MCU-Specific layer
│   ├── CH32V307/                  #   CH32V307 support
│   │   ├── main.c                 #     Entry point
│   │   ├── system_ch32v30x.c/h    #     Clock init (144MHz)
│   │   ├── ch32v30x_it.c/h        #     Interrupt handlers
│   │   ├── sdk/                   #     WCH V30x peripheral library
│   │   └── ld/Link.ld             #     Linker script
│   │
│   └── CH32V203RBT6/              #   CH32V203RBT6 support
│       ├── main.c                 #     Entry point
│       ├── system_ch32v20x.c/h    #     Clock init (144MHz)
│       ├── ch32v20x_it.c/h        #     Interrupt handlers
│       ├── sdk/                   #     WCH V20x peripheral library
│       └── ld/Link.ld             #     Linker script
│
├── scripts/                       # Build system
│   ├── build.bat                  #   Compile + Link
│   ├── clean.bat                  #   Clean artifacts
│   ├── rebuild.bat                #   Clean + Build
│   ├── upload.bat                 #   Flash via WCH-Link
│   ├── mcu_config_CH32V307.bat    #   CH32V307 config
│   ├── mcu_config_CH32V203.bat    #   CH32V203RBT6 config
│   └── make_clangd.bat            #   Generate IntelliSense config
│
└── docs/                          # Documentation
    ├── README_TH.md               #   Thai user manual
    ├── GRBL_GCODE_REFERENCE.md    #   G-code/M-code reference
    └── MIGRATION_V203RBT6.md      #   V203 migration guide
```

---

## 📐 G-Code Support (35 Commands)

| Group | Commands |
|-------|----------|
| **Motion** | G0, G1, G2, G3, G38.2–G38.5, G80 |
| **Plane** | G17, G18, G19 |
| **Distance** | G90, G91 |
| **Feed Rate** | G93, G94 |
| **Units** | G20, G21 |
| **Tool Offset** | G43.1, G49 |
| **Coordinate** | G54–G59 |
| **Path Control** | G61 |
| **Non-Modal** | G4, G10 L2/L20, G28/28.1, G30/30.1, G53, G92/92.1 |

## 🛠️ M-Code Support (9 Commands)

| Group | Commands |
|-------|----------|
| **Program Flow** | M0, M1, M2, M30 |
| **Spindle** | M3, M4, M5 (+ S for RPM) |
| **Coolant** | M7, M8, M9 |
| **Override** | M56 (Parking) |

## ⚡ Real-Time Commands (22 Commands)

`?` Status | `!` Feed Hold | `~` Cycle Start | `Ctrl+X` Reset  
Feed Override (5) | Rapid Override (3) | Spindle Override (6) | Coolant Override (2)

---

## 🔌 Pin Map (CH32V307 — LQFP100)

```
         CH32V307VCT6 LQFP100
    ┌─────────────────────────────┐
    │                             │
    │  GPIOE:                     │
    │   PE0  X_DIR       PE1  X_STEP
    │   PE2  Y_DIR       PE3  Y_STEP
    │   PE4  Z_DIR       PE5  Z_STEP
    │   PE6  A_DIR       PE7  A_STEP
    │   PE8  B_DIR       PE9  B_STEP
    │   PE10 C_DIR       PE11 C_STEP
    │   PE12 MIST        PE13 FLOOD
    │   PE14 PROBE       PE15 STEP_DISABLE
    │                             │
    │  GPIOD:                     │
    │   PD0  SPN_DIR     PD1  SPN_EN
    │   PD3  SAFETY      PD4  FEED_HOLD
    │   PD5  RESET       PD7  CYCLE_START
    │   PD10 X_LIMIT     PD11 Y_LIMIT
    │   PD12 Z_LIMIT     PD13 A_LIMIT
    │   PD14 B_LIMIT     PD15 C_LIMIT
    │                             │
    │  GPIOA:                     │
    │   PA2  SERIAL_TX   PA3  SERIAL_RX
    │   PA8  SPINDLE_PWM (TIM1_CH1)
    │                             │
    └─────────────────────────────┘
```

> For CH32V203RBT6 (LQFP64) 3-axis pin map, see [`docs/MIGRATION_V203RBT6.md`](docs/MIGRATION_V203RBT6.md)

---

## 🏷️ Version & Credits

| | |
|---|---|
| **GRBL Version** | 1.1f |
| **Build** | 20230112 |
| **Base** | [gnea/grbl](https://github.com/gnea/grbl) by Sungeun K. Jeon |
| **Multi-axis** | YSV (22-06-2018) |
| **CH32 Port** | Custom `cpu_map.h` + conditional defines |
| **License** | GPLv3 |

---

## 📚 Resources

- **GRBL Official**: https://github.com/gnea/grbl
- **GRBL Wiki**: https://github.com/gnea/grbl/wiki
- **grblHAL** (next-gen): https://github.com/grblHAL
- **WCH Official**: https://www.wch.cn/
- **MounRiver Studio**: https://www.mounriver.com/
- **Thai Manual**: [`docs/README_TH.md`](docs/README_TH.md)
- **G-code Reference**: [`docs/GRBL_GCODE_REFERENCE.md`](docs/GRBL_GCODE_REFERENCE.md)
- **V203 Migration**: [`docs/MIGRATION_V203RBT6.md`](docs/MIGRATION_V203RBT6.md)

---

> **Last Updated**: 20 May 2026
