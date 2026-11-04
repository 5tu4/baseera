# بصيرة — Baseera (app)

Android app for deaf/hard-of-hearing and blind/low-vision users, paired with
the Baseera smart glasses. Flutter; Arabic (RTL) and English.

> Keep this project in a folder whose path is plain English/ASCII — Flutter's
> shader compiler and Gradle fail on Windows when the path has Arabic in it.

## Modes (picked at first launch, changeable in settings)

| Mode | Home |
|---|---|
| أصم أو ضعيف سمع | Tabs: افهمني · أقرأ كلامك · صوتي |
| كفيف أو ضعيف بصر | One voice-first glasses screen (auto-connects, TalkBack-friendly) |
| مرافق | All four tabs, including نظارتي |

## Sections

| Section | What it does |
|---|---|
| افهمني | Camera → MediaPipe hand + pose landmarks → sign model → word shown and spoken; signs build a sentence. Sign in, then lower your hands. 39 signs (listed in the app). |
| أقرأ كلامك | Speech → large text (`ar-SA`). Keeps listening through pauses until stopped; adjustable text size. |
| صوتي | Type-to-speak, yes/no, ready phrases in 6 categories, and the user's own words (add, edit, delete; hide built-ins). Male/female Arabic forms. |
| نظارتي | Connection, glasses camera (with a turn button), warning settings, latest warnings; live distances on glasses with distance sensors. Demo mode simulates stage 1 glasses. |

## Run

```sh
flutter pub get
flutter run                 # on a connected Android phone
flutter test                # unit + widget tests
python tool/make_arb.py     # after editing UI strings (Arabic + English table)
```

## Layout

```
lib/
  theme/tokens.dart            colors (light + dark), spacing, radii — edit here
  data/vocabulary.dart         the 39 signs (ids = model labels — keep stable)
  data/phrases.dart            built-in صوتي phrases (ids saved when hidden — keep stable)
  data/obstacles.dart          what the glasses warn about + voice-clip numbers
  recognition/                 sign recognition, reused from Ishara unchanged
  services/glasses/            glasses protocol, Wi-Fi link, demo link, warning logic
  services/phrases_store.dart  user's own words (on the device)
  screens/                     one file per screen
android/.../LandmarkChannel.kt MediaPipe hand + pose on Android
```

## Glasses protocol

Defined in `lib/services/glasses/glasses_link.dart` (WebSocket at
`ws://192.168.4.1/ws`; JPEG frames + status JSON up, `vib`/`buzz`/`say`/`config`
down). The status says what the glasses have fitted (`caps`): stage 1 glasses
have only the camera and the vibration module, so the phone speaks every
warning and sends a vibration pattern (`GlassesVibration` in
`lib/data/obstacles.dart`). Voice-clip numbers, for glasses with a speaker, are
in the same file; the firmware's clip table must use the same numbers.

## Credits

Sign model trained on KArSL (KFUPM Arabic Sign Language dataset) — ask the
authors before any wider release. MediaPipe (Google). Font: IBM Plex Sans
Arabic (SIL OFL).
