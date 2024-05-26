package funkin.mobile;

import funkin.save.Save;

/**
 * A core class which provides a store of user-configurable, globally relevant values.
 */
class MobilePreferences
{
  /**
   * Loads the user's preferences from the save data and apply them.
   */
  public static function init():Void
  {
    // empty for now
  }

  /**
   * If enabled, vpad will be disabled.
   * @default `true`
   */
  public static var legacyControls(get, set):Bool;

  static function get_legacyControls():Bool
  {
    return Save?.instance?.mobile?.legacyControls ?? true;
  }

  static function set_legacyControls(value:Bool):Bool
  {
    var save:Save = Save.instance;
    save.mobile.legacyControls = value;
    save.flush();
    return value;
  }
}
