package funkin.modding.events;

@:nullSafety
enum abstract ScriptEventType(String) from String to String
{
  /**
   * Called when the relevant object is created.
   * Keep in mind that the constructor may be called before the object is needed,
   * for the purposes of caching data or otherwise.
   *
   * This event is not cancelable.
   */
  var CREATE = 'CREATE';

  /**
   * Called when the relevant object is destroyed.
   * This should perform relevant cleanup to ensure good performance.
   *
   * This event is not cancelable.
   */
  var DESTROY = 'DESTROY';

  /**
   * Called when the relevant object is added to the game state.
   * This assumes all data is loaded and ready to go.
   *
   * This event is not cancelable.
   */
  var ADDED = 'ADDED';

  /**
   * Called during the update function.
   * This is called every frame, so be careful!
   *
   * This event is not cancelable.
   */
  var UPDATE = 'UPDATE';

  /**
   * Called when the player moves to pause the game.
   *
   * This event IS cancelable! Canceling the event will prevent the game from pausing.
   */
  var PAUSE = 'PAUSE';

  /**
   * Called when the player moves to unpause the game while paused.
   *
   * This event IS cancelable! Canceling the event will prevent the game from resuming.
   */
  var RESUME = 'RESUME';

  /**
   * Called once per step in the song. This happens 4 times per measure.
   *
   * This event is not cancelable.
   */
  var SONG_BEAT_HIT = 'BEAT_HIT';

  /**
   * Called once per step in the song. This happens 16 times per measure.
   *
   * This event is not cancelable.
   */
  var SONG_STEP_HIT = 'STEP_HIT';

  /**
   * Called when a note comes on screen and starts approaching the strumline.
   *
   * This event is not cancelable.
   */
  var NOTE_INCOMING = 'NOTE_INCOMING';

  /**
   * Called when a character hits a note.
   * Important information such as judgement/timing, note data, player/opponent, etc. are all provided.
   *
   * This event IS cancelable! Canceling this event prevents the note from being hit,
   *   and will likely result in a miss later.
   */
  var NOTE_HIT = 'NOTE_HIT';

  /**
   * Called when a character misses a note.
   * Important information such as note data, player/opponent, etc. are all provided.
   *
   * This event IS cancelable! Canceling this event prevents the note from being considered missed,
   *   avoiding a combo break and lost health.
   */
  var NOTE_MISS = 'NOTE_MISS';

  /**
   * Called when a character lets go of a hold note.
   * Important information such as note data, player/opponent, etc. are all provided.
   *
   * This event is not cancelable.
   */
  var NOTE_HOLD_DROP = 'NOTE_HOLD_DROP';

  /**
   * Called when a character presses a note when there was none there, causing them to lose health.
   * Important information such as direction pressed, etc. are all provided.
   *
   * This event IS cancelable! Canceling this event prevents the note from being considered missed,
   *   avoiding lost health/score and preventing the miss animation.
   */
  var NOTE_GHOST_MISS = 'NOTE_GHOST_MISS';

  /**
   * Called when a song event is reached in the chart.
   *
   * This event IS cancelable! Cancelling this event prevents the event from being triggered,
   *   thus blocking its normal functionality.
   */
  var SONG_EVENT = 'SONG_EVENT';

  /**
   * Called when the song starts. This occurs as the countdown ends and the instrumental and vocals begin.
   *
   * This event is not cancelable.
   */
  var SONG_START = 'SONG_START';

  /**
   * Called when the song ends. This happens as the instrumental and vocals end.
   *
   * This event is not cancelable.
   */
  var SONG_END = 'SONG_END';

  /**
   * Called when the countdown begins. This occurs before the song starts.
   *
   * This event IS cancelable! Canceling this event will prevent the countdown from starting.
   * - The song will not start until you call Countdown.performCountdown() later.
   * - Note that calling performCountdown() will trigger this event again, so be sure to add logic to ignore it.
   */
  var COUNTDOWN_START = 'COUNTDOWN_START';

  /**
   * Called when a step of the countdown happens.
   * Includes information about what step of the countdown was hit.
   *
   * This event IS cancelable! Canceling this event will pause the countdown.
   * - The countdown will not resume until you call PlayState.resumeCountdown().
   */
  var COUNTDOWN_STEP = 'COUNTDOWN_STEP';

