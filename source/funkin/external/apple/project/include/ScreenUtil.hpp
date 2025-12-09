#pragma once

/**
 * Retrieves the safe area insets for the current screen on iOS devices.
 *
 * This function populates the provided pointers with the safe area insets (in pixels) for the top, bottom, left, and right edges of the screen.
 * On iOS 11 and later, it uses the main window's safeAreaInsets and converts them to pixel values using the screen scale.
 * On earlier iOS versions, all insets are set to 0.0.
 *
 * @param top Pointer to a double to receive the top safe area inset (in pixels).
 * @param bottom Pointer to a double to receive the bottom safe area inset (in pixels).
 * @param left Pointer to a double to receive the left safe area inset (in pixels).
 * @param right Pointer to a double to receive the right safe area inset (in pixels).
 */
void Apple_ScreenUtil_GetSafeAreaInsets(double* top, double* bottom, double* left, double* right);

/**
 * Retrieves the size of the main screen in pixels.
 *
 * @param width  Pointer to a double where the screen width (in pixels) will be stored.
 * @param height Pointer to a double where the screen height (in pixels) will be stored.
 */
void Apple_ScreenUtil_GetScreenSize(double* width, double* height);
