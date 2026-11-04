#include "link.h"

#include <ArduinoJson.h>

#include "audio.h"
#include "clips.h"
#include "config.h"
#include "haptics.h"
#include "sensors.h"
#include "settings.h"

// --- Shared: commands and status ---------------------------------------------

static void handleCommand(JsonDocument &doc) {
  const char *type = doc["t"] | "";

  if (strcmp(type, "vib") == 0) {
    // The phone decides the pattern; muting on the glasses still wins.
    if (settings.muted) return;
    uint16_t steps[16];
    size_t count = 0;
    for (JsonVariant v : doc["p"].as<JsonArray>()) {
      if (count < 16) steps[count++] = v.as<uint16_t>();
    }
    if (count) hapticsPattern(steps, count);
  } else if (strcmp(type, "buzz") == 0) {
    if (!settings.muted) hapticsBuzz(constrain(doc["ms"] | 300, 20, 2000));
  } else if (strcmp(type, "say") == 0) {
#if HAS_SPEAKER
    uint8_t clips[8];
    size_t count = 0;
    for (JsonVariant v : doc["clips"].as<JsonArray>()) {
      if (count < sizeof(clips)) clips[count++] = v.as<uint8_t>();
    }
    // Muted on the glasses: only system messages (connected, alerts on/off…).
    if (count && (!settings.muted || clips[0] >= CLIP_CONNECTED)) {
      audioSay(clips, count);
    }
#endif
  } else if (strcmp(type, "config") == 0) {
    settings.alertCm = constrain(doc["alertCm"] | settings.alertCm, 30, 400);
    settings.voice = doc["voice"] | settings.voice;
    settings.vibrate = doc["vibrate"] | settings.vibrate;
    if (!doc["volume"].isNull()) {
      settings.volume = constrain(doc["volume"].as<int>(), 0, 100);
    }
    settingsSave();
  }
}

static void handleCommandText(const uint8_t *data, size_t len) {
  JsonDocument doc;
  if (deserializeJson(doc, data, len) == DeserializationError::Ok) {
    handleCommand(doc);
  }
}

static size_t statusJson(char *text, size_t size) {
  JsonDocument doc;
  doc["t"] = "status";
  int battery = sensorsBatteryPercent();
  if (battery >= 0) doc["bat"] = battery;
  else doc["bat"] = nullptr;
#if HAS_DISTANCE
  int front = sensorsFrontCm();
  int down = sensorsDownCm();
  if (front >= 0) doc["front"] = front;
  else doc["front"] = nullptr;
  if (down >= 0) doc["down"] = down;
  else doc["down"] = nullptr;
#endif
  doc["fw"] = FIRMWARE_VERSION;
  doc["mute"] = settings.muted;
  JsonObject caps = doc["caps"].to<JsonObject>();
  caps["spk"] = (bool)HAS_SPEAKER;
  caps["dist"] = (bool)HAS_DISTANCE;
  caps["btn"] = (bool)HAS_BUTTON;
  return serializeJson(doc, text, size);
}

#if LINK_BLUETOOTH
// --- Bluetooth Low Energy ------------------------------------------------------
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>

#define BLE_SERVICE_UUID "6b9a0001-3c1e-4f5a-9a2e-b45e1ea5a001"
#define BLE_FRAME_UUID "6b9a0002-3c1e-4f5a-9a2e-b45e1ea5a001"
#define BLE_STATUS_UUID "6b9a0003-3c1e-4f5a-9a2e-b45e1ea5a001"
#define BLE_COMMAND_UUID "6b9a0004-3c1e-4f5a-9a2e-b45e1ea5a001"

// 247 = one link-layer packet per piece (244 bytes of data) once the phone
// has asked for a bigger MTU, which the app does right after connecting.
static const uint16_t BLE_MTU = 247;

static BLEServer *server = nullptr;
static BLECharacteristic *frameChar = nullptr;
static BLECharacteristic *statusChar = nullptr;
static volatile bool connected = false;
static volatile bool advertiseAgain = false;
static volatile bool notifyFailed = false;

class ServerEvents : public BLEServerCallbacks {
  void onConnect(BLEServer *) override {
    connected = true;
    Serial.println("phone connected (Bluetooth)");
  }
  void onDisconnect(BLEServer *) override {
    connected = false;
    advertiseAgain = true;
    Serial.println("phone disconnected (Bluetooth)");
  }
};

class CommandEvents : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *c) override {
    String value = c->getValue();
    handleCommandText((const uint8_t *)value.c_str(), value.length());
  }
};

class NotifyEvents : public BLECharacteristicCallbacks {
  void onStatus(BLECharacteristic *, Status s, uint32_t) override {
    if (s == ERROR_GATT) notifyFailed = true;  // out of buffers: try again
  }
};

