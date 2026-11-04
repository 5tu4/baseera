# Baseera glasses firmware

Arduino sketch for the **Seeed XIAO ESP32S3 Sense**. The glasses stream the
camera to the Baseera app over Bluetooth (or their own Wi-Fi:
`LINK_BLUETOOTH 0` in `config.h`). The app runs the obstacle model, speaks the
warning on the phone and sends back a vibration pattern.

## Stage 1: XIAO + vibration module + battery

What is fitted is set at the top of `config.h`:

```c
#define HAS_SPEAKER 0        // MAX98357A + speaker
#define HAS_DISTANCE 0       // two VL53L1X
#define HAS_BUTTON 0         // push button
#define HAS_BATTERY_SENSE 1  // 100k/100k divider on D0/A0; 0 if not fitted
```

The glasses report these to the phone, which adapts: it hides the distance
and glasses-speaker settings and vibrates the glasses for every warning.

Wiring (diagram, wire list, checks and build order: `hardware/wiring/wiring-diagram.pdf`):

| From | To |
|---|---|
| Vibration module GND | XIAO GND |
| Vibration module VCC | XIAO 3V3 |
| Vibration module IN | XIAO D8 (GPIO 7) |
| Battery red / black | TP4056 B+ / B− |
| TP4056 OUT+ | slide switch middle leg |
| Switch side leg | XIAO BAT+ pad on the back (not the 5V pin: that is the USB-C line) |
| TP4056 OUT− | XIAO BAT− pad on the back, the one nearer the USB-C |
| optional: 100 kΩ BAT+ to D0/A0, 100 kΩ D0/A0 to BAT− | battery level for the phone |

Charge through the TP4056's USB-C, switch on or off (fit a 4.7 kΩ R3 first: the
board ships set to 1 A). The XIAO's USB-C is for programming; with the switch on
it charges the battery too, so plug in one cable at a time.

| Warning | Phone | Glasses |
|---|---|---|
| Stairs | "درج أمامك" | two long buzzes |
| Anything very close | "كرسي أمامك، قريب جداً" | three quick pulses, then one pulse every 1.2 s while it stays close ahead |
| People, vehicles, dogs | "شخص على يمينك" | two buzzes |
| Furniture, doors, poles | "باب على يسارك" | one buzz |
| Phone link lost | "انقطع الاتصال بالنظارة" | long-short-long, from the glasses themselves |
| Phone connected | "تم الاتصال بالنظارة" | one short buzz |

## Later stages: distance sensors, speaker, button

With these fitted and switched on in `config.h`, the closest dangers don't
wait for the phone (the wearer has no cane):

| Danger | With the phone | Glasses alone |
|---|---|---|
| Something close ahead (front sensor < alert distance) | Vibration pulses, faster when closer + the phone names it ("كرسي أمامك") | Vibration pulses |
| Floor drops away (stairs down, curb, hole) | Strong buzz + "انخفاض أمامك، قريب جداً" | Same — spoken by the glasses |
| Phone lost / battery low | Spoken by the phone | "انقطع الاتصال بالجوال" / "البطارية منخفضة" |

**Button:** short press repeats the last warning · long press (1 s) mutes or
unmutes ("التنبيهات متوقفة" / "التنبيهات تعمل").

### Full wiring

| XIAO pad | GPIO | Goes to |
|---|---|---|
| D0 / A0 | 1 | Battery divider: BAT+ — 100k — **A0** — 100k — GND |
| D1 | 2 | MAX98357A **BCLK** |
| D2 | 3 | MAX98357A **LRC** |
| D3 | 4 | MAX98357A **DIN** |
| D4 | 5 | **SDA** of both VL53L1X |
| D5 | 6 | **SCL** of both VL53L1X |
| D8 | 7 | Vibration module **IN** (VCC to 3V3) |
| D9 | 8 | Push button → GND (internal pull-up) |
| D10 | 9 | **XSHUT** of the *downward* VL53L1X only |
| 3V3 | — | VIN of both VL53L1X |
| BAT+ (switched) | — | MAX98357A VIN |
| GND | — | Everything's ground |

