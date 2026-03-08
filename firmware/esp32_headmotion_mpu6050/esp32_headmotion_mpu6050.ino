#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <BluetoothSerial.h>

Adafruit_MPU6050 mpu;
BluetoothSerial SerialBT;

static const float COMMAND_THRESHOLD = 1.5f;
static const float RELEASE_BAND = 1.2f;          // hysteresis to reduce jitter
static const float LOW_PASS_ALPHA = 0.2f;        // smoothing factor
static const uint32_t LOOP_PERIOD_MS = 20;       // 50 Hz
static const uint32_t DEBUG_PERIOD_MS = 250;
static const uint32_t HEARTBEAT_PERIOD_MS = 400; // resend same cmd occasionally

float axFiltered = 0.0f;
float ayFiltered = 0.0f;
char lastCommand = 's';

uint32_t lastLoopAt = 0;
uint32_t lastDebugAt = 0;
uint32_t lastSendAt = 0;

char chooseCommand(float ax, float ay) {
  // Center dead-zone
  if (fabs(ax) < RELEASE_BAND && fabs(ay) < RELEASE_BAND) {
    return 's';
  }

  // Use dominant axis to avoid ambiguous diagonal motions.
  if (fabs(ax) >= fabs(ay)) {
    if (ax > COMMAND_THRESHOLD) return 'f';
    if (ax < -COMMAND_THRESHOLD) return 'b';
  } else {
    if (ay > COMMAND_THRESHOLD) return 'l';
    if (ay < -COMMAND_THRESHOLD) return 'r';
  }

  return 's';
}

void sendCommand(char cmd) {
  if (!SerialBT.hasClient()) return;
  SerialBT.write((uint8_t)cmd); // Single-byte command protocol
}

void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32_HeadMotion");

  if (!mpu.begin(0x68)) {
    Serial.println("MPU6050 connection failed.");
    while (true) {
      delay(1000);
    }
  }

  mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
  mpu.setGyroRange(MPU6050_RANGE_500_DEG);
  mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

  Serial.println("MPU6050 ready.");
}

void loop() {
  uint32_t now = millis();
  if (now - lastLoopAt < LOOP_PERIOD_MS) return;
  lastLoopAt = now;

  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);

  // Low-pass filtering
  axFiltered = (1.0f - LOW_PASS_ALPHA) * axFiltered + LOW_PASS_ALPHA * a.acceleration.x;
  ayFiltered = (1.0f - LOW_PASS_ALPHA) * ayFiltered + LOW_PASS_ALPHA * a.acceleration.y;

  char cmd = chooseCommand(axFiltered, ayFiltered);

  // Send on change or as heartbeat.
  if (cmd != lastCommand || (now - lastSendAt) >= HEARTBEAT_PERIOD_MS) {
    sendCommand(cmd);
    lastCommand = cmd;
    lastSendAt = now;
  }

  if (now - lastDebugAt >= DEBUG_PERIOD_MS) {
    lastDebugAt = now;
    Serial.print("ax=");
    Serial.print(axFiltered, 3);
    Serial.print(" ay=");
    Serial.print(ayFiltered, 3);
    Serial.print(" cmd=");
    Serial.println(cmd);
  }
}
