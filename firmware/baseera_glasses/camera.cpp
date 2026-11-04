#include "camera.h"

#include <Arduino.h>
#include <esp_camera.h>

#include "config.h"
#include "link.h"

bool cameraBegin() {
  camera_config_t c = {};
  // XIAO ESP32S3 Sense camera connector.
  c.pin_pwdn = -1;
  c.pin_reset = -1;
  c.pin_xclk = 10;
  c.pin_sccb_sda = 40;
  c.pin_sccb_scl = 39;
  c.pin_d7 = 48;
  c.pin_d6 = 11;
  c.pin_d5 = 12;
  c.pin_d4 = 14;
  c.pin_d3 = 16;
  c.pin_d2 = 18;
  c.pin_d1 = 17;
  c.pin_d0 = 15;
  c.pin_vsync = 38;
  c.pin_href = 47;
  c.pin_pclk = 13;
  c.xclk_freq_hz = 20000000;
  c.ledc_timer = LEDC_TIMER_0;
  c.ledc_channel = LEDC_CHANNEL_0;  // the motor uses channel 4
  c.pixel_format = PIXFORMAT_JPEG;
  c.frame_size = FRAMESIZE_QVGA;  // 320x240, what the obstacle model reads
  c.jpeg_quality = CAMERA_JPEG_QUALITY;
  c.fb_count = 2;
  c.fb_location = CAMERA_FB_IN_PSRAM;
  c.grab_mode = CAMERA_GRAB_LATEST;  // never hand over a stale frame

  if (esp_camera_init(&c) != ESP_OK) return false;
  sensor_t *s = esp_camera_sensor_get();
  s->set_vflip(s, CAMERA_FLIP_VERTICAL);
  s->set_hmirror(s, CAMERA_MIRROR);
  return true;
}

static void streamTask(void *) {
  const TickType_t period = pdMS_TO_TICKS(1000 / CAMERA_FPS);
  TickType_t wake = xTaskGetTickCount();
  for (;;) {
    vTaskDelayUntil(&wake, period);
    if (!linkConnected() || !linkCanSendFrame()) continue;
    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) continue;
    linkSendFrame(fb->buf, fb->len);
    esp_camera_fb_return(fb);
  }
}

void cameraStartStreaming() {
  xTaskCreatePinnedToCore(streamTask, "camera", 4096, nullptr, 2, nullptr, 0);
}
