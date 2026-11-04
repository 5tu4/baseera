// What the phone configures, kept in flash so the glasses behave the same
// when they start without the phone.
#pragma once
#include <stdint.h>

struct Settings {
  int alertCm;     // vibrate when something ahead is closer than this
  bool voice;      // speak warnings
  bool vibrate;    // vibrate for close obstacles and drops
  bool muted;      // long-press on the button: everything off but the voice
                   // confirming it
  uint8_t volume;  // 0-100
};

extern Settings settings;

void settingsLoad();
void settingsSave();
