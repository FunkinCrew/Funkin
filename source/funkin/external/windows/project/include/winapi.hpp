#pragma once

/**
 * Shows an error message box.
 *
 * @param message The error message to display
 * @param title The title of the message box
 */
void WINAPI_ShowError(const char *message, const char *title);

/**
 * Shows a warning message box.
 *
 * @param message The warning message to display
 * @param title The title of the message box
 */
void WINAPI_ShowWarning(const char *message, const char *title);

/**
 * Shows an information message box.
 *
 * @param message The information message to display
 * @param title The title of the message box
 */
void WINAPI_ShowInformation(const char *message, const char *title);

/**
 * Shows a question message box with OK/Cancel buttons.
 *
 * @param message The question message to display
 * @param title The title of the message box
 */
void WINAPI_ShowQuestion(const char *message, const char *title);

/**
 * Disables Windows error reporting dialogs.
 */
void WINAPI_DisableErrorReporting();

/**
 * Disables Windows ghosting for the current process.
 */
void WINAPI_DisableWindowsGhosting();

/**
 * Retrieves the current working set size (in bytes) of the calling process.
 *
 * This function queries the operating system for the amount of physical memory currently allocated to the process (its working set).
 *
 * @return The working set size in bytes. Returns 0 if the query fails.
 */
size_t WINAPI_GetProcessMemoryWorkingSetSize();

/**
 * Sets dark mode for the active window.
 *
 * @param enable True to enable dark mode, false to disable
 */
void WINAPI_SetDarkMode(bool enable);

/**
 * Checks if the system is using dark mode.
 *
 * @return True if system is in dark mode, false otherwise
 */
bool WINAPI_IsSystemDarkMode();
