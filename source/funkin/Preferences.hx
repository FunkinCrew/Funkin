package funkin;

import funkin.save.Save;

/**
 * A core class which provides a store of user-configurable, globally relevant values.
 */
class Preferences
{
  /**
   * FPS
   * @default `60`
   */
  public static var framerate(get, set):Int;

  static function get_framerate():Int
  {
    #if web
    return 60;
    #else
    return Save?.instance?.options?.framerate ?? 60;
    #end
  }

  static function set_framerate(value:Int):Int
  {
    #if web
    return 60;
    #else
    var save:Save = Save.instance;
    save.options.framerate = value;
    save.flush();
    FlxG.updateFramerate = value;
    FlxG.drawFramerate = value;
    return value;
    #end
  }

  /**
   * Whether some particularly foul language is displayed.
   * @default `true`
   */
  public static var naughtyness(get, set):Bool;

  static function get_naughtyness():Bool
  {
    return Save?.instance?.options?.naughtyness;
  }

  static function set_naughtyness(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.options.naughtyness = value;
    save.flush();
    return value;
  }

  /**
   * If enabled, the strumline is at the bottom of the screen rather than the top.
   * @default `false`
   */
  public static var downscroll(get, set):Bool;

  static function get_downscroll():Bool
  {
    return Save?.instance?.options?.downscroll;
  }

  static function set_downscroll(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.options.downscroll = value;
    save.flush();
    return value;
  }

  /**
   * If disabled, flashing lights in the main menu and other areas will be less intense.
   * @default `true`
   */
  public static var flashingLights(get, set):Bool;

  static function get_flashingLights():Bool
  {
    return Save?.instance?.options?.flashingLights ?? true;
  }

  static function set_flashingLights(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.options.flashingLights = value;
    save.flush();
    return value;
  }

  /**
   * If disabled, the camera bump synchronized to the beat.
   * @default `false`
   */
  public static var zoomCamera(get, set):Bool;

  static function get_zoomCamera():Bool
  {
    return Save?.instance?.options?.zoomCamera;
  }

  static function set_zoomCamera(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.options.zoomCamera = value;
    save.flush();
    return value;
  }

  /**
   * If enabled, an FPS and memory counter will be displayed even if this is not a debug build.
   * @default `false`
   */
  public static var debugDisplay(get, set):Bool;

  static function get_debugDisplay():Bool
  {
    return Save?.instance?.options?.debugDisplay;
  }

  static function set_debugDisplay(value:Bool):Bool
  {
    if (value != Save.instance.options.debugDisplay)
    {
      toggleDebugDisplay(value);
    }

    var save = Save.instance;
    save.options.debugDisplay = value;
    save.flush();
    return value;
  }

  /**
   * If enabled, the game will automatically pause when tabbing out.
   * @default `true`
   */
  public static var autoPause(get, set):Bool;

  static function get_autoPause():Bool
  {
    return Save?.instance?.options?.autoPause ?? true;
  }

  static function set_autoPause(value:Bool):Bool
  {
    if (value != Save.instance.options.autoPause) FlxG.autoPause = value;

    var save:Save = Save.instance;
    save.options.autoPause = value;
    save.flush();
    return value;
  }

  /**
   * If enabled, the game will automatically launch in fullscreen on startup.
   * @default `true`
   */
  public static var autoFullscreen(get, set):Bool;

  static function get_autoFullscreen():Bool
  {
    return Save?.instance?.options?.autoFullscreen ?? true;
  }

  static function set_autoFullscreen(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.options.autoFullscreen = value;
    save.flush();
    return value;
  }

  public static var unlockedFramerate(get, set):Bool;

  static function get_unlockedFramerate():Bool
  {
    return Save?.instance?.options?.unlockedFramerate;
  }

  static function set_unlockedFramerate(value:Bool):Bool
  {
    if (value != Save.instance.options.unlockedFramerate)
    {
      #if web
      toggleFramerateCap(value);
      #end
    }

    var save:Save = Save.instance;
    save.options.unlockedFramerate = value;
    save.flush();
    return value;
  }

  #if web
  // We create a haxe version of this just for readability.
  // We use these to override `window.requestAnimationFrame` in Javascript to uncap the framerate / "animation" request rate
  // Javascript is crazy since u can just do stuff like that lol

  public static function unlockedFramerateFunction(callback, element)
  {
    var currTime = Date.now().getTime();
    var timeToCall = 0;
    var id = js.Browser.window.setTimeout(function() {
      callback(currTime + timeToCall);
    }, timeToCall);
    return id;
  }

