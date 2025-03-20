package funkin.modding;

import funkin.modding.events.ScriptEvent;

/**
 * Defines a set of callbacks available to all scripted classes.
 *
 * Includes events handling basic life cycle relevant to all scripted classes.
 */
interface IScriptedClass
{
  public function onScriptEvent(event:ScriptEvent):Void;

  public function onCreate(event:ScriptEvent):Void;
  public function onDestroy(event:ScriptEvent):Void;
  public function onUpdate(event:UpdateScriptEvent):Void;
}

/**
 * Defines an element which can receive script events.
 * For example, the PlayState dispatches the event to all its child elements.
 */
interface IEventHandler
{
  public function dispatchEvent(event:ScriptEvent):Void;
}

/**
 * Defines a set of callbacks available to scripted classes which can follow the game between states.
 */
interface IStateChangingScriptedClass extends IScriptedClass
{
  public function onStateChangeBegin(event:StateChangeScriptEvent):Void;
  public function onStateChangeEnd(event:StateChangeScriptEvent):Void;

  public function onSubStateOpenBegin(event:SubStateScriptEvent):Void;
  public function onSubStateOpenEnd(event:SubStateScriptEvent):Void;
  public function onSubStateCloseBegin(event:SubStateScriptEvent):Void;
  public function onSubStateCloseEnd(event:SubStateScriptEvent):Void;

  public function onFocusLost(event:FocusScriptEvent):Void;
  public function onFocusGained(event:FocusScriptEvent):Void;
}

/**
 * Defines a set of callbacks available to scripted classes which can be added to the current state.
 * Generally requires the class to be an instance of FlxBasic.
 */
interface IStateStageProp extends IScriptedClass
{
  /**
   * Called when the relevant element is added to the game state.
   */
  public function onAdd(event:ScriptEvent):Void;
}

/**
 * Defines a set of callbacks available to scripted classes which represent notes.
 */
interface INoteScriptedClass extends IScriptedClass
{
  /**
   * Called when a note enters the field of view and approaches the strumline.
   */
  public function onNoteIncoming(event:NoteScriptEvent):Void;

  /**
   * Called when EITHER player hits a note.
   * Query the note attached to the event to determine if it was hit by the player or CPU.
   */
  public function onNoteHit(event:HitNoteScriptEvent):Void;

  /**
   * Called when EITHER player (usually the player) misses a note.
   */
  public function onNoteMiss(event:NoteScriptEvent):Void;

  /**
   * Called when EITHER player (usually the player) drops a hold note.
   */
  public function onNoteHoldDrop(event:HoldNoteScriptEvent):Void;
}

/**
 * Defines a set of callbacks available to scripted classes which represent sprites synced with the BPM.
 */
interface IBPMSyncedScriptedClass extends IScriptedClass
{
  /**
   * Called once every step of the song.
   */
  public function onStepHit(event:SongTimeScriptEvent):Void;

  /**
   * Called once every beat of the song.
   */
  public function onBeatHit(event:SongTimeScriptEvent):Void;
}

/**
 * Developer note:
 *
 * I previously considered adding events for onKeyDown, onKeyUp, mouse events, etc.
 * However, I realized that you can simply call something like the following within a module:
 * `FlxG.state.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);`
 * This is more efficient than adding an entire event handler for every key press.
 *
 * -Eric
 */
/**
 * Defines a set of callbacks available to scripted classes that involve the lifecycle of the Play State.
 */
interface IPlayStateScriptedClass extends INoteScriptedClass extends IBPMSyncedScriptedClass
{
  /**
   * Called when the game is paused.
   * Has properties to set whether the pause easter egg will happen,
   * and can be cancelled by scripts.
   */
  public function onPause(event:PauseScriptEvent):Void;

  /**
   * Called when the game is unpaused.
   */
  public function onResume(event:ScriptEvent):Void;

  /**
   * Called when the song has been parsed, before notes have been placed.
   * Use this to mutate the chart.
   */
  public function onSongLoaded(event:SongLoadScriptEvent):Void;

  /**
   * Called when the song starts (conductor time is 0 seconds).
   */
  public function onSongStart(event:ScriptEvent):Void;

  /**
   * Called when the song ends and the song is about to be unloaded.
   */
  public function onSongEnd(event:ScriptEvent):Void;

  /**
   * Called as the player runs out of health just before the game over substate is entered.
   */
  public function onGameOver(event:ScriptEvent):Void;

  /**
   * Called when the player restarts the song, either via pause menu or restarting after a game over.
   */
  public function onSongRetry(event:SongRetryEvent):Void;

  /**
   * Called when the player presses a key when no note is on the strumline.
   */
  public function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void;

  /**
   * Called when the song reaches an event.
   */
  public function onSongEvent(event:SongEventScriptEvent):Void;

  /**
   * Called when the countdown of the song starts.
   */
  public function onCountdownStart(event:CountdownScriptEvent):Void;

  /**
   * Called when the a part of the countdown happens.
   */
  public function onCountdownStep(event:CountdownScriptEvent):Void;

  /**
   * Called when the countdown of the song ends.
   */
  public function onCountdownEnd(event:CountdownScriptEvent):Void;
}

/**
 * Defines a set of callbacks activated during a dialogue conversation.
 */
interface IDialogueScriptedClass extends IScriptedClass
{
  /**
   * Called as the dialogue starts, and before the first dialogue text is displayed.
   */
  public function onDialogueStart(event:DialogueScriptEvent):Void;

  public function onDialogueCompleteLine(event:DialogueScriptEvent):Void;
  public function onDialogueLine(event:DialogueScriptEvent):Void;
  public function onDialogueSkip(event:DialogueScriptEvent):Void;
  public function onDialogueEnd(event:DialogueScriptEvent):Void;
}
