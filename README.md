# Baseera (بصيرة)

Smart glasses for blind and low-vision people, and an Android app for blind and deaf users.

- **Glasses:** a XIAO ESP32-S3 Sense streams its camera to the phone over Bluetooth LE. The app runs a
  YOLO11n obstacle model on the phone, speaks the warning ("person ahead, very close") and makes the
  glasses vibrate with a pattern that says how urgent it is.
- **App:** also translates Arabic sign language (MediaPipe landmarks + a classifier trained on KArSL,
  39 signs), shows what a speaker says as text, and speaks ready-made or user-added phrases.
  Arabic and English, light and dark.

| Folder | What is in it |
| --- | --- |
| [app/](app/) | Flutter app (Android) |
| [firmware/](firmware/) | Arduino sketch for the glasses |
| [ml/obstacle/](ml/obstacle/) | Training and install tools for the obstacle model |
| [hardware/cad/](hardware/cad/) | CadQuery model of the frame and housings, print notes |
| [hardware/wiring/](hardware/wiring/) | Wiring diagram |

Each folder's README has the build steps.
