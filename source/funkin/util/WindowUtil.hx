package funkin.util;

import flixel.util.FlxSignal.FlxTypedSignal;

using StringTools;

/**
 * Utilities for operating on the current window, such as changing the title.
 */
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
      #if FEATURE_HAXEUI
      if (haxe.ui.focus.FocusManager.instance.focus != null)
      {
        return;
      }
      #end

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
}
