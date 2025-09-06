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
   * Shows a message box with an error icon.
   *
   * @param message The message to display.
   * @param title The title of the message box.
   */
  @:native('WINAPI_ShowError')
  static function showError(message:cpp.ConstCharStar, title:cpp.ConstCharStar):Void;

  /**
   * Shows a message box with a warning icon.
   *
   * @param message The message to display.
   * @param title The title of the message box.
   */
  @:native('WINAPI_ShowWarning')
  static function showWarning(message:cpp.ConstCharStar, title:cpp.ConstCharStar):Void;

  /**
   * Shows a message box with an information icon.
   *
   * @param message The message to display.
   * @param title The title of the message box.
   */
  @:native('WINAPI_ShowInformation')
  static function showInformation(message:cpp.ConstCharStar, title:cpp.ConstCharStar):Void;

  /**
   * Shows a message box with a question icon.
   *
   * @param message The message to display.
   * @param title The title of the message box.
   */
  @:native('WINAPI_ShowQuestion')
  static function showQuestion(message:cpp.ConstCharStar, title:cpp.ConstCharStar):Void;

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

  /**
   * Sets the dark mode for the active window.
   *
   * @param enable Whether to enable or disable dark mode.
   */
  @:native('WINAPI_SetDarkMode')
  static function setDarkMode(enable:Bool):Void;

  /**
   * Checks if the system is using dark mode.
   *
   * @return True if system is in dark mode, false otherwise.
   */
  @:native('WINAPI_IsSystemDarkMode')
  static function isSystemDarkMode():Bool;
}
#end
