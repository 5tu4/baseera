#include "audio.h"

#include "config.h"

#if HAS_SPEAKER
#include <Arduino.h>
#include <ESP_I2S.h>
#include <string.h>

#include "clips.h"
#include "settings.h"

static const size_t MAX_CLIPS = 8;

static I2SClass i2s;
static portMUX_TYPE lock = portMUX_INITIALIZER_UNLOCKED;
static uint8_t queue[MAX_CLIPS];
static size_t queued = 0;
static uint8_t last[MAX_CLIPS];
static size_t lastCount = 0;
static volatile bool interrupt = false;
static volatile bool playing = false;

static const Clip *findClip(uint8_t id) {
  for (size_t i = 0; i < CLIP_COUNT; i++) {
    if (CLIPS[i].id == id) return &CLIPS[i];
  }
  return nullptr;
}

static bool takeNext(uint8_t &id) {
  bool have = false;
  portENTER_CRITICAL(&lock);
  if (queued > 0) {
    id = queue[0];
    memmove(queue, queue + 1, --queued);
    interrupt = false;
    have = true;
  }
  portEXIT_CRITICAL(&lock);
  return have;
}

static void play(const Clip &clip) {
  // Mono clip -> both stereo slots, so the amp plays it whatever its
  // channel jumper says.
  static int16_t frame[512];
  const int32_t volume = settings.volume;
  for (uint32_t i = 0; i < clip.samples && !interrupt;) {
    size_t n = min<uint32_t>(256, clip.samples - i);
    for (size_t k = 0; k < n; k++) {
      int16_t s = (int32_t)clip.pcm[i + k] * volume / 100;
      frame[2 * k] = s;
      frame[2 * k + 1] = s;
    }
    i2s.write((uint8_t *)frame, n * 4);
    i += n;
  }
}

static void audioTask(void *) {
  static int16_t silence[256] = {};
  for (;;) {
    uint8_t id;
    if (!takeNext(id)) {
      if (playing) {
        // A moment of silence after speech so the amp doesn't click.
        i2s.write((uint8_t *)silence, sizeof(silence));
        playing = false;
      }
      vTaskDelay(pdMS_TO_TICKS(10));
      continue;
    }
    const Clip *clip = findClip(id);
    if (!clip) continue;
    playing = true;
    play(*clip);
  }
}

void audioBegin() {
  i2s.setPins(PIN_I2S_BCLK, PIN_I2S_LRC, PIN_I2S_DOUT);
  if (!i2s.begin(I2S_MODE_STD, CLIP_RATE, I2S_DATA_BIT_WIDTH_16BIT,
                 I2S_SLOT_MODE_STEREO)) {
    Serial.println("speaker: I2S failed to start");
    return;
  }
  xTaskCreatePinnedToCore(audioTask, "audio", 4096, nullptr, 3, nullptr, 1);
}

void audioSay(const uint8_t *clips, size_t count) {
  count = min(count, MAX_CLIPS);
  if (count == 0) return;
  portENTER_CRITICAL(&lock);
  memcpy(queue, clips, count);
  queued = count;
  memcpy(last, clips, count);
  lastCount = count;
  interrupt = true;
  portEXIT_CRITICAL(&lock);
}

void audioSayOne(uint8_t clip) { audioSay(&clip, 1); }

void audioRepeatLast() {
  uint8_t copy[MAX_CLIPS];
  size_t count;
  portENTER_CRITICAL(&lock);
  count = lastCount;
  memcpy(copy, last, count);
  portEXIT_CRITICAL(&lock);
  audioSay(copy, count);
}

bool audioIsPlaying() { return playing; }

#else
// No speaker fitted: the phone speaks the warnings.
void audioBegin() {}
void audioSay(const uint8_t *, size_t) {}
void audioSayOne(uint8_t) {}
void audioRepeatLast() {}
bool audioIsPlaying() { return false; }
#endif
