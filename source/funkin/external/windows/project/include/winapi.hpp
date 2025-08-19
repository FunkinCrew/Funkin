#pragma once

/**
 * @brief Shows an error message box
 * @param message The error message to display
 * @param title The title of the message box
 */
void WINAPI_ShowError(const char *message, const char *title);

/**
 * @brief Shows a warning message box
 * @param message The warning message to display
 * @param title The title of the message box
 */
void WINAPI_ShowWarning(const char *message, const char *title);

/**
 * @brief Shows an information message box
 * @param message The information message to display
 * @param title The title of the message box
 */
void WINAPI_ShowInformation(const char *message, const char *title);

/**
 * @brief Shows a question message box with OK/Cancel buttons
 * @param message The question message to display
 * @param title The title of the message box
 */
void WINAPI_ShowQuestion(const char *message, const char *title);

/**
 * @brief Disables Windows error reporting dialogs
 */
void WINAPI_DisableErrorReporting();

/**
 * @brief Disables Windows ghosting for the current process
 */
void WINAPI_DisableWindowsGhosting();

/**
 * @brief Sets dark mode for the active window
 * @param enable True to enable dark mode, false to disable
 */
void WINAPI_SetDarkMode(bool enable);

/**
 * @brief Checks if the system is using dark mode
 * @return True if system is in dark mode, false otherwise
 */
bool WINAPI_IsSystemDarkMode();
