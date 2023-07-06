package funkin.play.cutscene.dialogue;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.system.FlxSound;
import funkin.util.SortUtil;
import flixel.util.FlxSort;
import funkin.modding.events.ScriptEvent;
import funkin.modding.IScriptedClass.IEventHandler;
import funkin.play.cutscene.dialogue.DialogueBox;
import funkin.modding.IScriptedClass.IDialogueScriptedClass;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.cutscene.dialogue.ConversationData.DialogueEntryData;
import flixel.addons.display.FlxPieDial;

/**
 * A high-level handler for dialogue.
 * 
 * This shit is great for modders but it's pretty elaborate for how much it'll actually be used, lolol. -Eric
 */
class Conversation extends FlxSpriteGroup implements IDialogueScriptedClass
{
  static final CONVERSATION_SKIP_TIMER:Float = 1.5;

  var skipHeldTimer:Float = 0.0;

  /**
   * DATA
   */
  /**
   * The ID of the associated dialogue.
   */
  public final conversationId:String;

  /**
   * The current state of the conversation.
   */
  var state:ConversationState = ConversationState.Start;

  /**
   * The data for the associated dialogue.
   */
  var conversationData:ConversationData;

  /**
   * The current entry in the dialogue.
   */
  var currentDialogueEntry:Int = 0;

  var currentDialogueEntryCount(get, null):Int;

  function get_currentDialogueEntryCount():Int
  {
    return conversationData.dialogue.length;
  }

  /**
   * The current line in the current entry in the dialogue.
  * **/
  var currentDialogueLine:Int = 0;

  var currentDialogueLineCount(get, null):Int;

  function get_currentDialogueLineCount():Int
  {
    return currentDialogueEntryData.text.length;
  }

  var currentDialogueEntryData(get, null):DialogueEntryData;

  function get_currentDialogueEntryData():DialogueEntryData
  {
    if (conversationData == null || conversationData.dialogue == null) return null;
    if (currentDialogueEntry < 0 || currentDialogueEntry >= conversationData.dialogue.length) return null;

    return conversationData.dialogue[currentDialogueEntry];
  }

  var currentDialogueLineString(get, null):String;

  function get_currentDialogueLineString():String
  {
    return currentDialogueEntryData?.text[currentDialogueLine];
  }

  /**
   * AUDIO
   */
  var music:FlxSound;

  /**
   * GRAPHICS
   */
  var backdrop:FlxSprite;

  var currentSpeaker:Speaker;

  var currentDialogueBox:DialogueBox;

  var skipTimer:FlxPieDial;

  public function new(conversationId:String)
  {
    super();

    this.conversationId = conversationId;
    this.conversationData = ConversationDataParser.parseConversationData(this.conversationId);

    if (conversationData == null) throw 'Could not load conversation data for conversation ID "$conversationId"';
  }

  public function onCreate(event:ScriptEvent):Void
  {
    // Reset the progress in the dialogue.
    currentDialogueEntry = 0;
    this.state = ConversationState.Start;
    this.alpha = 1.0;

    // Start the dialogue.
    dispatchEvent(new DialogueScriptEvent(ScriptEvent.DIALOGUE_START, this, false));
  }

  function setupMusic():Void
  {
    if (conversationData.music == null) return;

    music = new FlxSound().loadEmbedded(Paths.music(conversationData.music.asset), true, true);
    music.volume = 0;

    if (conversationData.music.fadeTime > 0.0)
    {
      FlxTween.tween(music, {volume: 1.0}, conversationData.music.fadeTime, {ease: FlxEase.linear});
    }
    else
    {
      music.volume = 1.0;
    }

    FlxG.sound.list.add(music);
    music.play();
  }

