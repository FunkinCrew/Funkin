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

  public function toString():String
  {
    return 'EditorTheme($id)';
  }

  static function _fetchData(id:String):Null<ThemeData>
  {
    return ThemeRegistry.instance.parseEntryDataWithMigration(id, ThemeRegistry.instance.fetchEntryVersion(id));
  }
}
