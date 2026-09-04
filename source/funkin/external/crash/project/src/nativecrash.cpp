#define _CRT_SECURE_NO_WARNINGS

#include "nativecrash.hpp"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(_WIN32)
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <dbghelp.h>
#include <signal.h>
#include <exception>
#if defined(_MSC_VER)
#include <new.h>
#endif
#else
#include <cxxabi.h>
#include <dlfcn.h>
#include <execinfo.h>
#include <signal.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <pthread.h>
#include <unistd.h>
#if defined(__APPLE__)
#include <CoreFoundation/CoreFoundation.h>
#endif
#endif

#define NC_LOGDIR_MAX 512
#define NC_NAME_MAX 128
#define NC_CONTEXT_MAX 1024
#define NC_PATH_MAX 1024
#define NC_FRAMES 64

static char gLogDir[NC_LOGDIR_MAX] = "logs";
static char gAppName[NC_NAME_MAX] = "Funkin";
static char gContext[NC_CONTEXT_MAX] = "(nothing recorded)";
static time_t gContextTime = 0;
static char gReportPath[NC_PATH_MAX] = "";

static bool gInstalled = false;

// Set the moment a fault is picked up.
static volatile int gHandling = 0;

static void nc_ensureLogDir()
{
#if defined(_WIN32)
	CreateDirectoryA(gLogDir, NULL);
#else
	mkdir(gLogDir, 0755);
#endif
}

static FILE *nc_openReport()
{
	time_t now = time(NULL);
	struct tm *local = localtime(&now);

	if (local == NULL)
	{
		snprintf(gReportPath, sizeof(gReportPath), "%s/crash-native.log", gLogDir);
	}
	else
	{
		snprintf(gReportPath, sizeof(gReportPath), "%s/crash-native-%04d-%02d-%02d-%02d-%02d-%02d.log", gLogDir,
				 local->tm_year + 1900, local->tm_mon + 1, local->tm_mday, local->tm_hour, local->tm_min, local->tm_sec);
	}

	nc_ensureLogDir();

	FILE *file = fopen(gReportPath, "w");

	// Fall back to a simple name if the log dir is not writable.
	if (file == NULL)
	{
		snprintf(gReportPath, sizeof(gReportPath), "crash-native.log");
		file = fopen(gReportPath, "w");
	}

	return file;
}

static void nc_writeHeader(FILE *file, const char *kind, const char *detail)
{
	time_t now = time(NULL);

	fprintf(file, "=====================\n");
	fprintf(file, "%s Crash Report\n", gAppName);
	fprintf(file, "=====================\n\n");

	fprintf(file, "Fault: %s\n", kind);

	if (detail != NULL && detail[0] != 0) fprintf(file, "Detail: %s\n", detail);

	fprintf(file, "Time: %s", ctime(&now));

#if defined(_WIN32)
	fprintf(file, "Thread: %lu\n", (unsigned long)GetCurrentThreadId());
#else
	fprintf(file, "Thread: %p\n", (void *)pthread_self());
#endif

	fprintf(file, "\n=====================\n\n");
	fprintf(file, "Doing: %s\n", gContext);

	if (gContextTime != 0) fprintf(file, "Recorded: %ld seconds before the fault\n", (long)(now - gContextTime));
	fprintf(file, "\n=====================\n\n");
	fprintf(file, "Stack:\n");
}

#if defined(_WIN32)

