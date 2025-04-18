package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import funkin.ui.FullScreenScaleMode;
import funkin.Preferences;
import funkin.util.logging.CrashHandler;
import funkin.ui.debug.MemoryCounter;
import funkin.save.Save;
import haxe.ui.Toolkit;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.Lib;
import openfl.media.Video;
import openfl.net.NetStream;
import funkin.util.WindowUtil;

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
  var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

  // You can pretty much ignore everything from here on - your code should go in your states.

  public static function main():Void
  {
    // Set the current working directory for Android and iOS devices
    #if android
    // For Android we determine the appropriate directory based on Android version
    Sys.setCwd(haxe.io.Path.addTrailingSlash(android.os.Build.VERSION.SDK_INT > 30 ? android.content.Context.getObbDir() : // Use Obb directory for Android SDK version > 30
      android.content.Context.getExternalFilesDir() // Use External Files directory for Android SDK version < 30
    ));
    #elseif ios
    Sys.setCwd(haxe.io.Path.addTrailingSlash(lime.system.System.documentsDirectory)); // For iOS we use documents directory and this is only way we can do.
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
    #if web
    // set this variable (which is a function) from the lime version at lime/_internal/backend/html5/HTML5Application.hx
    // The framerate cap will more thoroughly initialize via Preferences in InitState.hx
    funkin.Preferences.lockedFramerateFunction = untyped js.Syntax.code("window.requestAnimationFrame");
    #end

    WindowUtil.setVSyncMode(funkin.Preferences.vsyncMode);

    if (hasEventListener(Event.ADDED_TO_STAGE))
    {
      removeEventListener(Event.ADDED_TO_STAGE, init);
    }

    setupGame();
  }

  var video:Video;
  var netStream:NetStream;
  var overlay:Sprite;

  /**
   * A frame counter displayed at the top left.
   */
  public static var fpsCounter:FPS;

  /**
   * A RAM counter displayed at the top left.
   */
  public static var memoryCounter:MemoryCounter;

  function setupGame():Void
  {
    initHaxeUI();

    // addChild gets called by the user settings code.
    fpsCounter = new FPS(10, 3, 0xFFFFFF);

    #if !html5
    // addChild gets called by the user settings code.
    // TODO: disabled on HTML5 (todo: find another method that works?)
    memoryCounter = new MemoryCounter(10, 13, 0xFFFFFF);
    #end

    #if mobile
    // Add this signal so we can repososition and resize the memory and fps counter.
    FlxG.signals.preUpdate.add(repositionCounters.bind(true));
    #end

    // George recommends binding the save before FlxGame is created.
    Save.load();

    var game:FlxGame = new FlxGame(gameWidth, gameHeight, initialState, Preferences.framerate, Preferences.framerate, skipSplash, startFullscreen);

    // FlxG.game._customSoundTray wants just the class, it calls new from
    // create() in there, which gets called when it's added to the stage
    // which is why it needs to be added before addChild(game) here
    @:privateAccess
    game._customSoundTray = funkin.ui.options.FunkinSoundTray;

    #if FEATURE_ADMOB_ADS
    funkin.mobile.util.AdMobUtil.init();
    #end

    addChild(game);

    #if FEATURE_DEBUG_FUNCTIONS
    game.debugger.interaction.addTool(new funkin.util.TrackerToolButtonUtil());
    #end

    addChild(fpsCounter);

    #if mobile
    FlxG.scaleMode = new FullScreenScaleMode();
    #end

    #if mobile
    // Repososition and resize the memory and fps counter without lerping.
    repositionCounters(false);
    #end

    #if hxcpp_debug_server
    trace('hxcpp_debug_server is enabled! You can now connect to the game with a debugger.');
    #else
    trace('hxcpp_debug_server is disabled! This build does not support debugging.');
    #end
  }

  function initHaxeUI():Void
  {
    // Calling this before any HaxeUI components get used is important:
    // - It initializes the theme styles.
    // - It scans the class path and registers any HaxeUI components.
    Toolkit.init();
    Toolkit.theme = 'dark'; // don't be cringe
    // Toolkit.theme = 'light'; // embrace cringe
    Toolkit.autoScale = false;
    // Don't focus on UI elements when they first appear.
    haxe.ui.focus.FocusManager.instance.autoFocus = false;
    funkin.input.Cursor.registerHaxeUICursors();
    haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
  }

  #if mobile
  function repositionCounters(lerp:Bool):Void
  {
    // Calling this so it gets scaled based on the resolution of the game and device's resolution.
    var scale:Float = Math.min(flixel.FlxG.stage.stageWidth / flixel.FlxG.width, flixel.FlxG.stage.stageHeight / flixel.FlxG.height);
    #if android
    scale = scale > 1 ? scale : 1;
    #else
    scale = scale < 1 ? scale : 1;
    #end

    if (fpsCounter != null)
    {
      fpsCounter.scaleX = fpsCounter.scaleY = scale;

      if (FlxG.game != null)
      {
        if (lerp) fpsCounter.x = flixel.math.FlxMath.lerp(fpsCounter.x, FlxG.game.x + FullScreenScaleMode.notchSize.x + 10, FlxG.elapsed * 3);
        else
        {
          fpsCounter.x = FlxG.game.x + FullScreenScaleMode.notchSize.x + 10;
        }

        fpsCounter.y = FlxG.game.y + (3 * scale);
      }
    }

    if (memoryCounter != null)
    {
      memoryCounter.scaleX = memoryCounter.scaleY = scale;

      if (FlxG.game != null)
      {
        if (lerp) memoryCounter.x = flixel.math.FlxMath.lerp(fpsCounter.x, FlxG.game.x + FullScreenScaleMode.notchSize.x + 10, FlxG.elapsed * 3);
        else
        {
          memoryCounter.x = FlxG.game.x + FullScreenScaleMode.notchSize.x + 10;
        }

        memoryCounter.y = FlxG.game.y + (13 * scale);
      }
    }
  }
  #end
}
