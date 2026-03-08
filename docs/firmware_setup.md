# Firmware Setup Guide

## 1) Arduino UNO + HC-05 + MDDS10 (Wheelchair Controller)

Firmware file:
- `firmware/arduino_uno_hc05_mdds10/arduino_uno_hc05_mdds10.ino`

### Required Hardware
- Arduino UNO
- HC-05 Bluetooth module
- Cytron MDDS10 dual channel motor driver
- Wheelchair motors + battery system
- Voltage divider for UNO TX -> HC-05 RX

### Bluetooth Name Requirement
Set HC-05 Bluetooth name to:
- `GoThrough Wheelchair`

The Flutter app connects to that exact name.

### Suggested Wiring
- HC-05 TX -> UNO D10 (RX)
- HC-05 RX <- UNO D11 (TX) through voltage divider
- HC-05 GND -> UNO GND
- MDDS10 M1 PWM -> UNO D5
- MDDS10 M1 DIR -> UNO D4
- MDDS10 M2 PWM -> UNO D6
- MDDS10 M2 DIR -> UNO D7
- Common GND: UNO + HC-05 + MDDS10

### MDDS10 Mode
Configure MDDS10 to **PWM + DIR mode**.

### Flash Steps
1. Open `.ino` in Arduino IDE.
2. Select Board: `Arduino Uno`.
3. Select the correct COM port.
4. Upload firmware.
5. Open Serial Monitor @ `115200`.

### Tuning
- `DRIVE_SPEED` and `TURN_SPEED` in firmware control movement intensity.
- Use very low values initially.
- Flip motor direction flags if forward/backward is reversed.

### Safety
- Keep wheels off ground for first tests.
- Confirm `s` command stops both motors.
- Keep emergency power cutoff accessible.

## 2) ESP32 + MPU6050 (Head Motion Controller)

Firmware file:
- `firmware/esp32_headmotion_mpu6050/esp32_headmotion_mpu6050.ino`

### Required Hardware
- ESP32 dev board
- MPU6050 IMU
- Stable 3.3V supply and shared GND

### I2C Wiring (typical ESP32)
- MPU6050 SDA -> ESP32 SDA (often GPIO 21)
- MPU6050 SCL -> ESP32 SCL (often GPIO 22)
- MPU6050 VCC -> 3.3V
- MPU6050 GND -> GND

### Bluetooth Name Requirement
The firmware advertises:
- `ESP32_HeadMotion`

The app connects to that exact name.

### Flash Steps
1. Open file in Arduino IDE.
2. Install libraries:
   - `Adafruit MPU6050`
   - `Adafruit Unified Sensor`
3. Select your ESP32 board and COM port.
4. Upload firmware.
5. Open Serial Monitor @ `115200`.

### Calibration / Behavior
- `COMMAND_THRESHOLD` controls motion sensitivity.
- `RELEASE_BAND` creates dead-zone around center.
- `LOW_PASS_ALPHA` smooths sensor readings.

The firmware emits command bytes: `f`, `b`, `l`, `r`, `s`.

## 3) End-to-End Validation
1. Pair phone with `GoThrough Wheelchair` and `ESP32_HeadMotion`.
2. Open app and sign in.
3. Connect wheelchair from center Bluetooth button.
4. Test manual ring control.
5. Connect ESP32 mode from Head Motion card.
6. Verify head movements produce expected direction.
7. Verify neutral head position produces `s` (stop).
