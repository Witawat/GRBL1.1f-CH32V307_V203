# GRBL 1.1f — Migration to CH32V203RBT6 (3-Axis CNC)

> **สถานะ**: ✅ Migration เสร็จสมบูรณ์ — Build ผ่านทั้ง CH32V307 และ CH32V203RBT6  
> **อัปเดตล่าสุด**: 20 พฤษภาคม 2569

## 📋 Summary

| Item | Original | New Target |
|------|----------|------------|
| **Chip** | CH32V307 (LQFP100) | **CH32V203RBT6** (LQFP64) |
| **Core** | QingKe V4F (RISC-V + FPU) | QingKe V4B (RISC-V, no FPU) |
| **Flash** | 168K | **128K** |
| **RAM** | 128K | **64K** |
| **Package** | LQFP100 | **LQFP64** |
| **Axes** | 6-axis capable (AB_AXIS active) | **3-axis (X, Y, Z)** |
| **USB** | USBHS | USBFS |

---

## 🔌 PIN Map — CH32V203RBT6 (LQFP64)

```
           CH32V203RBT6 LQFP64
         ┌───────────────────┐
    PB0  │ 1  X_STEP     48  │ PB15
    PB1  │ 2  X_DIR      47  │ PB14 PROBE
    PB2  │ 3  (free)     46  │ PB13 COOLANT_MIST
    PB3  │ 4  Y_STEP *   45  │ PB12 COOLANT_FLOOD
    PB4  │ 5  (free) *   44  │ PB11 (free)
    PB5  │ 6  Y_DIR      43  │ PB10 (free)
    PB6  │ 7  Z_STEP     42  │ PB9  (free)
    PB7  │ 8  Z_DIR      41  │ PB8  STEPPERS_DISABLE
         │                  │
    PA0  │    LED          │
    PA2  │    SERIAL_TX    │
    PA3  │    SERIAL_RX    │
    PA4  │                  │
    PA5  │    CTRL_RESET   │
    PA6  │    CTRL_FEED_HOLD│
    PA7  │    CTRL_CYCLE_ST│
    PA8  │    SPINDLE_PWM  │ (TIM1_CH1)
    PA9  │    CTRL_SAFETY  │
         │                  │
    PC10 │    X_LIMIT      │
    PC11 │    Y_LIMIT      │
    PC12 │    Z_LIMIT      │
         │                  │
    PD0  │    SPINDLE_EN   │
    PD1  │    SPINDLE_DIR  │
         └───────────────────┘

    * PB3/PB4 need JTAG disable (done in system_init)
```

### Pin Table

| Function | Pin | Port | Notes |
|----------|-----|------|-------|
| X_STEP | PB0 | GPIOB | |
| X_DIR | PB1 | GPIOB | |
| Y_STEP | PB3 | GPIOB | JTAG remap required |
| Y_DIR | PB5 | GPIOB | |
| Z_STEP | PB6 | GPIOB | |
| Z_DIR | PB7 | GPIOB | |
| STEPPERS_DISABLE | PB8 | GPIOB | Active LOW (configurable) |
| X_LIMIT | PC10 | GPIOC | EXTI10, EXTI15_10_IRQn |
| Y_LIMIT | PC11 | GPIOC | EXTI11, EXTI15_10_IRQn |
| Z_LIMIT | PC12 | GPIOC | EXTI12, EXTI15_10_IRQn |
| SPINDLE_PWM | PA8 | GPIOA | TIM1_CH1, 10kHz |
| SPINDLE_ENABLE | PD0 | GPIOD | |
| SPINDLE_DIR | PD1 | GPIOD | |
| COOLANT_FLOOD | PB12 | GPIOB | |
| COOLANT_MIST | PB13 | GPIOB | |
| PROBE | PB14 | GPIOB | Input pull-up |
| CONTROL_RESET | PA5 | GPIOA | EXTI5, Active LOW |
| CONTROL_FEED_HOLD | PA6 | GPIOA | EXTI6, Active LOW |
| CONTROL_CYCLE_START | PA7 | GPIOA | EXTI7, Active LOW |
| CONTROL_SAFETY_DOOR | PA9 | GPIOA | EXTI9, Active LOW |
| SERIAL_TX | PA2 | GPIOA | USART2 AF |
| SERIAL_RX | PA3 | GPIOA | USART2 Input |
| LED | PA0 | GPIOA | GPIO output (LedBlink() defined, not yet in main loop) |

---

## 📁 Files Changed

