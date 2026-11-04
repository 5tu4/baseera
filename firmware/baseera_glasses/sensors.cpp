#include "sensors.h"

#include <Arduino.h>

#include "config.h"

// --- Battery -----------------------------------------------------------------
static float batteryMv = 0;
static uint32_t lastBatteryRead = 0;

static void updateBattery() {
#if HAS_BATTERY_SENSE
  uint32_t now = millis();
  if (now - lastBatteryRead < 2000 && lastBatteryRead != 0) return;
  lastBatteryRead = now;
  float mv = analogReadMilliVolts(PIN_BATTERY) * 2.0f;  // 1:2 divider
  batteryMv = batteryMv == 0 ? mv : batteryMv * 0.8f + mv * 0.2f;
#endif
}

int sensorsBatteryPercent() {
  // Outside what a LiPo can read: the divider isn't there or isn't connected.
  if (batteryMv < 2800 || batteryMv > 4500) return -1;
  // LiPo resting voltage -> charge, roughly.
  static const int mv[] = {3300, 3500, 3600, 3700, 3800, 3900, 4000, 4100, 4200};
  static const int pct[] = {0, 8, 20, 35, 50, 65, 80, 90, 100};
  if (batteryMv <= mv[0]) return 0;
  for (int i = 1; i < 9; i++) {
    if (batteryMv <= mv[i]) {
      return pct[i - 1] + (batteryMv - mv[i - 1]) * (pct[i] - pct[i - 1]) /
                              (mv[i] - mv[i - 1]);
    }
  }
  return 100;
}

#if HAS_DISTANCE
// --- Two VL53L1X ---------------------------------------------------------------
#include <VL53L1X.h>
#include <Wire.h>

static VL53L1X front;
static VL53L1X down;
static bool frontOk = false;
static bool downOk = false;
static int frontCm = -1;
static int downCm = -1;
static bool newDown = false;

static bool startSensor(VL53L1X &sensor) {
  sensor.setBus(&Wire);
  sensor.setTimeout(100);
  if (!sensor.init()) return false;
  // Long mode reaches ~4 m indoors (less in bright sun).
  sensor.setDistanceMode(VL53L1X::Long);
  sensor.setMeasurementTimingBudget(33000);
  sensor.startContinuous(40);
  return true;
}

static bool readCm(VL53L1X &sensor, int &cm) {
  if (!sensor.dataReady()) return false;
  sensor.read(false);
  cm = sensor.ranging_data.range_status == VL53L1X::RangeValid
           ? sensor.ranging_data.range_mm / 10
           : -1;
  return true;
}

void sensorsBegin() {
  // Both sensors wake up at address 0x29. Hold the downward one off, move
  // the front one to 0x30, then let the downward one start at 0x29.
  pinMode(PIN_DOWN_XSHUT, OUTPUT);
  digitalWrite(PIN_DOWN_XSHUT, LOW);
  Wire.begin(PIN_SDA, PIN_SCL, 400000);
  delay(10);
  frontOk = startSensor(front);
  if (frontOk) front.setAddress(0x30);
  digitalWrite(PIN_DOWN_XSHUT, HIGH);
  delay(10);
  downOk = startSensor(down);
  analogReadResolution(12);
}

void sensorsUpdate() {
  if (frontOk) readCm(front, frontCm);
  if (downOk && readCm(down, downCm)) newDown = true;
  updateBattery();
}

int sensorsFrontCm() { return frontCm; }
int sensorsDownCm() { return downCm; }
bool sensorsFrontOk() { return frontOk; }
bool sensorsDownOk() { return downOk; }

bool sensorsTakeNewDown() {
  bool fresh = newDown;
  newDown = false;
  return fresh;
}

#else
// --- No distance sensors fitted ------------------------------------------------
void sensorsBegin() { analogReadResolution(12); }
void sensorsUpdate() { updateBattery(); }
int sensorsFrontCm() { return -1; }
int sensorsDownCm() { return -1; }
bool sensorsFrontOk() { return false; }
bool sensorsDownOk() { return false; }
bool sensorsTakeNewDown() { return false; }
#endif
