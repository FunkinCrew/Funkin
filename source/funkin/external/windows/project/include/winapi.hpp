#pragma once

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
 * Registers a custom URL scheme for the current user under HKCU\Software\Classes.
 *
 * @param scheme The scheme name, without the trailing colon.
 * @param description The human readable name shown by the shell.
 * @param exePath The absolute path of the executable that should handle the scheme.
 * @return True if every key was written successfully.
 */
bool WINAPI_RegisterUrlProtocol(const char *scheme, const char *description, const char *exePath);

/**
 * Checks whether the given scheme is already pointed at the given executable for this user.
 *
 * @param scheme The scheme name, without the trailing colon.
 * @param exePath The absolute path of the executable we expect to be registered.
 * @return True if the registered open command already targets exePath.
 */
bool WINAPI_IsUrlProtocolRegistered(const char *scheme, const char *exePath);

/**
 * Removes a previously registered custom URL scheme for the current user.
 *
 * @param scheme The scheme name, without the trailing colon.
 * @return True if the scheme is gone once the call returns.
 */
bool WINAPI_UnregisterUrlProtocol(const char *scheme);
