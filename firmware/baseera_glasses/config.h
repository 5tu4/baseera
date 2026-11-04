// Baseera glasses — pins and tunables. Board: Seeed XIAO ESP32S3 Sense.
#pragma once

#define FIRMWARE_VERSION "0.3.0"

// --- What is fitted -----------------------------------------------------------
// Stage 1 glasses: XIAO + vibration module + TP4056 charger, switch and 300 mAh
// battery (on the XIAO's BAT pads). The phone runs the
// obstacle model and speaks the warnings; the glasses stream the camera and
// vibrate. Set these to 1 as the other parts go in; the phone reads them from
// the status message and adapts.
#define HAS_SPEAKER 0        // MAX98357A + speaker on D1-D3
#define HAS_DISTANCE 0       // two VL53L1X on D4/D5, the downward one's XSHUT on D10
#define HAS_BUTTON 0         // push button on D9
#define HAS_BATTERY_SENSE 1  // 100k/100k divider BAT+ -> D0/A0 -> GND; 0 if not fitted

// --- Link to the phone ---------------------------------------------------------
// 1: Bluetooth. The glasses show up as "Baseera-XXXX" and the app finds them
//    itself; nothing to pair or join. Camera frames: about 4 per second.
// 0: their own Wi-Fi access point "Baseera-XXXX" + ws://192.168.4.1/ws, 8
//    frames per second and firmware updates over the air; the phone must join
//    that Wi-Fi, and "Wi-Fi glasses" must be on in the app's settings.
// Protocol: link.h and app/lib/services/glasses/glasses_link.dart.
#define LINK_BLUETOOTH 1
#define AP_PASSWORD "baseera123"  // Wi-Fi + OTA password, at least 8 characters
#define AP_CHANNEL 6

// --- Pins (XIAO pad -> GPIO) --------------------------------------------
#define PIN_BATTERY 1      // D0/A0: middle of a 100k/100k divider on BAT+
#define PIN_I2S_BCLK 2     // D1 -> MAX98357A BCLK
#define PIN_I2S_LRC 3      // D2 -> MAX98357A LRC
#define PIN_I2S_DOUT 4     // D3 -> MAX98357A DIN
#define PIN_SDA 5          // D4 -> SDA of both VL53L1X
#define PIN_SCL 6          // D5 -> SCL of both VL53L1X
#define PIN_MOTOR 7        // D8 -> IN of the vibration module
#define PIN_BUTTON 8       // D9 -> push button to GND
#define PIN_DOWN_XSHUT 9   // D10 -> XSHUT of the downward VL53L1X
// The SD-card slot on the Sense board shares D8-D10: leave it empty.

// --- Vibration ----------------------------------------------------------------
// The module's VCC is on 3V3, so full power is right for its 3 V motor. If you
// move VCC to the battery (up to 4.2 V), drop this to about 205.
#define VIB_DUTY 255

// --- Camera ---------------------------------------------------------------
#if LINK_BLUETOOTH
#define CAMERA_FPS 4                // what Bluetooth carries reliably
#define CAMERA_JPEG_QUALITY 15      // 0-63, lower = better image, bigger
#else
#define CAMERA_FPS 8                // enough at walking pace; less heat
#define CAMERA_JPEG_QUALITY 12
#endif
#define CAMERA_FLIP_VERTICAL false  // the app can also turn the picture
#define CAMERA_MIRROR false

// --- Warnings ---------------------------------------------------------------
#define DEFAULT_ALERT_CM 120   // the phone overrides this (setting in نظارتي)
// The downward sensor sees the floor at a steady distance; a reading this
// much farther, twice in a row, means the floor dropped away.
#define DROP_FACTOR 1.35f
#define DROP_MARGIN_CM 10
#define LOW_BATTERY_PERCENT 15
// Without the phone the glasses can't see obstacles: they buzz this pattern
// (on/off ms) when the phone has been gone for PHONE_LOST_MS.
#define PHONE_LOST_MS 3000
#define PHONE_LOST_PATTERN {500, 200, 150, 200, 500}

#define STATUS_INTERVAL_MS 500
#define LONG_PRESS_MS 1000
