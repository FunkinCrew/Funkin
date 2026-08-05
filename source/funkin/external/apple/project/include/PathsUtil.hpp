#pragma once

/**
 * Returns the current application's cache directory.
 *
 * @return A UTF-8 string containing the cache directory path, or `NULL` on failure.
 */
const char *Apple_PathsUtil_GetCacheDirectory();
