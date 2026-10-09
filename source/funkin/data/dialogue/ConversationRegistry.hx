package funkin.data.dialogue;

import funkin.play.cutscene.dialogue.Conversation;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class ConversationRegistry extends BaseRegistry<Conversation, ConversationData, ConversationEntryParams> implements DefaultRegistryImpl
{
  static var _instance:Null<ConversationRegistry>;

  public static var instance(get, never):ConversationRegistry;

  static function get_instance():ConversationRegistry
  {
    if (_instance == null)
    {
      _instance = new ConversationRegistry();
    }
    return _instance;
  }

  /**
   * The current version string for the dialogue box data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateConversationData()` function.
   */
  public static final CONVERSATION_DATA_VERSION:thx.semver.Version = '1.0.0';

  public static final CONVERSATION_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super({
      registryId: 'CONVERSATION',
      dataFilePath: 'gameplay/dialogue/conversations/',
      nestedEntries: true,
      versionRule: CONVERSATION_DATA_VERSION_RULE
    });
  }
}

typedef ConversationEntryParams =
{
  var placeholder:String;
}
