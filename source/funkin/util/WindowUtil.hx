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
@:nullSafety
class WindowUtil
{
  /**
   * A regex to match valid URLs.
   */
  public static final URL_REGEX:EReg = ~/^https?:\/?\/?(?:www\.)?[-a-zA-Z0-9@:%_\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)$/;

  /**
   * Sanitizes a URL via a regex.
   *
   * @param targetUrl The URL to sanitize.
   * @return The sanitized URL, or an empty string if the URL is invalid.
   */
  public static function sanitizeURL(targetUrl:String):String
  {
    targetUrl = (targetUrl ?? '').trim();
    if (targetUrl == '')
    {
      return '';
    }

    final lowerUrl:String = targetUrl.toLowerCase();
    if (!lowerUrl.startsWith('http:') && !lowerUrl.startsWith('https:'))
    {
      targetUrl = 'http://' + targetUrl;
    }

    if (URL_REGEX.match(targetUrl))
    {
      return URL_REGEX.matched(0);
    }

    return '';
  }

  /**
   * Runs platform-specific code to open a URL in a web browser.
   * @param targetUrl The URL to open.
   */
  public static function openURL(targetUrl:String):Void
  {
    // Ensure you can't open protocols such as steam://, file://, etc
    var protocol:Array<String> = targetUrl.split("://");
    if (protocol.length == 1) targetUrl = 'https://${targetUrl}';
    else if (protocol[0] != 'http' && protocol[0] != 'https') throw "openURL can only open http and https links.";

    #if FEATURE_OPEN_URL
    targetUrl = sanitizeURL(targetUrl);
    if (targetUrl == '')
    {
      throw 'Invalid URL: "$targetUrl"';
    }

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

  #if FEATURE_DEBUG_TRACY
  /**
   * Initialize Tracy.
   * NOTE: Call this from the main thread ONLY!
   */
  public static function initTracy():Void
  {
    var appInfoMessage = funkin.util.logging.CrashHandler.buildSystemInfo();

    trace("Friday Night Funkin': Connection to Tracy profiler successful.");

    // Post system info like Git hash
    cpp.vm.tracy.TracyProfiler.messageAppInfo(appInfoMessage);

    cpp.vm.tracy.TracyProfiler.setThreadName("main");
  }
  #end

  /**
   * Dispatched when the game window is closed.
   */
  public static final windowExit:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

  /**
   * Has `initWindowEvents()` been called already?
   * This is to prevent multiple instances of the same function.
   */
  private static var _initializedWindowEvents:Bool = false;

  /**
   * Wires up FlxSignals that happen based on window activity.
   * For example, we can run a callback when the window is closed.
   */
  public static function initWindowEvents():Void
  {
    if (_initializedWindowEvents) return; // Fix that annoying
    // onUpdate is called every frame just before rendering.

    // onExit is called when the game window is closed.
    openfl.Lib.current.stage.application.onExit.add(function(exitCode:Int) {
      windowExit.dispatch(exitCode);
    });

    #if (desktop || html5)
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
    #end
    _initializedWindowEvents = true;
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
   * Shows an error dialog with an error icon.
   * @param name The title of the dialog window.
   * @param desc The error message to display.
   */
  public static function showError(name:String, desc:String):Void
  {
    #if (windows && cpp)
    funkin.external.windows.WinAPI.showError(desc, name);
    #else
    lime.app.Application.current.window.alert(desc, name);
    #end
  }

  /**
   * Shows a warning dialog with a warning icon.
   * @param name The title of the dialog window.
   * @param desc The warning message to display.
   */
  public static function showWarning(name:String, desc:String):Void
  {
    #if (windows && cpp)
    funkin.external.windows.WinAPI.showWarning(desc, name);
    #else
    lime.app.Application.current.window.alert(desc, name);
    #end
  }

  /**
   * Shows an information dialog with an information icon.
   * @param name The title of the dialog window.
   * @param desc The information message to display.
   */
  public static function showInformation(name:String, desc:String):Void
  {
    #if (windows && cpp)
    funkin.external.windows.WinAPI.showInformation(desc, name);
    #else
    lime.app.Application.current.window.alert(desc, name);
    #end
  }

  /**
   * Shows a question dialog with a question icon and OK/Cancel buttons.
   * @param name The title of the dialog window.
   * @param desc The question message to display.
   */
  public static function showQuestion(name:String, desc:String):Void
  {
    #if (windows && cpp)
    funkin.external.windows.WinAPI.showQuestion(desc, name);
    #else
    lime.app.Application.current.window.alert(desc, name);
    #end
  }

  public static function setVSyncMode(value:lime.ui.WindowVSyncMode):Void
  {
    // vsync crap dont worky on mac rn derp
    #if !mac
    var res:Bool = FlxG.stage.application.window.setVSyncMode(value);

    // SDL_GL_SetSwapInterval returns the value we assigned on success, https://wiki.libsdl.org/SDL2/SDL_GL_GetSwapInterval#return-value.
    // In lime, we can compare this to the original value to get a boolean.
    if (!res)
    {
      trace('Failed to set VSync mode to ' + value);
      FlxG.stage.application.window.setVSyncMode(lime.ui.WindowVSyncMode.OFF);
    }
    #end
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
    final intColor:Int = value != null && Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, value.alpha) : 0xffffffff;
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
    final intColor:Int = value != null && Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, value.alpha) : 0xffffffff;
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
    final intColor:Int = value != null && Std.isOfType(value, Int) ? cast FlxColor.fromRGB(value.blue, value.green, value.red, value.alpha) : 0xffffffff;
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
