# GoThrough Wheelchair Control System

Mobile + firmware system for controlling an electric wheelchair from:
- Phone touch controls (Bluetooth classic)
- ESP32 head-motion input (MPU6050 over Bluetooth classic)

## Read This First
- This repository is shared for learning and discussion.
- It includes **placeholder Firebase values**. You must configure your own Firebase project.
- Wheelchair systems are safety-critical. Test with wheels lifted and emergency stop available.

## Project Scope
This repository contains:
- Flutter mobile app (`lib/`) for login, pairing, and driving commands
- Arduino UNO firmware for wheelchair motor driver control (`firmware/arduino_uno_hc05_mdds10/`)
- ESP32 firmware for head-motion command generation (`firmware/esp32_headmotion_mpu6050/`)
- Setup and hardware documentation (`docs/`)

## Command Protocol
Single-character commands sent over Bluetooth:
- `f` forward
- `b` backward
- `l` left
- `r` right
- `s` stop

The Flutter app expects:
- Wheelchair Bluetooth name: `GoThrough Wheelchair`
- ESP32 Bluetooth name: `ESP32_HeadMotion`

## Quick Start (End-to-End)
1. Configure Firebase for your own project (steps below).
2. Flash Arduino UNO wheelchair firmware.
3. Flash ESP32 head-motion firmware.
4. Pair your phone with both Bluetooth devices.
5. Run the Flutter app and sign in.
6. Connect wheelchair from center Bluetooth button.
7. Optionally connect ESP32 mode from `Head Motion Mode`.

## Firebase Setup (Required)
The committed files are intentionally sanitized:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `firebase.json`

Use your own Firebase values:
1. Create a Firebase project.
2. Register Android app package (`com.example.go_through`) or your real package.
3. Download Firebase Android config and replace:
   - `android/app/google-services.json`
4. Regenerate Flutter options with FlutterFire CLI (recommended):
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
5. Ensure `lib/firebase_options.dart` now has your project values.
6. Configure Firebase Auth providers (Email/Password + Google) in Firebase Console.
7. Apply strict Firebase security rules and App Check before public release.

## Architecture
1. Flutter app connects directly to wheelchair HC-05 and sends drive commands.
2. Flutter app can also connect to ESP32 head-motion device.
3. ESP32 motion commands are forwarded by the app to the wheelchair link.

## Repository Layout
```text
lib/                                      Flutter application
firmware/
  arduino_uno_hc05_mdds10/
    arduino_uno_hc05_mdds10.ino          Wheelchair drive controller
  esp32_headmotion_mpu6050/
    esp32_headmotion_mpu6050.ino         MPU6050 head-motion controller
docs/
  firmware_setup.md                       Wiring + flashing + calibration
LICENSE                                   Learning-only license
NOTICE                                    License intent summary
```

## Mobile App Setup
1. Install Flutter SDK.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run:
   ```bash
   flutter run
   ```
4. If Firebase is not configured yet, fix that first.

## Firmware Setup
Use the detailed guide:
- [`docs/firmware_setup.md`](docs/firmware_setup.md)

## Public Sharing Checklist
Before making repository public:
1. Verify no production secrets/tokens are committed.
2. Keep only placeholder Firebase config in repo.
3. Use Firebase security rules and App Check.
4. Remove personally identifiable data and device addresses.
5. Document safety warnings and hardware test procedure.

## Safety
- Always test with drive wheels lifted from the ground first.
- Keep an emergency stop switch accessible.
- Use conservative speed values before real-world movement tests.
- Keep command timeout failsafe enabled on the Arduino firmware.

## License
This repository is intentionally **not open source**.

Read full terms in [`LICENSE`](LICENSE).  
Short version: viewing, learning, and discussion are allowed; reuse, modification, redistribution, or deployment are not allowed without prior written permission.
