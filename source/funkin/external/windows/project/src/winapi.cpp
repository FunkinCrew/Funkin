#define WIN32_LEAN_AND_MEAN // Excludes rarely-used APIs like cryptography, DDE, RPC, and shell functions, reducing compile time and binary size.
#define NOMINMAX						// Prevents Windows from defining min() and max() macros, which can conflict with standard C++ functions.
#define NOCRYPT							// Excludes Cryptographic APIs, such as Encrypt/Decrypt functions.
#define NOCOMM							// Excludes serial communication APIs, such as COM port handling.
#define NOKANJI							// Excludes Kanji character set support (not needed unless working with Japanese text processing).
#define NOHELP							// Excludes Windows Help APIs, removing functions related to WinHelp and other help systems.

#include <windows.h>
#include <psapi.h>
#include <dwmapi.h>
#include <stdint.h>
#include <stdio.h>
#include <string>

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

	if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS *)&pmc, sizeof(pmc)))
		return pmc.WorkingSetSize;

	return 0;
}

// The root every scheme key hangs off of. HKCU keeps this a per user opt in with no UAC prompt.
static const char *URL_PROTOCOL_ROOT = "Software\\Classes\\";

static bool WriteDefaultValue(const std::string &subKey, const std::string &value)
{
	HKEY key = NULL;

	if (RegCreateKeyExA(HKEY_CURRENT_USER, subKey.c_str(), 0, NULL, REG_OPTION_NON_VOLATILE, KEY_WRITE, NULL, &key, NULL) != ERROR_SUCCESS)
		return false;

	// The cast is safe, registry string lengths are bounded well below 2GB.
	LONG result = RegSetValueExA(key, NULL, 0, REG_SZ, (const BYTE *)value.c_str(), (DWORD)(value.size() + 1));

	RegCloseKey(key);

	return result == ERROR_SUCCESS;
}

static bool ReadDefaultValue(const std::string &subKey, std::string &out)
{
	HKEY key = NULL;

	if (RegOpenKeyExA(HKEY_CURRENT_USER, subKey.c_str(), 0, KEY_READ, &key) != ERROR_SUCCESS)
		return false;

	char buffer[1024];
	DWORD size = sizeof(buffer);
	DWORD type = 0;

	LONG result = RegQueryValueExA(key, NULL, NULL, &type, (LPBYTE)buffer, &size);

	RegCloseKey(key);

	if (result != ERROR_SUCCESS || type != REG_SZ)
		return false;

	// RegQueryValueExA does not guarantee the value is null terminated.
	if (size == 0)
		out = "";
	else
		out = std::string(buffer, buffer[size - 1] == '\0' ? size - 1 : size);

	return true;
}

static std::string BuildOpenCommand(const char *exePath)
{
	return std::string("\"") + exePath + "\" \"%1\"";
}

bool WINAPI_RegisterUrlProtocol(const char *scheme, const char *description, const char *exePath)
{
	if (scheme == NULL || description == NULL || exePath == NULL)
		return false;

	std::string root = std::string(URL_PROTOCOL_ROOT) + scheme;

	if (!WriteDefaultValue(root, std::string("URL:") + description))
		return false;

	// The presence of an (empty) "URL Protocol" value is what marks the key as a scheme handler.
	HKEY key = NULL;

	if (RegOpenKeyExA(HKEY_CURRENT_USER, root.c_str(), 0, KEY_WRITE, &key) != ERROR_SUCCESS)
		return false;

	LONG marker = RegSetValueExA(key, "URL Protocol", 0, REG_SZ, (const BYTE *)"", 1);

	RegCloseKey(key);

	if (marker != ERROR_SUCCESS)
		return false;

	if (!WriteDefaultValue(root + "\\DefaultIcon", std::string(exePath) + ",0"))
		return false;

	return WriteDefaultValue(root + "\\shell\\open\\command", BuildOpenCommand(exePath));
}

bool WINAPI_IsUrlProtocolRegistered(const char *scheme, const char *exePath)
{
	if (scheme == NULL || exePath == NULL)
		return false;

	std::string command;

	if (!ReadDefaultValue(std::string(URL_PROTOCOL_ROOT) + scheme + "\\shell\\open\\command", command))
		return false;

	return command == BuildOpenCommand(exePath);
}

bool WINAPI_UnregisterUrlProtocol(const char *scheme)
{
	if (scheme == NULL)
		return false;

	std::string root = std::string(URL_PROTOCOL_ROOT) + scheme;

	// RegDeleteTreeA removes the subkeys as well, which RegDeleteKeyA refuses to do.
	LONG result = RegDeleteTreeA(HKEY_CURRENT_USER, root.c_str());

	return result == ERROR_SUCCESS || result == ERROR_FILE_NOT_FOUND;
}
