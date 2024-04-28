package funkin.data.dialogue.dialoguebox;

import funkin.play.cutscene.dialogue.DialogueBox;
import funkin.data.dialogue.dialoguebox.DialogueBoxData;
import funkin.play.cutscene.dialogue.ScriptedDialogueBox;

class DialogueBoxRegistry extends BaseRegistry<DialogueBox, DialogueBoxData>
{
  /**
   * The current version string for the dialogue box data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateDialogueBoxData()` function.
   */
  public static final DIALOGUEBOX_DATA_VERSION:thx.semver.Version = "1.1.0";

  public static final DIALOGUEBOX_DATA_VERSION_RULE:thx.semver.VersionRule = "1.1.x";

  public static var instance(get, never):DialogueBoxRegistry;
  static var _instance:Null<DialogueBoxRegistry> = null;

  static function get_instance():DialogueBoxRegistry
  {
    if (_instance == null) _instance = new DialogueBoxRegistry();
    return _instance;
  }

  public function new()
  {
    super('DIALOGUEBOX', 'dialogue/boxes', DIALOGUEBOX_DATA_VERSION_RULE);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<DialogueBoxData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<DialogueBoxData>();
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
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<DialogueBoxData>
  {
    var parser = new json2object.JsonParser<DialogueBoxData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  function createScriptedEntry(clsName:String):DialogueBox
  {
    return ScriptedDialogueBox.init(clsName, "unknown");
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedDialogueBox.listScriptClasses();
  }
}