- **Two VL53L1X:** one looking straight ahead, one tilted ~60° down at the
  floor about a metre ahead. (Second sensor is new vs. the first BOM:
  +25–50 SAR — needed because there's no cane to find drops.)
- Power the amp and motor from the **battery line, not 3V3**, so Wi-Fi + speaker
  peaks don't brown out the board.
- Leave the Sense board's **microSD slot empty** — it shares D8–D10.
- Camera faces forward; if the picture is upside down, set
  `CAMERA_FLIP_VERTICAL true` in `config.h`.

## Build and upload (Arduino IDE)

1. Boards Manager: **esp32 by Espressif**, 3.3.x.
2. Library Manager: **ArduinoJson** (Benoit Blanchon); for the Wi-Fi build
   also **ESP Async WebServer** and **Async TCP** (both by ESP32Async);
   **VL53L1X** (Pololu) once the distance sensors are fitted. Bluetooth comes
   with the board package.
3. Open `baseera_glasses/baseera_glasses.ino`. Tools menu:
   - Board: **XIAO_ESP32S3**
   - PSRAM: **OPI PSRAM** (the camera needs it)
   - Partition Scheme: **Default with spiffs (3MB APP/1.5MB SPIFFS)**
4. Upload over USB-C. Serial Monitor (115200) shows the glasses' name
   (Baseera-XXXX), the link, and whether the camera and sensors started.

The Wi-Fi build can also be updated over the air once sealed in the frame:
join the glasses' network from the laptop, then Tools → Port →
**baseera-glasses** (password `baseera123`). The Bluetooth build updates over
USB-C only.

## Try it with the app

1. Power the glasses — one short buzz means they're running.
2. Phone: Bluetooth on. Nothing to pair: the app finds the glasses itself.
   The first time, allow **Nearby devices** (Android 12+) or location (older
   Android). Wi-Fi build instead: join Wi-Fi **Baseera-XXXX** (password
   `baseera123`), turn mobile data off, and turn on **نظارة بالواي فاي** in the
   app's settings.
3. App → settings → turn **وضع التجربة** off → نظارتي → **اتصال**. The
   glasses buzz once and the phone says "تم الاتصال بالنظارة"; the camera
   picture appears. If it is on its side or upside down, tap the turn button
   on the picture until it is upright (the obstacle model sees it the same way).
4. **اختبر الاهتزاز** buzzes the glasses; **اختبر الصوت** speaks a sample
   warning on the phone.

The app ships with the stock COCO obstacle model; the trained one (stairs,
doors, poles, trees) replaces it: see `ml/obstacle/README.md`.

Wi-Fi build: http://192.168.4.1 from a laptop on the glasses' Wi-Fi shows the
firmware version, the battery and what is fitted.

## Voice clips

`clips.h` / `clips.cpp` are generated — 29 short Saudi Arabic clips (≈700 KB)
compiled into the firmware, so there's no file system to upload. The numbers
come from the app (`app/lib/data/obstacles.dart`); the phone sends only
numbers. After changing that table:

```sh
cd firmware/tools
python -m venv .venv
.venv\Scripts\pip install edge-tts miniaudio
.venv\Scripts\python make_clips.py            # male voice (ar-SA-HamedNeural)
```

Then rebuild. `tools/clips/*.wav` are the same clips to listen to.

## Files

| File | |
|---|---|
| `baseera_glasses.ino` | Setup, main loop, the on-glasses safety logic, button |
| `config.h` | What is fitted, Bluetooth or Wi-Fi, pins, camera and warning tunables |
| `link.*` | Link to the phone: Bluetooth LE service, or Wi-Fi access point + WebSocket |
| `camera.*` | Camera setup and frame streaming (own task) |
| `sensors.*` | Battery, and both VL53L1X when fitted |
| `audio.*` | Clip playback on the MAX98357A (own task), when fitted |
| `haptics.*` | Vibration module: patterns from the phone, proximity pulses |
| `settings.*` | Settings from the phone, kept in flash |
| `clips.*` | Generated voice clips |
