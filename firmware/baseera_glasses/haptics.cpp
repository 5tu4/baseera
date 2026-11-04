#include "haptics.h"

#include <Arduino.h>

#include "config.h"

static const uint8_t LEDC_CHANNEL = 4;  // channel 0 drives the camera clock
static const size_t MAX_STEPS = 16;

static portMUX_TYPE lock = portMUX_INITIALIZER_UNLOCKED;
static uint16_t steps[MAX_STEPS];
static size_t stepCount = 0;  // 0 = no pattern playing
static size_t step = 0;
static uint32_t stepStart = 0;

static int proximityCm = -1;
static int proximityAlertCm = DEFAULT_ALERT_CM;

void hapticsBegin() {
  ledcAttachChannel(PIN_MOTOR, 20000, 8, LEDC_CHANNEL);
  ledcWrite(PIN_MOTOR, 0);
}

void hapticsPattern(const uint16_t *ms, size_t count) {
  count = min(count, MAX_STEPS);
  portENTER_CRITICAL(&lock);
  for (size_t i = 0; i < count; i++) steps[i] = constrain(ms[i], 10, 2000);
  stepCount = count;
  step = 0;
  stepStart = millis();
  portEXIT_CRITICAL(&lock);
}

void hapticsBuzz(uint16_t ms) { hapticsPattern(&ms, 1); }

void hapticsProximity(int cm, int alertCm) {
  proximityCm = cm;
  proximityAlertCm = alertCm;
}

void hapticsUpdate() {
  uint32_t now = millis();
  bool on = false;
  bool playing = false;

  portENTER_CRITICAL(&lock);
  while (stepCount > 0 && now - stepStart >= steps[step]) {
    stepStart += steps[step];
    if (++step >= stepCount) stepCount = 0;
  }
  if (stepCount > 0) {
    playing = true;
    on = step % 2 == 0;  // even steps buzz, odd steps are the gaps
  }
  portEXIT_CRITICAL(&lock);

  if (!playing && proximityCm >= 0) {
    // 70 ms pulses: every 0.8 s at the alert distance, every 0.15 s up close.
    int cm = constrain(proximityCm, 20, max(proximityAlertCm, 21));
    uint32_t period = map(cm, 20, max(proximityAlertCm, 21), 150, 800);
    on = now % period < 70;
  }
  ledcWrite(PIN_MOTOR, on ? VIB_DUTY : 0);
}
