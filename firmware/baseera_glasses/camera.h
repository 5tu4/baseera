// The OV2640/OV3660 on the XIAO ESP32S3 Sense, as JPEG frames for the phone.
#pragma once

bool cameraBegin();

// Sends frames to the phone at CAMERA_FPS while it is connected and keeping
// up (frames are skipped, never queued). Runs on its own task.
void cameraStartStreaming();