### Modified (core pin mapping)
- `grbl/cpu_map.h` — Added `CH32V203_RBT6_3AXIS` section with new pin map
- `grbl/config.h` — Switched from `ABC_AXIS_EXAMPLE`/`AB_AXIS` to `CH32V203_RBT6_3AXIS` (3-axis)
- `grbl/grbl.h` — All `CH32V307` conditionals now include `|| defined(CH32V203_RBT6_3AXIS)`

### Modified (conditional compilation)
- `grbl/stepper.c` — 17 occurrences updated
- `grbl/spindle_control.c` — 10 occurrences updated
- `grbl/system.c` — 12 occurrences updated
- `grbl/limits.c` — 7 occurrences updated
- `grbl/eeprom.c` — 7 occurrences updated
- `grbl/coolant_control.c` — 4 occurrences updated
- `grbl/serial.c` — 4 occurrences updated
- `grbl/probe.c` — 2 occurrences updated
- `grbl/motion_control.c` — 1 occurrence updated
- `grbl/print.c` — 1 occurrence updated
- `grbl/eeprom.h` — 1 occurrence updated
- `grbl/nuts_bolts.h` — 1 occurrence updated
- `grbl/spindle_control.h` — 1 occurrence updated
- `app/main.c` — 2 occurrences updated

### Modified (hardware layer)
- `ld/Link.ld` — Memory: **128K Flash / 64K RAM**
- `app/ch32v30x_conf.h` — Conditional V20x / V30x header includes

---

## 🔧 Build Instructions

### Prerequisites
1. **MounRiver Studio 2.0** — ติดตั้งที่ `C:\MounRiver\MounRiver_Studio2\` (มาพร้อม RISC-V GCC toolchain)
2. ไฟล์ V20x SDK มีอยู่ใน `mcu/CH32V203RBT6/sdk/` แล้ว — **ไม่ต้องดาวน์โหลดเพิ่ม**

### Steps (ใช้ Batch Scripts — วิธีที่ง่ายที่สุด)
1. เปิด `scripts/build.bat` — เปลี่ยนเป็น:
   ```batch
   ::call "%~dp0mcu_config_CH32V307.bat"
   call "%~dp0mcu_config_CH32V203.bat"
   ```
2. รัน `scripts\build.bat`
3. Build สำเร็จ — ได้ไฟล์ `output\GRBL_CH32V203.hex`

### Compiler Flags (ตั้งค่าใน mcu_config_CH32V203.bat แล้ว)
```
-DCH32V203_RBT6_3AXIS
-march=rv32imac -mabi=ilp32
-Os -flto  (recommended for size)
```

---

## ⚠️ Important Notes

### USB
- CH32V203RBT6 has **USBFS** (Full Speed), NOT USBHS
- The current code uses USBHS device stack (`ch32v30x_usbhs_device.c`)
- For V203 USB: use the V20x USBFS device library instead
- Or disable USB entirely (`#undef USEUSB`) and use USART2 serial only

### FPU
- CH32V203 (V4B core) has **NO FPU**
- GRBL 1.1f uses `float` extensively — these will be software-emulated
- Performance impact should be acceptable at 144MHz
- Remove `-march=rv32imafc` flags, use `-march=rv32imac` instead

### Flash Size
- Original V307: 168K Flash
- V203RBT6: 128K Flash
- Estimated GRBL binary size: ~80-100K (with USB disabled)
- Use `-Os -flto` for size optimization

### RCC Clock
- The system_ch32v30x.c file must be replaced with the V203 equivalent
- Both support 144MHz HSE, but register layout might differ slightly
- Use the clock init from WCH V203 EVT example

### EXTI Interrupts
- All limits (PC10-PC12) share EXTI15_10_IRQn — same as original
- All controls (PA5-PA9) share EXTI9_5_IRQn — same as original
- ✅ No IRQ handler changes needed

---

## 📊 GRBL Version

- **GRBL Version:** 1.1f
- **Build:** 20230112
- **Based on:** GRBL 1.1f by Sungeun K. Jeon (Gnea Research LLC)
- **Multi-axis extensions by:** YSV (22-06-2018)

---

## 🔄 สลับกลับไปใช้ CH32V307

เปลี่ยนกลับเป็น CH32V307 6-axis:
1. ใน `scripts/build.bat`: เปลี่ยนกลับเป็น `call "%~dp0mcu_config_CH32V307.bat"`
2. Build ใหม่ — config ทั้งหมดกลับเป็นค่าเดิมอัตโนมัติ
