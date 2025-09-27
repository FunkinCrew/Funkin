package funkin.util;

/**
 * Console Utility Class.
 * Pretty sure this works on mac and linux, maybe not though?
 */
@:buildXml('
<target id="haxe">
  <lib name="dwmapi.lib" if="windows" />
  <lib name="shell32.lib" if="windows" />
  <lib name="gdi32.lib" if="windows" />
  <lib name="ole32.lib" if="windows" />
  <lib name="uxtheme.lib" if="windows" />
</target>
')
// majority is taken from microsofts doc
@:cppFileCode('
#include "mmdeviceapi.h"
#include "combaseapi.h"
#include <iostream>
#include <Windows.h>
#include <cstdio>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <Shlobj.h>
#include <wingdi.h>
#include <shellapi.h>
#include <uxtheme.h>
#include <cstdlib>
')
@:dox(hide)
class ConsoleUtil
{
  public static var consoleInitialized(default, null):Bool = false;

  /**
   * Function to run when pressing F2.
   */
  public static function enableConsole()
  {
    if (!consoleInitialized)
    {
      allocConsole();
      consoleInitialized = true;
    }
    else
    {
      showConsole();
    }
  }

  /**
   * Function to run when pressing Shift + F2.
   */
  public static function disableConsole()
  {
    hideConsole();
  }

  @:functionCode('
    // https://stackoverflow.com/questions/15543571/allocconsole-not-displaying-cout

    if (!AllocConsole())
      return;

    freopen("CONIN$", "r", stdin);
    freopen("CONOUT$", "w", stdout);
    freopen("CONOUT$", "w", stderr);
  ')
  private static function allocConsole() {}

  @:functionCode('
		ShowWindow(GetConsoleWindow(), SW_HIDE);
	')
  private static function hideConsole() {}

  @:functionCode('
		ShowWindow(GetConsoleWindow(), SW_SHOW);
	')
  private static function showConsole() {}
}
