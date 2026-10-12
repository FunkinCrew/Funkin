#define WIN32_LEAN_AND_MEAN // Excludes rarely-used APIs like cryptography, DDE, RPC, and shell functions, reducing compile time and binary size.
#define NOMINMAX // Prevents Windows from defining min() and max() macros, which can conflict with standard C++ functions.
#define NOCRYPT // Excludes Cryptographic APIs, such as Encrypt/Decrypt functions.
#define NOCOMM // Excludes serial communication APIs, such as COM port handling.
#define NOKANJI // Excludes Kanji character set support (not needed unless working with Japanese text processing).
#define NOHELP // Excludes Windows Help APIs, removing functions related to WinHelp and other help systems.

#include <windows.h>
#include <psapi.h>
#include <dwmapi.h>
#include <stdint.h>
#include <stdio.h>

void WINAPI_DisableErrorReporting()
{
  SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
}

void WINAPI_DisableWindowsGhosting()
{
  DisableProcessWindowsGhosting();
}

size_t WINAPI_GetProcessMemoryWorkingSetSize()
{
	PROCESS_MEMORY_COUNTERS_EX pmc;

	if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc)))
		return pmc.WorkingSetSize;

	return 0;
}
