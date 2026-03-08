#include <SoftwareSerial.h>

// ------------------------------------------------------------
// HC-05 Bluetooth (UNO)
// ------------------------------------------------------------
// Arduino pin 10 (RX) <- HC-05 TX
// Arduino pin 11 (TX) -> HC-05 RX (through voltage divider)
static const uint8_t BT_RX_PIN = 10;
static const uint8_t BT_TX_PIN = 11;
SoftwareSerial BT(BT_RX_PIN, BT_TX_PIN);

// ------------------------------------------------------------
// MDDS10 motor driver (PWM + DIR mode)
// ------------------------------------------------------------
// Update these pins to match your wiring.
static const uint8_t M1_PWM_PIN = 5;   // Left motor PWM
static const uint8_t M1_DIR_PIN = 4;   // Left motor DIR
static const uint8_t M2_PWM_PIN = 6;   // Right motor PWM
static const uint8_t M2_DIR_PIN = 7;   // Right motor DIR

// Flip if any motor spins in opposite direction.
static const bool INVERT_LEFT_MOTOR = false;
static const bool INVERT_RIGHT_MOTOR = false;

// Speed profiles (0..255)
static const int DRIVE_SPEED = 190;
static const int TURN_SPEED = 170;

// If no command arrives for this time, stop motors.
static const unsigned long COMMAND_TIMEOUT_MS = 500;
unsigned long lastCommandMs = 0;

void setMotor(int value, uint8_t pwmPin, uint8_t dirPin, bool invert) {
  value = constrain(value, -255, 255);
  bool forward = (value >= 0);
  int pwm = abs(value);

  if (invert) {
    forward = !forward;
  }

  digitalWrite(dirPin, forward ? HIGH : LOW);
  analogWrite(pwmPin, pwm);
}

void applyDrive(int left, int right) {
  setMotor(left, M1_PWM_PIN, M1_DIR_PIN, INVERT_LEFT_MOTOR);
  setMotor(right, M2_PWM_PIN, M2_DIR_PIN, INVERT_RIGHT_MOTOR);
}

void stopChair() {
  applyDrive(0, 0);
}

void handleCommand(char c) {
  switch (c) {
    case 'f': // forward
      applyDrive(+DRIVE_SPEED, +DRIVE_SPEED);
      break;
    case 'b': // backward
      applyDrive(-DRIVE_SPEED, -DRIVE_SPEED);
      break;
    case 'l': // pivot left
      applyDrive(-TURN_SPEED, +TURN_SPEED);
      break;
    case 'r': // pivot right
      applyDrive(+TURN_SPEED, -TURN_SPEED);
      break;
    case 's': // stop
      stopChair();
      break;
    default:
      return; // ignore unknown bytes
  }

  lastCommandMs = millis();
}

void setup() {
  pinMode(M1_PWM_PIN, OUTPUT);
  pinMode(M1_DIR_PIN, OUTPUT);
  pinMode(M2_PWM_PIN, OUTPUT);
  pinMode(M2_DIR_PIN, OUTPUT);

  stopChair();

  Serial.begin(115200);
  BT.begin(9600); // HC-05 default baud

  lastCommandMs = millis();
  Serial.println("GoThrough wheelchair controller ready.");
}

void loop() {
  while (BT.available() > 0) {
    char c = (char)BT.read();

    // Ignore CR/LF if sender uses println.
    if (c == '\r' || c == '\n') {
      continue;
    }

    handleCommand(c);
  }

  // Safety failsafe
  if (millis() - lastCommandMs > COMMAND_TIMEOUT_MS) {
    stopChair();
  }
}
