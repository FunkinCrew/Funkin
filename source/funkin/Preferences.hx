package funkin;

#if mobile
import funkin.mobile.ui.FunkinHitbox;
import funkin.mobile.util.InAppPurchasesUtil;
#end
import funkin.save.Save;
import funkin.util.WindowUtil;
import funkin.util.HapticUtil.HapticsMode;

/**
 * A core class which provides a store of user-configurable, globally relevant values.
 */
@:nullSafety
class Preferences
{
  /**
   * FPS
   * Always the refresh rate of the display on mobile, or 60 on web.
   * @default `60`
   */
  public static var framerate(get, set):Int;

  static function get_framerate():Int
  {
    #if web
    return 60;
    #elseif mobile
    var refreshRate:Int = FlxG.stage.window.displayMode.refreshRate;

    if (refreshRate < 60) refreshRate = 60;

    return refreshRate;
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
    #if NO_FEATURE_NAUGHTYNESS
    return false;
    #else
    return Save?.instance?.options?.naughtyness ?? true;
    #end
  }

  static function set_naughtyness(value:Bool):Bool
  {
    #if NO_FEATURE_NAUGHTYNESS
    value = false;
    #end

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
    return Save?.instance?.options?.downscroll #if mobile ?? true #else ?? false #end;
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
    return Save?.instance?.options?.zoomCamera ?? true;
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
   * Always disabled on mobile.
   * @default `false`
   */
  public static var debugDisplay(get, set):Bool;

  static function get_debugDisplay():Bool
  {
    #if mobile
    return false;
    #end
    return Save?.instance?.options?.debugDisplay ?? false;
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
   * If enabled, haptic feedback will be enabled.
   * @default `All`
   */
  public static var hapticsMode(get, set):HapticsMode;

  static function get_hapticsMode():HapticsMode
  {
    var value = Save?.instance?.options?.hapticsMode ?? "All";

    return switch (value)
    {
      case "None":
        HapticsMode.NONE;
      case "Notes Only":
        HapticsMode.NOTES_ONLY;
      default:
        HapticsMode.ALL;
    };
  }

  static function set_hapticsMode(value:HapticsMode):HapticsMode
  {
    var string;

    switch (value)
    {
      case HapticsMode.NONE:
        string = "None";
      case HapticsMode.NOTES_ONLY:
        string = "Notes Only";
      default:
        string = "All";
    };

    var save:Save = Save.instance;
    save.options.hapticsMode = string;
    save.flush();
    return value;
  }

  /**
   * Multiplier of intensity for all the haptic feedback effects.
   * @default `2.5`
   */
  public static var hapticsIntensityMultiplier(get, set):Float;

  static function get_hapticsIntensityMultiplier():Float
  {
    return Save?.instance?.options?.hapticsIntensityMultiplier ?? 1;
  }

  static function set_hapticsIntensityMultiplier(value:Float):Float
  {
    var save:Save = Save.instance;
    save.options.hapticsIntensityMultiplier = value;
    save.flush();
    return value;
  }

  /**
   * If enabled, the game will automatically pause when tabbing out.
   * Always enabled on mobile.
   * @default `true`
   */
  public static var autoPause(get, set):Bool;

  static function get_autoPause():Bool
  {
    #if mobile
    return true;
    #end
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

  /**
   * A global audio offset in milliseconds.
   * This is used to sync the audio.
   * @default `0`
   */
  public static var globalOffset(get, set):Int;

  static function get_globalOffset():Int
  {
    return Save?.instance?.options?.globalOffset ?? 0;
  }

  static function set_globalOffset(value:Int):Int
  {
    var save:Save = Save.instance;
    save.options.globalOffset = value;
    save.flush();
    return value;
  }

  /**
   * If enabled, the game will utilize VSync (or adaptive VSync) on startup.
   * @default `OFF`
   */
  public static var vsyncMode(get, set):lime.ui.WindowVSyncMode;

  static function get_vsyncMode():lime.ui.WindowVSyncMode
  {
    var value = Save?.instance?.options?.vsyncMode ?? "Off";

    return switch (value)
    {
      case "Off":
        lime.ui.WindowVSyncMode.OFF;
      case "On":
        lime.ui.WindowVSyncMode.ON;
      case "Adaptive":
        lime.ui.WindowVSyncMode.ADAPTIVE;
      default:
        lime.ui.WindowVSyncMode.OFF;
    };
  }

  static function set_vsyncMode(value:lime.ui.WindowVSyncMode):lime.ui.WindowVSyncMode
  {
    var string;

    switch (value)
    {
      case lime.ui.WindowVSyncMode.OFF:
        string = "Off";
      case lime.ui.WindowVSyncMode.ON:
        string = "On";
      case lime.ui.WindowVSyncMode.ADAPTIVE:
        string = "Adaptive";
      default:
        string = "Off";
    };

    WindowUtil.setVSyncMode(value);

    var save:Save = Save.instance;
    save.options.vsyncMode = string;
    save.flush();
    return value;
  }

  public static var unlockedFramerate(get, set):Bool;

  static function get_unlockedFramerate():Bool
  {
    return Save?.instance?.options?.unlockedFramerate ?? false;
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
   * Loads the user's preferences from the save data and apply them.
   */
  public static function init():Void
  {
    // Apply the autoPause setting (enables automatic pausing on focus lost).
    FlxG.autoPause = Preferences.autoPause;
    // WindowUtil.setVSyncMode(Preferences.vsyncMode);
    // Apply the debugDisplay setting (enables the FPS and RAM display).
    toggleDebugDisplay(Preferences.debugDisplay);
    #if web
    toggleFramerateCap(Preferences.unlockedFramerate);
    #end

    #if desktop
    // Apply the autoFullscreen setting (launches the game in fullscreen automatically)
    FlxG.fullscreen = Preferences.autoFullscreen;
    #end

    #if mobile
    // Apply the allowScreenTimeout setting.
    lime.system.System.allowScreenTimeout = Preferences.screenTimeout;
    #end
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
      FlxG.game.parent.addChild(Main.fpsCounter);

      #if !html5
      FlxG.game.parent.addChild(Main.memoryCounter);
      #end
    }
    else
    {
      // Disable the debug display.
      FlxG.game.parent.removeChild(Main.fpsCounter);

      #if !html5
      FlxG.game.parent.removeChild(Main.memoryCounter);
      #end
    }
  }

  #if mobile
  /**
   * If enabled, device will be able to sleep on its own.
   * @default `false`
   */
  public static var screenTimeout(get, set):Bool;

  static function get_screenTimeout():Bool
  {
    return Save?.instance?.mobileOptions?.screenTimeout ?? false;
  }

  static function set_screenTimeout(value:Bool):Bool
  {
    if (value != Save.instance.mobileOptions.screenTimeout) lime.system.System.allowScreenTimeout = value;

    var save:Save = Save.instance;
    save.mobileOptions.screenTimeout = value;
    save.flush();
    return value;
  }

  /**
   * Controls Scheme for the hitbox.
   * @default `4 Lanes`
   */
  public static var controlsScheme(get, set):String;

  static function get_controlsScheme():String
  {
    return Save?.instance?.mobileOptions?.controlsScheme ?? FunkinHitboxControlSchemes.Arrows;
  }

  static function set_controlsScheme(value:String):String
  {
    var save:Save = Save.instance;
    save.mobileOptions.controlsScheme = value;
    save.flush();
    return value;
  }

  #if FEATURE_MOBILE_IAP
  /**
   * If bought, the game will not show any ads.
   * @default `false`
   */
  @:unreflective
  public static var noAds(get, set):Bool;

  @:unreflective
  static function get_noAds():Bool
  {
    if (InAppPurchasesUtil.hasInitialized) noAds = InAppPurchasesUtil.isPurchased(InAppPurchasesUtil.UPGRADE_PRODUCT_ID);
    var returnedValue = Save?.instance?.mobileOptions?.noAds ?? false;
    return returnedValue;
  }

  @:unreflective
  static function set_noAds(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.mobileOptions.noAds = value;
    save.flush();
    return value;
  }
  #end
  #end
}
