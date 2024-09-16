package funkin.data.dialogue.conversation;

import funkin.play.cutscene.dialogue.Conversation;
import funkin.play.cutscene.dialogue.ScriptedConversation;

class ConversationRegistry extends BaseRegistry<Conversation, ConversationData>
{
  /**
   * The current version string for the dialogue box data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateConversationData()` function.
   */
  public static final CONVERSATION_DATA_VERSION:thx.semver.Version = "1.0.0";

  public static final CONVERSATION_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";

  public static var instance(get, never):ConversationRegistry;
  static var _instance:Null<ConversationRegistry> = null;

  static function get_instance():ConversationRegistry
  {
    if (_instance == null) _instance = new ConversationRegistry();
    return _instance;
  }

  public function new()
  {
    super('CONVERSATION', 'dialogue/conversations', CONVERSATION_DATA_VERSION_RULE);
  }

  /**
   * Read, parse, and validate the JSON data and produce the corresponding data object.
   */
  public function parseEntryData(id:String):Null<ConversationData>
  {
    // JsonParser does not take type parameters,
    // otherwise this function would be in BaseRegistry.
    var parser = new json2object.JsonParser<ConversationData>();
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
  public function parseEntryDataRaw(contents:String, ?fileName:String):Null<ConversationData>
  {
    var parser = new json2object.JsonParser<ConversationData>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(contents, fileName);

    if (parser.errors.length > 0)
    {
      printErrors(parser.errors, fileName);
      return null;
    }
    return parser.value;
  }

  function createScriptedEntry(clsName:String):Conversation
  {
    return ScriptedConversation.init(clsName, "unknown");
  }

  function getScriptedClassNames():Array<String>
  {
    return ScriptedConversation.listScriptClasses();
  }
}
