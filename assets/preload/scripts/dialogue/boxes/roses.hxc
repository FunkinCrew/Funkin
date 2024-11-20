import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.play.cutscene.dialogue.ConversationState;
import funkin.play.cutscene.dialogue.DialogueBox;

class RosesDialogueBox extends DialogueBox {
	function new() {
		super('roses');
	}

  public function onDialogueLine(event:DialogueScriptEvent):Void {
    super.onDialogueLine(event);

    if (getCurrentAnimation() == 'idle') {
      // click, then speaking
      playAnimation('click');
    } else if (getCurrentAnimation() == 'click') {
      playAnimation('speaking');
    }
  }

  function onAnimationFinished(name:String):Void {
    super.onAnimationFinished(name);

    if (name == 'sentenceEnd') {
      playAnimation('idle');
    }
    if (name == 'click') {
      playAnimation('speaking');
    }
  }

  function onTypingComplete():Void {
    playAnimation('sentenceEnd');
    super.onTypingComplete();
  }

  public function onDialogueStart(event:DialogueScriptEvent):Void {
    super.onDialogueStart(event);
  }

  public function onDialogueLine(event:DialogueScriptEvent):Void {
    // Override the default box animation behavior by switching the state
    event.conversation.state = ConversationState.Opening;

    playAnimation('click', false);
    super.onDialogueEnd(event);
  }

  public function onDialogueEnd(event:DialogueScriptEvent):Void {
    super.onDialogueEnd(event);
    // Play 'enter' in reverse
    this.textDisplay.visible = false;

    playAnimation('exit', false);
  }

  override function onDestroy(event:ScriptEvent) {
    super.onDestroy(event);
  }
}
