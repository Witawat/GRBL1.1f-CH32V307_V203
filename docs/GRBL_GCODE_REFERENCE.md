# GRBL 1.1f — ข้อมูลเวอร์ชันและคำสั่งที่รองรับ

> **โปรเจค**: 6-AXIS-CH32V307-GRBL  
> **MCU**: CH32V307 (RISC-V, 144MHz, FPU)  
> **อัปเดตล่าสุด**: 20 พฤษภาคม 2569

---

## 🔢 ข้อมูลเวอร์ชัน

| รายการ | ค่า |
|--------|-----|
| **GRBL Version** | **1.1f** |
| **Build Date** | **20230112** (12 มกราคม 2566) |
| **Base** | GRBL 1.1f โดย Sungeun K. Jeon (Gnea Research LLC) |
| **License** | GPLv3 |
| **Multi-axis extensions** | โดย YSV (22-06-2018) |
| **CH32V307 Port** | Custom — เพิ่ม `cpu_map.h` + conditional defines สำหรับ CH32V307 |

### GRBL รุ่นล่าสุด

| รายการ | รุ่นที่เราใช้ | รุ่นล่าสุด (Official) |
|--------|--------------|----------------------|
| Version | v1.1f | v1.1h |
| Release | 2017-08-01 | 2019-08-25 |
| สถานะ | เสถียร — ใช้กันแพร่หลาย | Bugfix release — เพิ่ม Dual Motor Gantry |
| ความแตกต่าง | — | น้อยมาก (bug fixes + dual motor) |

