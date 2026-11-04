// Spoken warnings: short clips compiled into the firmware (clips.h), played
// through the MAX98357A on its own task. Without HAS_SPEAKER these do nothing.
#pragma once
#include <stddef.h>
#include <stdint.h>

void audioBegin();

// Plays these clips in order. Replaces whatever is playing or queued: the
// newest warning is the one that matters.
void audioSay(const uint8_t *clips, size_t count);
void audioSayOne(uint8_t clip);

// The button's short press: the last warning again.
void audioRepeatLast();

bool audioIsPlaying();
