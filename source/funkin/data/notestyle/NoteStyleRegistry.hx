package funkin.data.notestyle;

import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.notestyle.ScriptedNoteStyle;
import funkin.data.notestyle.NoteStyleData;

@:build(funkin.util.macro.RegistryMacro.build())
class NoteStyleRegistry extends BaseRegistry<NoteStyle, NoteStyleData>
{
  /**
   * The current version string for the note style data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateNoteStyleData()` function.
   */
  public static final NOTE_STYLE_DATA_VERSION:thx.semver.Version = "1.1.0";

  public static final NOTE_STYLE_DATA_VERSION_RULE:thx.semver.VersionRule = "1.1.x";

  // public static var instance(get, never):NoteStyleRegistry;
  // static var _instance:Null<NoteStyleRegistry> = null;
  // static function get_instance():NoteStyleRegistry
  // {
  //   if (_instance == null) _instance = new NoteStyleRegistry();
  //   return _instance;
  // }

  public function new()
  {
    super('NOTESTYLE', 'notestyles', NOTE_STYLE_DATA_VERSION_RULE);
  }

  public function fetchDefault():NoteStyle
  {
    return fetchEntry(Constants.DEFAULT_NOTE_STYLE);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<NoteStyleData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<NoteStyleData>();
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
   */
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<NoteStyleData>
  {
    var parser = new json2object.JsonParser<NoteStyleData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  // function createScriptedEntry(clsName:String):NoteStyle
  // {
  //   return ScriptedNoteStyle.init(clsName, "unknown");
  // }
  // function getScriptedClassNames():Array<String>
  // {
  //   return ScriptedNoteStyle.listScriptClasses();
  // }
}