static void nc_writeFrame(FILE *file, int index, DWORD64 address, HANDLE process)
{
	char symBuffer[sizeof(SYMBOL_INFO) + 512];
	memset(symBuffer, 0, sizeof(symBuffer));

	SYMBOL_INFO *symbol = (SYMBOL_INFO *)symBuffer;
	symbol->SizeOfStruct = sizeof(SYMBOL_INFO);
	symbol->MaxNameLen = 511;

	DWORD64 symbolOffset = 0;
	bool named = SymFromAddr(process, address, &symbolOffset, symbol) != FALSE;

	fprintf(file, "  #%-2d 0x%016llx", index, (unsigned long long)address);

	HMODULE module = NULL;
	if (GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
						   (LPCSTR)address, &module)
		&& module != NULL)
	{
		char full[MAX_PATH];
		const char *shortName = "?";

		if (GetModuleFileNameA(module, full, MAX_PATH))
		{
			const char *slash = strrchr(full, '\\');
			shortName = slash ? slash + 1 : full;
		}

		fprintf(file, "  %s+0x%llx", shortName, (unsigned long long)(address - (DWORD64)module));
	}
	else
	{
		fprintf(file, "  (no module)");
	}

	// Only print the symbol if it is a reasonable offset from the address.
	if (named && symbolOffset < 0x8000) fprintf(file, "  %s+0x%llx", symbol->Name, (unsigned long long)symbolOffset);

	IMAGEHLP_LINE64 line;
	memset(&line, 0, sizeof(line));
	line.SizeOfStruct = sizeof(IMAGEHLP_LINE64);

	DWORD lineOffset = 0;
	if (SymGetLineFromAddr64(process, address, &lineOffset, &line)) fprintf(file, "  (%s:%lu)", line.FileName, (unsigned long)line.LineNumber);

	fprintf(file, "\n");
}

static void nc_writeStack(FILE *file, CONTEXT *context)
{
	HANDLE process = GetCurrentProcess();
	HANDLE thread = GetCurrentThread();

	SymSetOptions(SYMOPT_DEFERRED_LOADS | SYMOPT_UNDNAME | SYMOPT_LOAD_LINES);

	bool symbols = SymInitialize(process, NULL, TRUE) != FALSE;

	CONTEXT walk = *context;

	STACKFRAME64 frame;
	memset(&frame, 0, sizeof(frame));

	DWORD machine;

#if defined(_M_X64)
	machine = IMAGE_FILE_MACHINE_AMD64;
	frame.AddrPC.Offset = walk.Rip;
	frame.AddrFrame.Offset = walk.Rbp;
	frame.AddrStack.Offset = walk.Rsp;
#elif defined(_M_IX86)
	machine = IMAGE_FILE_MACHINE_I386;
	frame.AddrPC.Offset = walk.Eip;
	frame.AddrFrame.Offset = walk.Ebp;
	frame.AddrStack.Offset = walk.Esp;
#elif defined(_M_ARM64)
	machine = IMAGE_FILE_MACHINE_ARM64;
	frame.AddrPC.Offset = walk.Pc;
	frame.AddrFrame.Offset = walk.Fp;
	frame.AddrStack.Offset = walk.Sp;
#else
	fprintf(file, "  (stack not available for this architecture)\n");
	if (symbols) SymCleanup(process);
	return;
#endif

	frame.AddrPC.Mode = AddrModeFlat;
	frame.AddrFrame.Mode = AddrModeFlat;
	frame.AddrStack.Mode = AddrModeFlat;

	for (int i = 0; i < NC_FRAMES; i++)
	{
		if (!StackWalk64(machine, process, thread, &frame, &walk, NULL, SymFunctionTableAccess64, SymGetModuleBase64, NULL)) break;
		if (frame.AddrPC.Offset == 0) break;

		nc_writeFrame(file, i, frame.AddrPC.Offset, process);
	}

	if (symbols) SymCleanup(process);
}

