#pragma once

typedef void (*FNFCCallback)(const char* event, const char* value);

void copyFNFCIntoCache(const char *url, FNFCCallback callback);
