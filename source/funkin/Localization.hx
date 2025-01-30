package funkin;

import firetongue.FireTongue;
import firetongue.Replace;
import lime.system.Locale;
import openfl.Assets as OpenFLAssets;
#if (lime >= "7.0.0")
import lime.utils.Assets as LimeAssets;
#elseif (lime && !lime_legacy)
import lime.Assets as LimeAssets;
#end

class Localization
{
  public static var sysLocale(get, never):String;

  public static var tongue(get, never):FireTongue;
  static var _tongue:FireTongue;

  static function get_tongue():FireTongue
  {
    // getText('locales/index.xml');
    if (_tongue == null)
    {
      _tongue = new FireTongue(null, null, null, null);
    }
    return _tongue;
  }

  static function get_sysLocale():String
  {
    var local:String = Locale.systemLocale;
    if (local.contains(".")) local = local.substr(0, local.indexOf("."));
    trace('Da system locale is: ' + local);
    return local;
  }

  /**
   * Loads the user's preferences for the localization and loads it.
   */
  public static function init():Void
  {
    // nothing yet
    tongue.initialize(
      {
        locale: Preferences.locale,
        checkMissing: true,
        // directory: 'locales',
      });
    trace(tongue.locales);
  }

  static function getText(filename:String):String
  {
    // var index:String = LimeAssets.getText(Paths.file(filename, TEXT));
    var index:String = OpenFLAssets.getText(Paths.file(filename, TEXT));
    trace(filename);
    trace(index);
    return index;
  }

  static function getDirectoryContents(path:String):Array<String>
  {
    // return Assets.getText(Paths.getPath(path, TEXT));
    return [];
  }
}
