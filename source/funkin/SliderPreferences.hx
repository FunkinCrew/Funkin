package funkin;

import funkin.save.Save;

// TODO: Merge this into Preferences

/**
 * All slider value preferences.
 */
class SliderPreferences
{
  /**
   * How dark the black screen behind gameplay should be.
   *
   * 0 = fully transparent. 1 = opaque.
   * @default `0`
   */
  public static var gameplayBackgroundAlpha(get, set):Float;

  static function get_gameplayBackgroundAlpha():Float
  {
    return Save?.instance?.options?.gameplayBackgroundAlpha ?? 0;
  }

  static function set_gameplayBackgroundAlpha(value:Float):Float
  {
    var save:Save = Save.instance;
    save.options.gameplayBackgroundAlpha = value;
    save.flush();
    return value;
  }
}
