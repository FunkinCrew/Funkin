package funkin.data.notestyle;

import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.notestyle.ScriptedNoteStyle;
import funkin.data.notestyle.NoteStyleData;

class NoteStyleRegistry extends BaseRegistry<NoteStyle, NoteStyleData>
{
  /**
   * The current version string for the note style data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateNoteStyleData()` function.
   */
  public static final NOTE_STYLE_DATA_VERSION:String = "1.0.0";

  public static final DEFAULT_NOTE_STYLE_ID:String = "funkin";

  public static final instance:NoteStyleRegistry = new NoteStyleRegistry();

  public function new()
  {
    super('NOTESTYLE', 'notestyles');
  }

  public function fetchDefault():NoteStyle
  {
    return fetchEntry(DEFAULT_NOTE_STYLE_ID);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<NoteStyleData>
  {
    if (id == null) id = DEFAULT_NOTE_STYLE_ID;

    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<NoteStyleData>();
    var jsonStr:String = loadEntryFile(id);

    parser.fromJson(jsonStr);

    if (parser.errors.length > 0)
    {
      trace('Failed to parse entry data: ${id}');
      for (error in parser.errors)
      {
        trace(error);
      }
      return null;
    }
    return parser.value;
  }

  function createScriptedEntry(clsName:String):NoteStyle
  {
    return ScriptedNoteStyle.init(clsName, "unknown");
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedNoteStyle.listScriptClasses();
  }
}