static void nc_showDialog(const char *body)
{
	char title[NC_NAME_MAX + 32];
	snprintf(title, sizeof(title), "%s has crashed", gAppName);

	int titleLen = MultiByteToWideChar(CP_UTF8, 0, title, -1, NULL, 0);
	int bodyLen = MultiByteToWideChar(CP_UTF8, 0, body, -1, NULL, 0);

	if (titleLen <= 0 || bodyLen <= 0) return;

	wchar_t *wideTitle = (wchar_t *)malloc(sizeof(wchar_t) * titleLen);
	wchar_t *wideBody = (wchar_t *)malloc(sizeof(wchar_t) * bodyLen);

	if (wideTitle != NULL && wideBody != NULL)
	{
		MultiByteToWideChar(CP_UTF8, 0, title, -1, wideTitle, titleLen);
		MultiByteToWideChar(CP_UTF8, 0, body, -1, wideBody, bodyLen);

		MessageBoxW(NULL, wideBody, wideTitle, MB_OK | MB_ICONERROR | MB_SETFOREGROUND | MB_TOPMOST);
	}

	free(wideTitle);
	free(wideBody);
}

static const char *nc_describe(DWORD code)
{
	switch (code)
	{
		case EXCEPTION_ACCESS_VIOLATION: return "Access violation";
		case EXCEPTION_ARRAY_BOUNDS_EXCEEDED: return "Array bounds exceeded";
		case EXCEPTION_DATATYPE_MISALIGNMENT: return "Datatype misalignment";
		case EXCEPTION_FLT_DIVIDE_BY_ZERO: return "Floating point divide by zero";
		case EXCEPTION_FLT_INVALID_OPERATION: return "Invalid floating point operation";
		case EXCEPTION_ILLEGAL_INSTRUCTION: return "Illegal instruction";
		case EXCEPTION_IN_PAGE_ERROR: return "In page error";
		case EXCEPTION_INT_DIVIDE_BY_ZERO: return "Integer divide by zero";
		case EXCEPTION_NONCONTINUABLE_EXCEPTION: return "Noncontinuable exception";
		case EXCEPTION_PRIV_INSTRUCTION: return "Privileged instruction";
		case EXCEPTION_STACK_OVERFLOW: return "Stack overflow";
		default: return "Unhandled exception";
	}
}

static bool nc_isFault(DWORD code)
{
	switch (code)
	{
		case 0xE06D7363: // A C++ throw in flight.
		case EXCEPTION_BREAKPOINT:
		case EXCEPTION_SINGLE_STEP:
		case DBG_PRINTEXCEPTION_C:
#if defined(DBG_PRINTEXCEPTION_WIDE_C)
		case DBG_PRINTEXCEPTION_WIDE_C:
#endif
			return false;
		default: return true;
	}
}

static void nc_report(const char *kind, const char *detail, CONTEXT *context)
{
	if (gHandling)
	{
		fprintf(stderr, "[crash] faulted again while reporting a crash, giving up\n");
		fflush(stderr);
		TerminateProcess(GetCurrentProcess(), 3);
		return;
	}

	gHandling = 1;

	FILE *file = nc_openReport();

	if (file != NULL)
	{
		nc_writeHeader(file, kind, detail);

		if (context != NULL) nc_writeStack(file, context);
		else fprintf(file, "  (no context record available)\n");

		fflush(file);
		fclose(file);
	}

	char body[NC_CONTEXT_MAX + NC_PATH_MAX + 512];
	snprintf(body, sizeof(body), "%s\n\n%s\n\nDoing: %s\n\nA report was written to:\n%s", kind, detail != NULL ? detail : "",
			 gContext, file != NULL ? gReportPath : "(the report could not be written)");

	nc_showDialog(body);

	TerminateProcess(GetCurrentProcess(), 1);
}

