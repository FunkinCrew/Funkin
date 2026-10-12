#pragma once

/**
 * Retrieves wether a hardware keyboard is connected to the device.
 *
 * Works on iOS 16.4 and later.
 *
 * @return Returns a Boolean value that indicates whether someone is likely to enter text using a hardware keyboard.
 */
bool Apple_KeyboardUtil_isKeyboardConnected();
