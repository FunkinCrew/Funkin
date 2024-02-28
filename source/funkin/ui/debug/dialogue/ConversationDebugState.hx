package funkin.ui.debug.dialogue;

import flixel.FlxState;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.events.ScriptEvent;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import funkin.data.dialogue.ConversationData;
import funkin.data.dialogue.ConversationRegistry;
import funkin.data.dialogue.DialogueBoxData;
import funkin.data.dialogue.DialogueBoxRegistry;
import funkin.data.dialogue.SpeakerData;
import funkin.data.dialogue.SpeakerRegistry;
import funkin.play.cutscene.dialogue.Conversation;
import funkin.play.cutscene.dialogue.DialogueBox;
import funkin.play.cutscene.dialogue.Speaker;

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
    conversation = ConversationRegistry.instance.fetchEntry(conversationId);
    conversation.completeCallback = onConversationComplete;
    add(conversation);

    ScriptEventDispatcher.callEvent(conversation, new ScriptEvent(CREATE, false));
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
      if (controls.CUTSCENE_ADVANCE) conversation.advanceConversation();
    }
  }
}