static LONG WINAPI nc_exceptionFilter(EXCEPTION_POINTERS *info)
{
	if (info == NULL || info->ExceptionRecord == NULL) return EXCEPTION_CONTINUE_SEARCH;

	DWORD code = info->ExceptionRecord->ExceptionCode;

	if (!nc_isFault(code)) return EXCEPTION_CONTINUE_SEARCH;

	char detail[256];

	if (code == EXCEPTION_ACCESS_VIOLATION && info->ExceptionRecord->NumberParameters >= 2)
	{
		ULONG_PTR operation = info->ExceptionRecord->ExceptionInformation[0];
		ULONG_PTR address = info->ExceptionRecord->ExceptionInformation[1];

		snprintf(detail, sizeof(detail), "code 0x%08lx at 0x%p, tried to %s 0x%p", (unsigned long)code,
				 info->ExceptionRecord->ExceptionAddress, operation == 0 ? "read" : operation == 1 ? "write" : "execute", (void *)address);
	}
	else
	{
		snprintf(detail, sizeof(detail), "code 0x%08lx at 0x%p", (unsigned long)code, info->ExceptionRecord->ExceptionAddress);
	}

	nc_report(nc_describe(code), detail, info->ContextRecord);

	return EXCEPTION_EXECUTE_HANDLER;
}

static void nc_onAbort(int signalNumber)
{
	(void)signalNumber;

	CONTEXT context;
	RtlCaptureContext(&context);

	nc_report("Aborted", "the C runtime called abort()", &context);
}

static void nc_onTerminate()
{
	CONTEXT context;
	RtlCaptureContext(&context);

	nc_report("Terminated", "an exception escaped without a handler", &context);
}

static void nc_onPureCall()
{
	CONTEXT context;
	RtlCaptureContext(&context);

	nc_report("Pure virtual call", "a virtual method was called on a partly destroyed object", &context);
}

#if defined(_MSC_VER)
static int nc_onAllocationFailed(size_t size)
{
	(void)size;

	CONTEXT context;
	RtlCaptureContext(&context);

	nc_report("Out of memory", "an allocation failed", &context);

	return 0;
}
#endif

#else

static void nc_writeStack(FILE *file)
{
	void *frames[NC_FRAMES];
	int count = backtrace(frames, NC_FRAMES);

	for (int i = 0; i < count; i++)
	{
		fprintf(file, "  #%-2d %p", i, frames[i]);

		Dl_info info;
		if (dladdr(frames[i], &info) && info.dli_fname != NULL)
		{
			const char *slash = strrchr(info.dli_fname, '/');
			const char *shortName = slash ? slash + 1 : info.dli_fname;

			fprintf(file, "  %s+0x%lx", shortName, (unsigned long)((char *)frames[i] - (char *)info.dli_fbase));

			if (info.dli_sname != NULL)
			{
				unsigned long symbolOffset = (unsigned long)((char *)frames[i] - (char *)info.dli_saddr);

				int status = 0;
				char *pretty = abi::__cxa_demangle(info.dli_sname, NULL, NULL, &status);

				fprintf(file, "  %s+0x%lx", (status == 0 && pretty != NULL) ? pretty : info.dli_sname, symbolOffset);

				free(pretty);
			}
		}
		else
		{
			fprintf(file, " (no object)");
		}

		fprintf(file, "\n");
	}

	fflush(file);

	fprintf(file, "\nRaw:\n");
	fflush(file);

	backtrace_symbols_fd(frames, count, fileno(file));
}

static void nc_showDialog(const char *body)
{
#if defined(__APPLE__)
	char title[NC_NAME_MAX + 32];
	snprintf(title, sizeof(title), "%s has crashed", gAppName);

	CFStringRef titleRef = CFStringCreateWithCString(NULL, title, kCFStringEncodingUTF8);
	CFStringRef bodyRef = CFStringCreateWithCString(NULL, body, kCFStringEncodingUTF8);

	if (titleRef != NULL && bodyRef != NULL)
	{
		CFOptionFlags response = 0;
		CFUserNotificationDisplayAlert(0, kCFUserNotificationStopAlertLevel, NULL, NULL, NULL, titleRef, bodyRef, NULL, NULL, NULL, &response);
	}

	if (titleRef != NULL) CFRelease(titleRef);
	if (bodyRef != NULL) CFRelease(bodyRef);
#else
	fprintf(stderr, "\n%s\n", body);
	fflush(stderr);
#endif
}

