package funkin.data.freeplay.style;

import funkin.ui.freeplay.FreeplayStyle;
import funkin.data.freeplay.style.FreeplayStyleData;
import funkin.ui.freeplay.ScriptedFreeplayStyle;

class FreeplayStyleRegistry extends BaseRegistry<FreeplayStyle, FreeplayStyleData>
{
  /**
   * The current version string for the style data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStyleData()` function.
   */
  public static final FREEPLAYSTYLE_DATA_VERSION:thx.semver.Version = '1.0.0';

  public static final FREEPLAYSTYLE_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public static final instance:FreeplayStyleRegistry = new FreeplayStyleRegistry();

  public function new()
  {
    super('FREEPLAYSTYLE', 'ui/freeplay/styles', FREEPLAYSTYLE_DATA_VERSION_RULE);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   * @param id The ID of the entry to load.
   * @return The parsed data object.
   */
  public function parseEntryData(id:String):Null<FreeplayStyleData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser:json2object.JsonParser<FreeplayStyleData> = new json2object.JsonParser<FreeplayStyleData>();
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
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<FreeplayStyleData>
  {
    var parser:json2object.JsonParser<FreeplayStyleData> = new json2object.JsonParser<FreeplayStyleData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  function createScriptedEntry(clsName:String):FreeplayStyle
  {
    return ScriptedFreeplayStyle.init(clsName, 'unknown');
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedFreeplayStyle.listScriptClasses();
  }
}
