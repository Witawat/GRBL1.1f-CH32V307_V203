# เอกสารอธิบายการทำงานของ GRBL บน CH32V307/V203RBT6 (ภาษาไทย)

> **เวอร์ชัน**: GRBL 1.1f  
> **แพลตฟอร์ม**: CH32V307 / CH32V203RBT6 (RISC-V MCU)  
> **จำนวนแกน**: 3-6 แกน (X, Y, Z, A, B, C)

---

## สารบัญ

1. [ภาพรวมสถาปัตยกรรม](#1-ภาพรวมสถาปัตยกรรม)
2. [วงจรการทำงานหลัก (Main Loop)](#2-วงจรการทำงานหลัก-main-loop)
3. [ระบบสื่อสาร (Serial)](#3-ระบบสื่อสาร-serial)
4. [โพรโทคอล (Protocol)](#4-โพรโทคอล-protocol)
5. [ตัวแยกคำสั่ง G-code (GCode Parser)](#5-ตัวแยกคำสั่ง-g-code-gcode-parser)
6. [การควบคุมการเคลื่อนที่ (Motion Control)](#6-การควบคุมการเคลื่อนที่-motion-control)
7. [ตัววางแผนวิถีการเคลื่อนที่ (Planner)](#7-ตัววางแผนวิถีการเคลื่อนที่-planner)
8. [ตัวขับสเต็ปเปอร์ (Stepper)](#8-ตัวขับสเต็ปเปอร์-stepper)
9. [การควบคุมสปินเดิล (Spindle Control)](#9-การควบคุมสปินเดิล-spindle-control)
10. [การควบคุมน้ำหล่อเย็น (Coolant Control)](#10-การควบคุมน้ำหล่อเย็น-coolant-control)
11. [ลิมิตสวิตช์และการหาจุดศูนย์ (Limits & Homing)](#11-ลิมิตสวิตช์และการหาจุดศูนย์-limits--homing)
12. [โพรบ (Probe)](#12-โพรบ-probe)
13. [การจ็อก (Jogging)](#13-การจ็อก-jogging)
14. [ระบบสถานะ (System)](#14-ระบบสถานะ-system)
15. [การตั้งค่าและ EEPROM (Settings & EEPROM)](#15-การตั้งค่าและ-eeprom-settings--eeprom)
16. [การรายงานผล (Report)](#16-การรายงานผล-report)
17. [ฟังก์ชันพื้นฐาน (Nuts & Bolts)](#17-ฟังก์ชันพื้นฐาน-nuts--bolts)
18. [แผนผังพิน (CPU Map)](#18-แผนผังพิน-cpu-map)
19. [ไฟล์การตั้งค่า (Config & Defaults)](#19-ไฟล์การตั้งค่า-config--defaults)
20. [แผนภาพการไหลของข้อมูล](#20-แผนภาพการไหลของข้อมูล)

---

## 1. ภาพรวมสถาปัตยกรรม

GRBL เป็นเฟิร์มแวร์ควบคุมเครื่อง CNC แบบเรียลไทม์ที่ทำงานบนไมโครคอนโทรลเลอร์ สถาปัตยกรรมของ GRBL ถูกออกแบบให้เป็นระบบ **single-loop cooperative multitasking** โดยมี interrupt สำหรับงานที่ต้องการความแม่นยำสูงทางเวลา

### โครงสร้างระบบแบ่งเป็น 3 ระดับ:

```
┌─────────────────────────────────────────────────────────────────┐
│                      ระดับที่ 1: Main Loop                        │
│  protocol_main_loop() → อ่าน Serial → ส่งให้ system/gcode parser  │
│  ทำงานเป็น Foreground Process                                     │
└────────────────────────────────────────────────────────┬────────┘
                                                         │
┌────────────────────────────────────────────────────────▼────────┐
│                ระดับที่ 2: Motion Control & Planner                │
│  mc_line() → plan_buffer_line() → คำนวณเส้นทางและความเร็ว         │
│  ทำงานใน Main Loop (Foreground)                                   │
└────────────────────────────────────────────────────────┬────────┘
                                                         │
┌────────────────────────────────────────────────────────▼────────┐
│              ระดับที่ 3: Stepper Interrupt (TIM2 ISR)              │
│  Bresenham Algorithm + AMASS → สร้าง Pulse ส่งให้มอเตอร์           │
│  ทำงานเป็น Background Process (Interrupt Driven)                  │
└─────────────────────────────────────────────────────────────────┘
```

### การไหลของข้อมูลหลัก

```
Serial Input → protocol_main_loop() → gc_execute_line() → mc_line()/mc_arc()
                                           ↓
                                    plan_buffer_line() [Planner Ring Buffer]
                                           ↓
                                    st_prep_buffer() [Segment Buffer]
                                           ↓
                                    TIM2 ISR → Stepper Pulses → Motors
```

### ไฟล์หลักและหน้าที่

| ไฟล์ | หน้าที่ |
|------|--------|
| `grbl.h` | รวมไฟล์ส่วนหัวทั้งหมด, กำหนดเวอร์ชัน |
| `serial.c/h` | การสื่อสารผ่าน UART/USB (ระดับต่ำ) |
| `protocol.c/h` | โพรโทคอลหลัก, การประมวลผลคำสั่งเรียลไทม์ |
| `gcode.c/h` | ตัวแยกคำสั่ง G-code (RS274/NGC) |
| `motion_control.c/h` | อินเทอร์เฟซระดับสูงสำหรับคำสั่งเคลื่อนที่ |
| `planner.c/h` | ตัววางแผนการเคลื่อนที่ (ring buffer + velocity profile) |
| `stepper.c/h` | ตัวขับสเต็ปเปอร์ (Bresenham + AMASS) |
| `spindle_control.c/h` | ควบคุมสปินเดิล (PWM, ทิศทาง) |
| `coolant_control.c/h` | ควบคุมน้ำหล่อเย็น (Flood, Mist) |
| `limits.c/h` | ลิมิตสวิตช์ และวงจร Homing |
| `probe.c/h` | ระบบโพรบวัดชิ้นงาน |
| `jog.c/h` | การเคลื่อนที่แบบ Jog |
| `system.c/h` | การจัดการสถานะ, คำสั่งระบบ ($) |
| `settings.c/h` | การตั้งค่าและ EEPROM |
| `report.c/h` | การรายงานสถานะและข้อความ |
| `print.c/h` | ฟังก์ชันจัดรูปแบบการพิมพ์ |
| `nuts_bolts.c/h` | ฟังก์ชันคณิตศาสตร์พื้นฐาน, การแปลงหน่วย |
| `config.h` | การตั้งค่าคอมไพล์ไทม์ |
| `defaults.h` | ค่าเริ่มต้นของการตั้งค่า |
| `cpu_map.h` | การกำหนดขาพินสำหรับ MCU |

---

## 2. วงจรการทำงานหลัก (Main Loop)

### `protocol_main_loop()` — [protocol.c](file:///d:/MyCode/grbl/grbl_ch32v307/6-AXIS-CH32V307-GRBL/grbl/protocol.c)

นี่คือฟังก์ชันหลักของโปรแกรม ทำงานเป็นวงวนไม่มีที่สิ้นสุด:

1. **อ่านข้อมูลจาก Serial Buffer** — เรียก `serial_read()` เพื่ออ่านทีละไบต์
2. **กรองตัวอักษร** — ข้าม whitespace, คอมเมนต์ `(...)` และ `;`
3. **ตรวจสอบ Real-time Commands** — ตัวอักษรพิเศษ (เช่น `?`, `~`, `!`, `ctrl-x`) ถูกประมวลผลทันทีผ่าน `protocol_execute_realtime()`
4. **สร้างบรรทัดคำสั่ง** — เก็บอักขระใน line buffer จนพบ `\r` หรือ `\n`
5. **ประมวลผลบรรทัด**:
   - ถ้าขึ้นต้นด้วย `$` → ส่งให้ `system_execute_line()` (คำสั่งระบบ)
   - ถ้าเป็น G-code → ส่งให้ `gc_execute_line()` (คำสั่ง G-code)
6. **ส่ง `ok` หรือ `error:`** — ผ่าน `report_status_message()`

### `protocol_execute_realtime()` — การประมวลผลคำสั่งเรียลไทม์

ฟังก์ชันนี้ถูกเรียกจากหลายจุดในโค้ดเพื่อตรวจสอบคำสั่งเร่งด่วน แบ่งเป็น 3 ส่วน:

1. **`protocol_exec_rt_system()`** — จัดการสถานะระบบ:
   - สัญญาณเตือน (Alarm) → รีเซ็ตระบบ
   - Soft Reset (`ctrl-x`) → ล้าง buffer ทั้งหมด กลับสู่ IDLE
   - Safety Door → จัดการพาร์กกิ้ง
   - Feed Hold / Cycle Start
   - Override (ความเร็ว, สปินเดิล)

2. **`protocol_exec_rt_suspend()`** — จัดการ Safety Door:
   - Retract (ถอยเครื่องมือ)
   - Parking (จอด)
   - Restore (กลับมาทำงานต่อ)

3. **ตรวจสอบ Motion Overrides และ Accessory Overrides**

### State Machine (เครื่องสถานะ)

GRBL มีสถานะหลัก 9 สถานะ (นิยามใน [system.h](file:///d:/MyCode/grbl/grbl_ch32v307/6-AXIS-CH32V307-GRBL/grbl/system.h)):

```
IDLE → CYCLE  (เริ่มทำงานเมื่อมีคำสั่งเคลื่อนที่)
IDLE → JOG    (เริ่ม Jog)
IDLE → HOMING (เริ่ม Homing)
IDLE → CHECK_MODE (โหมดตรวจสอบ $C)

CYCLE → HOLD  (Feed Hold)
HOLD  → IDLE  (Jog Cancel / Cycle Stop)
HOLD  → CYCLE (Cycle Start)

IDLE → SLEEP  ($SLP)
IDLE → ALARM  (Hard/Soft Limit, Abort)

Any  → SAFETY_DOOR (Safety Door เปิด)
SAFETY_DOOR → IDLE (Safety Door ปิด + Restore)

ALARM → IDLE  ($X unlock หรือ $H homing)
```

---

## 3. ระบบสื่อสาร (Serial)

### `serial.c` — การจัดการ UART/USART ระดับต่ำ

ในเวอร์ชัน CH32V307/V203RBT6 ใช้ **USART2** ในการสื่อสาร

#### การรับข้อมูล (RX)

ใช้ **Interrupt-based Ring Buffer**:
- `serial_rx_buffer[RX_RING_BUFFER]` — buffer ขนาด 254 ไบต์
- `serial_rx_buffer_head` — ตำแหน่งเขียน (โดย ISR)
- `serial_rx_buffer_tail` — ตำแหน่งอ่าน (โดย main loop)

**การกรอง Real-time Commands**:

ใน `USART2_IRQHandler` (หรือ USB callback) ตัวอักษรที่เข้ามาจะถูกตรวจสอบก่อนเข้า buffer:
- `0x18` (ctrl-x) → `mc_reset()`
- `?` → ตั้งค่า flag `EXEC_STATUS_REPORT`
- `~` → ตั้งค่า flag `EXEC_CYCLE_START`
- `!` → ตั้งค่า flag `EXEC_FEED_HOLD`
- `0x84` → `EXEC_SAFETY_DOOR`
- ตัวอักษร extended-ASCII อื่นๆ → override commands
- ตัวอักษรปกติ → เก็บใน buffer

#### การส่งข้อมูล (TX)

เมื่อไม่ได้ใช้ USB จะส่งตรงผ่าน `USART_SendData()` โดยตรง (ไม่ใช้ TX buffer เพื่อความเร็ว)

#### ฟังก์ชันที่สำคัญ

- `serial_init()` — ตั้งค่า USART2, baud rate
- `serial_write(uint8_t data)` — ส่ง 1 ไบต์
- `serial_read()` — อ่าน 1 ไบต์จาก buffer (คืน `SERIAL_NO_DATA` = 0xFF หากว่าง)
- `serial_reset_read_buffer()` — ล้าง buffer (ใช้ตอน e-stop/reset)
- `serial_get_rx_buffer_available()` — จำนวนพื้นที่ว่างใน buffer

---

## 4. โพรโทคอล (Protocol)

### `protocol.h` — นิยามค่าคงที่

- `LINE_BUFFER_SIZE` — 80 ตัวอักษร (สำหรับ 6 แกน) หรือ 90 ตัวอักษร (3 แกน)

### `protocol.c` — การทำงาน

#### ฟังก์ชันหลัก:

1. **`protocol_main_loop()`** — วงวนหลัก (อธิบายแล้วในหัวข้อที่ 2)
2. **`protocol_execute_realtime()`** — ตรวจสอบและประมวลผลคำสั่งเรียลไทม์
3. **`protocol_buffer_synchronize()`** — รอให้ motion buffer ว่าง

#### `protocol_buffer_synchronize()`

ฟังก์ชันนี้สำคัญมาก — มันจะ block จนกว่า:
- Planner buffer ว่าง
- Stepper segment buffer ว่าง
- Steppers หยุด (สถานะ IDLE)

ใช้ก่อนคำสั่งที่ต้องการให้แน่ใจว่าการเคลื่อนที่ก่อนหน้าเสร็จสิ้นแล้ว (เช่น M3, M5, M9, G4)

#### `protocol_auto_cycle_start()`

เมื่อ planner buffer เริ่มจะเต็ม → เริ่มการเคลื่อนที่โดยอัตโนมัติ:
```
plan_buffer_line() → ถ้า buffer เกือบเต็ม → protocol_auto_cycle_start()
→ system_set_exec_state_flag(EXEC_CYCLE_START)
→ st_prep_buffer() + st_wake_up()
```

#### `protocol_exec_rt_suspend()` — กลไก Safety Door

เมื่อ Safety Door เปิด:
1. **Retract**: เคลื่อนที่ถอยหลังตาม `PARKING_RETRACT_DISTANCE`
2. **Park**: เคลื่อนที่ไปตำแหน่งจอดตาม `PARKING_TARGET`
3. **รอ**: จนกว่า Safety Door ปิด
4. **Restore**: 
   - เปิด Spindle (รอ SPINDLE_DELAY)
   - เปิด Coolant 
   - เคลื่อนที่กลับตำแหน่งเดิม

---

## 5. ตัวแยกคำสั่ง G-code (GCode Parser)

การทำงานแบ่งเป็น 4 ขั้นตอน:

### โครงสร้างข้อมูล (gcode.h)

- **`gc_modal_t`** — เก็บค่า modal state (G-code modes):
  - `motion` — โหมดการเคลื่อนที่ (G0, G1, G2, G3, G38.x, G80)
  - `coord_select` — ระบบพิกัด (G54-G59)
  - `plane_select` — ระนาบ (G17, G18, G19)
  - `units` — หน่วย (G20 นิ้ว, G21 มม.)
  - `distance` — ระยะทาง (G90 absolute, G91 incremental)
  - `feed_rate` — โหมดอัตราป้อน (G93, G94)
  - `spindle` — สถานะสปินเดิล (M3, M4, M5)
  - `coolant` — สถานะน้ำหล่อเย็น (M7, M8, M9)
  - `program_flow` — M0, M2, M30

- **`parser_state_t`** — สถานะ parser ทั้งหมด
- **`parser_block_t`** — บล็อกคำสั่งที่แยกวิเคราะห์แล้ว

### ขั้นตอนการทำงาน (gcode.c)

#### ขั้นที่ 1: Initialize Block
```c
memset(gc_block, 0, sizeof(parser_block_t));
// คัดลอก modal state ปัจจุบันไปยัง block
memcpy(&gc_block->modal, &gc_state.modal, sizeof(gc_modal_t));
```

#### ขั้นที่ 2: Parse Words
แยกวิเคราะห์คำในบรรทัด G-code:
- **G-words**: ตรวจสอบ modal group violation
- **M-words**: คำสั่งเบ็ดเตล็ด
- **Parameter words**: F (feed rate), S (spindle speed), X, Y, Z, A, B, C (coordinates), I, J, K (offsets), R (radius), P, L, T, N

**การตรวจสอบ Modal Group Violation**: G-code แต่ละกลุ่มมีได้เพียงคำสั่งเดียวต่อบรรทัด เช่น ใช้ G0 และ G1 พร้อมกันไม่ได้

#### ขั้นที่ 3: Error Check
ตรวจสอบความถูกต้องของคำสั่ง:
- Feed rate ต้องมีค่าเมื่อมีการเคลื่อนที่
- Spindle speed ต้องมีค่าสำหรับคำสั่ง M3/M4
- Arc commands ต้องมี offsets (I,J,K) หรือ radius (R) ที่ถูกต้อง
- Probe commands (G38.x) ต้องมีแกนที่เคลื่อนที่
- ระบบพิกัด (G54-G59) ต้องถูกต้อง
- ตรวจสอบ target ว่าอยู่ในขอบเขต
- ตรวจสอบค่าที่มากเกินไป

#### ขั้นที่ 4: Execute
ดำเนินการตามคำสั่งที่แยกวิเคราะห์แล้ว:

- **G0/G1**: `mc_line(target, pl_data)`
- **G2/G3**: `mc_arc(target, pl_data, ...)` → แบ่งเป็นเส้นตรงเล็กๆ หลายเส้น
- **G4 (Dwell)**: `mc_dwell(seconds)`
- **G10**: ตั้งค่า coordinate offsets
- **G28/G30**: `mc_line()` ไปยังตำแหน่ง home
- **G38.x (Probe)**: `mc_probe_cycle()`
- **G43.1**: ตั้งค่า tool length offset
- **G53**: เคลื่อนที่ใน machine coordinates
- **G54-G59**: เลือกระบบพิกัด
- **G80**: ยกเลิกโหมด motion
- **G90/G91**: ตั้งค่า absolute/incremental
- **G92/G92.1**: coordinate offset / reset
- **G93/G94**: inverse time / units per minute
- **M0/M2/M30**: program stop / end
- **M3/M4/M5**: spindle CW/CCW/stop
- **M7/M8/M9**: coolant mist/flood/off

### $J= Prefix — Jogging

เมื่อบรรทัดขึ้นต้นด้วย `$J=`: เรียก `jog_execute()` เพื่อประมวลผลคำสั่ง Jog

---

## 6. การควบคุมการเคลื่อนที่ (Motion Control)

### `mc_line()` — การเคลื่อนที่แนวเส้นตรง

นี่คือ **gateway หลัก** ของการเคลื่อนที่ทั้งหมดใน GRBL:

1. **ตรวจสอบ Soft Limits** — ถ้าเปิดใช้งานและไม่อยู่ในโหมด Jog
2. **ตรวจสอบ Check Mode** — ถ้าอยู่ใน `STATE_CHECK_MODE` จะไม่มีการเคลื่อนที่จริง
3. **รอให้ Planner Buffer มีพื้นที่ว่าง**:
   ```c
   do {
       protocol_execute_realtime();
       if (sys.abort) return;
       if (plan_check_full_buffer()) protocol_auto_cycle_start();
       else break;
   } while (1);
   ```
4. **ส่งไป Planner**: `plan_buffer_line(target, pl_data)`
5. **Laser Mode**: ถ้าเป็น `PLAN_EMPTY_BLOCK` (ไม่มีการเคลื่อนที่) → sync spindle

### `mc_arc()` — การเคลื่อนที่แนวโค้ง

ใช้อัลกอริทึมประมาณค่าส่วนโค้งวงกลมด้วยเส้นตรงเล็กๆ:

1. **คำนวณมุมการเคลื่อนที่** ด้วย `atan2f()`
2. **คำนวณจำนวนเซกเมนต์** จาก `angular_travel`, `radius`, และค่า `arc_tolerance`
3. **Small-angle Approximation** (อนุกรมเทย์เลอร์อันดับ 3):
   ```
   cos_T = 1 - θ²/2
   sin_T = θ - θ³/6
   ```
4. **Arc Correction**: ทุกๆ `N_ARC_CORRECTION` เซกเมนต์ จะคำนวณใหม่ด้วย `cosf()`/`sinf()` จริงเพื่อแก้ไขความคลาดเคลื่อนสะสม
5. **เรียก `mc_line()`** สำหรับแต่ละเซกเมนต์

### `mc_dwell()` — การหยุดรอ

รอตามเวลาที่กำหนด โดยยังคงประมวลผลคำสั่งเรียลไทม์:
```c
protocol_buffer_synchronize();  // รอให้ buffer ว่าง
delay_sec(seconds, DELAY_MODE_DWELL);  // หน่วงเวลาแบบไม่บล็อก
```

### `mc_homing_cycle()` — การหาจุดศูนย์เครื่อง

1. ปิดการทำงานของ Hard Limits
2. เรียก `limits_go_home()`:
   - **HOMING_CYCLE_0**: แกนตามที่กำหนด (อาจหลายแกนพร้อมกัน) เคลื่อนที่เข้าหาลิมิตสวิตช์ด้วยความเร็ว `homing_seek_rate`
   - **HOMING_CYCLE_1** (ถ้ากำหนด): แกนชุดต่อไป
   - **HOMING_CYCLE_2** (ถ้ากำหนด): แกนชุดต่อไป
   - 

### `mc_reset()` — การรีเซ็ตระบบ

เมื่อเกิด Alarm หรือคำสั่ง Reset:
1. ตั้ง `EXEC_RESET` flag
2. **หยุด Spindle** — `spindle_stop()`
3. **หยุด Coolant** — `coolant_stop()`
4. **หยุด Stepper** — `st_go_idle()` (ถ้ากำลังเคลื่อนที่)
5. ตั้ง Alarm ตามสถานะปัจจุบัน
6. ซิงค์ตำแหน่ง Planner และ G-code parser
7. เปิด Hard Limits อีกครั้ง

### `mc_parking_motion()` — การเคลื่อนที่จอด (Safety Door)

ใช้เมื่อ Safety Door เปิดระหว่างการทำงาน:
- ใช้ระบบ step control แยกจาก planner buffer ปกติ
- `st_parking_setup_buffer()` → `st_prep_buffer()` → `st_wake_up()`
- หลังเสร็จ → `st_parking_restore_buffer()`

### `mc_override_ctrl_update()` — อัพเดท Override Control

เปลี่ยน override state หลังจาก buffer ว่าง (`protocol_buffer_synchronize()`)

---

## 7. ตัววางแผนวิถีการเคลื่อนที่ (Planner)

Planner เป็นหัวใจของระบบ GRBL ใช้ **ring buffer** ในการจัดการบล็อกการเคลื่อนที่

### โครงสร้างข้อมูล

- **`plan_block_t`** — หนึ่งบล็อกการเคลื่อนที่:
  - `steps[N_AXIS]` — จำนวน step ในแต่ละแกน
  - `step_event_count` — จำนวน step events ทั้งหมด
  - `direction_bits` — ทิศทางของแต่ละแกน
  - `nominal_speed` — ความเร็วที่กำหนด (mm/min)
  - `entry_speed` — ความเร็วเมื่อเริ่มบล็อก
  - `max_entry_speed` — ความเร็วสูงสุดที่สามารถเข้าได้
  - `acceleration` — อัตราเร่ง
  - `rapid_motion` — เป็นการเคลื่อนที่เร็ว (G0) หรือไม่
  - `line_number` — หมายเลขบรรทัด (ถ้าเปิดใช้)

- **`plan_line_data_t`** — ข้อมูลขาเข้า:
  - `feed_rate` — อัตราป้อน
  - `spindle_speed` — ความเร็วสปินเดิล
  - `condition` — flags ต่างๆ (ระบบ, laser, coolant, ฯลฯ)

### Ring Buffer

```
block_buffer_head  → ตำแหน่งที่เขียนข้อมูลใหม่
block_buffer_tail  → ตำแหน่งที่ stepper ISR กำลังทำงาน
block_buffer_planned → ตำแหน่งที่วางแผนเสร็จแล้ว (พร้อมให้ stepper)
```

ขนาด: `BLOCK_BUFFER_SIZE = 36` (สำหรับ CH32V307/V203)

### `plan_buffer_line()` — ใส่บล็อกเข้าบัฟเฟอร์

1. **คำนวณ step counts**: `target_steps = target_mm * steps_per_mm`
2. **คำนวณทิศทาง**: บวก = 0, ลบ = 1
3. **คำนวณ unit vector** (เวกเตอร์หนึ่งหน่วย)
4. **คำนวณ nominal speed**: จาก feed rate และ unit vector
5. **กำหนด maximum entry speed**: อิงจาก:
   - Junction deviation (`junction_deviation`)
   - การประมาณความเร่งสู่ศูนย์กลาง (centripetal acceleration)
   - จุดตัดระหว่างเส้นตรงสองเส้น
6. **เรียก `planner_recalculate()`** — คำนวณ velocity profile ใหม่ทั้ง buffer

### `planner_recalculate()` — Backward + Forward Pass

#### Reverse Pass (ย้อนกลับ)

เริ่มจากบล็อกสุดท้าย → บล็อกแรก:
- บล็อกสุดท้าย: `entry_speed = 0` (ต้องหยุด)
- สำหรับแต่ละบล็อก: `entry_speed = min(max_entry_speed, next_entry_speed_after_deceleration)`

```
block[N-1] ← entry=0
block[N-2] ← entry = min(max_entry, sqrt(v_next² + 2*a*d))
...
block[0]
```

#### Forward Pass (เดินหน้า)

เริ่มจากบล็อกแรก → บล็อกสุดท้าย:
- บล็อกแรก: `entry_speed = 0`
- ปรับปรุง `entry_speed` ให้ดีขึ้น (เร่งได้มากขึ้นถ้าบล็อกถัดไปรับได้)
- กำหนดจุดเปลี่ยนความเร็ว (cruise-deceleration, acceleration-cruise)

### ประเภทของ Velocity Profile

หลังจากวางแผนแล้ว แต่ละบล็อกจะมีหนึ่งใน 7 รูปแบบ:
1. **Acceleration only** — เร่งอย่างเดียว (ไม่ถึง cruise)
2. **Cruise only** — ความเร็วคงที่อย่างเดียว
3. **Deceleration only** — ลดความเร็วอย่างเดียว
4. **Full Trapezoid** — เร่ง → cruise → ลด
5. **Triangle** — เร่ง → ลด (ไม่มี cruise)
6. **Cruise-Deceleration** — cruise → ลด
7. **Acceleration-Cruise** — เร่ง → cruise

---

## 8. ตัวขับสเต็ปเปอร์ (Stepper)

### สถาปัตยกรรม

Stepper module ทำงานผ่าน **Timer Interrupt (TIM2)**:

```
Planner Ring Buffer → Segment Buffer (10 segments) → TIM2 ISR → GPIO Pins → Stepper Drivers
            ↑                                            ↓
            └──── st_prep_buffer() ←─────────────── TIM3 ISR (step pulse reset)
```

### Segment Buffer

ขนาด: `SEGMENT_BUFFER_SIZE = 10` (สำหรับ CH32V307/V203)

segment buffer เป็นบัฟเฟอร์ระดับกลางระหว่าง planner และ stepper ISR:
- Planner ทำงานในหน่วย **blocks** (ทั้งเส้น)
- Stepper ISR ทำงานในหน่วย **segments** (ส่วนของการเร่ง/ลดความเร็ว)
- แต่ละ segment มีจำนวน step events และอัตราการเปลี่ยนความเร็ว

### `TIM2_IRQHandler` — Stepper ISR

นี่คือ ISR สำคัญที่สุดของ GRBL ทำงานทุกๆ step pulse cycle:

#### Bresenham Algorithm

ใช้หลักการเดียวกับการวาดเส้นบนจอภาพ แต่ขยายเป็นหลายแกน:

```c
for (แต่ละแกน) {
    counter[axis] += steps[axis];
    if (counter[axis] >= step_event_count) {
        counter[axis] -= step_event_count;
        ตั้ง step pin = HIGH;
    }
}
step_event_count++;
```

#### AMASS (Adaptive Multi-Axis Step Smoothing)

เมื่อความถี่ step ต่ำ AMASS จะแบ่ง step pulse ออกเป็นหลาย pulse ย่อยๆ (up to `ACCELERATION_TICKS_PER_SECOND/500`) เพื่อลดการสั่นสะเทือน:

```
ไม่มี AMASS:  ▐████████████████████████▌
มี AMASS:     ▐███▌  ▐███▌  ▐███▌  ▐███▌
```

#### TIM3 — Step Pulse Reset

TIM3 จับเวลาความกว้างของ step pulse (`pulse_microseconds`):
- `TIM3_IRQHandler` → reset step pin → DISABLE TIM3

### `st_prep_buffer()` — เตรียม Segment Buffer

ฟังก์ชันนี้ทำงานใน main loop คำนวณ segment จาก planner block:

1. **วิเคราะห์ velocity profile** ของบล็อกปัจจุบัน
2. **คำนวณความยาวของแต่ละเฟส**:
   - `accelerate_until`
   - `decelerate_after`
   - `cruise_until` (ถ้ามี cruise)
3. **คำนวณความเร็วที่แต่ละ segment**:
   - ช่วงเร่ง: `v = sqrt(v_start² + 2*a*d)`
   - ช่วง cruise: `v = v_cruise`
   - ช่วงลด: `v = sqrt(v_end² + 2*a*d_remaining)`
4. **คำนวณจำนวน step events ต่อ segment**
5. **คำนวณค่า prescaler สำหรับ TIM2** เพื่อสร้างความถี่ step ที่ถูกต้อง

### ฟังก์ชันที่สำคัญ

- `st_wake_up()` — เปิด stepper drivers, enable TIM2 interrupt
- `st_go_idle()` — หยุด stepper (หรือปล่อยให้ idle ตาม `stepper_idle_lock_time`)
- `st_reset()` — รีเซ็ต segment buffer, หยุด TIM2
- `st_generate_step_dir_invert_masks()` — สร้าง mask สำหรับ invert step/direction pins
- `st_get_realtime_rate()` — คืนค่าความเร็วปัจจุบัน (ใช้ในการรายงาน)

### `stepper_init()` — การตั้งค่าเริ่มต้น

1. ตั้งค่า GPIO สำหรับ step/direction/enable pins
2. ตั้งค่า TIM2 สำหรับ stepper pulse generation (ความถี่ ~100kHz)
3. ตั้งค่า TIM3 สำหรับ step pulse width
4. ตั้งค่า NVIC priority: TIM2 = ระดับ 0 (สูงสุด), TIM3 = ระดับ 1

---

## 9. การควบคุมสปินเดิล (Spindle Control)

### โครงสร้าง

- **Variable Spindle**: ใช้ TIM1 PWM (CH32V307) หรือ Timer PWM (AVR) ควบคุมความเร็ว
- **Non-Variable Spindle**: เปิด/ปิด + ทิศทาง (CW/CCW)

### การตั้งค่าเริ่มต้น `spindle_init()`

- ตั้งค่า GPIO: `SPINDLE_DIRECTION_BIT`, `SPINDLE_ENABLE_BIT`, `SPINDLE_PWM_BIT`
- ตั้งค่า TIM1 สำหรับ PWM:
  - Prescaler: `F_CPU / 1000000 - 1` → 1 MHz
  - Period: `SPINDLE_PWM_MAX_VALUE - 1`
  - OC Mode: `TIM_OCMode_PWM1`
- หยุด spindle

### การคำนวณ PWM

`spindle_compute_pwm_value(float rpm)`:

**Linear Model** (ค่าเริ่มต้น):
```
ถ้า rpm >= rpm_max: pwm = PWM_MAX
ถ้า rpm <= rpm_min: 
    rpm == 0: pwm = PWM_OFF (สปินเดิลปิด)
    rpm > 0:  pwm = PWM_MIN
อื่นๆ: pwm = (rpm - rpm_min) * pwm_gradient + PWM_MIN
```

**Piecewise Linear Model** (ถ้าเปิดใช้ `ENABLE_PIECEWISE_LINEAR_SPINDLE`):
- แบ่งช่วง RPM ออกเป็น 2-4 ช่วง
- แต่ละช่วงมีสมการเส้นตรงของตัวเอง: `pwm = slope * rpm - intercept`
- ให้ความแม่นยำสูงกว่าสำหรับ spindle ที่มีลักษณะ nonlinear

### ฟังก์ชันที่สำคัญ

- `spindle_set_state(state, rpm)` — ตั้งค่าสถานะ (CW/CCW/OFF) และความเร็ว
- `spindle_set_speed(pwm_value)` — ตั้งค่า PWM โดยตรง (เรียกจาก stepper ISR)
- `spindle_stop()` — หยุดสปินเดิล
- `spindle_sync(state, rpm)` — sync + set state (ใช้จาก gcode parser)
- `spindle_get_state()` — อ่านสถานะปัจจุบัน

### Laser Mode

เมื่อเปิด `BITFLAG_LASER_MODE`:
- Spindle PWM จะเปลี่ยนตามความเร็วการเคลื่อนที่ (สำหรับ laser engraving)
- CCW → ตั้ง RPM = 0
- `mc_line()` จะ sync spindle แม้ไม่มีคำสั่ง M3/M4 เมื่อมี `PL_COND_FLAG_SPINDLE_CW`

---

## 10. การควบคุมน้ำหล่อเย็น (Coolant Control)

โมดูลนี้เรียบง่าย ควบคุม 2 พิน:

- **Flood Coolant** (M8) — `COOLANT_FLOOD_BIT`
- **Mist Coolant** (M7) — `COOLANT_MIST_BIT` (ถ้าเปิดใช้ `ENABLE_M7`)

### ฟังก์ชัน

- `coolant_init()` — ตั้งค่า GPIO (Push-Pull Output)
- `coolant_set_state(mode)` — เปิด/ปิดตาม mode (มี flag `COOLANT_FLOOD_ENABLE`, `COOLANT_MIST_ENABLE`)
- `coolant_stop()` — ปิดทั้งหมด
- `coolant_get_state()` — อ่านสถานะปัจจุบัน
- `coolant_sync(mode)` — sync + set state (ใช้จาก gcode parser)

รองรับ `INVERT_COOLANT_FLOOD_PIN` และ `INVERT_COOLANT_MIST_PIN`

---

## 11. ลิมิตสวิตช์และการหาจุดศูนย์ (Limits & Homing)

### `limits_init()` — การตั้งค่าเริ่มต้น

1. ตั้งค่า GPIO เป็น input (pull-up หรือ floating)
2. ถ้า Hard Limits เปิด:
   - ตั้งค่า EXTI (External Interrupt) สำหรับแต่ละพินลิมิต
   - ตั้งค่า NVIC: `EXTI15_10_IRQn`, priority 2, sub-priority 2
3. ถ้า Hard Limits ปิด → `limits_disable()`

### `EXTI15_10_IRQHandler` — Hard Limit ISR

เมื่อลิมิตสวิตช์ทริก:
1. Clear EXTI pending bits สำหรับทุกแกน
2. ถ้าไม่อยู่ในสถานะ ALARM:
   - `mc_reset()` — หยุดระบบ
   - `system_set_exec_alarm(EXEC_ALARM_HARD_LIMIT)`

### `limits_get_state()`

อ่านสถานะลิมิตสวิตช์ทั้งหมด คืนค่าเป็น bitmask:
- bit 0 = X, bit 1 = Y, bit 2 = Z, bit 3 = A, ฯลฯ
- คำนึงถึง `INVERT_LIMIT_PIN_MASK` และ `BITFLAG_INVERT_LIMIT_PINS`

### `limits_go_home()` — วงจร Homing (ละเอียด)

**ภาพรวม**: Homing คือการหาตำแหน่งศูนย์เครื่องโดยใช้ลิมิตสวิตช์

#### จำนวนรอบ

```
n_cycle = 2 * N_HOMING_LOCATE_CYCLE + 1
```
เช่น ถ้า `N_HOMING_LOCATE_CYCLE = 1`:
- รอบ 1: Approach (เข้าหาลิมิต, เร็ว seek)
- รอบ 2: Pull-off (ถอยออก, เร็ว seek)
- รอบ 3: Approach อีกครั้ง (เข้าหาลิมิต, ช้า feed) ← แม่นยำ

#### การทำงานแต่ละรอบ

1. **กำหนดทิศทาง** — ตาม `homing_dir_mask`, สลับทิศระหว่าง approach/pull-off
2. **คำนวณระยะทาง**:
   - รอบแรก: `max_travel * HOMING_AXIS_SEARCH_SCALAR (1.5)`
   - รอบต่อมา: `homing_pulloff * HOMING_AXIS_LOCATE_SCALAR (5.0)` หรือ `homing_pulloff`
3. **คำนวณความเร็ว**:
   - Approach: `homing_seek_rate` หรือ `homing_feed_rate`
   - Pull-off: `homing_seek_rate`
4. **Axis Lock**: ใช้ `sys.homing_axis_lock` เพื่อหยุดแกนทีละแกนเมื่อแตะลิมิต
5. **เริ่มเคลื่อนที่**: `plan_buffer_line()` → `st_prep_buffer()` → `st_wake_up()`
6. **Polling loop**: ตรวจสอบลิมิต, เติม segment buffer, ตรวจสอบ abort
7. **หยุดเมื่อทุกแกนแตะลิมิต**: `st_reset()` + หน่วงเวลา `homing_debounce_delay`
8. **กลับทิศทาง** → รอบต่อไป

#### การตั้งค่าตำแหน่งศูนย์

หลัง homing เสร็จ:
- `sys_position[idx]`: ขึ้นกับทิศทางของลิมิตและ `homing_pulloff`
- ถ้า `HOMING_FORCE_SET_ORIGIN`: ตั้งเป็น 0 ทุกแกน

### `limits_soft_check()` — ตรวจสอบ Soft Limits

ตรวจสอบว่า target อยู่ภายใน `max_travel` (ค่าลบ):
- ถ้าเกิน → `sys.soft_limit = true`
- ถ้าอยู่ใน CYCLE: feed hold → รอ IDLE → alarm
- `mc_reset()` + `EXEC_ALARM_SOFT_LIMIT`

---

## 12. โพรบ (Probe)

### `probe_init()` — การตั้งค่าเริ่มต้น

ตั้งค่า GPIO เป็น input พร้อม pull-up

### หลักการทำงานของ Probe Invert Mask

```c
probe_invert_mask = 0;
if (!BITFLAG_INVERT_PROBE_PIN) probe_invert_mask ^= PROBE_MASK;  // normal-high → invert
if (is_probe_away) probe_invert_mask ^= PROBE_MASK;               // probe away → invert อีกครั้ง
```

### `probe_get_state()`

อ่านค่าพิน probe แล้ว XOR กับ `probe_invert_mask`:
- `true` = probe triggered (แตะชิ้นงาน)

### `probe_state_monitor()` — เรียกจาก Stepper ISR

ทุกๆ step pulse ISR tick:
```c
if (probe_get_state()) {
    sys_probe_state = PROBE_OFF;
    memcpy(sys_probe_position, sys_position, sizeof(sys_position));  // บันทึกตำแหน่ง
    bit_true(sys_rt_exec_state, EXEC_MOTION_CANCEL);  // ยกเลิกการเคลื่อนที่
}
```

### `mc_probe_cycle()` — วงจร Probe

1. `protocol_buffer_synchronize()` — รอ buffer ว่าง
2. ตั้งค่า `probe_invert_mask` ตามทิศทาง
3. ตรวจสอบว่า probe ยังไม่ถูกทริกก่อนเริ่ม
4. `mc_line(target, pl_data)` — ส่งคำสั่งเคลื่อนที่
5. ตั้ง `sys_probe_state = PROBE_ACTIVE` — เริ่มมอนิเตอร์
6. `system_set_exec_state_flag(EXEC_CYCLE_START)` — เริ่มเคลื่อนที่
7. รอจนกว่า `sys.state == STATE_IDLE` (probe ทริก หรือถึงปลายทาง)
8. ตรวจสอบผลลัพธ์:
   - PROBE_ACTIVE → probe ไม่ทริก → error (หรือ success ถ้า `is_no_error`)
   - PROBE_OFF → probe ทริก → success
9. `st_reset()` + `plan_reset()` — ล้าง buffer
10. รายงานตำแหน่ง probe (`[PRB:...]`)

---

## 13. การจ็อก (Jogging)

### `jog_execute()` — [jog.c](file:///d:/MyCode/grbl/grbl_ch32v307/6-AXIS-CH32V307-GRBL/grbl/jog.c)

การจ็อกเป็นการเคลื่อนที่แบบ manual ผ่านคำสั่ง `$J=`:

1. ตั้ง feed rate จาก G-code block
2. ตั้ง `PL_COND_FLAG_NO_FEED_OVERRIDE` — ไม่ใช้ feed override ระหว่าง jog
3. ตรวจสอบ Soft Limits (ถ้าเปิด)
4. `mc_line(target, pl_data)` — ส่งไป planner
5. ถ้าสถานะเป็น IDLE → เปลี่ยนเป็น STATE_JOG → `st_prep_buffer()` → `st_wake_up()`

**หมายเหตุ**: Jog ใช้ planner และ stepper ปกติ ต่างจาก G-code ปกติตรงที่ไม่ใช้ feed override

---

## 14. ระบบสถานะ (System)

### `system.h` — นิยามสถานะและ flags

#### States (สถานะหลัก)

```c
STATE_IDLE         = 0   // พร้อมทำงาน
STATE_ALARM        = 1   // สัญญาณเตือน
STATE_CHECK_MODE   = 2   // โหมดตรวจสอบ
STATE_HOMING       = 3   // กำลังหาจุดศูนย์
STATE_CYCLE        = 4   // กำลังทำงาน (CYCLE)
STATE_HOLD         = 5   // หยุดชั่วคราว (Feed Hold)
STATE_JOG          = 6   // กำลัง Jog
STATE_SAFETY_DOOR  = 7   // Safety Door เปิด
STATE_SLEEP        = 8   // โหมดหลับ
```

#### Executor Flags (flags สำหรับคำสั่งเรียลไทม์)

```c
EXEC_STATUS_REPORT  // ?   - รายงานสถานะ
EXEC_CYCLE_START    // ~   - เริ่มทำงาน
EXEC_FEED_HOLD      // !   - หยุดชั่วคราว
EXEC_RESET          // ctrl-x - รีเซ็ต
EXEC_SAFETY_DOOR    // 0x84 - Safety Door
EXEC_MOTION_CANCEL  // 0x85 - ยกเลิก jog
EXEC_ALARM          // สัญญาณเตือน
EXEC_SLEEP          // 0x86 - เข้าโหมดหลับ
```

#### Override Flags

- **Feed Override**: `EXEC_FEED_OVR_RESET/COARSE_PLUS/COARSE_MINUS/FINE_PLUS/FINE_MINUS`
- **Rapid Override**: `EXEC_RAPID_OVR_RESET/MEDIUM/LOW`
- **Spindle Override**: `EXEC_SPINDLE_OVR_RESET/COARSE_PLUS/COARSE_MINUS/FINE_PLUS/FINE_MINUS/STOP`
- **Coolant Override**: `EXEC_COOLANT_FLOOD_OVR_TOGGLE`, `EXEC_COOLANT_MIST_OVR_TOGGLE`

### `system_t` — โครงสร้างข้อมูลสถานะ

```c
typedef struct {
    uint8_t state;               // สถานะปัจจุบัน
    volatile uint8_t abort;      // สัญญาณยกเลิก
    volatile uint8_t suspend;    // สถานะ suspend (safety door, etc.)
    bool soft_limit;             // soft limit ถูกทริก
    uint8_t step_control;        // การควบคุม step (ปกติ, homing, parking)
    uint8_t f_override;          // feed override (100 = 100%)
    uint8_t r_override;          // rapid override
    uint8_t spindle_speed_ovr;   // spindle speed override (100 = 100%)
    float spindle_speed;
    int32_t position[N_AXIS];    // ตำแหน่งปัจจุบัน (steps)
    uint32_t probe_position[N_AXIS]; // ตำแหน่งที่ probe ทริก
    bool probe_succeeded;
    uint16_t homing_axis_lock;   // axis lock mask ระหว่าง homing
    uint8_t override_ctrl;       // override control state
    uint8_t report_ovr_counter;
    uint8_t report_wco_counter;
} system_t;
```

### `system_execute_line()` — คำสั่งระบบ

ประมวลผลคำสั่งที่ขึ้นต้นด้วย `$`:

| คำสั่ง | ความหมาย |
|--------|----------|
| `$` | แสดง help |
| `$$` | แสดงการตั้งค่า |
| `$#` | แสดง NGC parameters (G54-G59, G92, TLO, PRB) |
| `$G` | แสดงสถานะ G-code parser |
| `$I` | แสดง build info |
| `$N` | แสดง startup lines |
| `$N0=` | ตั้ง startup line 0 |
| `$N1=` | ตั้ง startup line 1 |
| `$x=val` | ตั้งค่า setting x |
| `$C` | ตรวจสอบ G-code (check mode) |
| `$X` | ปลดล็อก alarm |
| `$H` | รัน homing cycle |
| `$SLP` | เข้าโหมด sleep |
| `$RST=$` | รีเซ็ต settings เป็นค่าเริ่มต้น |
| `$RST=#` | ล้าง coordinate offsets |
| `$RST=*` | รีเซ็ตทั้งหมด |
| `$J=` | Jogging |

### ฟังก์ชันจัดการสถานะ

- `system_set_exec_state_flag()` / `system_clear_exec_state_flag()` — ตั้ง/ล้าง execution flags
- `system_set_exec_alarm()` — ตั้ง alarm
- `system_set_exec_motion_override_flag()` — ตั้ง motion override
- `system_set_exec_accessory_override_flag()` — ตั้ง accessory override
- `system_convert_array_steps_to_mpos()` — แปลง steps → mm
- `system_check_travel_limits()` — ตรวจสอบ soft limits

---

## 15. การตั้งค่าและ EEPROM (Settings & EEPROM)

### โครงสร้าง `settings_t` — [settings.h](file:///d:/MyCode/grbl/grbl_ch32v307/6-AXIS-CH32V307-GRBL/grbl/settings.h)

```c
typedef struct {
    float steps_per_mm[N_AXIS];     // จำนวน step ต่อ mm (แกนละค่า)
    float max_rate[N_AXIS];         // ความเร็วสูงสุด mm/min
    float acceleration[N_AXIS];     // อัตราเร่ง mm/sec² (ภายในใช้ mm/min²)
    float max_travel[N_AXIS];       // ระยะสูงสุด (ค่าเป็นลบ)
    
    uint8_t pulse_microseconds;     // ความกว้าง step pulse (μs)
    uint16_t step_invert_mask;      // กลับขั้ว step
    uint16_t dir_invert_mask;       // กลับขั้วทิศทาง
    uint8_t stepper_idle_lock_time; // เวลาก่อน disable stepper (ms, 255=ไม่ปิด)
    uint8_t status_report_mask;     // กำหนดข้อมูลในรายงานสถานะ
    float junction_deviation;       // ค่า junction deviation
    float arc_tolerance;            // ความคลาดเคลื่อนของส่วนโค้ง
    
    float rpm_max;                  // RPM สูงสุด
    float rpm_min;                  // RPM ต่ำสุด
    
    uint8_t flags;                  // boolean flags ต่างๆ
    uint16_t homing_dir_mask;       // ทิศทาง homing
    float homing_feed_rate;         // ความเร็ว homing ช้า
    float homing_seek_rate;         // ความเร็ว homing เร็ว
    uint16_t homing_debounce_delay; // หน่วงเวลาหลัง homing
    float homing_pulloff;           // ระยะถอยหลัง
} settings_t;
```

### Flag Bits

| Bit | Flag | ความหมาย |
|-----|------|----------|
| 0 | `BITFLAG_REPORT_INCHES` | รายงานเป็นนิ้ว |
| 1 | `BITFLAG_LASER_MODE` | โหมดเลเซอร์ |
| 2 | `BITFLAG_INVERT_ST_ENABLE` | กลับขั้ว stepper enable |
| 3 | `BITFLAG_HARD_LIMIT_ENABLE` | เปิด hard limits |
| 4 | `BITFLAG_HOMING_ENABLE` | เปิด homing |
| 5 | `BITFLAG_SOFT_LIMIT_ENABLE` | เปิด soft limits |
| 6 | `BITFLAG_INVERT_LIMIT_PINS` | กลับขั้วลิมิต |
| 7 | `BITFLAG_INVERT_PROBE_PIN` | กลับขั้ว probe |

### การจัดเก็บใน Flash/EEPROM

**CH32V307/V203RBT6** ใช้ Flash แทน EEPROM:
- `EEPROM_START_ADDRESS = 0x0800F000` — เริ่มที่ 60KB ใน Flash
- `PAGE_SIZE = 4096` (V307) หรือ `1024` (V203) — ขนาด EE_Buffer
- `HW_ERASE_PAGE_SIZE = 256` (V203 D8 series) — ขนาดหน้า Flash จริงสำหรับ `FLASH_ErasePage_Fast`
- `EE_Buffer[]` — buffer ใน RAM สำหรับ settings

#### การทำงานของ EEPROM emulation:

1. **Init**: อ่าน Flash ทั้งหน้า → `EE_Buffer[]`
   - ถ้า version ไม่ตรง → ล้าง EE_Buffer เป็น 0xFF
2. **Read**: `EE_Buffer[addr]` — อ่านจาก RAM
3. **Write**: `EE_Buffer[addr] = value` — เขียนใน RAM
4. **Flush**: ลบ Flash page(s) → เขียนเฉพาะข้อมูลที่ไม่ใช่ 0xFFFF แบบ half-word
   - V307: `FLASH_ErasePage()` — ลบ 4KB ทีเดียว
   - V203: `FLASH_ErasePage_Fast()` — ลบทีละ 256 bytes × 4 ครั้ง (รวม 1024 bytes)

#### Checksum

ใช้ rolling checksum 8-bit:
```c
checksum = (checksum << 1) || (checksum >> 7);
checksum += *source;
```

### `settings_init()` — โหลดการตั้งค่า

1. `read_global_settings()` — อ่านจาก EEPROM
2. ถ้าล้มเหลว → `settings_restore(SETTINGS_RESTORE_ALL)` + แสดง settings

### `settings_store_global_setting()` — บันทึกการตั้งค่า

ระบบการกำหนดหมายเลข settings:
- ค่า 0-32: การตั้งค่าทั่วไป (pulse, stepper, limits, homing, spindle)
- ค่า 100+: การตั้งค่าแกน (100=X steps/mm, 110=Y steps/mm, 101=X max rate, ฯลฯ)

---

## 16. การรายงานผล (Report)

### ประเภทข้อความ

1. **Status Message**: `ok` หรือ `error:N`
2. **Alarm Message**: `ALARM:N`
3. **Feedback Message**: `[MSG:...]`
4. **Welcome Message**: `Grbl 1.1f ['$' for help]`

### `report_realtime_status()` — รายงานสถานะเรียลไทม์

รูปแบบ:
```
<สถานะ|WPos:x,y,z|Bf:planner,serial|Ln:N|FS:feed,speed|WCO:x,y,z|Ov:feed,rapid,spindle|A:S,F>
```

ตัวอย่างผลลัพธ์:
```
<Run|WPos:10.000,20.000,5.000|Bf:15,128|FS:500.0,12000>
```

#### ฟิลด์ที่รายงาน

| ฟิลด์ | ความหมาย | เปิดโดย |
|-------|----------|---------|
| `<State>` | สถานะ (Idle, Run, Hold, Jog, Home, Alarm, Check, Door, Sleep) | ตลอด |
| `WPos` | Work Position | `BITFLAG_RT_STATUS_POSITION_TYPE` เป็น 0 |
| `MPos` | Machine Position | `BITFLAG_RT_STATUS_POSITION_TYPE` เป็น 1 |
| `Bf` | Buffer state (planner, serial) | `BITFLAG_RT_STATUS_BUFFER_STATE` |
| `Ln` | Line number | `REPORT_FIELD_LINE_NUMBERS` |
| `FS` | Feed Speed + Spindle Speed | `REPORT_FIELD_CURRENT_FEED_SPEED` |
| `Pn` | Pin state (probe, limits, controls) | `REPORT_FIELD_PIN_STATE` |
| `WCO` | Work Coordinate Offset | `REPORT_FIELD_WORK_COORD_OFFSET` |
| `Ov` | Override values | `REPORT_FIELD_OVERRIDES` |
| `A` | Accessory state (spindle, coolant) | `REPORT_FIELD_OVERRIDES` |

### ฟังก์ชันอื่นๆ

- `report_gcode_modes()` — รายงานสถานะ G-code (`[GC:G0 G54 G17 G21 G90 G94 M5 M9 T0 F0 S0]`)
- `report_grbl_settings()` — รายงานการตั้งค่าทั้งหมด (รูปแบบ `$N=value`)
- `report_ngc_parameters()` — รายงาน G54-G59, G28, G30, G92, TLO, Probe
- `report_probe_parameters()` — `[PRB:x,y,z:1]`
- `report_build_info()` — `[VER:1.1f.20180101:...]` + `[OPT:...]`
- `report_startup_line()` — `$N0=...`
- `report_echo_line_received()` — `[echo: ...]`

---

## 17. ฟังก์ชันพื้นฐาน (Nuts & Bolts)

### `nuts_bolts.h` — นิยามพื้นฐาน

#### การกำหนดจำนวนแกน

```c
#ifdef AA_AXIS:    N_AXIS = 4  (X,Y,Z,A)
#elif AB_AXIS:    N_AXIS = 5  (X,Y,Z,A,B)
#elif ABC_AXIS:   N_AXIS = 6  (X,Y,Z,A,B,C)
#else:            N_AXIS = 3  (X,Y,Z)
```

#### Macros ที่ใช้บ่อย

| Macro | ความหมาย |
|-------|----------|
| `bit(n)` | `1 << n` |
| `bit_true(x,mask)` | `x \|= mask` |
| `bit_false(x,mask)` | `x &= ~mask` |
| `bit_istrue(x,mask)` | `(x & mask) != 0` |
| `bit_isfalse(x,mask)` | `(x & mask) == 0` |
| `clear_vector(a)` | `memset(a, 0, sizeof(a))` |
| `max(a,b)` / `min(a,b)` | ค่าสูงสุด/ต่ำสุด |

#### การแปลงหน่วย

- `MM_PER_INCH = 25.40` — มิลลิเมตรต่อนิ้ว
- `INCH_PER_MM = 0.0393701` — นิ้วต่อมิลลิเมตร
- `TICKS_PER_MICROSECOND = F_CPU/1000000` — CPU ticks ต่อไมโครวินาที

### `read_float()` — อ่านเลขทศนิยม

อัลกอริทึมที่ปรับแต่งให้เร็วสำหรับงาน CNC:
1. เก็บเครื่องหมาย (+/-)
2. อ่านตัวเลขเป็น integer (`intval = intval*10 + digit`)
3. เก็บจำนวนตำแหน่งทศนิยม (`exp` ลดลง)
4. แปลงกลับเป็น float:
   ```c
   while (exp <= -2) { fval *= 0.01f; exp += 2; }
   if (exp < 0) fval *= 0.1f;
   else if (exp > 0) fval *= 10^exp;
   ```
5. ใส่เครื่องหมาย

**ข้อจำกัด**: อ่านได้สูงสุด 8 หลัก (ป้องกัน overflow)

### `delay_sec()` — หน่วงเวลาแบบไม่บล็อก

```c
while (i-- > 0) {
    if (sys.abort) return;
    if (mode == DELAY_MODE_DWELL) protocol_execute_realtime();
    else protocol_exec_rt_system();
    Delay_Ms(DWELL_TIME_STEP);  // 50ms
}
```

### `hypot_f()` — คำนวณด้านตรงข้ามมุมฉาก

```c
return sqrtf(x*x + y*y);
```

### `convert_delta_vector_to_unit_vector()`

1. คำนวณขนาด: `magnitude = sqrt(Σ vector[i]²)`
2. หารแต่ละ component ด้วย magnitude
3. คืนค่า magnitude

### `limit_value_by_axis_maximum()`

หา feed rate สูงสุดที่ทุกแกนไม่เกิน `max_rate`:
```c
limit_value = min(limit_value, fabsf(max_value[idx] / unit_vec[idx]))
```

### `print.c` — ฟังก์ชันการพิมพ์

- `printString(s)` — พิมพ์สตริง
- `print_uint8_base10(n)` — พิมพ์เลข 8-bit (ฐาน 10)
- `print_uint32_base10(n)` — พิมพ์เลข 32-bit (ฐาน 10)
- `printInteger(n)` — พิมพ์เลขมีเครื่องหมาย
- `printFloat(n, decimal_places)` — พิมพ์เลขทศนิยม
- `printFloat_CoordValue(n)` — พิมพ์ค่าพิกัด (mm หรือ inch)
- `printFloat_RateValue(n)` — พิมพ์ค่าความเร็ว (mm หรือ inch)

**เทคนิคการพิมพ์ `printFloat`**: แปลง float → integer โดยคูณด้วย 10^decimal_places, ปัดเศษ, แล้วพิมพ์ตัวเลขทีละหลัก (มีประสิทธิภาพมากกว่า `sprintf`)

---

## 18. แผนผังพิน (CPU Map)

ไฟล์ [cpu_map.h](file:///d:/MyCode/grbl/grbl_ch32v307/6-AXIS-CH32V307-GRBL/grbl/cpu_map.h) กำหนดการแมปพิน แบ่งเป็น 3 ส่วน:

### 1. CPU_MAP_ATMEGA328P — AVR (Arduino Uno)
ใช้ `PORTD`, `PORTB` สำหรับ step/direction/limits/controls

### 2. ABC_AXIS_EXAMPLE — CH32V307 (6-axis)
- **Step/Direction**:
  - X,Y,Z: GPIOE (PE0-PE5)
  - A,B,C: GPIOD (PD0-PD5)
- **Limits** (Hard Limit): GPIOB (PB12-PB14: X,Y,Z), GPIOA (PA4-PA6: A,B,C)
- **Control Pins**: GPIOA (PA0: Reset, PA1: Feed Hold, PA2: Cycle Start, PA3: Safety Door)
- **Spindle**: GPIOA (PA8: PWM, PA11: Direction, PA12: Enable)
- **Coolant**: GPIOC (PC14: Flood, PC15: Mist)
- **Probe**: GPIOB (PB15)

### 3. CH32V203_RBT6_3AXIS — CH32V203 (3-axis)
- **Step/Direction**: GPIOB (X: PB0=Step, PB1=Dir; Y: PB3=Step, PB5=Dir; Z: PB6=Step, PB7=Dir)
- **Limits**: GPIOC (PC10: X, PC11: Y, PC12: Z) — EXTI15_10_IRQn
- **Control Pins**: GPIOA (PA5: Reset, PA6: Feed Hold, PA7: Cycle Start, PA9: Safety Door) — EXTI9_5_IRQn
- **Spindle**: GPIOA (PA8: PWM TIM1_CH1), GPIOD (PD0: Enable, PD1: Direction)
- **Coolant**: GPIOB (PB12: Flood, PB13: Mist)
- **Probe**: GPIOB (PB14)
- **Stepper Disable**: GPIOB (PB8)
- **Serial**: USART2 (PA2: TX, PA3: RX)
- **LED**: GPIOA (PA0: optional, define LEDBLINK)

---

## 19. ไฟล์การตั้งค่า (Config & Defaults)

### `config.h` — การตั้งค่าคอมไพล์ไทม์

| Parameter | ค่าเริ่มต้น | ความหมาย |
|-----------|-------------|----------|
| `BAUD_RATE` | 115200 | ความเร็วสื่อสาร |
| `BLOCK_BUFFER_SIZE` | 36 | จำนวนบล็อกใน planner |
| `SEGMENT_BUFFER_SIZE` | 10 | จำนวน segment |
| `ACCELERATION_TICKS_PER_SECOND` | 100 | ความถี่ AMASS |
| `DWELL_TIME_STEP` | 50 ms | ขั้นตอนการหน่วงเวลา |
| `N_ARC_CORRECTION` | 12 | จำนวน segment ก่อนแก้ไข arc |
| `N_HOMING_LOCATE_CYCLE` | 1 | รอบการ locate homing |

#### Real-time Command Characters

| Character | Hex | คำสั่ง |
|-----------|-----|--------|
| `ctrl-x` | 0x18 | Reset |
| `?` | 0x3F | Status Report |
| `~` | 0x7E | Cycle Start |
| `!` | 0x21 | Feed Hold |
| `0x84` | 132 | Safety Door |
| `0x85` | 133 | Jog Cancel |
| `0x90` | 144 | Feed Override Reset |
| `0x91` | 145 | Feed Override +10% |
| `0x92` | 146 | Feed Override -10% |
| `0x93` | 147 | Feed Override +1% |
| `0x94` | 148 | Feed Override -1% |
| `0x95` | 149 | Rapid Override 100% |
| `0x96` | 150 | Rapid Override 50% |
| `0x97` | 151 | Rapid Override 25% |
| `0x99` | 153 | Spindle Override Reset |
| `0x9A` | 154 | Spindle Override +10% |
| `0x9B` | 155 | Spindle Override -10% |
| `0x9C` | 156 | Spindle Override +1% |
| `0x9D` | 157 | Spindle Override -1% |
| `0x9E` | 158 | Spindle Stop |
| `0xA0` | 160 | Coolant Flood Toggle |

### `defaults.h` — ค่าเริ่มต้นสำหรับเครื่องแต่ละรุ่น

มีชุดค่าเริ่มต้นสำหรับเครื่อง CNC หลายรุ่น:
- **GENERIC**: ค่าพื้นฐาน (250 steps/mm, 500 mm/min, 10 mm/sec²)
- **SHERLINE_5400**: Sherline 5400 mill
- **SHAPEOKO**: Shapeoko CNC
- **X_CARVE**: X-Carve CNC  
- **ABC_AXIS_EXAMPLE**: 6-axis (5120 steps/mm, 800 mm/min)

---

## 20. แผนภาพการไหลของข้อมูล

### Initialization Flow

```
main()
  ├─ system_init()          // ตั้งค่า GPIO, EXTI สำหรับ Control Pins
  ├─ serial_init()          // ตั้งค่า USART2
  ├─ settings_init()        // โหลด settings จาก EEPROM/Flash
  │   └─ read_global_settings()
  │       └─ (ถ้าล้มเหลว) → settings_restore(ALL)
  ├─ stepper_init()         // ตั้งค่า TIM2, TIM3, GPIO step/direction
  ├─ spindle_init()         // ตั้งค่า TIM1 PWM, GPIO spindle
  ├─ coolant_init()         // ตั้งค่า GPIO coolant
  ├─ limits_init()          // ตั้งค่า GPIO limits, EXTI
  ├─ probe_init()           // ตั้งค่า GPIO probe
  ├─ plan_reset()           // รีเซ็ต planner buffer
  ├─ gc_init()              // รีเซ็ต G-code parser
  ├─ report_init_message()  // พิมพ์ข้อความต้อนรับ
  └─ protocol_main_loop()   // เข้าวงวนหลัก
```

### G-code Execution Flow

```
protocol_main_loop():
  serial_read()
    ↓
  [มีตัวอักษร]
    ↓
  ต่อบรรทัด → ถ้าขึ้นด้วย $ → system_execute_line()
    ↓ ถ้าเป็น G-code
  gc_execute_line():
    Step 1: init block, copy modes
    Step 2: parse words (G,M,F,S,X,Y,Z, etc.)
    Step 3: error check
    Step 4: execute
      ├─ motion commands → mc_line()/mc_arc()
      │   └─ plan_buffer_line()
      │       └─ planner_recalculate()
      │           ├─ reverse pass (deceleration)
      │           └─ forward pass (acceleration)
      ├─ spindle → spindle_sync()
      ├─ coolant → coolant_sync()
      ├─ dwell → mc_dwell()
      └─ program flow → M0/M2/M30
    ↓
  report_status_message(ok/error)
```

### Stepper Execution Flow

```
TIM2_IRQHandler (ทุกๆ step cycle):
  ├─ ตรวจสอบ probe state (ถ้า probing)
  │   └─ probe_state_monitor()
  ├─ step_event_count++
  ├─ Bresenham Algorithm:
  │   for each axis:
  │     counter[axis] += steps[axis]
  │     if (counter[axis] >= step_event_count):
  │       counter[axis] -= step_event_count
  │       ตั้ง step pin = HIGH
  │       ตั้ง TIM3 → reset step pin หลัง pulse_microseconds
  ├─ เปลี่ยน segment เมื่อครบ step events:
  │   อ่าน segment ถัดไปจาก segment buffer
  ├─ เปลี่ยน block เมื่อ segment หมด:
  │   st_prep_buffer() → ... (ใน main loop)
  └─ ถ้าไม่มี segment เหลือ → st_go_idle()
```

### Alarm Handling Flow

```
Hard Limit Trigger (EXTI ISR):
  limits_isr()
    ├─ clear EXTI pending
    ├─ mc_reset()
    │   ├─ set EXEC_RESET
    │   ├─ spindle_stop()
    │   ├─ coolant_stop()
    │   ├─ st_go_idle()
    │   └─ set EXEC_ALARM_HARD_LIMIT
    └─ [return to main loop]

Main Loop ตรวจพบ alarm:
  protocol_exec_rt_system()
    ├─ sys_rt_exec_alarm != 0
    ├─ report_alarm_message()
    ├─ mc_reset()
    ├─ plan_reset()
    ├─ gc_init()
    ├─ st_go_idle()
    ├─ spindle_stop()
    ├─ coolant_stop()
    └─ system_set_exec_state_flag(EXEC_ALARM)
        → sys.state = STATE_ALARM

ผู้ใช้ปลดล็อก:
  $X → system_execute_line()
    ├─ system_clear_exec_state_flag(EXEC_ALARM)
    ├─ sys.state = STATE_IDLE
    └─ report_feedback_message("Caution: Unlocked")

หรือ: $H → mc_homing_cycle()
    → เมื่อเสร็จ → sys.state = STATE_IDLE
```

---

## สรุป

GRBL เป็นเฟิร์มแวร์ CNC ที่ได้รับการออกแบบอย่างดีเยี่ยม โดยใช้สถาปัตยกรรมแบบ cooperative multitasking ที่แยกงานระหว่าง foreground (main loop) และ background (interrupt) อย่างชาญฉลาด

**จุดเด่นของ GRBL**:
- **Real-time Performance**: Stepper ISR ทำงานด้วย priority สูงสุด
- **Bresenham Multi-axis**: Synchronize หลายแกนอย่างแม่นยำ
- **AMASS**: ลดการสั่นสะเทือนที่ความเร็วต่ำ
- **Junction Deviation**: คำนวณความเร็วที่จุดต่อระหว่างเส้นตรงเพื่อให้การเคลื่อนที่ราบรื่น
- **Forward/Reverse Pass Planning**: คำนวณ velocity profile ที่เหมาะสมที่สุด
- **State Machine**: จัดการสถานะได้ครอบคลุมทุกกรณี

**การพอร์ตไป CH32V307/V203RBT6**:
- ใช้ Flash emulation แทน EEPROM (ผ่าน `EE_Buffer` + `eeprom_flush()`)
- ใช้ TIM1 สำหรับ spindle PWM (16-bit แทน 8-bit)
- ใช้ TIM2 สำหรับ stepper pulse
- ใช้ TIM3 สำหรับ step pulse timing
- ใช้ EXTI สำหรับ limit switch และ hardware interrupt
- ใช้ USART2 สำหรับการสื่อสาร
- รองรับ USB (CDC) ผ่าน `USEUSB` flag
