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
