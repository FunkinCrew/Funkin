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

void WINAPI_ShowError(const char *message, const char *title)
{
  MessageBox(GetActiveWindow(), message, title, MB_OK | MB_ICONERROR);
}

void WINAPI_ShowWarning(const char *message, const char *title)
{
  MessageBox(GetActiveWindow(), message, title, MB_OK | MB_ICONWARNING);
}

void WINAPI_ShowInformation(const char *message, const char *title)
{
  MessageBox(GetActiveWindow(), message, title, MB_OK | MB_ICONINFORMATION);
}

void WINAPI_ShowQuestion(const char *message, const char *title)
{
  MessageBox(GetActiveWindow(), message, title, MB_OKCANCEL | MB_ICONQUESTION);
}

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

void WINAPI_SetDarkMode(bool enable)
{
  HWND window = GetActiveWindow();

  int darkMode = enable ? 1 : 0;

  if (DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode)) != S_OK)
    DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode));

  UpdateWindow(window);
}

bool WINAPI_IsSystemDarkMode()
{
  HKEY hKey;
  DWORD dwValue = 0;
  DWORD dwSize = sizeof(DWORD);
  DWORD dwType = REG_DWORD;

  if (RegOpenKeyEx(HKEY_CURRENT_USER, "Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize", 0, KEY_READ, &hKey) == ERROR_SUCCESS)
  {
    if (RegQueryValueEx(hKey, "AppsUseLightTheme", NULL, &dwType, (LPBYTE)&dwValue, &dwSize) == ERROR_SUCCESS)
    {
      RegCloseKey(hKey);
      return dwValue == 0;
    }

    RegCloseKey(hKey);
  }

  return false;
}