  function setupBackdrop():Void
  {
    backdrop = new FlxSprite(0, 0);

    if (conversationData.backdrop == null) return;

    // Play intro
    switch (conversationData?.backdrop.type)
    {
      case SOLID:
        backdrop.makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), FlxColor.fromString(conversationData.backdrop.data.color));
        if (conversationData.backdrop.data.fadeTime > 0.0)
        {
          backdrop.alpha = 0.0;
          FlxTween.tween(backdrop, {alpha: 1.0}, conversationData.backdrop.data.fadeTime, {ease: FlxEase.linear});
        }
        else
        {
          backdrop.alpha = 1.0;
        }
      default:
        return;
    }

    backdrop.zIndex = 10;
    add(backdrop);
    refresh();
  }

  function setupSkipTimer():Void
  {
    add(skipTimer = new FlxPieDial(16, 16, 32, FlxColor.WHITE, 36, CIRCLE, true, 24));
    skipTimer.amount = 0;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    dispatchEvent(new UpdateScriptEvent(elapsed));
  }

  function showCurrentSpeaker():Void
  {
    var nextSpeakerId:String = currentDialogueEntryData.speaker;

    // Skip the next steps if the current speaker is already displayed.
    if (currentSpeaker != null && nextSpeakerId == currentSpeaker.speakerId) return;

    var nextSpeaker:Speaker = SpeakerDataParser.fetchSpeaker(nextSpeakerId);

    if (currentSpeaker != null)
    {
      remove(currentSpeaker);
      currentSpeaker.kill(); // Kill, don't destroy! We want to revive it later.
      currentSpeaker = null;
    }

    if (nextSpeaker == null)
    {
      if (nextSpeakerId == null)
      {
        trace('Dialogue entry has no speaker.');
      }
      else
      {
        trace('Speaker could not be retrieved.');
      }
      return;
    }

    ScriptEventDispatcher.callEvent(nextSpeaker, new ScriptEvent(ScriptEvent.CREATE, true));

    currentSpeaker = nextSpeaker;
    currentSpeaker.zIndex = 200;
    add(currentSpeaker);
    refresh();
  }

  function playSpeakerAnimation():Void
  {
    var nextSpeakerAnimation:String = currentDialogueEntryData.speakerAnimation;

    if (nextSpeakerAnimation == null) return;

    currentSpeaker.playAnimation(nextSpeakerAnimation);
  }

  public function refresh():Void
  {
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);
  }

  function showCurrentDialogueBox():Void
  {
    var nextDialogueBoxId:String = currentDialogueEntryData?.box;

    // Skip the next steps if the current speaker is already displayed.
    if (currentDialogueBox != null && nextDialogueBoxId == currentDialogueBox.dialogueBoxId) return;

    if (currentDialogueBox != null)
    {
      remove(currentDialogueBox);
      currentDialogueBox.kill(); // Kill, don't destroy! We want to revive it later.
      currentDialogueBox = null;
    }

    var nextDialogueBox:DialogueBox = DialogueBoxDataParser.fetchDialogueBox(nextDialogueBoxId);

    if (nextDialogueBox == null)
    {
      trace('Dialogue box could not be retrieved.');
      return;
    }

    ScriptEventDispatcher.callEvent(nextDialogueBox, new ScriptEvent(ScriptEvent.CREATE, true));

    currentDialogueBox = nextDialogueBox;
    currentDialogueBox.zIndex = 300;

    currentDialogueBox.typingCompleteCallback = this.onTypingComplete;

    add(currentDialogueBox);
    refresh();
  }

  function playDialogueBoxAnimation():Void
  {
    var nextDialogueBoxAnimation:String = currentDialogueEntryData?.boxAnimation;

    if (nextDialogueBoxAnimation == null) return;

    currentDialogueBox.playAnimation(nextDialogueBoxAnimation);
  }

  function onTypingComplete():Void
  {
    if (this.state == ConversationState.Speaking)
    {
      this.state = ConversationState.Idle;
    }
    else
    {
      trace('[WARNING] Unexpected state transition from ${this.state}');
      this.state = ConversationState.Idle;
    }
  }

  public function startConversation():Void
  {
    dispatchEvent(new DialogueScriptEvent(ScriptEvent.DIALOGUE_START, this, true));
  }

  /**
   * Dispatch an event to attempt to advance the conversation.
   * This is done once at the start of the conversation, and once whenever the user presses CONFIRM to advance the conversation.
   * 
   * The broadcast event may be cancelled by modules or ScriptedConversations. This will prevent the conversation from actually advancing.
   * This is useful if you want to manually play an animation or something.
   */
  public function advanceConversation():Void
  {
    switch (state)
    {
      case ConversationState.Start:
        dispatchEvent(new DialogueScriptEvent(ScriptEvent.DIALOGUE_START, this, true));
      case ConversationState.Opening:
        dispatchEvent(new DialogueScriptEvent(ScriptEvent.DIALOGUE_COMPLETE_LINE, this, true));
      case ConversationState.Speaking:
        dispatchEvent(new DialogueScriptEvent(ScriptEvent.DIALOGUE_COMPLETE_LINE, this, true));
      case ConversationState.Idle:
        dispatchEvent(new DialogueScriptEvent(ScriptEvent.DIALOGUE_LINE, this, true));
      case ConversationState.Ending:
        // Skip the outro.
        endOutro();
      default:
        // Do nothing.
    }
  }

  public function dispatchEvent(event:ScriptEvent):Void
  {
    var currentState:IEventHandler = cast FlxG.state;
    currentState.dispatchEvent(event);
  }

  /**
   * Reset the conversation back to the start.
   */
  public function resetConversation():Void
  {
    // Reset the progress in the dialogue.
    currentDialogueEntry = 0;
    this.state = ConversationState.Start;

    advanceConversation();
  }

  public function trySkipConversation(elapsed:Float):Void
  {
    if (skipTimer == null || skipTimer.animation == null) return;

    if (elapsed < 0)
    {
      skipHeldTimer = 0.0;
    }
    else
    {
      skipHeldTimer += elapsed;
    }

    skipTimer.visible = skipHeldTimer >= 0.05;
    skipTimer.amount = Math.min(skipHeldTimer / CONVERSATION_SKIP_TIMER, 1.0);

    if (skipHeldTimer >= CONVERSATION_SKIP_TIMER)
    {
      skipConversation();
    }
  }

  /**
   * Dispatch an event to attempt to immediately end the conversation.
   * 
   * The broadcast event may be cancelled by modules or ScriptedConversations. This will prevent the conversation from being cancelled.
   * This is useful if you want to prevent an animation from being skipped or something.
   */
  public function skipConversation():Void
  {
    dispatchEvent(new DialogueScriptEvent(ScriptEvent.DIALOGUE_SKIP, this, true));
  }

  static var outroTween:FlxTween;

  public function startOutro():Void
  {
    switch (conversationData?.outro?.type)
    {
      case FADE:
        var fadeTime:Float = conversationData?.outro.data.fadeTime ?? 1.0;

        outroTween = FlxTween.tween(this, {alpha: 0.0}, fadeTime,
          {
            type: ONESHOT, // holy shit like the game no way
            startDelay: 0,
            onComplete: (_) -> endOutro(),
          });

        FlxTween.tween(this.music, {volume: 0.0}, fadeTime);
      case NONE:
        // Immediately clean up.
        endOutro();
      default:
        // Immediately clean up.
        endOutro();
    }
  }

  public var completeCallback:Void->Void;

  public function endOutro():Void
  {
    outroTween = null;
    ScriptEventDispatcher.callEvent(this, new ScriptEvent(ScriptEvent.DESTROY, false));
  }

  /**
   * Performed as the conversation starts.
   */
  public function onDialogueStart(event:DialogueScriptEvent):Void
  {
    propagateEvent(event);

    // Fade in the music and backdrop.
    setupMusic();
    setupBackdrop();
    setupSkipTimer();

    // Advance the conversation.
    state = ConversationState.Opening;

    showCurrentDialogueBox();
    playDialogueBoxAnimation();
  }

  /**
   * Display the next line of conversation.
   */
  public function onDialogueLine(event:DialogueScriptEvent):Void
  {
    propagateEvent(event);
    if (event.eventCanceled) return;

    // Perform the actual logic to advance the conversation.
    currentDialogueLine += 1;
    if (currentDialogueLine >= currentDialogueLineCount)
    {
      // Open the next entry.
      currentDialogueLine = 0;
      currentDialogueEntry += 1;

      if (currentDialogueEntry >= currentDialogueEntryCount)
      {
        dispatchEvent(new DialogueScriptEvent(ScriptEvent.DIALOGUE_END, this, false));
      }
      else
      {
        if (state == Idle)
        {
          showCurrentDialogueBox();
          playDialogueBoxAnimation();

          state = Opening;
        }
      }
    }
    else
    {
      // Continue the dialog with more lines.
      state = Speaking;
      currentDialogueBox.appendText(currentDialogueLineString);
    }
  }

  /**
   * Skip the scrolling of the next line of conversation.
   */
  public function onDialogueCompleteLine(event:DialogueScriptEvent):Void
  {
    propagateEvent(event);
    if (event.eventCanceled) return;

    currentDialogueBox.skip();
  }

  /**
   * Skip to the end of the conversation, immediately triggering the DIALOGUE_END event.
   */
  public function onDialogueSkip(event:DialogueScriptEvent):Void
  {
    propagateEvent(event);
    if (event.eventCanceled) return;

    dispatchEvent(new DialogueScriptEvent(ScriptEvent.DIALOGUE_END, this, false));
  }

  public function onDialogueEnd(event:DialogueScriptEvent):Void
  {
    propagateEvent(event);

    state = Ending;
  }

  // Only used for events/scripts.

  public function onUpdate(event:UpdateScriptEvent):Void
  {
    propagateEvent(event);

    if (event.eventCanceled) return;

    switch (state)
    {
      case ConversationState.Start:
        // Wait for advance() to be called and DIALOGUE_LINE to be dispatched.
        return;
      case ConversationState.Opening:
        // Backdrop animation should have started.
        // Box animations should have started.
        if (currentDialogueBox != null
          && (currentDialogueBox.isAnimationFinished()
            || currentDialogueBox.getCurrentAnimation() != currentDialogueEntryData?.boxAnimation))
        {
          // Box animations have finished.

          // Start playing the speaker animation.
          state = ConversationState.Speaking;
          showCurrentSpeaker();
          playSpeakerAnimation();
          currentDialogueBox.setText(currentDialogueLineString);
        }
        return;
      case ConversationState.Speaking:
        // Speaker animation should be playing.
        return;
      case ConversationState.Idle:
        // Waiting for user input via `advanceConversation()`.
        return;
      case ConversationState.Ending:
        if (outroTween == null) startOutro();
        return;
    }
  }

  public function onDestroy(event:ScriptEvent):Void
  {
    propagateEvent(event);

    if (outroTween != null) outroTween.cancel(); // Canc
    outroTween = null;

    this.alpha = 0.0;
    if (this.music != null) this.music.stop();
    this.music = null;

    this.skipTimer = null;
    if (currentSpeaker != null) currentSpeaker.kill();
    currentSpeaker = null;
    if (currentDialogueBox != null) currentDialogueBox.kill();
    currentDialogueBox = null;
    if (backdrop != null) backdrop.kill();
    backdrop = null;

    this.clear();

    if (completeCallback != null) completeCallback();
  }

  public function onScriptEvent(event:ScriptEvent):Void
  {
    propagateEvent(event);
  }

  /**
   * As this event is dispatched to the Conversation, it is also dispatched to the active speaker.
   * @param event 
   */
  function propagateEvent(event:ScriptEvent):Void
  {
    if (this.currentDialogueBox != null)
    {
      ScriptEventDispatcher.callEvent(this.currentDialogueBox, event);
    }
    if (this.currentSpeaker != null)
    {
      ScriptEventDispatcher.callEvent(this.currentSpeaker, event);
    }
  }

  public override function toString():String
  {
    return 'Conversation($conversationId)';
  }
}

// Managing things with a single enum is a lot easier than a multitude of flags.
enum ConversationState
{
  /**
   * State hasn't been initialized yet.
   */
  Start;

  /**
   * A dialog is animating. If the dialog is static, this may only last for one frame.
   */
  Opening;

  /**
   * Text is scrolling and audio is playing. Speaker portrait is probably animating too.
   */
  Speaking;

  /**
   * Text is done scrolling and game is waiting for user to open another dialog.
   */
  Idle;

  /**
   * Fade out and leave conversation.
   */
  Ending;
}
