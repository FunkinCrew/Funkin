package funkin;

import funkin.save.Save;

/**
 * A core class which provides a store of user-configurable, globally relevant values.
 */
class Preferences
{
  /**
   * Whether some particularly fowl language is displayed.
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
   * Loads the user's preferences from the save data and apply them.
   */
  public static function init():Void
  {
    // Apply the autoPause setting (enables automatic pausing on focus lost).
    FlxG.autoPause = Preferences.autoPause;
    // Apply the debugDisplay setting (enables the FPS and RAM display).
    toggleDebugDisplay(Preferences.debugDisplay);
    #if mobile
    // Apply the allowScreenTimeout setting (enables screen timeout).
    lime.system.System.allowScreenTimeout = Preferences.screenTimeout;
    #end
  }

  static function toggleDebugDisplay(show:Bool):Void
  {
    if (show)
    {
      // Enable the debug display.
      #if mobile
      FlxG.game.addChild(Main.fpsCounter);
      #else
      FlxG.stage.addChild(Main.fpsCounter);
      #end

      #if !html5
      #if mobile
      FlxG.game.addChild(Main.memoryCounter);
      #else
      FlxG.stage.addChild(Main.memoryCounter);
      #end
      #end
    }
    else
    {
      // Disable the debug display.
      #if mobile
      FlxG.game.removeChild(Main.fpsCounter);
      #else
      FlxG.stage.removeChild(Main.fpsCounter);
      #end

      #if !html5
      #if mobile
      FlxG.game.removeChild(Main.memoryCounter);
      #else
      FlxG.stage.removeChild(Main.memoryCounter);
      #end
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
   * If enabled, vibration will be enabled.
   * @default `true`
   */
  public static var vibration(get, set):Bool;

  static function get_vibration():Bool
  {
    return Save?.instance?.mobileOptions?.vibration ?? true;
  }

  static function set_vibration(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.mobileOptions.vibration = value;
    save.flush();
    return value;
  }
  #end
}
