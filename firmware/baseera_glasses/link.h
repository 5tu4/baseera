// Link to the phone: Bluetooth Low Energy, or the glasses' own Wi-Fi access
// point + WebSocket (LINK_BLUETOOTH in config.h). Same messages either way
// (they must match the app, app/lib/services/glasses/glasses_link.dart):
//
//   glasses -> phone   JPEG camera frame
//                      {"t":"status","bat":82,"fw":"0.3.0","mute":false,
//                       "caps":{"spk":false,"dist":false,"btn":false},
//                       "front":143,"down":61}     (distances only with HAS_DISTANCE)
//   phone -> glasses   {"t":"vib","p":[120,80,120]}   vibration pattern, on/off ms
//                      {"t":"buzz","ms":300}
//                      {"t":"say","clips":[26,52,60]} (only with HAS_SPEAKER)
//                      {"t":"config","alertCm":120,"voice":true,"vibrate":true}
//
// Bluetooth: one service, three characteristics (UUIDs in link.cpp):
//   frame   notify  a JPEG in pieces: the first piece starts with 0x80|id and
//                   the JPEG's length (4 bytes, little-endian), the others
//                   with id; id counts 0..127
//   status  notify  the status JSON
//   command write   one command JSON per write
#pragma once
#include <stddef.h>
#include <stdint.h>

// name: "Baseera-XXXX", the Bluetooth name or the Wi-Fi network.
void linkBegin(const char *name);

bool linkConnected();
bool linkCanSendFrame();
void linkSendFrame(const uint8_t *jpeg, size_t len);
void linkSendStatus();

// Call from loop(): drops dead connections, advertises again after one ends.
void linkUpdate();
