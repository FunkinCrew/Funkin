#pragma once

/**
 * Initializes the audio session for playback.
 *
 * This function configures the shared AVAudioSession instance with the following settings:
 * - Sets the audio session category to Playback, allowing Bluetooth A2DP and mixing with spoken audio interruptions.
 * - For iOS 17.0 and above, disables interruption on route disconnect.
 * - For iOS 14.5 and above, prefers no interruptions from system alerts.
 */
void Apple_AudioSession_Initialize();

/**
 * Sets the active state of the shared AVAudioSession.
 *
 * @param active Whether to activate or deactivate the audio session.
 */
void Apple_AudioSession_SetActive(bool active);
