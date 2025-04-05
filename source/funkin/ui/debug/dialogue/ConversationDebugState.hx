package funkin.ui.debug.dialogue;

import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import funkin.ui.MusicBeatState;
import funkin.data.dialogue.conversation.ConversationRegistry;
import funkin.play.cutscene.dialogue.Conversation;

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
    super.create();
    startConversation();
  }

  function startConversation():Void
  {
    if (conversation != null) return;

    conversation = ConversationRegistry.instance.fetchEntry(conversationId);
    if (conversation == null) return;
    if (!conversation.alive) conversation.revive();

    conversation.zIndex = 1000;
    add(conversation);
    refresh();

    var event:ScriptEvent = new ScriptEvent(CREATE, false);
    ScriptEventDispatcher.callEvent(conversation, event);
  }

  function onConversationComplete():Void
  {
    remove(conversation);
    conversation = null;
  }

  public override function dispatchEvent(event:ScriptEvent):Void
  {
    // Dispatch event to conversation script.
    ScriptEventDispatcher.callEvent(conversation, event);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (conversation != null)
    {
      if (controls.CUTSCENE_ADVANCE)
      {
        conversation.advanceConversation();
      }
      else if (controls.PAUSE)
      {
        conversation.kill();
        remove(conversation);
        conversation = null;

        FlxG.switchState(() -> new ConversationDebugState());
      }
    }
  }
}
