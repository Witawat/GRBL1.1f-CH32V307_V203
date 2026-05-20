# GRBL CH32V307 — คู่มือการใช้งาน (ภาษาไทย)

> **เวอร์ชันล่าสุด**: 20 พฤษภาคม 2569  
> **GRBL**: 1.1f (Build 20230112)  
> **MCU**: CH32V307 (RISC-V, 144MHz, FPU, 6 แกน)  
> **Build System**: Batch scripts + GCC (MounRiver Toolchain)

---

## 📋 สารบัญ

1. [ภาพรวมโปรเจค](#1-ภาพรวมโปรเจค)
2. [โครงสร้างโฟลเดอร์](#2-โครงสร้างโฟลเดอร์)
3. [ซอฟต์แวร์ที่ต้องติดตั้ง](#3-ซอฟต์แวร์ที่ต้องติดตั้ง)
4. [วิธี Build](#4-วิธี-build)
5. [วิธีเปลี่ยน MCU](#5-วิธีเปลี่ยน-mcu)
6. [วิธีเพิ่ม MCU ใหม่](#6-วิธีเพิ่ม-mcu-ใหม่)
7. [การใช้งานร่วมกับ VS Code](#7-การใช้งานร่วมกับ-vs-code)
8. [การใช้งานร่วมกับ MounRiver Studio 2.0](#8-การใช้งานร่วมกับ-mounriver-studio-20)
9. [การอัปโหลดเฟิร์มแวร์ลงบอร์ด](#9-การอัปโหลดเฟิร์มแวร์ลงบอร์ด)
10. [การตั้งค่า clangd (Autocomplete)](#10-การตั้งค่า-clangd-autocomplete)
11. [คำถามที่พบบ่อย (FAQ)](#11-คำถามที่พบบ่อย-faq)
12. [การย้ายไป CH32V203RBT6](#12-การย้ายไป-ch32v203rbt6)

---

## 1. ภาพรวมโปรเจค

โปรเจคนี้คือ **GRBL 1.1f** — ซอฟต์แวร์ควบคุมเครื่อง CNC แบบ Open Source ที่ถูกพอร์ตมารันบนไมโครคอนโทรลเลอร์ **CH32V307** ของ WCH (Nanjing Qinheng Microelectronics) รองรับการควบคุมสูงสุด **6 แกน** (X, Y, Z, A, B, C)

### 1.1 GRBL คืออะไร?

GRBL คือเฟิร์มแวร์สำหรับควบคุมการเคลื่อนที่ของเครื่อง CNC ที่แปลภาษา G-code เป็นสัญญาณ step/direction สำหรับขับมอเตอร์สเต็ปปิ้ง คุณสมบัติหลัก:

- แปลภาษา G-code (rs274/ngc)
- วางแผนการเคลื่อนที่ (Motion Planner) แบบ Trapezoidal Acceleration
- ควบคุม Spindle (PWM) และ Coolant (M7/M8/M9)
- ตรวจจับ Limit Switch และ Probe
- สื่อสารผ่าน Serial (USART) หรือ USB
- Jogging (ควบคุมด้วยมือแบบ real-time)

### 1.2 CH32V307 คืออะไร?

CH32V307 คือไมโครคอนโทรลเลอร์ RISC-V 32-bit ตระกูล QingKe V4F จาก WCH:

| คุณสมบัติ | ค่า |
|-----------|-----|
| Core | QingKe V4F (RISC-V 32-bit พร้อม FPU) |
| ความเร็ว | สูงสุด 144 MHz |
| Flash | 128K / 168K (ขึ้นอยู่กับรุ่น) |
| RAM | 64K / 128K (ขึ้นอยู่กับรุ่น) |
| USB | USB High-Speed (480 Mbps) |
| Ethernet | 10/100M |
| แพ็คเกจ | LQFP100 |

### 1.3 เส้นทางการทำงาน (Pipeline)

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  G-code  │ →  │  G-code  │ →  │  Motion  │ →  │  Stepper │ →  │  มอเตอร์  │
│  (PC)    │    │  Parser  │    │  Planner │    │  Driver  │    │  (Pulse) │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
      ↑              ↓               ↓               ↓
   Serial/USB    grbl/gcode.c   grbl/planner.c   grbl/stepper.c
                                  grbl/motion_control.c
```

---

## 2. โครงสร้างโฟลเดอร์

```
6-AXIS-CH32V307-GRBL/
│
├── grbl/                          # 🔵 GRBL Core — โค้ด CNC (ไม่ขึ้นกับ MCU ใดๆ)
│   ├── grbl.h                     #    Master include — รวมทุกเฮดเดอร์
│   ├── config.h                   #    ตั้งค่า Build (จำนวนแกน, ฟีเจอร์)
│   ├── defaults.h                 #    ค่า Default ของเครื่อง CNC
│   ├── cpu_map.h                  #    Bridge: แผนที่ Pin GPIO ← จุดเดียวที่แตะฮาร์ดแวร์
│   │
│   ├── gcode.c/h                  #    ตัวแปลภาษา G-code
│   ├── planner.c/h                #    วางแผนการเคลื่อนที่ (Trapezoidal Planner)
│   ├── stepper.c/h                #    สร้างสัญญาณ Pulse สำหรับมอเตอร์
│   ├── motion_control.c/h         #    ควบคุมการเคลื่อนที่
│   ├── spindle_control.c/h        #    ควบคุม Spindle (PWM + ทิศทาง)
│   ├── coolant_control.c/h        #    ควบคุม Coolant (M7/M8/M9)
│   ├── limits.c/h                 #    ตรวจจับ Limit Switch
│   ├── probe.c/h                  #    วงจร Probe (G38.x)
│   ├── jog.c/h                    #    Jogging (ควบคุมด้วยมือ)
│   ├── protocol.c/h               #    Main Protocol Loop
│   ├── report.c/h                 #    สร้างรายงานสถานะ
│   ├── print.c/h                  #    จัดการ String Output
│   ├── serial.c/h                 #    สื่อสารผ่าน USART
│   ├── system.c/h                 #    State Machine ของระบบ
│   ├── settings.c/h               #    จัดเก็บ Settings
│   ├── eeprom.c/h                 #    อ่าน/เขียน EEPROM (จำลองใน Flash)
│   └── nuts_bolts.c/h             #    Utility Functions
│
├── mcu/                           # 🟠 MCU-Specific — เปลี่ยนทั้งโฟลเดอร์เมื่อย้าย MCU
│   └── CH32V307/                  #    ← MCU ปัจจุบัน
│       ├── main.c                 #    Entry Point + Initialization
│       ├── system_ch32v30x.c/h    #    ตั้งค่า System Clock (144MHz HSE)
│       ├── ch32v30x_it.c/h        #    Interrupt Handlers
│       ├── ch32v30x_conf.h        #    Peripheral Configuration
│       ├── ch32v30x_usbhs_device.c/h  # USB High-Speed Device Stack
│       ├── ov.c/h                 #    OV2640 Camera Overlay (Optional)
│       ├── sdk/
│       │   ├── Core/              #    RISC-V Core Utilities
│       │   ├── Debug/             #    Debug Printf + Delay
│       │   ├── Startup/           #    Startup Assembly (vector table)
│       │   └── Peripheral/
│       │       ├── inc/           #    27 WCH Driver Headers
│       │       └── src/           #    27 WCH Driver Sources
│       └── ld/
│           ├── Link.ld            #    Linker Script (Memory Layout)
│           └── libm.a             #    Math Library
│
├── scripts/                       # 🔧 Build Scripts
│   ├── mcu_config_CH32V307.bat    #    ⭐ Config สำหรับ CH32V307
│   ├── mcu_config_CH32V203.bat    #    ⭐ Config placeholder สำหรับ CH32V203
│   ├── build.bat                  #    ⭐ คอมไพล์ + ลิงก์
│   ├── clean.bat                  #    ล้าง obj/ และ output/
│   ├── rebuild.bat                #    Clean + Build
│   ├── upload.bat                 #    แฟลชลงบอร์ดผ่าน WCH-Link
│   ├── gen_vscode_files.bat       #    สร้างไฟล์ .vscode/
│   └── make_clangd.bat            #    สร้าง .clangd (IntelliSense)
│
├── .vscode/                       # VS Code Configuration
│   ├── tasks.json                 #    Build/Clean/Rebuild/Upload Tasks
│   ├── c_cpp_properties.json      #    Include Paths + Defines
│   └── settings.json              #    Editor Settings
│
├── docs/                          # 📄 เอกสาร
│   ├── MIGRATION_V203RBT6.md      #    คู่มือการย้ายไป CH32V203RBT6
│   └── README_TH.md               #    ไฟล์นี้
│
├── .clangd                        # clangd Language Server Config
└── .gitignore                     # Git Ignore Rules
```

### 2.1 หลักการแยก GRBL / MCU

```
┌─────────────────────────────────────────────┐
│   grbl/  (GRBL Core)                        │
│   ✅ พกพาได้ — ใช้กับ MCU อะไรก็ได้           │
│   ✅ ไม่พึ่งพา Hardware ของ MCU ใดๆ           │
│   ✅ ใช้ cpu_map.h เป็น Abstraction จุดเดียว  │
└──────────────────┬──────────────────────────┘
                   │  #include "cpu_map.h"
┌──────────────────▼──────────────────────────┐
│   mcu/CH32V307/  (MCU-Specific)             │
│   🔧 ต้องเปลี่ยนเมื่อเปลี่ยน MCU              │
│   🔧 มี SDK, Startup, Linker Script          │
└─────────────────────────────────────────────┘
```

---

## 3. ซอฟต์แวร์ที่ต้องติดตั้ง

### 3.1 MounRiver Studio 2.0

ดาวน์โหลดและติดตั้ง **MounRiver Studio 2.0** จากเว็บไซต์ WCH:
- **ลิงก์**: https://www.mounriver.com/
- **ติดตั้งที่**: `C:\MounRiver\MounRiver_Studio2\` (ค่าเริ่มต้น)

MounRiver Studio มาพร้อมกับ:
- RISC-V GCC Toolchain (GCC 8.2.0 และ GCC 12.2.0)
- OpenOCD (สำหรับแฟลชผ่าน WCH-Link)
- WCH Peripheral SDK

### 3.2 VS Code (แนะนำ)

- ดาวน์โหลด **Visual Studio Code**: https://code.visualstudio.com/
- ติดตั้ง Extension แนะนำ:
  - **C/C++** (Microsoft)
  - **clangd** (LLVM) — Autocomplete ที่ดีกว่า
  - **MounRiver Studio** — ถ้ามี extension นี้

### 3.3 WCH-Link (Hardware)

สำหรับอัปโหลดเฟิร์มแวร์ลงบอร์ด:
- **WCH-Link** (debugger/programmer)
- หรือ **WCH-LinkE** (รุ่นประหยัด)

---

## 4. วิธี Build

### 4.1 Build ด้วย Command Line (วิธีที่ง่ายที่สุด)

เปิด **PowerShell** หรือ **Command Prompt** ในโฟลเดอร์โปรเจค:

```batch
# Build (คอมไพล์ + ลิงก์)
.\scripts\build.bat

# Clean (ล้างไฟล์ชั่วคราว)
.\scripts\clean.bat

# Rebuild (Clean + Build)
.\scripts\rebuild.bat
```

### 4.2 ผลลัพธ์ที่ได้

หลัง Build สำเร็จ:

```
output/
├── GRBL_CH32V307.elf     # Executable (ใช้ Debug)
├── GRBL_CH32V307.hex     # Intel HEX (ใช้แฟลช)
├── GRBL_CH32V307.bin     # Binary (ใช้แฟลช)
└── GRBL_CH32V307.map     # Linker Map (ดู Memory Layout)
```

### 4.3 ตัวอย่างผลลัพธ์

```
=============================================================
  GRBL CH32V307 - Build  [riscv-none-embed-gcc]
  Architecture: -march=rv32imafc -mabi=ilp32f
=============================================================

[OK] Compiler: ...riscv-none-embed-gcc.exe

--- Compiling C files ---
  [C] core_riscv.c
  [C] debug.c
  [C] ch32v30x_adc.c
  ... (55 ไฟล์)
  [ASM] Startup\startup_ch32v30x_D8.S

--- Linking ---
[OK] output\GRBL_CH32V307.elf

--- Creating HEX ---
[OK] output\GRBL_CH32V307.hex

--- Firmware Size ---
   text    data     bss     dec     hex filename
  38296     136    8592   47024    b7b0 GRBL_CH32V307.elf

--- Memory Usage (CH32V307: Flash=131072  RAM=65536) ---
  Flash:  38432 / 131072 bytes  (29%)  [Free: 92640 bytes]
  RAM:    8728 / 65536 bytes  (13%)  [Free: 56808 bytes]

=============================================================
  [OK] Build successful!
=============================================================
```

### 4.4 ถ้า Build ไม่ผ่าน

ตรวจสอบตามลำดับนี้:

1. **Compiler not found**: เช็คว่าติดตั้ง MounRiver Studio 2.0 ที่ `C:\MounRiver\MounRiver_Studio2\`
2. **Header file not found**: เช็คว่า include paths ใน `build.bat` ถูกต้อง
3. **Undefined reference**: เช็คว่า source files ครบทุกไฟล์
4. **Flash/RAM overflow**: ลอง `-Os` optimize หรือปิดฟีเจอร์ที่ไม่ใช้ใน `config.h`

---

## 5. วิธีเปลี่ยน MCU

### 5.1 เปลี่ยนจาก CH32V307 → CH32V203RBT6

ในไฟล์ `scripts/build.bat` และ `scripts/upload.bat` ให้เปลี่ยนบรรทัด `call`:

```batch
:: จาก
call "%~dp0mcu_config_CH32V307.bat"

:: เป็น
call "%~dp0mcu_config_CH32V203.bat"
```

**⚠️ ก่อนเปลี่ยน** ต้องเตรียม `mcu/CH32V203RBT6/` ให้พร้อมก่อน (มี V20x SDK, startup, linker script) — ดูบทที่ 12

### 5.2 ไฟล์ที่ต้องแก้ไขนอกเหนือจาก scripts

เมื่อเปลี่ยน MCU ต้องแก้ไขไฟล์เหล่านี้ด้วย:

| ไฟล์ | รายละเอียด |
|------|-----------|
| `grbl/cpu_map.h` | เปลี่ยน Pin Map ให้ตรงกับ MCU ใหม่ |
| `grbl/config.h` | เปลี่ยน `#define` ให้ตรงกับ MCU ใหม่ |
| `grbl/grbl.h` | เพิ่ม conditional check สำหรับ MCU ใหม่ (ถ้าจำเป็น) |
| `mcu/<MCU>/` | เปลี่ยน SDK, Startup, Linker Script |

---

## 6. วิธีเพิ่ม MCU ใหม่

สมมติต้องการเพิ่ม **GD32F303** (ARM Cortex-M4) เป็น MCU ตัวใหม่:

### ขั้นตอน

#### 6.1 สร้างโฟลเดอร์ MCU ใหม่

```
mcu/GD32F303/
├── main.c
├── system_gd32f30x.c/h
├── gd32f30x_it.c/h
├── gd32f30x_conf.h
├── sdk/
│   ├── Core/
│   ├── Startup/
│   └── Peripheral/
└── ld/
    └── Link.ld
```

#### 6.2 สร้างไฟล์ Config

คัดลอก `mcu_config_CH32V307.bat` → `mcu_config_GD32F303.bat` แล้วแก้ไขค่า:

```batch
:: scripts/mcu_config_GD32F303.bat
set MCU_NAME=GD32F303
set MCU_FOLDER=mcu\GD32F303
set OUTPUT_NAME=GRBL_GD32F303
set ARCH=-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
set EXTRA_CFLAGS=-fsingle-precision-constant
set DEFINES=-DGD32F303 -DARM_MATH_CM4
set TOOLCHAIN_CHOICE=1
set FLASH_TOTAL=262144
set RAM_TOTAL=98304
set STARTUP_ASM=startup_gd32f30x_hd.s
set USB_SOURCE=
set OV_SOURCE=
```

#### 6.3 เปลี่ยน Config ใน build.bat

```batch
::call "%~dp0mcu_config_CH32V307.bat"
call "%~dp0mcu_config_GD32F303.bat"
```

#### 6.4 (Optional) เปลี่ยน Toolchain Path

ถ้าใช้ ARM GCC แทน RISC-V GCC — แก้ `TOOLCHAIN_BASE` ใน `build.bat` ให้ชี้ไปที่ ARM toolchain

---

## 7. การใช้งานร่วมกับ VS Code

### 7.1 เปิดโปรเจคใน VS Code

```
File → Open Folder... → เลือกโฟลเดอร์ 6-AXIS-CH32V307-GRBL
```

### 7.2 Build ด้วย VS Code

กด **`Ctrl+Shift+B`** → เลือกงาน:

| Task | คำอธิบาย |
|------|---------|
| **Build GRBL CH32V307** | คอมไพล์ + ลิงก์ |
| **Clean GRBL CH32V307** | ล้าง build artifacts |
| **Rebuild GRBL CH32V307** | Clean + Build |
| **Upload GRBL CH32V307 (WCH-Link)** | แฟลชลงบอร์ด |
| **Generate .clangd** | สร้างไฟล์ IntelliSense ใหม่ |

### 7.3 Autocomplete / IntelliSense

โปรเจคมาพร้อม `.clangd` ที่ตั้งค่าไว้แล้ว — clangd จะ:
- รู้จักทุก include path (`grbl/`, `mcu/CH32V307/`, `sdk/...`)
- รู้จัก defines (`CH32V307`, `ABC_AXIS_EXAMPLE`, `AB_AXIS`)
- ไม่ฟ้อง error ปลอมจาก RISC-V specific flags

**ถ้า clangd ไม่ทำงาน**: รัน `.\scripts\make_clangd.bat` แล้ว restart clangd

### 7.4 ปัญหาที่อาจพบใน VS Code

| ปัญหา | วิธีแก้ |
|--------|--------|
| เส้นแดงใต้ `#include` | เช็ค `c_cpp_properties.json` — includePath ถูกต้องไหม |
| `GPIO_InitTypeDef` unknown | clangd ไม่รู้จัก WCH types → รัน `make_clangd.bat` |
| `warning: "ABC_AXIS_EXAMPLE" redefined` | ปกติ — ประกาศทั้งใน config.h และ compiler flag |

---

## 8. การใช้งานร่วมกับ MounRiver Studio 2.0

### 8.1 สร้างโปรเจคใหม่

1. เปิด MounRiver Studio 2.0
2. **File → New → MounRiver Project**
3. เลือก **CH32V307VCT6** (หรือรุ่นที่ตรงกับบอร์ด)
4. ตั้งชื่อโปรเจค → Finish

### 8.2 Import Source Code

หลังจาก MRS สร้างโปรเจคเปล่า:

1. **ลบ** โฟลเดอร์ `User/` ที่ MRS สร้างให้อัตโนมัติ
2. **คลิกขวาที่โปรเจค → Import → General → File System**
3. เลือกไฟล์จากโปรเจค GRBL:

```
เลือก:
  grbl/            →  import ทั้งโฟลเดอร์
  mcu/CH32V307/    →  import ทั้งโฟลเดอร์
```

### 8.3 ตั้งค่า Include Paths

**Project → Properties → C/C++ Build → Settings → GNU RISC-V Cross C Compiler → Includes**

เพิ่ม paths:
```
"${workspace_loc:/${ProjName}/grbl}"
"${workspace_loc:/${ProjName}/mcu/CH32V307}"
"${workspace_loc:/${ProjName}/mcu/CH32V307/sdk/Core}"
"${workspace_loc:/${ProjName}/mcu/CH32V307/sdk/Debug}"
"${workspace_loc:/${ProjName}/mcu/CH32V307/sdk/Peripheral/inc}"
```

### 8.4 ตั้งค่า Defines

**Project → Properties → C/C++ Build → Settings → GNU RISC-V Cross C Compiler → Preprocessor**

เพิ่ม:
```
CH32V307
ABC_AXIS_EXAMPLE
AB_AXIS
```

### 8.5 ตั้งค่า Linker Script

**Project → Properties → C/C++ Build → Settings → GNU RISC-V Cross C Linker → General**

เปลี่ยน Linker Script เป็น:
```
"${workspace_loc:/${ProjName}/mcu/CH32V307/ld/Link.ld}"
```

---

## 9. การอัปโหลดเฟิร์มแวร์ลงบอร์ด

### 9.1 ใช้อัปโหลดด้วย Command Line

```batch
.\scripts\upload.bat
```

### 9.2 ข้อกำหนด

1. **WCH-Link** ต้องเชื่อมต่อกับบอร์ดผ่าน SWD (3 สาย: SWCLK, SWDIO, GND)
2. บอร์ดต้องมีไฟเลี้ยง
3. ต้อง Build สำเร็จก่อน (มีไฟล์ `.elf` ใน `output/`)

### 9.3 ตัวอย่างผลลัพธ์

```
============================================================
 GRBL CH32V307 Upload via WCH-Link
============================================================
OpenOCD : C:\...\openocd.exe
Config  : C:\...\wch-riscv.cfg
Firmware: D:\...\output\GRBL_CH32V307.elf

Connecting to WCH-Link...

... (OpenOCD output) ...

============================================================
 Upload successful! Device is running.
============================================================
```

### 9.4 ปัญหาที่อาจพบ

| ปัญหา | วิธีแก้ |
|--------|--------|
| `OpenOCD not found` | ติดตั้ง MounRiver Studio 2.0 — OpenOCD มาพร้อม MRS |
| `Firmware not found` | Build ก่อน (`.\scripts\build.bat`) |
| `Error: init mode failed` | เช็คสาย SWD / ไฟเลี้ยงบอร์ด / ไดรเวอร์ WCH-Link |
| `Error: timed out while waiting for target` | กด Reset บอร์ดค้างไว้ แล้วลองใหม่ |

---

## 10. การตั้งค่า clangd (Autocomplete)

### 10.1 สร้างหรืออัปเดต .clangd

```batch
.\scripts\make_clangd.bat
```

### 10.2 Restart clangd ใน VS Code

1. กด `Ctrl+Shift+P`
2. เลือก **"clangd: Restart Language Server"**

### 10.3 ตรวจสอบว่า clangd ทำงาน

ดูที่ Status Bar ของ VS Code ด้านล่างซ้าย — ควรขึ้นว่า **"clangd: idle"**

### 10.4 clangd ตั้งค่าอะไรให้เรา

- ✅ Include paths อัตโนมัติ (`grbl/`, `mcu/...`, `sdk/...`)
- ✅ Defines อัตโนมัติ (`CH32V307`, `ABC_AXIS_EXAMPLE`, `AB_AXIS`)
- ✅ กรอง RISC-V flags ที่ clangd ไม่รู้จักออก (`-march=`, `-mabi=`, `-msave-restore`)
- ✅ ปิด clang-tidy checks ที่ไม่เหมาะกับ embedded C
- ✅ ป้องกัน error ปลอม "main file cannot be included recursively"

---

## 11. คำถามที่พบบ่อย (FAQ)

### Q: GRBL กับ SDK คือตัวไหน?

| โค้ด | ที่อยู่ | คืออะไร |
|------|--------|---------|
| **GRBL** | `grbl/` ทั้งโฟลเดอร์ | โค้ด CNC — พกพาได้, ไม่ขึ้นกับ MCU |
| **SDK** | `mcu/CH32V307/sdk/` + `mcu/CH32V307/system_*` + `mcu/CH32V307/*_it*` | WCH Vendor HAL — เฉพาะ MCU นี้ |
| **Bridge** | `grbl/cpu_map.h` | จุดเชื่อม GRBL ↔ MCU (Pin Map) |

### Q: GRBL ใช้กับ MCU อื่นได้ไหม?

✅ **ได้** — GRBL core ใช้ `cpu_map.h` เป็น abstraction จุดเดียว เวลาย้าย MCU ให้เปลี่ยนเฉพาะ:
1. `mcu/<MCUใหม่>/` — เอา SDK + Startup ของ MCU นั้นมาใส่
2. `grbl/cpu_map.h` — แก้ Pin Map
3. `grbl/config.h` — แก้ Defines
4. `scripts/mcu_config_<MCU>.bat` — แก้ Build Flags

### Q: Build แล้วไฟล์อยู่ที่ไหน?

| ไฟล์ | ที่อยู่ | ใช้ทำอะไร |
|------|--------|-----------|
| `*.elf` | `output/` | Executable — ใช้ Debug |
| `*.hex` | `output/` | Intel HEX — ใช้แฟลช |
| `*.bin` | `output/` | Binary — ใช้แฟลช |
| `*.map` | `output/` | Memory Map — ดูว่าแต่ละฟังก์ชันอยู่ตรงไหน |
| `*.o` | `obj/` | Object Files — ไฟล์ระหว่างทาง (ลบได้) |

### Q: Build แล้วขอให้ Clean ด้วยไหม?

ควร Clean เมื่อ:
- เปลี่ยน Config (เช่น เปิด/ปิดฟีเจอร์ใน `config.h`)
- เปลี่ยน MCU
- เปลี่ยน Compiler Flags
- เจอ error แปลกๆ ที่ไม่น่าเกิด

ไม่ต้อง Clean เมื่อ:
- แก้ไขโค้ดในไฟล์ `.c` (build.bat จะ rebuild เฉพาะไฟล์ที่เปลี่ยน)

### Q: ปิด USB ได้ไหม?

ใน `mcu/CH32V307/main.c` — คอมเมนต์ `#define USEUSB` แล้วไปใช้ USART2 แทน:

```c
//#define USEUSB  // ← คอมเมนต์บรรทัดนี้เพื่อปิด USB
```

พอร์ต Serial ที่ใช้เมื่อปิด USB:
- **TX**: PA2 (USART2)
- **RX**: PA3 (USART2)
- **Baud Rate**: 115200 (ค่าเริ่มต้น)

### Q: เปลี่ยน Baud Rate Serial ยังไง?

ใน `grbl/config.h` หรือ `mcu/CH32V307/main.c` — ฟังก์ชัน `USART2_Configuration()` รับค่า Baud Rate เป็นพารามิเตอร์

### Q: ต้องการ 3 แกน ไม่ใช่ 6 แกน?

ใน `grbl/config.h` และใน `scripts/mcu_config_CH32V307.bat`:

```c
// config.h
#define ABC_AXIS_EXAMPLE        // ใช้ 6-axis pin map
//#define AA_AXIS               // 4 แกน (X,Y,Z,A)
//#define AB_AXIS               // 5 แกน (X,Y,Z,A,B)
//#define ABC_AXIS              // 6 แกน (X,Y,Z,A,B,C)
```

```batch
:: mcu_config_CH32V307.bat
set DEFINES=-DCH32V307 -DABC_AXIS_EXAMPLE -DAB_AXIS
:: เปลี่ยนเป็น:
set DEFINES=-DCH32V307 -DABC_AXIS_EXAMPLE
:: (ไม่ใส่ -DAB_AXIS → จะเป็น 3 แกน)
```

### Q: มีฟีเจอร์อะไรที่เปิด/ปิดได้บ้าง?

ดูใน `grbl/config.h` — มีฟีเจอร์ที่ปรับได้:

| Define | หน้าที่ |
|--------|--------|
| `VARIABLE_SPINDLE` | เปิด Spindle PWM |
| `USE_SPINDLE_DIR_AS_ENABLE_PIN` | ใช้ Spindle Dir pin เป็น Enable |
| `ENABLE_M7` | เปิด Coolant Mist (M7) |
| `USE_LASER_MODE` | โหมด Laser (แทน Spindle) |
| `HOMING_CYCLE_0` (ถึง `HOMING_CYCLE_5`) | Homing Cycles |
| `USE_RESET_BTN_AS_ESTOP` | ใช้ Reset Button เป็น Emergency Stop |

---

## 12. การย้ายไป CH32V203RBT6

### 12.1 ภาพรวม

CH32V203RBT6 เป็น MCU ที่เล็กกว่าและถูกกว่า CH32V307:

| รายการ | CH32V307 (ปัจจุบัน) | CH32V203RBT6 |
|--------|--------------------|--------------|
| Core | QingKe V4F + FPU | QingKe V4B (ไม่มี FPU) |
| Flash | 128K | 128K |
| RAM | 64K | 64K |
| แกน | 6 แกน | 3 แกน (X, Y, Z) |
| แพ็คเกจ | LQFP100 | LQFP64 |
| USB | USB High-Speed | USB Full-Speed |
| ราคา | ~$3-4 | ~$0.50-1 |

### 12.2 ขั้นตอนการย้าย

ดูรายละเอียดทั้งหมดใน `docs/MIGRATION_V203RBT6.md`

**ขั้นตอนย่อ**:

1. Copy V20x SDK ไปไว้ที่ `mcu/CH32V203RBT6/sdk/`
2. Copy `startup_ch32v20x_D6.S` ไป `mcu/CH32V203RBT6/sdk/Startup/`
3. Copy `system_ch32v20x.c/h` ไป `mcu/CH32V203RBT6/`
4. Copy `ch32v20x_it.c/h` ไป `mcu/CH32V203RBT6/`
5. แก้ไข `Link.ld` เป็น 128K Flash / 64K RAM
6. เปลี่ยน `grbl/config.h`: `ABC_AXIS_EXAMPLE` → `CH32V203_RBT6_3AXIS`
7. เปลี่ยน `scripts/build.bat`: ใช้ `mcu_config_CH32V203.bat`
8. ปิด USB (คอมเมนต์ `#define USEUSB`)
9. Build → แก้ Error → Build → สำเร็จ

### 12.3 ข้อควรระวัง

- ⚠️ **ไม่มี FPU**: `float` จะถูกคำนวณด้วย Software — ช้าลงแต่ยังพอรับได้ที่ 144MHz
- ⚠️ **เปลี่ยน Compiler Flag**: `-march=rv32imafc` → `-march=rv32imac`
- ⚠️ **ปิด USB**: USBHS → USBFS (คนละ driver stack) หรือปิด USB ไปเลย
- ⚠️ **Pin Map เปลี่ยน**: ดู `cpu_map.h` section `CH32V203_RBT6_3AXIS`

---

## 📚 แหล่งข้อมูลเพิ่มเติม

- **GRBL GitHub**: https://github.com/gnea/grbl
- **GRBL Wiki**: https://github.com/gnea/grbl/wiki
- **WCH Official**: https://www.wch.cn/
- **MounRiver Studio**: https://www.mounriver.com/
- **CH32V307 Datasheet**: ดาวน์โหลดจาก WCH website
- **CH32V203 Datasheet**: ดาวน์โหลดจาก WCH website
- **grblHAL** (GRBL + HAL abstraction): https://github.com/grblHAL

---

> **Last Updated**: 20 พฤษภาคม 2569  
> **Maintainer**: GRBL CH32V307 Project Team
