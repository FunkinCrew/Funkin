#pragma once

void NATIVECRASH_Install(const char *logDir, const char *appName);
void NATIVECRASH_SetContext(const char *info);
void NATIVECRASH_ForceCrash();
