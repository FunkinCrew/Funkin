package;

import lime.system.System;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import funkin.ui.FullScreenScaleMode;
import funkin.Preferences;
import funkin.PlayerSettings;
import funkin.util.logging.CrashHandler;
import funkin.ui.debug.FunkinDebugDisplay;
import funkin.ui.debug.FunkinDebugDisplay.DebugDisplayMode;
import funkin.save.Save;
#if hxvlc
import hxvlc.util.Handle;
#end
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.Lib;
import openfl.media.Video;
import openfl.net.NetStream;
import funkin.util.WindowUtil;

using funkin.util.AnsiUtil;

/**
 * The main class which initializes HaxeFlixel and starts the game in its initial state.
 */
class Main extends Sprite
{
  var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
  var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
  var initialState:Class<FlxState> = funkin.InitState; // The FlxState the game starts with.
  var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
  var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.

  // You can pretty much ignore everything from here on - your code should go in your states.

  public static function main():Void
  {
    // Set the current working directory for Android and iOS devices
    #if android
    // On Android use External Files Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(extension.androidtools.content.Context.getExternalFilesDir()));
    #elseif ios
    // On iOS use Documents Dir.
    Sys.setCwd(haxe.io.Path.addTrailingSlash(lime.system.System.documentsDirectory));
    #end

    // We need to make the crash handler LITERALLY FIRST so nothing EVER gets past it.
    CrashHandler.initialize();
    CrashHandler.queryStatus();

    Lib.current.addChild(new Main());
  }

  public function new()
  {
    super();

    // Initialize custom logging.
    haxe.Log.trace = funkin.util.logging.AnsiTrace.trace;
    funkin.util.logging.AnsiTrace.traceBF();

    // Get OpenFL to stop complaining so much.
    // You can remove this line if you want to read debug messages.
    openfl.utils._internal.Log.level = openfl.utils._internal.Log.LogLevel.INFO;

    // Load mods to override assets.
    // TODO: Replace with loadEnabledMods() once the user can configure the mod list.
    funkin.modding.PolymodHandler.loadAllMods();

    if (stage != null)
    {
      init();
    }
    else
    {
      addEventListener(Event.ADDED_TO_STAGE, init);
    }
  }

  function init(?event:Event):Void
  {
    if (hasEventListener(Event.ADDED_TO_STAGE))
    {
      removeEventListener(Event.ADDED_TO_STAGE, init);
    }

    #if (sys && !mobile)
    // Force-kill the game to prevent background processing.
    Lib.current.stage.window.onClose.add(function()
    {
      trace(' EXITING '.bold().bg_red() + ' Game is exiting, cleaning up resources...');

      #if hxvlc
      // Clean up VLC threads to prevent memory leaks.
      hxvlc.util.Handle.dispose();
      #end

      Sys.exit(0);
    });
    #end

    // Manually crash the game when using a software renderer in order to give a nicer error message.
    var context = stage.window.context.type;
    if (context != WEBGL && context != OPENGL && context != OPENGLES)
    {
      var tech:String = #if web "WebGL" #elseif desktop "OpenGL" #else "OpenGL ES" #end;
      var requiredVersion:String = #if web '$tech 1.0 or newer' #elseif desktop '$tech 3.0 or newer' #else '$tech 2.0 or newer' #end;
      var desc:String = 'Failed to initialize the $tech rendering context!\n\n';
      #if web
      desc += 'Make sure your graphics card supports $requiredVersion, your graphics drivers are up to date, and hardware acceleration is enabled on your browser.';
      #elseif desktop
      desc += 'Make sure your graphics card supports $requiredVersion, and your graphics drivers are up to date.';
      #else
      desc += 'Make sure your device supports $requiredVersion.';
      #end

      WindowUtil.showError('Failed to initialize $tech', desc);
      System.exit(1);
    }

    setupGame();
  }

  /**
   * The debug display at the top left.
   */
  public static var debugDisplay:FunkinDebugDisplay;