static const char *nc_describe(int signalNumber)
{
	switch (signalNumber)
	{
		case SIGSEGV: return "Segmentation fault";
		case SIGBUS: return "Bus error";
		case SIGFPE: return "Arithmetic fault";
		case SIGILL: return "Illegal instruction";
		case SIGABRT: return "Aborted";
		default: return "Fatal signal";
	}
}

static void nc_report(const char *kind, const char *detail)
{
	if (gHandling)
	{
		fprintf(stderr, "[crash] failed to report a crash\n");
		fflush(stderr);
		_exit(3);
	}

	gHandling = 1;

	FILE *file = nc_openReport();

	if (file != NULL)
	{
		nc_writeHeader(file, kind, detail);
		nc_writeStack(file);

		fflush(file);
		fclose(file);
	}

	char body[NC_CONTEXT_MAX + NC_PATH_MAX + 512];
	snprintf(body, sizeof(body), "%s\n\n%s\n\nDoing: %s\n\nA report was written to:\n%s", kind, detail != NULL ? detail : "",
			 gContext, file != NULL ? gReportPath : "(the report could not be written)");

	nc_showDialog(body);

	_exit(1);
}

static void nc_onSignal(int signalNumber, siginfo_t *info, void *context)
{
	(void)context;

	char detail[256];

	if (info != NULL) snprintf(detail, sizeof(detail), "signal %d, code %d, at %p", signalNumber, info->si_code, info->si_addr);
	else snprintf(detail, sizeof(detail), "signal %d", signalNumber);

	nc_report(nc_describe(signalNumber), detail);
}

#endif

void NATIVECRASH_Install(const char *logDir, const char *appName)
{
	if (gInstalled) return;

	if (logDir != NULL && logDir[0] != 0)
	{
		strncpy(gLogDir, logDir, sizeof(gLogDir) - 1);
		gLogDir[sizeof(gLogDir) - 1] = 0;
	}

	if (appName != NULL && appName[0] != 0)
	{
		strncpy(gAppName, appName, sizeof(gAppName) - 1);
		gAppName[sizeof(gAppName) - 1] = 0;
	}

#if defined(_WIN32)
	// Reserve stack for the handler, otherwise a stack overflow leaves no room to report itself.
	ULONG guarantee = 64 * 1024;
	SetThreadStackGuarantee(&guarantee);

	SetUnhandledExceptionFilter(nc_exceptionFilter);

	signal(SIGABRT, nc_onAbort);
	std::set_terminate(nc_onTerminate);

#if defined(_MSC_VER)
	_set_purecall_handler(nc_onPureCall);
	_set_new_handler(nc_onAllocationFailed);
#endif
#else
	static char alternateStack[256 * 1024];

	stack_t alternate;
	memset(&alternate, 0, sizeof(alternate));
	alternate.ss_sp = alternateStack;
	alternate.ss_size = sizeof(alternateStack);
	alternate.ss_flags = 0;
	sigaltstack(&alternate, NULL);

	struct sigaction action;
	memset(&action, 0, sizeof(action));
	action.sa_sigaction = nc_onSignal;
	action.sa_flags = SA_SIGINFO | SA_ONSTACK | SA_RESETHAND;
	sigemptyset(&action.sa_mask);

	sigaction(SIGSEGV, &action, NULL);
	sigaction(SIGBUS, &action, NULL);
	sigaction(SIGFPE, &action, NULL);
	sigaction(SIGILL, &action, NULL);
	sigaction(SIGABRT, &action, NULL);
#endif

	gInstalled = true;
}

void NATIVECRASH_SetContext(const char *info)
{
	if (info == NULL || info[0] == 0)
	{
		strncpy(gContext, "(nothing recorded)", sizeof(gContext) - 1);
	}
	else
	{
		strncpy(gContext, info, sizeof(gContext) - 1);
	}

	gContext[sizeof(gContext) - 1] = 0;
	gContextTime = time(NULL);
}