  // Lime already implements their own little framerate cap, so we can just use that
  // This also gets set in the init function in Main.hx, since we need to definitely override it
  public static var lockedFramerateFunction = untyped js.Syntax.code("window.requestAnimationFrame");
  #end

  /**
   * If >0, the game will display a semi-opaque background under the notes.
   * `0` for no background, `100` for solid black if you're freaky like that
   * @default `0`
   */
  public static var strumlineBackgroundOpacity(get, set):Int;

  static function get_strumlineBackgroundOpacity():Int
  {
    return (Save?.instance?.options?.strumlineBackgroundOpacity ?? 0);
  }

  static function set_strumlineBackgroundOpacity(value:Int):Int
  {
    var save:Save = Save.instance;
    save.options.strumlineBackgroundOpacity = value;
    save.flush();
    return value;
  }

  /**
   * If enabled, the game will hide the mouse when taking a screenshot.
   * @default `true`
   */
  public static var shouldHideMouse(get, set):Bool;

  static function get_shouldHideMouse():Bool
  {
    return Save?.instance?.options?.screenshot?.shouldHideMouse ?? true;
  }

  static function set_shouldHideMouse(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.options.screenshot.shouldHideMouse = value;
    save.flush();
    return value;
  }

  /**
   * If enabled, the game will show a preview after taking a screenshot.
   * @default `true`
   */
  public static var fancyPreview(get, set):Bool;

  static function get_fancyPreview():Bool
  {
    return Save?.instance?.options?.screenshot?.fancyPreview ?? true;
  }

  static function set_fancyPreview(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.options.screenshot.fancyPreview = value;
    save.flush();
    return value;
  }

  /**
   * If enabled, the game will show the preview only after a screenshot is saved.
   * @default `true`
   */
  public static var previewOnSave(get, set):Bool;

  static function get_previewOnSave():Bool
  {
    return Save?.instance?.options?.screenshot?.previewOnSave ?? true;
  }

  static function set_previewOnSave(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.options.screenshot.previewOnSave = value;
    save.flush();
    return value;
  }

  /**
   * The game will save any screenshots taken to this format.
   * @default `PNG`
   */
  public static var saveFormat(get, set):Any;

  static function get_saveFormat():Any
  {
    return Save?.instance?.options?.screenshot?.saveFormat ?? 'PNG';
  }

  static function set_saveFormat(value):Any
  {
    var save:Save = Save.instance;
    save.options.screenshot.saveFormat = value;
    save.flush();
    return value;
  }

  /**
   * The game will save JPEG screenshots with this quality percentage.
   * @default `80`
   */
  public static var jpegQuality(get, set):Int;

  static function get_jpegQuality():Int
  {
    return Save?.instance?.options?.screenshot?.jpegQuality ?? 80;
  }

  static function set_jpegQuality(value:Int):Int
  {
    var save:Save = Save.instance;
    save.options.screenshot.jpegQuality = value;
    save.flush();
    return value;
  }

  /**
   * Loads the user's preferences from the save data and apply them.
   */
  public static function init():Void
  {
    // Apply the autoPause setting (enables automatic pausing on focus lost).
    FlxG.autoPause = Preferences.autoPause;
    // Apply the debugDisplay setting (enables the FPS and RAM display).
    toggleDebugDisplay(Preferences.debugDisplay);
    #if web
    toggleFramerateCap(Preferences.unlockedFramerate);
    #end
    // Apply the autoFullscreen setting (launches the game in fullscreen automatically)
    FlxG.fullscreen = Preferences.autoFullscreen;
  }

  static function toggleFramerateCap(unlocked:Bool):Void
  {
    #if web
    var framerateFunction = unlocked ? unlockedFramerateFunction : lockedFramerateFunction;
    untyped js.Syntax.code("window.requestAnimationFrame = framerateFunction;");
    #end
  }

  static function toggleDebugDisplay(show:Bool):Void
  {
    if (show)
    {
      // Enable the debug display.
      FlxG.stage.addChild(Main.fpsCounter);
      #if !html5
      FlxG.stage.addChild(Main.memoryCounter);
      #end
    }
    else
    {
      // Disable the debug display.
      FlxG.stage.removeChild(Main.fpsCounter);
      #if !html5
      FlxG.stage.removeChild(Main.memoryCounter);
      #end
    }
  }
}
