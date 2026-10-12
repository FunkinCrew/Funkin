#pragma once

#include <cstddef>

/**
 * Retrieves the current process's resident set size (RSS) in bytes on Apple platforms.
 *
 * @return The resident set size (RSS) in bytes if successful; otherwise, returns 0 on failure.
 */
size_t Apple_MemoryUtil_GetCurrentProcessRss();
