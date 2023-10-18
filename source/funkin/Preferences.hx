package funkin;

import funkin.save.Save;

/**
 * A store of user-configurable, globally relevant values.
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
    return Save.get().options.naughtyness;
  }

  static function set_naughtyness(value:Bool):Bool
  {
    return Save.get().options.naughtyness = value;
  }

  /**
   * If enabled, the strumline is at the bottom of the screen rather than the top.
   * @default `false`
   */
  public static var downscroll(get, set):Bool;

  static function get_downscroll():Bool
  {
    return Save.get().options.downscroll;
  }

  static function set_downscroll(value:Bool):Bool
  {
    return Save.get().options.downscroll = value;
  }

  /**
   * If disabled, flashing lights in the main menu and other areas will be less intense.
   * @default `true`
   */
  public static var flashingLights(get, set):Bool;

  static function get_flashingLights():Bool
  {
    return Save.get().options.flashingLights;
  }

  static function set_flashingLights(value:Bool):Bool
  {
    return Save.get().options.flashingLights = value;
  }

  /**
   * If disabled, the camera bump synchronized to the beat.
   * @default `false`
   */
  public static var zoomCamera(get, set):Bool;

  static function get_zoomCamera():Bool
  {
    return Save.get().options.zoomCamera;
  }

  static function set_zoomCamera(value:Bool):Bool
  {
    return Save.get().options.zoomCamera = value;
  }

  /**
   * If enabled, an FPS and memory counter will be displayed even if this is not a debug build.
   * @default `false`
   */
  public static var debugDisplay(get, set):Bool;

  static function get_debugDisplay():Bool
  {
    return Save.get().options.debugDisplay;
  }

  static function set_debugDisplay(value:Bool):Bool
  {
    if (value != Save.get().options.debugDisplay)
    {
      toggleDebugDisplay(value);
    }

    return Save.get().options.debugDisplay = value;
  }

  /**
   * If enabled, the game will automatically pause when tabbing out.
   * @default `true`
   */
  public static var autoPause(get, set):Bool;

  static function get_autoPause():Bool
  {
    return Save.get().options.autoPause;
  }

  static function set_autoPause(value:Bool):Bool
  {
    if (value != Save.get().options.autoPause) FlxG.autoPause = value;

    return Save.get().options.autoPause = value;
  }

  public static function init():Void
  {
    FlxG.autoPause = Preferences.autoPause;
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
