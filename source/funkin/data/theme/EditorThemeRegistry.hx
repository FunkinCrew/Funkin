package funkin.data.theme;

import funkin.ui.debug.theme.EditorTheme;
import funkin.data.theme.EditorThemeData;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

class EditorThemeRegistry extends BaseRegistry<EditorTheme, EditorThemeData, EditorThemeEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the theme data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateThemeData()` function.
   */
  public static final THEME_DATA_VERSION:thx.semver.Version = '1.0.0';

  public static final THEME_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super('EDITORTHEME', 'ui/themes', THEME_DATA_VERSION_RULE);
  }

  public function fetchDefault():EditorTheme
  {
    return fetchEntry(Constants.DEFAULT_EDITOR_THEME);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   * @param id The ID of the entry to load.
   * @return The parsed data object.
   */
  public function parseEntryData(id:String):Null<EditorThemeData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser:json2object.JsonParser<EditorThemeData> = new json2object.JsonParser<EditorThemeData>();
    parser.ignoreUnknownVariables = false;

    switch (loadEntryFile(id))
    {
      case {fileName: fileName, contents: contents}:
        parser.fromJson(contents, fileName);
      default:
        return null;
    }

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, id);
      return null;
    }
    return parser.value;
  }

  /**
   * Parse and validate the JSON data and produce the corresponding data object.
   *
   * NOTE: Must be implemented on the implementation class.
   * @param contents The JSON as a string.
   * @param fileName An optional file name for error reporting.
   * @return The parsed data object.
   */
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<EditorThemeData>
  {
    var parser:json2object.JsonParser<EditorThemeData> = new json2object.JsonParser<EditorThemeData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }
}

typedef EditorThemeEntryParams = {}
