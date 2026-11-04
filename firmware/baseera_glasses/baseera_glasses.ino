// Baseera smart glasses — Seeed XIAO ESP32S3 Sense.
//
// The glasses sense; the phone thinks. They stream camera frames to the
// Baseera app over Bluetooth (or their own Wi-Fi, LINK_BLUETOOTH in config.h);
// the app runs the obstacle model, speaks the warning and sends back a
// vibration pattern.
//
// Stage 1 (config.h): XIAO + vibration module + battery. Without the phone the
// glasses can't see obstacles, so they buzz a long-short-long pattern when the
// phone link drops.
//
// With the later parts switched on in config.h, the glasses also warn on their
// own: distance sensors -> pulses that speed up as something gets closer and a
// strong buzz when the floor drops away; speaker -> spoken warnings; button ->
// short press repeats the last warning, long press mutes/unmutes.
// Wiring, libraries and board settings: firmware/README.md.

#include "audio.h"
#include "camera.h"
#include "clips.h"
#include "config.h"
#include "haptics.h"
#include "link.h"
#include "sensors.h"
#include "settings.h"

#if !LINK_BLUETOOTH
#include <ArduinoOTA.h>
#endif

static uint32_t lastStatus = 0;

#if HAS_DISTANCE
// --- Drops --------------------------------------------------------------
static float floorCm = -1;
static uint8_t dropReadings = 0;
static uint32_t lastDropAt = 0;

static void checkForDrop(uint32_t now) {
  if (!sensorsTakeNewDown()) return;
  int down = sensorsDownCm();
  if (down < 0) return;
  if (floorCm < 0) {
    floorCm = down;
    return;
  }
  if (down > floorCm * DROP_FACTOR + DROP_MARGIN_CM) {
    // Two readings in a row, so one bad echo doesn't cry wolf.
    if (++dropReadings != 2 || settings.muted || now - lastDropAt < 2000) return;
    lastDropAt = now;
    if (settings.vibrate) hapticsBuzz(600);
    // Connected, the phone sees the same readings and says it itself.
    if (settings.voice && !linkConnected()) {
      const uint8_t clips[] = {CLIP_DROP_OFF, CLIP_AHEAD, CLIP_VERY_CLOSE};
      audioSay(clips, sizeof(clips));
    }
  } else {
    dropReadings = 0;
    // Follow slow changes (slopes, how the head is tilted).
    floorCm = floorCm * 0.9f + down * 0.1f;
  }
}

static void checkAhead() {
  int front = sensorsFrontCm();
  bool warnAhead = !settings.muted && settings.vibrate && front >= 0 &&
                   front < settings.alertCm;
  hapticsProximity(warnAhead ? front : -1, settings.alertCm);
}
#endif

// --- When the phone isn't there --------------------------------------------
static bool hadPhone = false;
static uint32_t phoneLostAt = 0;
static bool warnedBattery = false;

static void checkAlone(uint32_t now) {
  if (linkConnected()) {
    hadPhone = true;
    phoneLostAt = 0;
  } else if (hadPhone) {
    // Brief link hiccups are normal; only warn if it stays gone.
    if (phoneLostAt == 0) phoneLostAt = now;
    if (now - phoneLostAt > PHONE_LOST_MS) {
      static const uint16_t lost[] = PHONE_LOST_PATTERN;
      if (!settings.muted) hapticsPattern(lost, sizeof(lost) / sizeof(lost[0]));
      audioSayOne(CLIP_DISCONNECTED);
      hadPhone = false;
    }
  }

  int battery = sensorsBatteryPercent();
  if (battery >= 0 && battery <= LOW_BATTERY_PERCENT && !warnedBattery) {
    warnedBattery = true;
    if (!linkConnected()) audioSayOne(CLIP_BATTERY_LOW);  // else the phone says it
  } else if (battery > LOW_BATTERY_PERCENT + 5) {
    warnedBattery = false;
  }
}

#if HAS_BUTTON
// --- Button --------------------------------------------------------------
static bool pressed = false;
static bool longPressDone = false;
static uint32_t pressedAt = 0;

static void checkButton(uint32_t now) {
  bool down = digitalRead(PIN_BUTTON) == LOW;
  if (down && !pressed) {
    pressed = true;
    longPressDone = false;
    pressedAt = now;
  } else if (down && !longPressDone && now - pressedAt >= LONG_PRESS_MS) {
    longPressDone = true;
    settings.muted = !settings.muted;
    settingsSave();
    hapticsBuzz(120);
    audioSayOne(settings.muted ? CLIP_ALERTS_OFF : CLIP_ALERTS_ON);
  } else if (!down && pressed) {
    pressed = false;
    if (!longPressDone && now - pressedAt > 40) audioRepeatLast();
  }
}
#endif

void setup() {
  Serial.begin(115200);
  settingsLoad();
#if HAS_BUTTON
  pinMode(PIN_BUTTON, INPUT_PULLUP);
#endif

  sensorsBegin();
  hapticsBegin();
  audioBegin();
  bool camera = cameraBegin();

  char name[24];
  uint64_t mac = ESP.getEfuseMac();
  snprintf(name, sizeof(name), "Baseera-%04X", (uint16_t)(mac >> 32));
  linkBegin(name);
  if (camera) cameraStartStreaming();

#if LINK_BLUETOOTH
  Serial.printf("Baseera glasses %s on Bluetooth as \"%s\"\n", FIRMWARE_VERSION, name);
#else
  // Firmware updates over the glasses' Wi-Fi once they're sealed shut.
  ArduinoOTA.setHostname("baseera-glasses");
  ArduinoOTA.setPassword(AP_PASSWORD);
  ArduinoOTA.begin();
  Serial.printf("Baseera glasses %s on Wi-Fi \"%s\"\n", FIRMWARE_VERSION, name);
#endif
  Serial.printf("camera %s, battery %d%%, speaker %d, distance sensors %d, button %d\n",
                camera ? "ok" : "FAILED", sensorsBatteryPercent(), HAS_SPEAKER,
                HAS_DISTANCE, HAS_BUTTON);
#if HAS_DISTANCE
  Serial.printf("front sensor %s, floor sensor %s\n", sensorsFrontOk() ? "ok" : "FAILED",
                sensorsDownOk() ? "ok" : "FAILED");
#endif
  hapticsBuzz(150);  // alive
}

void loop() {
  uint32_t now = millis();
  sensorsUpdate();
#if HAS_DISTANCE
  checkAhead();
  checkForDrop(now);
#endif
  checkAlone(now);
#if HAS_BUTTON
  checkButton(now);
#endif
  hapticsUpdate();

  if (now - lastStatus >= STATUS_INTERVAL_MS) {
    lastStatus = now;
    linkSendStatus();
    linkUpdate();
  }
#if !LINK_BLUETOOTH
  ArduinoOTA.handle();
#endif
  delay(2);
}
