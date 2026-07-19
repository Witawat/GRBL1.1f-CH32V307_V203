# GRBL 1.1f — คู่มือออกแบบวงจร PCB สำหรับ CH32V203RBT6 (3 แกน)

> **เวอร์ชันเอกสาร**: 1.0 — กรกฎาคม 2569  
> **MCU เป้าหมาย**: CH32V203RBT6 (QingKe V4B, RISC-V 144MHz, ไม่มี FPU)  
> **จำนวนแกน**: 3 (X, Y, Z)  
> **เฟิร์มแวร์**: GRBL 1.1f (Build 20230112)

---

## สารบัญ

1. [ภาพรวมบอร์ด](#1-ภาพรวมบอร์ด)
2. [การเลือกชิ้นส่วน](#2-การเลือกชิ้นส่วน)
3. [แผนผังวงจร](#3-แผนผังวงจร)
4. [ข้อควรระวังในการออกแบบ PCB](#4-ข้อควรระวังในการออกแบบ-pcb)
5. [การเลือก Stepper Driver](#5-การเลือก-stepper-driver)
6. [ESTLCam Compatibility](#6-estlcam-compatibility)
7. [Bill of Materials (BOM)](#7-bill-of-materials-bom)
8. [ข้อควรระวังสำคัญ](#8-ข้อควรระวังสำคัญ)

---

## 1. ภาพรวมบอร์ด

### 1.1 คุณสมบัติ

| หัวข้อ | รายละเอียด |
|--------|-----------|
| แกนควบคุม | X, Y, Z (3 แกน) |
| Stepper Interface | Step/Direction + Enable (optocoupler isolation) |
| Spindle | PWM (10kHz) + Enable + Direction Relay |
| Coolant | Flood (M8) + Mist (M7) — Relay output |
| Limit Switch | 3 ช่อง (X, Y, Z) — ต่อแบบ NC + RC filter |
| Probe | 1 ช่อง (G38.x) — Input pull-up |
| Control Input | Reset, Feed Hold, Cycle Start, Safety Door |
| Serial | USART2 (PA2/PA3) — CH340G หรือ MAX3232 |
| Power | 12-24V DC → 5V → 3.3V |
| Programming | SWD (SWCLK + SWDIO + RESET) |

### 1.2 บล็อกไดอะแกรมระบบ

```
                    ┌──────────────────────────────────────┐
                    │        12-24V DC Power Supply         │
                    └──────┬──────────────────────┬────────┘
                           │                      │
                    ┌──────▼──────┐        ┌──────▼──────┐
                    │  Buck 5V    │        │  Stepper    │
                    │  (LM2596)   │        │  Drivers    │
                    └──────┬──────┘        │  (DM542/    │
                           │               │   TB6600/   │
                    ┌──────▼──────┐        │   TMC2209)  │
                    │  LDO 3.3V  │        └──────▲───────┘
                    │  (AMS1117) │               │
                    └──────┬──────┘        ┌──────┴───────┐
                           │               │  Optocoupler │
                    ┌──────▼──────┐        │  Isolation   │
                    │ CH32V203RBT6│        │  (6N137/     │
                    │  + Crystal  │◄───────┤   PC817)     │
                    │  + Decap    │        └──────────────┘
                    └──┬──┬──┬───┘
                       │  │  │
              ┌────────┘  │  └──────────┐
              │           │             │
       ┌──────▼──┐  ┌────▼───┐  ┌──────▼───┐
       │ CH340G  │  │ Relay  │  │ Limit +  │
       │ Serial  │  │ Board  │  │ Control  │
       │ (USB)   │  │(Spindle│  │ Inputs   │
       └─────────┘  │ Coolant│  │ (Filter) │
                    └────────┘  └──────────┘
```

### 1.3 ข้อแตกต่างระหว่าง CH32V307 และ CH32V203RBT6

| รายการ | CH32V307 | CH32V203RBT6 |
|--------|----------|--------------|
| แพ็คเกจ | LQFP100 | **LQFP64** (พินน้อยกว่า) |
| แกน | 6 (X,Y,Z,A,B,C) | **3 (X,Y,Z)** |
| FPU | มี (V4F) | **ไม่มี** (V4B) |
| GPIOE | มี (16 พิน) | **ไม่มี** |
| USB | USBHS | USBFS (ยังไม่สมบูรณ์ใน firmware) |
| พินว่าง | ~20 พิน | **~10 พิน** |

---

## 2. การเลือกชิ้นส่วน

### 2.1 MCU — CH32V203RBT6

| พารามิเตอร์ | ค่า |
|-----------|-----|
| แพ็คเกจ | LQFP64 (10×10mm, pitch 0.5mm) |
| Flash | 128KB |
| RAM | 64KB |
| ความเร็ว | 144MHz (PLL: HSE 32MHz ÷4 ×18) |
| แรงดัน | 2.5V – 3.6V (VDD) |
| Core | QingKe V4B (RV32IMAC, ไม่มี FPU) |

### 2.2 Stepper Driver (แนะนำ)

| รุ่น | พิกัด | Microstep | Opto | ราคา |
|-----|-------|-----------|------|------|
| **DM542** | 4.2A, 24-48V | สูงถึง 256 | ✅ | ~500 บาท |
| **TB6600** | 4A, 9-42V | สูงถึง 32 | ✅ | ~300 บาท |
| **TMC2209** | 2A, 4.75-29V | สูงถึง 256 | ❌ (ภายใน) | ~150 บาท |
| **ST820** | 7.2A, 24-50V | สูงถึง 256 | ✅ | ~600 บาท |

**คำแนะนำ**: DM542 หรือ TB6600 สำหรับ CNC งานไม้/อะคริลิค, TMC2209 สำหรับงานเงียบ (laser/3D printer)

### 2.3 คริสตัล (HSE)

- **ความถี่**: 32MHz (สำหรับ CH32V203RBT6 D8 series)
- **ชนิด**: คริสตัล HC-49S หรือ SMD 3225
- **Load Capacitance**: 20pF
- **Accuracy**: ±20ppm หรือดีกว่า
- ** capacitors**: 18pF–22pF (คำนวณจาก CL ของคริสตัล)

### 2.4  Voltage Regulator

| ชิ้นส่วน | หน้าที่ | Input | Output | กระแส |
|---------|--------|-------|--------|-------|
| **LM2596** (หรือ MP1584) | Buck Converter | 12-24V | 5V | ~2A |
| **AMS1117-3.3** | LDO | 5V | 3.3V | ~800mA |

เผื่อกระแสสำหรับ:
- MCU: ~100mA
- Optocoupler: ~100mA
- Cooling fan: ~100mA
- อื่นๆ: ~100mA

### 2.5 Optocoupler

| ตำแหน่ง | รุ่น | ความเร็ว | จำนวน |
|---------|-----|---------|-------|
| Step/Direction | **6N137** หรือ **EL3H7-G** | 10MBd | 7 ตัว (3 Step + 3 Dir + 1 Enable) |
| Limit/Probe | **PC817** | 80kHz | 4 ตัว |
| Spindle PWM | **6N137** หรือ **PC817** | 10MBd/80kHz | 1 ตัว |
| รีเลย์ Spindle/Coolant | **PC817** | 80kHz | 4 ตัว |

### 2.6 รีเลย์

| อุปกรณ์ | ชนิด | แนะนำ |
|---------|------|-------|
| Spindle On/Off | Relay 5V 10A | **SRD-05VDC-SL-C** (Songle) |
| Spindle Direction | Relay 5V 10A | SRD-05VDC-SL-C |
| Coolant Flood | Relay 5V 10A | SRD-05VDC-SL-C |
| Coolant Mist | Relay 5V 10A | SRD-05VDC-SL-C |

### 2.7 ขั้วต่อ

| ชนิด | การใช้งาน |
|------|----------|
| **Terminal Block 2-pin 5.08mm** | Power input, Limit switch, Spindle |
| **Terminal Block 4-pin 5.08mm** | Stepper motor output |
| **Pin Header 2.54mm** | SWD programming header (4-pin) |
| **Pin Header 2.54mm 6-pin** | Control inputs |
| **USB Type-B หรือ Micro-B** | Serial (ต่อ CH340G) |
| **DB9 Female** | Optional serial port |

### 2.8 ชิ้นส่วนอื่นๆ

| ชิ้นส่วน | ค่า | จำนวน | หมายเหตุ |
|---------|-----|-------|---------|
| MLCC 100nF | 0603/0805 | ~15 | Decoupling MCU + ICs |
| Electrolytic 10µF | 5mm pitch | ~5 | Filter ที่ input regulator |
| TVS SMBJ5.0A | SMB | ~5 | ป้องกัน ESD ที่ limit/control |
| Resistor 4.7kΩ | 0603/0805 | ~10 | Pull-up |
| Resistor 330Ω | 0603/0805 | ~7 | LED current limit |
| Ferrite Bead 100Ω | 0603/0805 | ~3 | Filter power supply |

---

## 3. แผนผังวงจร

### 3.1 วงจร Power Supply

```
12-24V DC ─┬─────── IN+ ─────── LM2596 ─────── +5V ─────── AMS1117-3.3 ─────── +3.3V
           │        │                        (Buck)                           (LDO)
           │    ┌───┴───┐                                                    ┌──┴──┐
           │    │ TVS   │                                         100nF   100nF  10µF
           │    │SMBJ24A│                                                   Ferrite
           │    └───────┘                                                     (100Ω)
           │                                                              ┌──┴──┐
           └────────────────────────────────────────────────────────────── GND
```

**ข้อควรระวัง**:
- แยก Power GND และ MCU GND ด้วย 0Ω resistor หรือ ferrite bead
- แยกวงจร 12-24V ออกจาก MCU เพื่อป้องกัน noise
- เก็บสาย 12-24V ให้ห่างจากสัญญาณ step/dir
- ใช้ TVS diode ที่ input (SMBJ24A สำหรับ 24V)

### 3.2 วงจร MCU ขั้นต่ำ

```
                    CH32V203RBT6 (LQFP64)
               ┌──────────────────────────┐
               │                          │
      ┌───100nF─┤ VDD (multiple pins)     │
      │         │                          │
     +3.3V──────┤ VDD                      │
               │                          │
      ┌───100nF─┤ VDDA                    │
      │         │                          │
     +3.3V──────┤ VDDA                    │
               │                          │
      ┌───100nF─┤ VDDIO                   │
      │         │                          │
     +3.3V──────┤ VDDIO                   │
               │                          │
         GND───┤ VSS (multiple pins)      │
               │                          │
               │   OSC_IN ───┬──── 32MHz   │
               │             │  Crystal    │
               │   OSC_OUT ──┤  (HC-49S)   │
               │             │             │
               │             │ 22pF  22pF  │
               │             ├──┐  ┌──┤    │
               │             │  └──┘  │    │
               │             │   GND  │    │
               │                    │       │
               │   NRST ───── 10kΩ ─┼─ +3.3V│
               │                    │       │
               │                    └─── SW (optional)│
               └──────────────────────────┘
```

**ข้อควรระวังสำหรับ LQFP64**:
- ใช้ Decoupling Capacitor 100nF ใกล้ทุกคู่ VDD-VSS (มี ~4-5 คู่)
- วาง Capacitor ให้ห่างจากพินไม่เกิน 5mm
- คริสตัล 32MHz ต่อกับ OSC_IN/OSC_OUT (PD6/PD7 — ตรวจสอบ datasheet)
- Reset ต่อ pull-up 10kΩ ไปยัง 3.3V
- เผื่อ SW-PB กด reset ได้

### 3.3 วงจร Optocoupler Isolation (Step/Direction)

```
MCU Side (3.3V)             Driver Side (5V หรือ 12-24V)
┌──────────────┐            ┌──────────────────────┐
│              │            │                      │
│ PB0 (X_STEP) ───┬─── 330Ω │     6N137            │
│              │  │        │  ┌──────────┐        │
│              │  └────────┼──┤  Anode   │        │
│              │           │  │          │         │
│              │           │  │ Cathode  ├─── GND  │
│              │  ┌────────┼──┤          │         │
│              │  │ 10kΩ   │  │          │         │
│              │  └────────┼──┤  Vo      ├───────┬─┤── Step+ Driver
│              │           │  └──────────┘       │ │
│              │           │                      │  ┌─── GND Driver
│              │           │           Pull-up    │  │
│              │           │           (ตาม        │  │
│              │           │            spec       │  │
│              │           │             driver)   │  │
└──────────────┘           └──────────────────────┘  │
                                                     │
ทำซ้ำสำหรับ: PB1 (X_DIR), PB3 (Y_STEP), PB5 (Y_DIR),
             PB6 (Z_STEP), PB7 (Z_DIR), PB8 (ENABLE)

```

**ข้อควรระวัง**:
- Step/Dir ใช้ **6N137** (10MBd) เท่านั้น — ห้ามใช้ PC817 (ช้าเกินไป)
- ความยาวสายจากบอร์ดไป Stepper Driver ควรไม่เกิน 1m
- สาย Step/Dir ใช้ Twisted Pair + Shielded Cable
- Pull-up resistor ฝั่ง Driver ขึ้นอยู่กับ spec ของ driver (ปกติ 2.2kΩ–10kΩ)
- ไฟเลี้ยงฝั่ง Driver (5V) ต้องแยกจากไฟเลี้ยง MCU

### 3.4 วงจร Limit Switch (NC + RC Filter)

```
                      +3.3V (MCU side)
                        │
                       10kΩ
                        │
  ┌─── PC10 (X_LIMIT) ──┼───────┬───── 100nF ──── GND
  │                       │      │
  │                       │     100Ω
  │                       │      │
  │               ┌───────┘      │
  │               │              │
  │             Shield           │
  │          ┌────┴────┐         │
  │          │  Limit  │         │
  │          │  Switch │         │
  │          │  (NC)   │         │
  │          └────┬────┘         │
  │               │              │
  └───────────────┴──── GND ─────┘ (sensor GND แยก)

ทำซ้ำสำหรับ: PC11 (Y_LIMIT), PC12 (Z_LIMIT)
```

**หลักการ**: Normally-Closed (NC) ต่อกับ GND — ถ้าสายขาดหรือ switch ถูกกด จะได้ HIGH
- RC filter (100Ω + 100nF) = cutoff ~16kHz — กรองสัญญาณรบกวน
- Shielded cable — ต่อ shield ที่ GND ฝั่งบอร์ดเท่านั้น
- ควรใช้ TVS diode (SMBJ5.0A) เพิ่มจากพินลง GND ป้องกัน ESD

### 3.5 วงจร Control Inputs

```
                     +3.3V (MCU side)
                       │
                      10kΩ
                       │
  ┌─── PA5 (RESET) ────┼───────┬──── 100nF ──── GND
  │                      │      │
  │                     100Ω    │
  │                      │      │
  │              ┌───────┘      │
  │              │   Shield     │
  │          ┌───┴───┐          │
  │          │  SW   │          │
  │          │  (NC) │          │
  │          └───┬───┘          │
  │              │              │
  └──────────────┴──── GND ─────┘

ทำซ้ำสำหรับ: PA6 (FEED_HOLD), PA7 (CYCLE_START), PA9 (SAFETY_DOOR)
```

**หมายเหตุ**: Control inputs ทั้งหมดใช้ EXTI9_5_IRQn ร่วมกัน — trigger Rising_Falling

### 3.6 วงจร Probe

```
                    +3.3V (MCU side)
                      │
                     10kΩ
                      │
  ┌── PB14 (PROBE) ───┼─────────┬──── 100nF ──── GND
  │                     │        │
  │                    100Ω      │
  │                     │        │
  │             ┌───────┘        │
  │             │  Shield        │
  │         ┌───┴───┐            │
  │         │Probe  │            │
  │         │(N.O.) │            │
  │         └───┬───┘            │
  │             │                │
  └─────────────┴──── GND ───────┘
```

### 3.7 วงจร Spindle Control

#### PWM Output (PA8 → TIM1_CH1)

```
MCU Side (3.3V)              Driver Side (5V หรือ 12V)
┌──────────────┐            ┌───────────────────────┐
│              │            │                       │
│ PA8 (PWM) ───┬─── 330Ω    │     6N137              │
│  TIM1_CH1   │  │        │  ┌──────────┐           │
│  10kHz      │  └────────┼──┤ Anode    │           │
│              │           │  │          │           │
│              │           │  │ Cathode  ├── GND     │
│              │           │  │          │           │
│              │           │  │ Vo       ├───┬───── PWM │
│              │           │  └──────────┘  │      ไปยัง
│              │           │                │      Spindle
│              │           │                │      Driver
└──────────────┘           └────────────────┼─────── (VFD/SCR)
                                            │
                                    Pull-up 10kΩ
                                            │
                                           +5V Driver
```

**ข้อควรระวัง PWM**:
- TIM1_CH1 PWM 10kHz — สามารถแปลงเป็น 0-10V สำหรับ VFD ผ่านวงจร RC filter + op-amp
- หรือใช้ SSR สำหรับควบคุม AC Spindle แบบเปิด/ปิด
- ความถี่ 10kHz อาจต้องปรับถ้า VFD ต้องการความถี่อื่น (ใน config.h: `SPINDLE_PWM_FREQUENCY`)

#### Enable/Direction Relay

```
MCU Side                     Driver Side
┌──────────────┐            ┌────────────────────┐
│              │            │                    │
│ PD0 ──┬─── 330Ω ── PC817 ──┤ Base Transistor   │
│(SPINDLE│     │            │ (2N2222 หรือ ULN2803)│
│ ENABLE)│     └────────────┤                     │
│        │                  │ Coil 5V Relay       │
│        │                  │ (SRD-05VDC-SL-C)    │
│        │                  │  ┌──────┐          │
│        │                  │  │ COM  ├── AC-N    │
│        │                  │  │ NO   ├── Spindle  │
│        │                  │  │ NC   │ (AC-L)    │
│        │                  │  └──────┘          │
│        │                  │                     │
│ PD1 ───┼─── 330Ω ── PC817 ──┤ Direction Relay  │
│(SPINDLE│                  │ (สลับขั้วกลับทาง)  │
│  DIR)  │                  └────────────────────┘
└──────────────┘
```

### 3.8 วงจร Coolant Control

```
MCU Side                     Driver Side
┌──────────────┐            ┌────────────────────┐
│              │            │                    │
│ PB12 ──┬─── 330Ω ── PC817 ──┤ ULN2803 Input    │
│(FLOOD)  │                  │              │    │
│         │                  │ ULN2803 Out ─┴──┤ │
│         │                  │                  │ │
│         │                  │  Relay           │ │
│         │                  │ 5V Coil          │ │
│         │                  │  ┌──────┐        │ │
│         │                  │  │ COM  ├── AC-N  │ │
│         │                  │  │ NO   ├── Pump   │ │
│         │                  │  └──────┘        │ │
│         │                  │                   │ │
│ PB13 ───┼─── 330Ω ── PC817 ──┤ Mist Relay    │ │
│ (MIST) │                  └────────────────────┘ │
└──────────────┘                                    │
                                                    │
**หมายเหตุ**: ใช้ ULN2803 แทน transistor 7 ตัวเพื่อขับรีเลย์
```

### 3.9 วงจร Serial Communication (USART2)

```
CH32V203RBT6              CH340G (USB-UART)
┌──────────┐              ┌────────────────────┐
│          │              │                    │
│ PA2(TX) ─┼────────────────── RXD             │
│          │              │                    │
│ PA3(RX) ─┼────────────────── TXD             │
│          │              │                    │
│          │              │   USB_D- ──── USB-B│
│          │              │   USB_D+ ──── (Type│
│          │              │                    │
└──────────┘              └────────────────────┘

หรือใช้ MAX3232 สำหรับ RS-232 DB9:
CH32V203RBT6              MAX3232
┌──────────┐              ┌───────────┐
│ PA2(TX) ─┼────────────────── T1IN   │
│          │              │           │
│ PA3(RX) ─┼────────────────── R1OUT  │
│          │              │           │
│          │              │  T1OUT ───┼── DB9 Pin 3 (TX)
│          │              │  R1IN  ───┼── DB9 Pin 2 (RX)
│          │              │           │
└──────────┘              └───────────┘
```

### 3.10 วงจร Programming (SWD)

```
                        CH32V203RBT6
                        ┌──────────┐
  ┌─ 4-pin Header ──┐   │          │
  │ 1. SWCLK (PA14) ─┼───┤ SWCLK   │
  │ 2. SWDIO (PA13) ─┼───┤ SWDIO   │
  │ 3. RESET         ─┼───┤ NRST    │
  │ 4. GND           ─┼───┤ VSS     │
  │ 5. +3.3V         ─┼───┤ VDD     │  (ถ้าหัว 5-pin)
  └───────────────────┘   │          │
                          └──────────┘

  เชื่อมต่อ: WCH-LinkE ──── SWD Header
  - ใช้สาย 10-pin หรือ 4-pin (SWD)
  - ถ้าต้องการโปรแกรมผ่าน WCH-Link แบบ "Under Reset": ต่อ RESET ด้วย
```

---

## 4. ข้อควรระวังในการออกแบบ PCB

### 4.1 การจัดวาง Layer (2-Layer Board)

```
Layer 1 (Top): ────── สัญญาณ + Power 3.3V + 5V
Layer 2 (Bottom): ─── GND Plane (Solid Ground)
```

### 4.2 Layout Guidelines

| หัวข้อ | คำแนะนำ |
|--------|--------|
| **Decoupling Capacitor** | 100nF ทุกคู่ VDD-VSS, วางห่างจากพิน ≤ 5mm |
| **Crystal** | วางใกล้ MCU ที่สุด, เส้น OSC_IN/OSC_OUT สั้นที่สุด |
| **Ground Plane** | GND เต็มพื้นที่ด้านล่าง — ห้ามแบ่งเป็น island |
| **Star Ground** | จุดต่อ GND รวมที่จุดเดียว (supply input) |
| **Analog/Digital** | แยก Power GND ↔ MCU GND ด้วย 0Ω resistor |
| **Optocoupler** | ร่องตัด (slot) ใต้ optocoupler แยกฝั่ง Primary/Secondary |
| **Step/Dir Trace** | ความยาวใกล้เคียงกัน, เดินคู่ขนานกัน |
| **High Current** | เส้น Power (12-24V) หนา ≥ 1mm |
| **Clearance** | ระยะห่าง 12-24V ↔ 3.3V ใช้ ≥ 1mm |
| **Via Size** | 0.3mm hole / 0.6mm pad (minimum) |
| **Trace Width** | Signal: 0.25mm, Power 5V: 0.5mm, 12-24V: 1.0mm |

### 4.3 Component Placement

```
┌─────────────────────────────────────────────────────┐
│    [Power Input]                                     │
│  ┌────────┐  ┌────────┐    [Stepper Drivers]         │
│  │ LM2596 │  │AMS1117 │     ┌─── ─── ─── ───┐       │
│  │ (Buck) │  │(LDO)   │     │ X    Y     Z   │       │
│  └───┬────┘  └────┬───┘     └─┬───┬───┬─────┘       │
│      └──────┬─────┘            │   │   │              │
│             │           ┌──────┘   │   └──────┐       │
│        ┌────▼────┐     │  Opto    │   Isolation│       │
│        │ Relays  │     └──────┬───┴───┬───────┘       │
│        │ Spindle │            │       │               │
│        │ Coolant │     ┌──────▼───────▼──────┐        │
│        └─────────┘     │    CH32V203RBT6      │        │
│                        │    + Crystal         │        │
│                        └──────────┬───────────┘        │
│                                   │                    │
│        [Limit/Control Inputs]      │                    │
│        ┌───── ─── ─── ───┐        │                    │
│        │  X  Y  Z  Probe │        │                    │
│        │  R  FH CS  SD   │        │                    │
│        └───── ─── ─── ───┘        │                    │
│                                   │                    │
│        [CH340G Serial] ───────────┘                    │
│        ┌──────────────────┐                            │
│        │   CH340G         │                            │
│        │   USB Type-B     │                            │
│        └──────────────────┘                            │
│                                                        │
│   [SWD Header]  [LED]                                  │
└─────────────────────────────────────────────────────────┘
```

### 4.4 ขนาดบอร์ดที่แนะนำ

| รูปแบบ | ขนาด | Layers |
|--------|------|--------|
| ขั้นต่ำ | 80×60mm | 2-layer |
| แนะนำ | 100×80mm (4×3 inch) | 2-layer |
| เต็มรูปแบบ | 120×100mm | 2-layer |

ขนาด 100×80mm พอดีสำหรับใส่ในกล่อง ABS ขนาดมาตรฐาน (เช่น Modushop หรือ Hammond 1590B)

---

## 5. การเลือก Stepper Driver

### 5.1 ตารางเปรียบเทียบ

| รุ่น | แรงดัน | กระแสสูงสุด | Microstep | Opto | ราคา (USD) |
|-----|--------|------------|-----------|------|-----------|
| A4988 | 8-36V | 2A | 16 | ❌ | ~$1 |
| DRV8825 | 8.2-45V | 2.5A | 32 | ❌ | ~$3 |
| TMC2209 | 4.75-29V | 2A | 256 | ❌ | ~$5 |
| TB6600 | 9-42V | 4A | 32 | ✅ | ~$10 |
| DM542 | 20-50V | 4.2A | 256 | ✅ | ~$15 |
| ST820 | 24-50V | 7.2A | 256 | ✅ | ~$20 |
| CL86T | 24-80V | 8A | 512 | ✅ | ~$40 |

### 5.2 การตั้งค่า Microstepping

GRBL steps_per_mm คำนวณจาก:

```
steps_per_mm = (motor_step_angle × microstep × pulley_teeth × belt_pitch) / 360
```

ตัวอย่าง:
- NEMA17 1.8° (200 steps/rev), 16 microstep, 2mm lead ballscrew
  → `200 × 16 / 2 = 1600 steps/mm`

- NEMA23 1.8° (200 steps/rev), 8 microstep, GT2-20 pulley, 2mm belt
  → `200 × 8 / (20 × 2) = 40 steps/mm`

---

## 6. ESTLCam Compatibility

ESTLCam รองรับ GRBL protocol โดยตรง ไม่ต้องตั้งค่าเพิ่มเติม

### 6.1 Pin Mapping ใน ESTLCam

เข้า **Config → I/O Ports** ตั้งค่าดังนี้:

| ฟังก์ชันใน ESTLCam | พิน CH32V203RBT6 |
|-------------------|-------------------|
| Step X | PB0 |
| Dir X | PB1 |
| Step Y | PB3 |
| Dir Y | PB5 |
| Step Z | PB6 |
| Dir Z | PB7 |
| Spindle PWM | PA8 (TIM1_CH1, 10kHz) |
| Spindle On/Off | PD0 (หรือใช้ PWM อย่างเดียวก็ได้) |
| Probe | PB14 |
| Coolant Flood | PB12 (M8) |

### 6.2 ฟีเจอร์ ESTLCam ที่ทำงานได้

| ฟีเจอร์ | G-code ที่ใช้ | สถานะใน GRBL นี้ |
|---------|-------------|------------------|
| Isolation routing | G0, G1, G2, G3 | ✅ รองรับ |
| PCB drilling | G81 (แปลงเป็น G0/G1 ใน ESTLCam) | ✅ |
| Auto leveling | G38.2, G38.3 | ✅ รองรับครบ 4 โหมด |
| Spindle speed | S + M3/M4/M5 | ✅ |
| Coolant | M7/M8/M9 | ✅ |
| Offset reset | G92 | ✅ |

### 6.3 ข้อควรรู้

- ESTLCam ใช้ Serial 115200 baud — ตรงกับ GRBL default ไม่ต้องเปลี่ยน
- ESTLCam Tool Change (M6) — GRBL ไม่มี M6 แต่ ESTLCam จัดการ Tool Change ที่ฝั่งซอฟต์แวร์อยู่แล้ว
- PB3/PB4 ต้อง disable JTAG — firmware ถูกตั้งค่าไว้แล้ว ไม่ต้องทำเพิ่ม

---

## 7. Bill of Materials (BOM)

### 7.1 BOM หลัก

| # | ชิ้นส่วน | ค่า | Package | จำนวน | ราคาประมาณ (บาท) |
|---|---------|-----|---------|-------|-----------------|
| 1 | CH32V203RBT6 | MCU RISC-V 144MHz | LQFP64 | 1 | 120 |
| 2 | AMS1117-3.3 | LDO 3.3V 800mA | SOT-223 | 1 | 15 |
| 3 | LM2596 | Buck 5V 2A | TO-220 | 1 | 50 |
| 4 | Crystal 32MHz | HC-49S | DIP-2 | 1 | 10 |
| 5 | Ceramic 22pF | 22pF ±5% 50V | 0805 | 2 | 2 |
| 6 | Ceramic 100nF | 0.1µF ±10% 50V | 0805 | 15 | 8 |
| 7 | Ceramic 10µF | 10µF ±10% 16V | 0805 | 5 | 10 |
| 8 | Resistor 10kΩ | 10kΩ ±1% | 0805 | 10 | 5 |
| 9 | Resistor 330Ω | 330Ω ±1% | 0805 | 7 | 4 |
| 10 | Resistor 100Ω | 100Ω ±1% | 0805 | 7 | 4 |
| 11 | 6N137 | Optocoupler 10MBd | DIP-8 | 7 | 120 |
| 12 | PC817 | Optocoupler 80kHz | DIP-4 | 5 | 25 |
| 13 | ULN2803 | Darlington Driver | DIP-18 | 1 | 20 |
| 14 | SRD-05VDC-SL-C | Relay 5V 10A | — | 4 | 80 |
| 15 | TVS SMBJ24A | TVS 24V 600W | SMB | 2 | 10 |
| 16 | CH340G | USB-UART | SOP-16 | 1 | 30 |
| 17 | USB Type-B | USB Connector | — | 1 | 15 |
| 18 | Terminal Block 2-pin | 5.08mm | — | 6 | 30 |
| 19 | Terminal Block 4-pin | 5.08mm | — | 3 | 25 |
| 20 | Pin Header 2.54mm | Male 40-pin | — | 2 | 10 |
| 21 | PCB 100×80mm | 2-layer FR4 1.6mm | — | 1 | 100 |
| | | | **รวม** | | **~693 บาท** |

### 7.2 ไม่รวมใน BOM

- Stepper Driver (DM542/TB6600/TMC2209) — ขึ้นกับรูปแบบที่เลือก
- Stepper Motor — NEMA17/NEMA23
- Power Supply (12-24V) — แยกต่างหาก
- WCH-LinkE — สำหรับโปรแกรม MCU

---

## 8. ข้อควรระวังสำคัญ

### ⚠️ 8.1 PB3/PB4 — ต้อง Disable JTAG

PB3 ใช้เป็น **Y_STEP** — หลังจาก power up ถ้ายังไม่ disable JTAG จะเป็นพิน JTDO/TMS ทำให้ Y_STEP ไม่ทำงาน

**วิธีแก้ไข**: Firmware ทำ `GPIO_PinRemapConfig(GPIO_Remap_SWJ_Disable, ENABLE)` ใน `system_init()` แล้ว — **ไม่มีผลต่อการโปรแกรม SWD** (SWCLK/SWDIO ยังใช้การได้)

⚠️ **โปรแกรมครั้งแรก**: โปรแกรมผ่าน SWD โดยใช้ WCH-Link ปกติ SWCLK(PA14) + SWDIO(PA13) + GND — ใช้การได้ทันที

### ⚠️ 8.2 PA8 — ห้ามใช้ MCO และ PWM พร้อมกัน

PA8 ใช้เป็น **SPINDLE_PWM (TIM1_CH1)** — หลังจากแก้ไขใน main.c เรียบร้อยแล้ว ไม่มี MCO conflict

### ⚠️ 8.3 Spindle PWM ต้องใช้ 6N137

PWM ที่ 10kHz ต้องใช้ optocoupler ความเร็วสูง **6N137** เท่านั้น — ห้ามใช้ PC817 (80kHz จำกัด, รูปคลื่น PWM ผิดเพี้ยน)

### ⚠️ 8.4 ไม่มี FPU — ประสิทธิภาพ Float ช้ากว่า V307

CH32V203 (V4B core) ไม่มี FPU — GRBL ใช้ float intensive การคำนวณจะใช้ software emulation
- ที่ 144MHz ยังยอมรับได้
- ไม่ควรตั้ง Acceleration Ticks สูงเกิน 100 (ใน config.h)

### ⚠️ 8.5 USB ยังไม่สมบูรณ์

CH32V203RBT6 มี USBFS (Full Speed) แต่ driver ใน firmware ยังไม่พร้อม — **ต้องใช้ USART2 (PA2/PA3)** ผ่าน CH340G หรือ MAX3232 แทน
- เผื่อ USB_DP (PA11) + USB_DM (PA12) บน PCB สำหรับอนาคต

### ⚠️ 8.6 Flash Page Size สำหรับ EEPROM Emulation

D8 series (V203RBT6) มี HW page erase ขนาด **256 bytes** (`FLASH_ErasePage_Fast`),
แต่ EE_Buffer ต้องมีขนาด **2048 bytes** เพื่อครอบคลุม settings layout ทั้งหมด
(BUILD_INFO checksum อยู่ที่ address 960+80=1040, เกิน 1024)

| MCU | HW Page Erase | EE_Buffer | EEPROM Address |
|-----|--------------|-----------|---------------|
| CH32V203RBT6 (D8) | 256B (Fast) | 2048 bytes | 0x0800F000 |
| CH32V203C8T6 (D6) | 256B (Fast) | 2048 bytes | 0x0800F000 |
| CH32V307 | 4KB (Standard) | 4096 bytes | 0x0800F000 |

ถ้านำไปใช้กับ MCU V203 รุ่นอื่น ต้องแก้ไข `grbl/eeprom.c`:

```c
// eeprom.c line 50-60
#ifdef CH32V203_RBT6_3AXIS
  #define HW_ERASE_PAGE_SIZE          256   // D8: fast page erase size
  #define PAGE_SIZE                  2048   // EE_Buffer + data range
  unsigned char EE_Buffer[2048];
#else
  #define PAGE_SIZE                  4096
  unsigned char EE_Buffer[4096];
#endif
```

### ⚠️ 8.7 HSE Crystal Selection

V203RBT6 เป็น **D8 series** — HSE crystal ต้องเป็น **32MHz** (สำหรับ D6 series ใช้ 8MHz)

| รุ่น MCU | HSE ความถี่ | PLL Config |
|---------|-------------|-----------|
| CH32V203RBT6 (D8) | 32MHz | ÷4 ×18 = 144MHz |
| CH32V203C8T6 (D6) | 8MHz | ×18 = 144MHz |

### ⚠️ 8.8 Limitation ของ Control Inputs

Control inputs (PA5-PA9) ใช้ EXTI9_5_IRQn ร่วมกัน — ทุกพินในกลุ่มนี้ **ใช้ ISR ตัวเดียวกัน**:
- การตั้ง trigger Rising_Falling ทำงานได้
- ไม่สามารถกำหนด priority แยกพินได้
- คำแนะนำ: ใช้ RC filter (100Ω + 100nF) ป้องกัน noise

### ⚠️ 8.9 การโปรแกรม MCU บนบอร์ดครั้งแรก

บอร์ดเปล่าที่ยังไม่เคยโปรแกรม — ต้องแน่ใจว่า:

1. WCH-LinkE ต่อกับ SWD (SWCLK + SWDIO + GND)
2. ต่อ RESET ด้วย (ถ้าเลือก "Under Reset" mode)
3. ถ้าใช้ JTAG, PB3-PB4 ยังไม่ถูก disable — เฉพาะ SWD เท่านั้นที่จำเป็น
4. Power บอร์ด 3.3V — WCH-LinkE สามารถจ่ายไฟให้ได้ (3.3V/50mA)

### ✅ 8.10 สรุปพินว่างสำหรับใช้งานเพิ่มเติม

| พิน | พอร์ต | หมายเหตุ |
|-----|-------|---------|
| PB2 | GPIOB | ใช้การได้ (ไม่โดน JTAG) |
| PB4 | GPIOB | ใช้ได้หลัง JTAG disable |
| PB9 | GPIOB | ใช้การได้ |
| PB10 | GPIOB | ใช้การได้ |
| PB11 | GPIOB | ใช้การได้ |
| PB15 | GPIOB | ใช้การได้ |
| PA1 | GPIOA | ใช้การได้ |
| PA4 | GPIOA | ใช้การได้ |
| PC0-PC9 | GPIOC | ใช้การได้ (ยกเว้น limit pins PC10-PC12) |

---

## ภาคผนวก A: Pin Reference Card

### CH32V203RBT6 (LQFP64) — GRBL Pin Assignment

```
            CH32V203RBT6 LQFP64
 ┌─────────────────────────────────┐
 │ PB0  (1)  X_STEP        (48) PB15  (ฟรี)       │
 │ PB1  (2)  X_DIR         (47) PB14  PROBE        │
 │ PB2  (3)  (ฟรี)          (46) PB13  COOLANT_MIST │
 │ PB3  (4)  Y_STEP*       (45) PB12  COOLANT_FLOOD│
 │ PB4  (5)  (ฟรี*)        (44) PB11  (ฟรี)        │
 │ PB5  (6)  Y_DIR         (43) PB10  (ฟรี)        │
 │ PB6  (7)  Z_STEP        (42) PB9   (ฟรี)        │
 │ PB7  (8)  Z_DIR         (41) PB8   STEPPER_DIS   │
 │                 ───                        │
 │ PA0  LED (debug blink, เรียกจาก protocol.c)        │
 │ PA2  SERIAL_TX (USART2)                         │
 │ PA3  SERIAL_RX (USART2)                         │
 │ PA5  CONTROL_RESET                              │
 │ PA6  CONTROL_FEED_HOLD                          │
 │ PA7  CONTROL_CYCLE_START                        │
 │ PA8  SPINDLE_PWM (TIM1_CH1)                     │
 │ PA9  CONTROL_SAFETY_DOOR                        │
 │ PA13 SWDIO                                      │
 │ PA14 SWCLK                                      │
 │ PC10 X_LIMIT                                    │
 │ PC11 Y_LIMIT                                    │
 │ PC12 Z_LIMIT                                    │
 │ PD0  SPINDLE_ENABLE                             │
 │ PD1  SPINDLE_DIR                                │
 └─────────────────────────────────┘
```

### ตารางสรุปตามฟังก์ชัน

| ฟังก์ชัน | Port/Pin | ไฟล์ | หมายเหตุ |
|---------|----------|------|---------|
| X_STEP | PB0 | cpu_map.h | |
| X_DIR | PB1 | cpu_map.h | |
| Y_STEP | PB3 | cpu_map.h | ต้อง disable JTAG |
| Y_DIR | PB5 | cpu_map.h | |
| Z_STEP | PB6 | cpu_map.h | |
| Z_DIR | PB7 | cpu_map.h | |
| STEPPERS_DISABLE | PB8 | cpu_map.h | Active LOW |
| COOLANT_FLOOD | PB12 | cpu_map.h | M8 |
| COOLANT_MIST | PB13 | cpu_map.h | M7 (ต้องเปิด ENABLE_M7) |
| PROBE | PB14 | cpu_map.h | Input pull-up |
| X_LIMIT | PC10 | cpu_map.h | EXTI10 |
| Y_LIMIT | PC11 | cpu_map.h | EXTI11 |
| Z_LIMIT | PC12 | cpu_map.h | EXTI12 |
| CONTROL_RESET | PA5 | cpu_map.h | Active LOW |
| CONTROL_FEED_HOLD | PA6 | cpu_map.h | Active LOW |
| CONTROL_CYCLE_START | PA7 | cpu_map.h | Active LOW |
| CONTROL_SAFETY_DOOR | PA9 | cpu_map.h | Active LOW |
| SPINDLE_PWM | PA8 | cpu_map.h | TIM1_CH1, 10kHz |
| SPINDLE_ENABLE | PD0 | cpu_map.h | Active HIGH |
| SPINDLE_DIR | PD1 | cpu_map.h | CW/CCW |
| SERIAL_TX | PA2 | main.c | USART2, 115200 |
| SERIAL_RX | PA3 | main.c | USART2, 115200 |
| LED | PA0 | main.c | Debug blink (LedBlink() ถูกเรียกจาก protocol_main_loop) |

---

## ภาคผนวก B: Timer และ Interrupt Reference

| Timer | หน้าที่ | Bus | ความถี่ | Priority |
|-------|--------|-----|---------|----------|
| TIM1 | Spindle PWM (CH1) | APB2 (144MHz) | 10kHz | — |
| TIM2 | Stepper rate | APB1 (72MHz) | variable | 1 |
| TIM3 | Step pulse width | APB1 (72MHz) | step rate | **0 (สูงสุด)** |

| IRQ | พิน | Priority | ใช้ร่วม |
|-----|-----|----------|---------|
| TIM3_IRQn | — | 0 | เฉพาะ TIM3 |
| TIM2_IRQn | — | 1 | เฉพาะ TIM2 |
| USART2_IRQn | PA2/PA3 | 1,1 | เฉพาะ USART2 |
| EXTI9_5_IRQn | PA5-PA9 | 2,2 | **แชร์ 4 control pins** |
| EXTI15_10_IRQn | PC10-PC12 | — | **แชร์ 3 limit pins** |

---

> **อัปเดตล่าสุด**: กรกฎาคม 2569  
> **อ้างอิงเฟิร์มแวร์**: GRBL 1.1f Build 20230112  
> **MCU**: CH32V203RBT6 (QingKe V4B, 144MHz, LQFP64)  
> **GitHub**: [Witawat/GRBL1.1f-CH32V307_V203](https://github.com/Witawat/GRBL1.1f-CH32V307_V203)
