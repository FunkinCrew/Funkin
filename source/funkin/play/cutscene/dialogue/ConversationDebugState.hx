package funkin.play.cutscene.dialogue;

import flixel.FlxState;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import flixel.util.FlxColor;

/**
 * A state with displays a conversation with no background.
 * Used for testing.
 * @param conversationId The conversation to display.
 */
class ConversationDebugState extends MusicBeatState
{
  final conversationId:String = 'senpai';

  var conversation:Conversation;

  public function new()
  {
    super();

    // TODO: Fix this BS
    Paths.setCurrentLevel('week6');
  }

  public override function create():Void
  {
    conversation = ConversationDataParser.fetchConversation(conversationId);
    conversation.completeCallback = onConversationComplete;
    add(conversation);

    ScriptEventDispatcher.callEvent(conversation, new ScriptEvent(ScriptEventType.CREATE, false));
  }

  function onConversationComplete():Void
  {
    remove(conversation);
    conversation = null;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (conversation != null)
    {
      if (controls.CUTSCENE_ADVANCE) conversation.advanceConversation();

      if (controls.CUTSCENE_SKIP)
      {
        conversation.trySkipConversation(elapsed);
      }
      else
      {
        conversation.trySkipConversation(-1);
      }
    }
  }
}
