package funkin.data.dialogue.conversation;

import funkin.play.cutscene.dialogue.Conversation;
import funkin.play.cutscene.dialogue.ScriptedConversation;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class ConversationRegistry extends BaseRegistry<Conversation, ConversationData> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the dialogue box data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateConversationData()` function.
   */
  public static final CONVERSATION_DATA_VERSION:thx.semver.Version = "1.0.0";

  public static final CONVERSATION_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";

  public function new()
  {
    super('CONVERSATION', 'dialogue/conversations', CONVERSATION_DATA_VERSION_RULE);
  }
}
