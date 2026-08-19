package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import funkin.PlayerSettings;
import funkin.ui.FullScreenScaleMode;
import funkin.Preferences;
import funkin.ui.debug.FunkinDebugDisplay;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.events.Event;

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
    Lib.current.addChild(new Main());
  }

  public function new()
  {
    super();

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

    // Force a `FunkinCamera` to be the default camera.
    // This allows the blend mode shader to work everywhere.
    untyped FlxG.cameras = new funkin.graphics.FunkinCameraFrontEnd();

    var framerate:Int = Preferences.unlockedFramerate ? 0 : Preferences.framerate;

    var game:FlxGame = new funkin.FunkinGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, FlxG.stage.window.fullscreen);

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
    haxe.ui.Toolkit.theme = 'funkin-dark'; // don't be cringe
    // haxe.ui.Toolkit.theme = 'light'; // embrace cringe
    haxe.ui.Toolkit.autoScale = false;
    // Don't focus on UI elements when they first appear.
    haxe.ui.focus.FocusManager.instance.autoFocus = false;
    funkin.input.Cursor.setupHaxeUICursors();
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

        debugDisplay.y = FlxG.game.y + (10 * scale);
      }
    }
  }
  #end
}
