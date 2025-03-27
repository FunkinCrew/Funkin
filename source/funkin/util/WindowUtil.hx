package funkin.util;

import flixel.util.FlxColor;
import flixel.util.FlxSignal.FlxTypedSignal;

using StringTools;

/**
 * Utilities for operating on the current window, such as changing the title.
 */
#if (cpp && windows)
@:buildXml('
<target id="haxe">
  <lib name="dwmapi.lib" if="windows"/>
</target>
')
@:cppFileCode('
#include <iostream>
#include <windows.h>
#include <psapi.h>
#include <dwmapi.h>
#include <winuser.h>

#define attributeDarkMode 20
#define attributeDarkModeFallback 19

#define attributeBorderColor 34
#define attributeCaptionColor 35
#define attributeTextColor 36

struct HandleData {
  DWORD pid = 0;
  HWND handle = 0;
};

BOOL CALLBACK findByPID(HWND handle, LPARAM lParam) {
  DWORD targetPID = ((HandleData*)lParam)->pid;
  DWORD curPID = 0;

  GetWindowThreadProcessId(handle, &curPID);
  if (targetPID != curPID || GetWindow(handle, GW_OWNER) != (HWND)0 || !IsWindowVisible(handle)) {
    return TRUE;
  }

  ((HandleData*)lParam)->handle = handle;
  return FALSE;
}

HWND curHandle = 0;
void getHandle() {
  if (curHandle == (HWND)0) {
    HandleData data;
    data.pid = GetCurrentProcessId();
    EnumWindows(findByPID, (LPARAM)&data);
    curHandle = data.handle;
  }
}

void forceRedraw() {
  if (curHandle != (HWND)0) {
    SetWindowPos(curHandle, HWND_TOP, 0, 0, 0, 0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
    RedrawWindow(curHandle, nullptr, nullptr, RDW_INVALIDATE | RDW_NOERASE | RDW_UPDATENOW | RDW_FRAME);
  }
}
')
#end
class WindowUtil
{
  /**
   * Runs platform-specific code to open a URL in a web browser.
   * @param targetUrl The URL to open.
   */
  public static function openURL(targetUrl:String):Void
  {
    #if FEATURE_OPEN_URL
    #if linux
    Sys.command('/usr/bin/xdg-open $targetUrl &');
    #else
    // This should work on Windows and HTML5.
    FlxG.openURL(targetUrl);
    #end
    #else
    throw 'Cannot open URLs on this platform.';
    #end
  }

  /**
   * Runs platform-specific code to open a path in the file explorer.
   * @param targetPath The path to open.
   */
  public static function openFolder(targetPath:String):Void
  {
    #if FEATURE_OPEN_URL
    #if windows
    Sys.command('explorer', [targetPath.replace('/', '\\')]);
    #elseif mac
    Sys.command('open', [targetPath]);
    #elseif linux
    Sys.command('open', [targetPath]);
    #end
    #else
    throw 'Cannot open URLs on this platform.';
    #end
  }

  /**
   * Runs platform-specific code to open a file explorer and select a specific file.
   * @param targetPath The path of the file to select.
   */
  public static function openSelectFile(targetPath:String):Void
  {
    #if FEATURE_OPEN_URL
    #if windows
    Sys.command('explorer', ['/select,' + targetPath.replace('/', '\\')]);
    #elseif mac
    Sys.command('open', ['-R', targetPath]);
    #elseif linux
    // TODO: unsure of the linux equivalent to opening a folder and then "selecting" a file.
    Sys.command('open', [targetPath]);
    #end
    #else
    throw 'Cannot open URLs on this platform.';
    #end
  }

  /**
   * Dispatched when the game window is closed.
   */
  public static final windowExit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

  /**
   * Wires up FlxSignals that happen based on window activity.
   * For example, we can run a callback when the window is closed.
   */
  public static function initWindowEvents():Void
  {
    // onUpdate is called every frame just before rendering.

    // onExit is called when the game window is closed.
    openfl.Lib.current.stage.application.onExit.add(function(exitCode:Int) {
      windowExit.dispatch(exitCode);
    });

    #if FEATURE_DEBUG_TRACY
    // Apply a marker to indicate frame end for the Tracy profiler.
    // Do this only if Tracy is configured to prevent lag.
    openfl.Lib.current.stage.addEventListener(openfl.events.Event.EXIT_FRAME, (e:openfl.events.Event) -> {
      cpp.vm.tracy.TracyProfiler.frameMark();
    });
    #end

    openfl.Lib.current.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e:openfl.events.KeyboardEvent) -> {
      for (key in PlayerSettings.player1.controls.getKeysForAction(WINDOW_FULLSCREEN))
      {
        // FlxG.stage.focus is set to null by the debug console stuff,
        // so when that's in focus, we don't want to toggle fullscreen using F
        // (annoying when tying "FlxG" in console... lol)
        #if FLX_DEBUG
        @:privateAccess
        if (FlxG.game.debugger.visible)
        {
          return;
        }
        #end

        if (e.keyCode == key)
        {
          openfl.Lib.application.window.fullscreen = !openfl.Lib.application.window.fullscreen;
        }
      }
    });
  }

  /**
   * Turns off that annoying "Report to Microsoft" dialog that pops up when the game crashes.
   */
  public static function disableCrashHandler():Void
  {
    #if (cpp && windows)
    untyped __cpp__('SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);');
    #else
    // Do nothing.
    #end
  }

  /**
   * Sets the title of the application window.
   * @param value The title to use.
   */
  public static function setWindowTitle(value:String):Void
  {
    lime.app.Application.current.window.title = value;
  }

  /**
   * Enables or disables dark mode support for the title bar.
   *
   * Only works on Windows 1809 and later.
   *
   * @param enable Whether to enable or disable dark mode support.
   * @param instant Whether to skip the transition tween.
   */
  public static function setWindowDarkMode(enable:Bool = true, instant:Bool = false):Void
  {
    #if (cpp && windows)
    var success:Bool = false;
    untyped __cpp__('
      getHandle();
      if (curHandle != (HWND)0) {
        const BOOL darkMode = enable ? TRUE : FALSE;

        success = (S_OK == DwmSetWindowAttribute(curHandle, attributeDarkMode, (LPCVOID)&darkMode, (DWORD)sizeof(darkMode)));
        if (!success) {
          // Pre-20H1
          success = (S_OK == DwmSetWindowAttribute(curHandle, attributeDarkModeFallback, (LPCVOID)&darkMode, (DWORD)sizeof(darkMode)));
        }

        if (success && !instant) {
          forceRedraw();
        }
      }
    ');

    if (success && instant)
    {
      final curBarColor:Null<FlxColor> = windowBarColor;
      windowBarColor = 0x00000000;
      windowBarColor = curBarColor;
    }
    #else
    // Do nothing.
    #end
  }

  /**
   * The color of the window title bar. If `null`, the system default is used (`0xffffffff`).
   *
   * Only works on Windows 21H2 and later.
   */
  public static var windowBarColor(default, set):Null<FlxColor> = null;
  public static function set_windowBarColor(value:Null<FlxColor>):Null<FlxColor>
  {
    #if (cpp && windows)
    final intColor:Int = Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, value.alpha) : 0xffffffff;
    untyped __cpp__('
      getHandle();
      if (curHandle != (HWND)0) {
        const COLORREF targetColor = (COLORREF)intColor;
        if (S_OK == DwmSetWindowAttribute(curHandle, attributeCaptionColor, (LPCVOID)&targetColor, (DWORD)sizeof(targetColor))) {
          forceRedraw();
        }
      }
    ');
    #else
    // Do nothing.
    #end

    return windowBarColor = value;
  }

  /**
   * The color of the window title bar text. If `null`, the system default is used (`0xffffffff`).
   *
   * Only works on Windows 21H2 and later.
   */
  public static var windowTextColor(default, set):Null<FlxColor> = null;
  public static function set_windowTextColor(value:Null<FlxColor>):Null<FlxColor>
  {
    #if (cpp && windows)
    final intColor:Int = Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, value.alpha) : 0xffffffff;
    untyped __cpp__('
      getHandle();
      if (curHandle != (HWND)0) {
        const COLORREF targetColor = (COLORREF)intColor;
        if (S_OK == DwmSetWindowAttribute(curHandle, attributeTextColor, (LPCVOID)&targetColor, (DWORD)sizeof(targetColor))) {
          forceRedraw();
        }
      }
    ');
    #else
    // Do nothing.
    #end

    return windowTextColor = value;
  }

  /**
   * The color of the window border. If `null`, the system default is used (`0xffffffff`).
   * Setting to `0xfffeffff` will disable the border entirely (use a color with alpha 0 to re-enable it).
   *
   * Only works on Windows 21H2 and later.
   */
  public static var windowBorderColor(default, set):Null<FlxColor> = null;
  public static function set_windowBorderColor(value:Null<FlxColor>):Null<FlxColor>
  {
    #if (cpp && windows)
    final intColor:Int = Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, value.alpha) : 0xffffffff;
    untyped __cpp__('
      getHandle();
      if (curHandle != (HWND)0) {
        const COLORREF targetColor = (COLORREF)intColor;
        if (S_OK == DwmSetWindowAttribute(curHandle, attributeBorderColor, (LPCVOID)&targetColor, (DWORD)sizeof(targetColor))) {
          forceRedraw();
        }
      }
    ');
    #else
    // Do nothing.
    #end

    return windowBorderColor = value;
  }
}
