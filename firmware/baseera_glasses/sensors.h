// Battery voltage, and the two VL53L1X distance sensors (ahead, and angled
// down at the floor) when HAS_DISTANCE is on; without them the distances read -1.
#pragma once

void sensorsBegin();

// Call often: reads whatever the sensors have ready, never waits.
void sensorsUpdate();

// Latest readings in cm, or -1 when there is no valid reading.
int sensorsFrontCm();
int sensorsDownCm();

// True once per new downward reading (drop detection looks at each one).
bool sensorsTakeNewDown();

// 0-100, or -1 before the first reading.
int sensorsBatteryPercent();

bool sensorsFrontOk();
bool sensorsDownOk();
