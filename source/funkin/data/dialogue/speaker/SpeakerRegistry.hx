package funkin.data.dialogue.speaker;

import funkin.play.cutscene.dialogue.Speaker;
import funkin.data.dialogue.speaker.SpeakerData;
import funkin.play.cutscene.dialogue.ScriptedSpeaker;

class SpeakerRegistry extends BaseRegistry<Speaker, SpeakerData>
{
  /**
   * The current version string for the speaker data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateSpeakerData()` function.
   */
  public static final SPEAKER_DATA_VERSION:thx.semver.Version = "1.0.0";

  public static final SPEAKER_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";

  public static var instance(get, never):SpeakerRegistry;
  static var _instance:Null<SpeakerRegistry> = null;

  static function get_instance():SpeakerRegistry
  {
    if (_instance == null) _instance = new SpeakerRegistry();
    return _instance;
  }

  public function new()
  {
    super('SPEAKER', 'dialogue/speakers', SPEAKER_DATA_VERSION_RULE);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<SpeakerData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<SpeakerData>();
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
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<SpeakerData>
  {
    var parser = new json2object.JsonParser<SpeakerData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  function createScriptedEntry(clsName:String):Speaker
  {
    return ScriptedSpeaker.init(clsName, "unknown");
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedSpeaker.listScriptClasses();
  }
}
