package funkin.ui.debug.theme;

import funkin.data.IRegistryEntry;
import funkin.data.theme.ThemeData;
import funkin.data.theme.ThemeRegistry;
import flixel.util.FlxColor;

class EditorTheme implements IRegistryEntry<ThemeData>
{
  /**
   * The internal ID for this theme.
   */
  public final id:String;

  /**
   * The full data for this theme.
   */
  public final _data:ThemeData;

  public function new(id:String)
  {
    this.id = id;
    this._data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse theme data for id: $id';
    }
  }

  /**
   * Return the name of the theme.
   * @return The name of the theme
   */
  public function getThemeName():String
  {
    return _data.name ?? 'Unknown Theme';
  }

  /**
   *  Return the data for chart editor colors.
   *  @return The chart theme data
   */
  public function getChartData() {
    return _data?.chart;
  }

  /**
   * Return the data for stage editor colors.
   * @return The stage theme data
   */
  public function getStageData() {
    return _data?.stage;
  }

  public function getColor(name:String, fallback:FlxColor, ?useStageData:Bool = false):FlxColor
  {
    var data:Dynamic = useStageData ? getStageData() : getChartData();
    if (data == null) return fallback;

    var regex = ~/^([a-zA-Z0-9_]+)\[(\d+)\]$/;
    if (regex.match(name))
    {
      var fieldName = regex.matched(1);
      var index = Std.parseInt(regex.matched(2));
      if (fieldName == null || index == null) return fallback;

      var arr:Null<Array<String>> = Reflect.field(data, fieldName);
      if (arr != null && index >= 0 && index < arr.length)
      {
        var colorStr = arr[index];
        var targetColor:Null<FlxColor> = FlxColor.fromString(colorStr);
        return targetColor != null ? targetColor : fallback;
      }

      return fallback;
    }

    var fieldValue = Reflect.field(data, name);
    if (fieldValue == null) return fallback;

    var targetColor:Null<FlxColor> = FlxColor.fromString(fieldValue);
    if (targetColor != null) return targetColor;

    return fallback;
  }

  public function toString():String
  {
    return 'EditorTheme($id)';
  }

  static function _fetchData(id:String):Null<ThemeData>
  {
    return ThemeRegistry.instance.parseEntryDataWithMigration(id, ThemeRegistry.instance.fetchEntryVersion(id));
  }
}