void linkBegin(const char *name) {
  BLEDevice::init(name);
  BLEDevice::setMTU(BLE_MTU);
  server = BLEDevice::createServer();
  server->setCallbacks(new ServerEvents());

  BLEService *service = server->createService(BLE_SERVICE_UUID);
  frameChar = service->createCharacteristic(BLE_FRAME_UUID, BLECharacteristic::PROPERTY_NOTIFY);
  frameChar->addDescriptor(new BLE2902());
  frameChar->setCallbacks(new NotifyEvents());
  statusChar = service->createCharacteristic(
      BLE_STATUS_UUID, BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_READ);
  statusChar->addDescriptor(new BLE2902());
  BLECharacteristic *command = service->createCharacteristic(
      BLE_COMMAND_UUID, BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_WRITE_NR);
  command->setCallbacks(new CommandEvents());
  service->start();

  BLEAdvertising *advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(BLE_SERVICE_UUID);
  advertising->setScanResponse(true);  // the name goes in the scan response
  BLEDevice::startAdvertising();
}

bool linkConnected() { return connected; }

bool linkCanSendFrame() { return connected; }

// Sends one piece, retrying while the stack is out of buffers.
static bool sendPiece(const uint8_t *data, size_t len) {
  for (int attempt = 0; attempt < 40 && connected; attempt++) {
    notifyFailed = false;
    frameChar->setValue(data, len);
    frameChar->notify();
    if (!notifyFailed) return true;
    vTaskDelay(pdMS_TO_TICKS(3));
  }
  return false;
}

void linkSendFrame(const uint8_t *jpeg, size_t len) {
  static uint8_t id = 0;
  static uint8_t piece[BLE_MTU];
  id = (id + 1) & 0x7F;

  uint16_t mtu = server->getPeerMTU(server->getConnId());
  if (mtu < 23 || mtu > BLE_MTU) mtu = mtu > BLE_MTU ? BLE_MTU : 23;
  size_t room = mtu - 3;  // ATT header

  size_t sent = 0;
  bool first = true;
  while (sent < len && connected) {
    size_t head = 1;
    piece[0] = id;
    if (first) {
      piece[0] |= 0x80;
      piece[1] = len & 0xFF;
      piece[2] = (len >> 8) & 0xFF;
      piece[3] = (len >> 16) & 0xFF;
      piece[4] = (len >> 24) & 0xFF;
      head = 5;
    }
    size_t n = min(room - head, len - sent);
    memcpy(piece + head, jpeg + sent, n);
    if (!sendPiece(piece, head + n)) return;  // the phone drops the half frame
    sent += n;
    first = false;
  }
}

void linkSendStatus() {
  if (!connected) return;
  char text[200];
  size_t len = statusJson(text, sizeof(text));
  statusChar->setValue((uint8_t *)text, len);
  statusChar->notify();
}

void linkUpdate() {
  if (advertiseAgain && !connected) {
    advertiseAgain = false;
    BLEDevice::startAdvertising();
  }
}

#else
// --- Wi-Fi access point + WebSocket ------------------------------------------
#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <WiFi.h>

static AsyncWebServer web(80);
static AsyncWebSocket ws("/ws");

static void onEvent(AsyncWebSocket *, AsyncWebSocketClient *client,
                    AwsEventType type, void *arg, uint8_t *data, size_t len) {
  switch (type) {
    case WS_EVT_CONNECT:
      Serial.printf("phone connected (%u)\n", client->id());
      linkSendStatus();
      break;
    case WS_EVT_DISCONNECT:
      Serial.printf("phone disconnected (%u)\n", client->id());
      break;
    case WS_EVT_DATA: {
      // Commands are small: always one whole text frame.
      auto *info = (AwsFrameInfo *)arg;
      if (!info->final || info->index != 0 || info->len != len ||
          info->opcode != WS_TEXT) {
        return;
      }
      handleCommandText(data, len);
      break;
    }
    default:
      break;
  }
}

void linkBegin(const char *name) {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(name, AP_PASSWORD, AP_CHANNEL, 0, 2);
  WiFi.setSleep(false);  // lower, steadier latency for warnings

  ws.onEvent(onEvent);
  web.addHandler(&ws);
  web.on("/", HTTP_GET, [](AsyncWebServerRequest *request) {
    // Handy check from a laptop joined to the glasses' Wi-Fi.
    char text[200];
    snprintf(text, sizeof(text),
             "Baseera glasses %s\nbattery %d%%\nspeaker %d, distance sensors %d, button %d\n"
             "front %d cm, down %d cm\n",
             FIRMWARE_VERSION, sensorsBatteryPercent(), HAS_SPEAKER, HAS_DISTANCE,
             HAS_BUTTON, sensorsFrontCm(), sensorsDownCm());
    request->send(200, "text/plain", text);
  });
  web.begin();
}

bool linkConnected() { return ws.count() > 0; }

bool linkCanSendFrame() { return ws.availableForWriteAll(); }

void linkSendFrame(const uint8_t *jpeg, size_t len) { ws.binaryAll(jpeg, len); }

void linkSendStatus() {
  if (!linkConnected()) return;
  char text[200];
  size_t len = statusJson(text, sizeof(text));
  ws.textAll(text, len);
}

void linkUpdate() { ws.cleanupClients(2); }
#endif
