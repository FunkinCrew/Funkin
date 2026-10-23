#pragma once

/**
 * Initializes the audio session for playback.
 *
 * This function configures the shared AVAudioSession instance with the following settings:
 * - For iOS 17.0 and above, disables interruption on route disconnect.
 * - For iOS 14.5 and above, prefers no interruptions from system alerts.
 */
void Apple_AudioSession_Initialize();
