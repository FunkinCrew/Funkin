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
   * @return The size of the working set memory used by the process.
   */
  @:native('WINAPI_GetProcessMemoryWorkingSetSize')
  static function getProcessMemoryWorkingSetSize():cpp.SizeT;

  /**
   * Registers a custom URL scheme for the current user, so links using it launch this executable.
   * Writes to HKCU, so no administrator rights are needed.
   * @param scheme The scheme name, without the trailing colon.
   * @param description The human readable name shown by the shell.
   * @param exePath The absolute path of the executable that should handle the scheme.
   * @return Whether the registration succeeded.
   */
  @:native('WINAPI_RegisterUrlProtocol')
  static function registerUrlProtocol(scheme:cpp.ConstCharStar, description:cpp.ConstCharStar, exePath:cpp.ConstCharStar):Bool;

  /**
   * Checks whether the given scheme already points at the given executable for this user.
   * @param scheme The scheme name, without the trailing colon.
   * @param exePath The absolute path of the executable we expect to be registered.
   * @return Whether the scheme is registered to that executable.
   */
  @:native('WINAPI_IsUrlProtocolRegistered')
  static function isUrlProtocolRegistered(scheme:cpp.ConstCharStar, exePath:cpp.ConstCharStar):Bool;

  /**
   * Removes a previously registered custom URL scheme for the current user.
   * @param scheme The scheme name, without the trailing colon.
   * @return Whether the scheme is gone once the call returns.
   */
  @:native('WINAPI_UnregisterUrlProtocol')
  static function unregisterUrlProtocol(scheme:cpp.ConstCharStar):Bool;
}
#end