  function setupGame():Void
  {
    #if FEATURE_HAXEUI
    initHaxeUI();
    #end

    // addChild gets called by the user settings code.
    debugDisplay = new FunkinDebugDisplay(10, 10, 0xFFFFFF);

    // Add this signal so the player can toggle the debug display using a hotkey.
    FlxG.signals.postUpdate.add(handleDebugDisplayKeys);

    #if mobile
    // Add this signal so we can reposition and resize the memory and fps counter.
    FlxG.signals.preUpdate.add(repositionCounters.bind(true));
    #end

    // George recommends binding the save before FlxGame is created.
    Save.load();

    #if hxvlc
    // Initialize hxvlc's Handle here so the videos are loading faster.
    Handle.initAsync(function(success:Bool):Void
    {
      if (success)
      {
        trace(' HXVLC '.bold().bg_orange() + ' LibVLC instance initialized!');
      }
      else
      {
        trace(' HXVLC '.bold().bg_orange() + ' LibVLC instance failed to initialize!');
      }
    });
    #end

    WindowUtil.setVSyncMode(funkin.Preferences.vsyncMode);

    // Force a `FunkinCamera` to be the default camera.
    // This allows the blend mode shader to work everywhere.
    untyped FlxG.cameras = new funkin.graphics.FunkinCameraFrontEnd();

    var framerate:Int = Preferences.unlockedFramerate ? 0 : Preferences.framerate;

    var game:FlxGame = new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash,
      (FlxG.stage.window.fullscreen || Preferences.autoFullscreen));

    // FlxG.game._customSoundTray wants just the class, it calls new from
    // create() in there, which gets called when it's added to the stage
    // which is why it needs to be added before addChild(game) here
    @:privateAccess
    game._customSoundTray = funkin.ui.options.FunkinSoundTray;

    addChild(game);

    #if FEATURE_DEBUG_FUNCTIONS
    #if !FLX_NO_DEBUG game.debugger.interaction.addTool(new funkin.util.TrackerToolButtonUtil()); #end
    funkin.util.macro.ConsoleMacro.init();
    #end

    #if !html5
    FlxG.scaleMode = new FullScreenScaleMode();
    #end

    #if mobile
    // Reposition and resize the memory and fps counter without lerping.
    repositionCounters(false);
    #end

    #if hxcpp_debug_server
    trace('hxcpp_debug_server is enabled! You can now connect to the game with a debugger.');
    #else
    trace('hxcpp_debug_server is disabled! This build does not support debugging.');
    #end
  }

  #if FEATURE_HAXEUI
  function initHaxeUI():Void
  {
    // This has to come before Toolkit.init since locales get initialized there
    haxe.ui.locale.LocaleManager.instance.autoSetLocale = false;
    // Calling this before any HaxeUI components get used is important:
    // - It initializes the theme styles.
    // - It scans the class path and registers any HaxeUI components.
    haxe.ui.Toolkit.init();
    haxe.ui.Toolkit.theme = 'dark'; // don't be cringe
    // haxe.ui.Toolkit.theme = 'light'; // embrace cringe
    haxe.ui.Toolkit.autoScale = false;
    // Don't focus on UI elements when they first appear.
    haxe.ui.focus.FocusManager.instance.autoFocus = false;
    funkin.input.Cursor.registerHaxeUICursors();
    haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
  }
  #end

  function handleDebugDisplayKeys():Void
  {
    if (PlayerSettings.player1.controls == null || !PlayerSettings.player1.controls.check(DEBUG_DISPLAY)) return;

    var nextMode:DebugDisplayMode;

    switch (Preferences.debugDisplay)
    {
      case DebugDisplayMode.Off:
        nextMode = DebugDisplayMode.Simple;
      case DebugDisplayMode.Simple:
        nextMode = DebugDisplayMode.Advanced;
      case DebugDisplayMode.Advanced:
        nextMode = DebugDisplayMode.Off;
    }

    Preferences.debugDisplay = nextMode;
  }

  #if mobile
  function repositionCounters(lerp:Bool):Void
  {
    // Calling this so it gets scaled based on the resolution of the game and device's resolution.
    var scale:Float = Math.max(Math.min(FlxG.stage.stageWidth / FlxG.width, FlxG.stage.stageHeight / FlxG.height), 1);

    if (debugDisplay != null)
    {
      debugDisplay.scaleX = debugDisplay.scaleY = scale;

      if (FlxG.game != null)
      {
        final thypos:Float = Math.max(FullScreenScaleMode.notchSize.x, 10);

        if (lerp)
        {
          debugDisplay.x = flixel.math.FlxMath.lerp(debugDisplay.x, FlxG.game.x + thypos, FlxG.elapsed * 3);
        }
        else
        {
          debugDisplay.x = FlxG.game.x + thypos;
        }

        debugDisplay.y = FlxG.game.y + (3 * scale);
      }
    }
  }
  #end
}
