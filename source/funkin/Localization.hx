package funkin;

import firetongue.FireTongue;
import firetongue.Replace;

class Localization
{
  public static var tongue(get, never):FireTongue;
  static var _tongue:FireTongue;

  static function get_tongue():FireTongue
  {
    if (_tongue == null)
    {
      _tongue = new FireTongue();
    }
    return _tongue;
  }

  /**
   * Loads the user's preferences for the localization and loads it.
   */
  public static function init():Void {}
}
