// The vibration module: one-off buzzes, patterns sent by the phone, and
// parking-sensor style pulses that speed up as an obstacle gets closer (with
// the distance sensors fitted).
#pragma once
#include <stddef.h>
#include <stdint.h>

void hapticsBegin();

void hapticsBuzz(uint16_t ms);

// On/off times in ms, starting with "on". Replaces whatever is playing: the
// newest warning is the one that matters. At most 16 steps.
void hapticsPattern(const uint16_t *ms, size_t count);

// Something is cm away (and closer than alertCm); -1 stops the pulses.
void hapticsProximity(int cm, int alertCm);

// Call from loop().
void hapticsUpdate();
