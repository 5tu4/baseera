#include "settings.h"

#include <Preferences.h>

#include "config.h"

Settings settings = {DEFAULT_ALERT_CM, true, true, false, 80};

static Preferences prefs;

void settingsLoad() {
  prefs.begin("baseera", true);
  settings.alertCm = prefs.getInt("alertCm", DEFAULT_ALERT_CM);
  settings.voice = prefs.getBool("voice", true);
  settings.vibrate = prefs.getBool("vibrate", true);
  settings.muted = prefs.getBool("muted", false);
  settings.volume = prefs.getUChar("volume", 80);
  prefs.end();
}

void settingsSave() {
  prefs.begin("baseera", false);
  prefs.putInt("alertCm", settings.alertCm);
  prefs.putBool("voice", settings.voice);
  prefs.putBool("vibrate", settings.vibrate);
  prefs.putBool("muted", settings.muted);
  prefs.putUChar("volume", settings.volume);
  prefs.end();
}
