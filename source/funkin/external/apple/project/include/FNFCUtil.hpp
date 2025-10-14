#pragma once

/**
 * Function pointer type for handling events with associated string values.
 *
 * @param event The name of the event as a null-terminated string.
 * @param value The value associated with the event as a null-terminated string.
 */
typedef void (*FNFCCallback)(const char* event, const char* value);

/**
 * Copies the FNFC resource from the specified URL into the cache.
 *
 * @param url The URL of the FNFC resource to copy into the cache.
 * @param callback A function to be called when the copy operation completes.
 */
void Apple_FNFCUtil_CopyFNFCIntoCache(const char *url, FNFCCallback callback);
