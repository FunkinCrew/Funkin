package funkin.external.windows;

#if (windows && cpp)
/**
 * This class provides handling for Windows API-related functions.
 */
@:build(funkin.util.macro.LinkerMacro.xml('project/Build.xml'))
@:include('winapi.hpp')
extern class WinAPI
{
  /**
   * Disables the "Report to Microsoft" dialog that appears when the application crashes.
   */
  @:native('WINAPI_DisableErrorReporting')
  static function disableErrorReporting():Void;

  /**
   * Disables Windows ghosting, which prevents the system from marking unresponsive windows as "Not Responding."
   */
  @:native('WINAPI_DisableWindowsGhosting')
  static function disableWindowsGhosting():Void;

  /**
   * Retrieves the current working set size (in bytes) of the process.
   *
   * @return The size of the working set memory used by the process.
   */
  @:native('WINAPI_GetProcessMemoryWorkingSetSize')
  static function getProcessMemoryWorkingSetSize():cpp.SizeT;
}
#end