> **หมายเหตุ**: GRBL ดั้งเดิม (gnea/grbl) หยุดพัฒนาตั้งแต่ปี 2019 โปรเจคที่พัฒนาต่อคือ [grblHAL](https://github.com/grblHAL) ซึ่งรองรับ MCU 32-bit หลายตัว

---

## 📐 G-Codes ที่รองรับ (35 คำสั่ง)

### Motion Modes (G1)
| คำสั่ง | หน้าที่ | หมายเหตุ |
|--------|--------|---------|
| **G0** | เคลื่อนที่เร็ว (Rapid Positioning) | ความเร็วสูงสุด — ไม่ทำงาน |
| **G1** | เคลื่อนที่แนวตรง (Linear Interpolation) | ใช้ร่วมกับ F (Feed Rate) |
| **G2** | เคลื่อนที่โค้งตามเข็มนาฬิกา (CW Arc) | ใช้ I,J,K หรือ R |
| **G3** | เคลื่อนที่โค้งทวนเข็มนาฬิกา (CCW Arc) | ใช้ I,J,K หรือ R |
| **G38.2** | Probe toward workpiece — error ถ้าไม่เจอ | หยุดเมื่อ Probe แตะ |
| **G38.3** | Probe toward workpiece — ไม่ error | หยุดเมื่อ Probe แตะ |
| **G38.4** | Probe away from workpiece — error ถ้าไม่เจอ | หยุดเมื่อ Probe หลุด |
| **G38.5** | Probe away from workpiece — ไม่ error | หยุดเมื่อ Probe หลุด |
| **G80** | ยกเลิก Motion Mode | ห้ามมี Axis Words |

### Plane Selection (G2)
| คำสั่ง | หน้าที่ |
|--------|--------|
| **G17** | เลือกระนาบ XY (ค่าเริ่มต้น) |
| **G18** | เลือกระนาบ ZX |
| **G19** | เลือกระนาบ YZ |

### Distance Mode (G3)
| คำสั่ง | หน้าที่ |
|--------|--------|
| **G90** | Absolute Distance Mode (ค่าเริ่มต้น) |
| **G91** | Incremental Distance Mode |

### Arc IJK Distance Mode (G4)
| คำสั่ง | หน้าที่ |
|--------|--------|
| **G91.1** | Arc IJK แบบ Incremental (ค่าเริ่มต้น — G90.1 ไม่รองรับ) |

### Feed Rate Mode (G5)
| คำสั่ง | หน้าที่ |
|--------|--------|
| **G93** | Inverse Time Feed Rate Mode |
| **G94** | Units per Minute Feed Rate Mode (ค่าเริ่มต้น) |

### Units (G6)
| คำสั่ง | หน้าที่ |
|--------|--------|
| **G20** | หน่วยเป็นนิ้ว (Inches) |
| **G21** | หน่วยเป็นมิลลิเมตร (ค่าเริ่มต้น) |

### Cutter Radius Compensation (G7)
| คำสั่ง | หน้าที่ | หมายเหตุ |
|--------|--------|---------|
| **G40** | ยกเลิก Cutter Compensation | รับเฉพาะใน Program Header |
| ~~G41~~ | ❌ ไม่รองรับ | Cutter Compensation Left |
| ~~G42~~ | ❌ ไม่รองรับ | Cutter Compensation Right |

### Tool Length Offset (G8)
| คำสั่ง | หน้าที่ | หมายเหตุ |
|--------|--------|---------|
| **G43.1** | Dynamic Tool Length Offset | ใช้คู่กับ H (Tool Number) |
| **G49** | ยกเลิก Tool Length Offset | |
| ~~G43~~ | ❌ ไม่รองรับ | ใช้ G43.1 แทน |

### Coordinate System Selection (G12)
| คำสั่ง | หน้าที่ |
|--------|--------|
| **G54** | ระบบพิกัดงาน 1 (ค่าเริ่มต้น) |
| **G55** | ระบบพิกัดงาน 2 |
| **G56** | ระบบพิกัดงาน 3 |
| **G57** | ระบบพิกัดงาน 4 |
| **G58** | ระบบพิกัดงาน 5 |
| **G59** | ระบบพิกัดงาน 6 |
| ~~G59.x~~ | ❌ ไม่รองรับ Extended Coordinates |

### Path Control Mode (G13)
| คำสั่ง | หน้าที่ | หมายเหตุ |
|--------|--------|---------|
| **G61** | Exact Path Mode (ค่าเริ่มต้น) | |
| ~~G61.1~~ | ❌ ไม่รองรับ | Exact Stop Mode |
| ~~G64~~ | ❌ ไม่รองรับ | Constant Velocity Mode |

### Non-Modal Commands (G0)
| คำสั่ง | หน้าที่ | หมายเหตุ |
|--------|--------|---------|
| **G4** | Dwell (หน่วงเวลา) | ใช้คู่กับ P (วินาที) |
| **G10 L2** | ตั้งค่า Coordinate System Offset | ใช้ P (1-6 = G54-G59) |
| **G10 L20** | ตั้งค่า Coordinate System Offset | ใช้ P (1-6 = G54-G59) |
| **G28** | กลับตำแหน่ง Home 0 | มี Intermediate Motion ได้ |
| **G28.1** | ตั้งตำแหน่ง Home 0 | เก็บพิกัดปัจจุบัน |
| **G30** | กลับตำแหน่ง Home 1 | มี Intermediate Motion ได้ |
| **G30.1** | ตั้งตำแหน่ง Home 1 | เก็บพิกัดปัจจุบัน |
| **G53** | Machine Coordinate System | ใช้กับ G0/G1 เท่านั้น |
| **G92** | ตั้ง Offset ชั่วคราว | |
| **G92.1** | รีเซ็ต G92 Offset | |

---

## 🛠️ M-Codes ที่รองรับ (9 คำสั่ง)

### Program Flow (M4)
| คำสั่ง | หน้าที่ | หมายเหตุ |
|--------|--------|---------|
| **M0** | หยุดโปรแกรม (Program Pause) | ต้องกด Cycle Start เพื่อทำต่อ |
| **M1** | Optional Stop | ยอมรับคำสั่งแต่ไม่ทำอะไร |
| **M2** | จบโปรแกรม + Reset | กลับสู่ค่าเริ่มต้น |
| **M30** | จบโปรแกรม + Reset | เหมือน M2 |

### Spindle Control (M7)
| คำสั่ง | หน้าที่ | หมายเหตุ |
|--------|--------|---------|
| **M3** | เปิด Spindle ตามเข็มนาฬิกา (CW) | ใช้ร่วมกับ S (RPM) |
| **M4** | เปิด Spindle ทวนเข็มนาฬิกา (CCW) | ใช้ร่วมกับ S (RPM) |
| **M5** | ปิด Spindle | |

### Coolant Control (M8)
| คำสั่ง | หน้าที่ | หมายเหตุ |
|--------|--------|---------|
| **M7** | เปิด Mist Coolant | ต้องเปิด `ENABLE_M7` ใน config.h |
| **M8** | เปิด Flood Coolant | |
| **M9** | ปิด Coolant ทั้งหมด | |

### Override Control (M9)
| คำสั่ง | หน้าที่ | หมายเหตุ |
|--------|--------|---------|
| **M56** | Parking Motion Override | ต้องเปิด `ENABLE_PARKING_OVERRIDE_CONTROL` |

---

## 📝 Parameter Words

| ตัวอักษร | หน้าที่ | หมายเหตุ |
|----------|--------|---------|
| **F** | Feed Rate | mm/min หรือ Inverse Time |
| **I** | Arc Center Offset X | |
| **J** | Arc Center Offset Y | |
| **K** | Arc Center Offset Z | |
| **L** | G10 Parameter | |
| **N** | Line Number | ติดตามแต่ไม่บังคับ |
| **P** | Dwell Time / G10 Offset | วินาที (G4) / Coordinate (G10) |
| **R** | Arc Radius | ใช้แทน I,J,K ได้ |
| **S** | Spindle Speed | RPM |
| **T** | Tool Number | ติดตามค่าแต่ไม่เปลี่ยน Tool |
| **X** | X Axis Position | |
| **Y** | Y Axis Position | |
| **Z** | Z Axis Position | |
| **A** | A Axis Position | เมื่อเปิด AA_AXIS / AB_AXIS / ABC_AXIS |
| **B** | B Axis Position | เมื่อเปิด AB_AXIS / ABC_AXIS |
| **C** | C Axis Position | เมื่อเปิด ABC_AXIS |

---

## ⚡ Real-Time Commands (22 คำสั่ง)

คำสั่งเหล่านี้ทำงาน**ทันที**โดยไม่ต้องรอคิว — ส่งเป็นตัวอักษรเดี่ยวผ่าน Serial

### คำสั่งพื้นฐาน (6 คำสั่ง)
| คำสั่ง | ตัวอักษร/ASCII | หน้าที่ |
|--------|---------------|--------|
| Status Report | **`?`** (0x3F) | ถามสถานะปัจจุบันของเครื่อง |
| Feed Hold | **`!`** (0x21) | หยุดการเคลื่อนที่ชั่วคราว |
| Cycle Start | **`~`** (0x7E) | เริ่มหรือทำต่อจาก Feed Hold |
| Reset | **Ctrl+X** (0x18) | รีเซ็ตฉุกเฉิน — ล้างคิวทั้งหมด |
| Safety Door | 0x84 | เปิด Safety Door — หยุด+de-energize |
| Jog Cancel | 0x85 | ยกเลิก Jog ที่กำลังทำงาน |

### Feed Override (5 คำสั่ง)
| ASCII | หน้าที่ |
|-------|--------|
| 0x90 | รีเซ็ต Feed Override → 100% |
| 0x91 | เพิ่ม Feed ~10% |
| 0x92 | ลด Feed ~10% |
| 0x93 | เพิ่ม Feed ~1% |
| 0x94 | ลด Feed ~1% |

### Rapid Override (3 คำสั่ง)
| ASCII | หน้าที่ |
|-------|--------|
| 0x95 | รีเซ็ต Rapid Override → 100% |
| 0x96 | Rapid → ~50% |
| 0x97 | Rapid → ~25% |

### Spindle Override (6 คำสั่ง)
| ASCII | หน้าที่ |
|-------|--------|
| 0x99 | รีเซ็ต Spindle Override → 100% |
| 0x9A | เพิ่ม Spindle ~10% |
| 0x9B | ลด Spindle ~10% |
| 0x9C | เพิ่ม Spindle ~1% |
| 0x9D | ลด Spindle ~1% |
| 0x9E | หยุด Spindle ทันที |

### Coolant Override (2 คำสั่ง)
| ASCII | หน้าที่ |
|-------|--------|
| 0xA0 | เปิด/ปิด Flood Coolant (M8) |
| 0xA1 | เปิด/ปิด Mist Coolant (M7) — ถ้าเปิดใช้งาน |

---

## 🚫 คำสั่งที่ไม่รองรับ

| คำสั่ง/ฟีเจอร์ | หมายเหตุ |
|----------------|---------|
| **G41, G42** | Cutter Radius Compensation — ไม่มี |
| **G43** | Tool Length Offset แบบปกติ — ใช้ G43.1 แทน |
| **G59.x** | Extended Coordinate Systems |
| **G61.1** | Exact Stop Mode |
| **G64** | Constant Velocity Mode |
| **G81–G89** | Canned Cycles (เจาะ/คว้าน/ทำเกลียว) |
| **G90.1** | Arc IJK Absolute Mode |
| **M6** | Tool Change — T parameter ติดตามค่าแต่ไม่เปลี่ยน Tool |
| **`%`** | Program Start/End — ไม่มี auto-cycle-start |
| **`/`** | Block Delete |
| **`(` `)`** | Comments ในวงเล็บ — ไม่รองรับ |
| **`;`** | Comments หลังเซมิโคลอน — ไม่รองรับ |
| **Expressions** | `#1=...` หรือ `[1+2]` — ไม่มี Macro |
| **Variables** | `#1`–`#99` — ไม่รองรับ |
| **Subroutines** | `M98`, `M99` — ไม่รองรับ |

---

## 🌟 ส่วนขยายพิเศษ (เหนือ GRBL 1.1f มาตรฐาน)

| ฟีเจอร์ | คำอธิบาย |
|---------|----------|
| **6 แกน** | รองรับ X, Y, Z, A, B, C — config ได้ 3/4/5/6 แกนผ่าน `AA_AXIS` / `AB_AXIS` / `ABC_AXIS` |
| **Jog** | `$J=G91 X10 Y5 F100` — Jog แบบ Linear ผ่านคำสั่ง `$J=` |
| **G43.1** | Dynamic Tool Length Offset — ตั้ง offset ต่อแกน |
| **6 ระบบพิกัด** | G54–G59 — เก็บ offset ทุกแกนอย่างถาวรใน EEPROM |
| **Probe 4 โหมด** | G38.2/3/4/5 — toward/away × error/no-error |
| **Safety Door** | หยุด + de-energize spindle/coolant อัตโนมัติ + parking motion |
| **Parking Motion** | M56 + auto-parking เมื่อ Safety Door เปิด |
| **M7 Mist** | Coolant แบบละออง — แยก pin จาก M8 |
| **Nonlinear Spindle** | PWM แบบไม่เชิงเส้น — calibrate ได้ |
| **Laser Mode** | Dynamic Laser Power — ปรับกำลังตามความเร็ว (M4) |
| **Sleep Mode** | `$SLP` — ปิดทุกอย่าง ประหยัดไฟ |

---

## 📊 System Commands (`$`)

| คำสั่ง | หน้าที่ |
|--------|--------|
| `$` | แสดง Settings ทั้งหมด |
| `$0`–`$132` | แสดง/ตั้งค่า Setting แต่ละตัว |
| `$G` | แสดง G-code Parser State |
| `$I` | แสดง Build Info (Version, Options, Buffer sizes) |
| `$N` | แสดง Startup Blocks |
| `$N0=...` | ตั้งค่า Startup Block 0 |
| `$N1=...` | ตั้งค่า Startup Block 1 |
| `$C` | Check Mode — ตรวจสอบ G-code โดยไม่ขยับมอเตอร์ |
| `$X` | Kill Alarm Lock — ปลดล็อคหลัง Alarm |
| `$H` | Run Homing Cycle |
| `$J=...` | Jog Motion |
| `$RST=$` | Restore Settings → Defaults |
| `$RST=#` | Restore Coordinate Offsets → Defaults |
| `$RST=*` | Restore ทั้งหมด → Defaults |
| `$SLP` | Sleep Mode |

---

## 🏷️ Error Codes (38 รหัส)

| Code | ข้อความ | ความหมาย |
|------|---------|---------|
| 1 | Expected command letter | ไม่พบตัวอักษร G หรือ M |
| 2 | Bad number format | รูปแบบตัวเลขไม่ถูกต้อง |
| 3 | Invalid statement | ไวยากรณ์คำสั่งผิด |
| 4 | Negative value | ค่า F/N/P/T/S ติดลบ |
| 5 | Setting disabled | ฟีเจอร์นี้ถูกปิดอยู่ |
| 6 | Setting step pulse minimum | Step pulse สั้นเกินไป |
| 7 | Setting read fail | อ่าน EEPROM ไม่สำเร็จ |
| 8 | Idle error | คำสั่งนี้ใช้ตอน Idle ไม่ได้ |
| 9 | System GC lock | ระบบล็อค / Alarm |
| 10 | Soft limit error | การเคลื่อนที่จะเกิน Soft Limit |
| 11 | Overflow | Buffer ล้น |
| 12 | Max step rate exceeded | Step rate สูงเกิน |
| 13 | Check door | Safety Door เปิดอยู่ |
| 14 | Line length exceeded | บรรทัด G-code ยาวเกิน |
| 15 | Travel exceeded | การเคลื่อนที่เกินระยะที่กำหนด |
| 16 | Invalid jog command | `$J=` syntax ผิด |
| 17 | Setting disabled laser | Laser mode ถูกปิด |
| 20 | Unsupported command | G/M code ไม่รองรับ |
| 21 | Modal group violation | คำสั่งในกลุ่มเดียวกันซ้ำ |
| 22 | Undefined feed rate | F จำเป็นแต่ไม่ได้ระบุ |
| 23 | Command value not integer | ค่า G-code ไม่ใช่จำนวนเต็ม |
| 24 | Axis command conflict | คำสั่งแกนขัดแย้งกัน |
| 25 | Word repeated | พารามิเตอร์ซ้ำในบรรทัดเดียว |
| 26 | No axis words | คำสั่ง Axis ไม่มีแกน |
| 27 | Invalid line number | N เกิน 10000000 |
| 28 | Value word missing | ขาดพารามิเตอร์ที่จำเป็น |
| 29 | Unsupported coord sys | ระบบพิกัดนอกช่วง |
| 30 | G53 invalid motion mode | G53 ต้องใช้กับ G0/G1 |
| 31 | Axis words exist | G80 ห้ามมี Axis Words |
| 32 | No axis words in plane | Arc ขาดแกนในระนาบที่เลือก |
| 33 | Invalid target | Arc จุดเริ่ม = จุดปลาย |
| 34 | Arc radius error | Arc geometry เป็นไปไม่ได้ |
| 35 | No offsets in plane | Arc แบบ Offset ขาด I/J/K |
| 36 | Unused words | มีพารามิเตอร์เกิน |
| 37 | G43 dynamic axis error | G43.1 แกนไม่ตรง |
| 38 | Max value exceeded | Tool number > 255 |

---

## 📈 เปรียบเทียบกับ GRBL รุ่นอื่น

| รายการ | v0.9j | v1.1e | **v1.1f (เรา)** | v1.1h |
|--------|-------|-------|----------------|-------|
| Real-time Overrides | ❌ | ✅ | ✅ | ✅ |
| Jogging Mode | ❌ | ✅ | ✅ | ✅ |
| Laser Mode | ❌ | ✅ | ✅ | ✅ |
| Sleep Mode | ❌ | ✅ | ✅ | ✅ |
| Safety Door Parking | ❌ | ✅ | ✅ | ✅ |
| Nonlinear Spindle | ❌ | ❌ | ✅ | ✅ |
| M56 Parking Override | ❌ | ❌ | ✅ | ✅ |
| Dual Motor Gantry | ❌ | ❌ | ❌ | ✅ |
| 30kHz Step Rate | ✅ | ✅ | ✅ | ✅ |
| 6-Axis (CH32V307) | ❌ | ❌ | ✅ | ❌ |

---

## 📚 แหล่งข้อมูลเพิ่มเติม

- **GRBL Official**: https://github.com/gnea/grbl
- **GRBL Wiki**: https://github.com/gnea/grbl/wiki
- **GRBL Releases**: https://github.com/gnea/grbl/releases
- **grblHAL** (รุ่นที่พัฒนาต่อ): https://github.com/grblHAL
- **G-code Reference**: https://github.com/gnea/grbl/wiki/G-Code

---

> **Last Updated**: 20 พฤษภาคม 2569  
> **Based on**: GRBL 1.1f Build 20230112 (gnea/grbl) + CH32V307 Multi-Axis Extensions