  /**
   * Called when the countdown is done but just before the song starts.
   *
   * This event is not cancelable.
   */
  var COUNTDOWN_END = 'COUNTDOWN_END';

  /**
   * Called before the game over screen triggers and the death animation plays.
   *
   * This event is not cancelable.
   */
  var GAME_OVER = 'GAME_OVER';

  /**
   * Called after the player presses a key to restart the game.
   * This can happen from the pause menu or the game over screen.
   *
   * This event IS cancelable! Canceling this event will prevent the game from restarting.
   */
  var SONG_RETRY = 'SONG_RETRY';

  /**
   * Called when the player pushes down any key on the keyboard.
   *
   * This event is not cancelable.
   */
  var KEY_DOWN = 'KEY_DOWN';

  /**
   * Called when the player releases a key on the keyboard.
   *
   * This event is not cancelable.
   */
  var KEY_UP = 'KEY_UP';

  /**
   * Called when the game has finished loading the notes from JSON.
   * This allows modders to mutate the notes before they are used in the song.
   *
   * This event is not cancelable.
   */
  var SONG_LOADED = 'SONG_LOADED';

  /**
   * Called when the game is about to switch the current FlxState.
   *
   * This event is not cancelable.
   */
  var STATE_CHANGE_BEGIN = 'STATE_CHANGE_BEGIN';

  /**
   * Called when the game has finished switching the current FlxState.
   *
   * This event is not cancelable.
   */
  var STATE_CHANGE_END = 'STATE_CHANGE_END';

  /**
   * Called when the game is about to open a new FlxSubState.
   *
   * This event is not cancelable.
   */
  var SUBSTATE_OPEN_BEGIN = 'SUBSTATE_OPEN_BEGIN';

  /**
   * Called when the game has finished opening a new FlxSubState.
   *
   * This event is not cancelable.
   */
  var SUBSTATE_OPEN_END = 'SUBSTATE_OPEN_END';

  /**
   * Called when the game is about to close the current FlxSubState.
   *
   * This event is not cancelable.
   */
  var SUBSTATE_CLOSE_BEGIN = 'SUBSTATE_CLOSE_BEGIN';

  /**
   * Called when the game has finished closing the current FlxSubState.
   *
   * This event is not cancelable.
   */
  var SUBSTATE_CLOSE_END = 'SUBSTATE_CLOSE_END';

  /**
   * Called when the game regains focus.
   *
   * This event is not cancelable.
   */
  var FOCUS_GAINED = 'FOCUS_GAINED';

  /**
   * Called when the game loses focus.
   *
   * This event is not cancelable.
   */
  var FOCUS_LOST = 'FOCUS_LOST';

  /**
   * Called when the game starts a conversation.
   *
   * This event is not cancelable.
   */
  var DIALOGUE_START = 'DIALOGUE_START';

  /**
   * Called to display the next line of conversation.
   *
   * This event IS cancelable! Canceling this event will prevent the conversation from moving to the next line.
   * - This event is called when the conversation starts, or when the user presses ACCEPT to advance the conversation.
   */
  var DIALOGUE_LINE = 'DIALOGUE_LINE';

  /**
   * Called to skip scrolling the current line of conversation.
   *
   * This event IS cancelable! Canceling this event will prevent the conversation from skipping to the next line.
   * - This event is called when the user presses ACCEPT to advance the conversation while it is already advancing.
   */
  var DIALOGUE_COMPLETE_LINE = 'DIALOGUE_COMPLETE_LINE';

  /**
   * Called to skip the conversation.
   *
   * This event IS cancelable! Canceling this event will prevent the conversation from skipping.
   */
  var DIALOGUE_SKIP = 'DIALOGUE_SKIP';

  /**
   * Called when the game ends a conversation.
   *
   * This event is not cancelable.
   */
  var DIALOGUE_END = 'DIALOGUE_END';

  /**
   * Allow for comparing `ScriptEventType` to `String`.
   */
  @:op(A == B) private static inline function equals(a:ScriptEventType, b:String):Bool
  {
    return (a : String) == b;
  }

  /**
   * Allow for comparing `ScriptEventType` to `String`.
   */
  @:op(A != B) private static inline function notEquals(a:ScriptEventType, b:String):Bool
  {
    return (a : String) != b;
  }
}
