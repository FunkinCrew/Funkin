package funkin;

import haxe.ds.StringMap;
import funkin.save.Save;

/**
 * An abstract class which behaves as a StringMap, caching all getters of options,
 * while also providing a more versitile way of modders adding their own preference setters and getters,
 * without requiring arbritrary Save instance calls or even null checking those instance calls.
 *
 * The reason for caching all the preferences into a StringMap, rather than just calling straight to Save data,
 * is the use of the Reflect API. This caching aims to keep it's use of Reflection to a minimum.
 */
abstract PreferenceMap(StringMap<Any>)
{
  public function new()
  {
    this = new StringMap<Any>();
  }

  /**
   * An operator overloading function, which returns either a cached instance of the current preference,
   * or a Save instance call.
   * @param key Alias for `key` in `StringMap#get(key)`.
   * @return Any
   */
  @:op(a.b)
  inline function fieldReadOverload(key:String):Any
  {
    // Previously, I did null condition the Save instance, but the getter for instance already does the null checking.
    if (!this.exists(key)) this.set(key, Reflect.field(Save.instance.options, key));
    return this.get(key);
  }

  /**
   * An operator overloading function, which sets not only the Save data for the preference
   * but also sets itself into this, as to not conflict with the getter.
   * @param key Alias for `key` in `StringMap#set(key, value)`.
   * @param value Alias for `value` in `StringMap#set(key, value)`.
   * @return Any
   */
  @:op(a.b)
  inline function fieldWriteOverload(key:String, value:Any):Any
  {
    Reflect.setField(Save.instance.options, key, value);
    Save.instance.flush();
    this.set(key, value);
    return value;
  }
}

/**
 * A core class which provides a store of user-configurable, globally relevant values.
 */
class Preferences
{
  static final PREFERENCE_MAP:PreferenceMap = new PreferenceMap();

  /**
   * Gets a abstracted StringMap, which acts as a wrapper for getting and setting Save option data.
   * @return PreferenceMap
   */
  public static function get():PreferenceMap
  {
    return PREFERENCE_MAP;
  }

  /**
   * Whether some particularly fowl language is displayed.
   * @default `true`
   */
  public static var naughtyness(get, set):Bool;

  static function get_naughtyness():Bool
  {
    return get().naughtyness;
  }

  static function set_naughtyness(value:Bool):Bool
  {
    return get().naughtyness = value;
  }

  /**
   * If enabled, the strumline is at the bottom of the screen rather than the top.
   * @default `false`
   */
  public static var downscroll(get, set):Bool;

  static function get_downscroll():Bool
  {
    return get().downscroll;
  }

  static function set_downscroll(value:Bool):Bool
  {
    return get().downscroll = value;
  }

  /**
   * If disabled, flashing lights in the main menu and other areas will be less intense.
   * @default `true`
   */
  public static var flashingLights(get, set):Bool;

  static function get_flashingLights():Bool
  {
    return get().flashingLights ?? true;
  }

  static function set_flashingLights(value:Bool):Bool
  {
    return get().flashingLights = value;
  }

  /**
   * If disabled, the camera bump synchronized to the beat.
   * @default `false`
   */
  public static var zoomCamera(get, set):Bool;

  static function get_zoomCamera():Bool
  {
    return get().zoomCamera;
  }

  static function set_zoomCamera(value:Bool):Bool
  {
    return get().zoomCamera = value;
  }

  /**
   * If enabled, an FPS and memory counter will be displayed even if this is not a debug build.
   * @default `false`
   */
  public static var debugDisplay(get, set):Bool;

  static function get_debugDisplay():Bool
  {
    return get().debugDisplay;
  }

  static function set_debugDisplay(value:Bool):Bool
  {
    if (value != get().debugDisplay)
    {
      toggleDebugDisplay(value);
    }
    return get().debugDisplay = value;
  }

  /**
   * If enabled, the game will automatically pause when tabbing out.
   * @default `true`
   */
  public static var autoPause(get, set):Bool;

  static function get_autoPause():Bool
  {
    return get().autoPause ?? true;
  }

  static function set_autoPause(value:Bool):Bool
  {
    if (value != get().autoPause) FlxG.autoPause = value;
    return get().autoPause = value;
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
