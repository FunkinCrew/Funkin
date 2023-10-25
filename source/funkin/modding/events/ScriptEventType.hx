package funkin.modding.events;

enum abstract ScriptEventType(String) from String to String
{
  /**
   * Called when the relevant object is created.
   * Keep in mind that the constructor may be called before the object is needed,
   * for the purposes of caching data or otherwise.
   *
   * This event is not cancelable.
   */
  public static inline final CREATE:ScriptEventType = 'CREATE';

  /**
   * Called when the relevant object is destroyed.
   * This should perform relevant cleanup to ensure good performance.
   *
   * This event is not cancelable.
   */
  public static inline final DESTROY:ScriptEventType = 'DESTROY';

  /**
   * Called when the relevent object is added to the game state.
   * This assumes all data is loaded and ready to go.
   *
   * This event is not cancelable.
   */
  public static inline final ADDED:ScriptEventType = 'ADDED';

  /**
   * Called during the update function.
   * This is called every frame, so be careful!
   *
   * This event is not cancelable.
   */
  public static inline final UPDATE:ScriptEventType = 'UPDATE';

  /**
   * Called when the player moves to pause the game.
   *
   * This event IS cancelable! Canceling the event will prevent the game from pausing.
   */
  public static inline final PAUSE:ScriptEventType = 'PAUSE';

  /**
   * Called when the player moves to unpause the game while paused.
   *
   * This event IS cancelable! Canceling the event will prevent the game from resuming.
   */
  public static inline final RESUME:ScriptEventType = 'RESUME';

  /**
   * Called once per step in the song. This happens 4 times per measure.
   *
   * This event is not cancelable.
   */
  public static inline final SONG_BEAT_HIT:ScriptEventType = 'BEAT_HIT';

  /**
   * Called once per step in the song. This happens 16 times per measure.
   *
   * This event is not cancelable.
   */
  public static inline final SONG_STEP_HIT:ScriptEventType = 'STEP_HIT';

  /**
   * Called when a character hits a note.
   * Important information such as judgement/timing, note data, player/opponent, etc. are all provided.
   *
   * This event IS cancelable! Canceling this event prevents the note from being hit,
   *   and will likely result in a miss later.
   */
  public static inline final NOTE_HIT:ScriptEventType = 'NOTE_HIT';

  /**
   * Called when a character misses a note.
   * Important information such as note data, player/opponent, etc. are all provided.
   *
   * This event IS cancelable! Canceling this event prevents the note from being considered missed,
   *   avoiding a combo break and lost health.
   */
  public static inline final NOTE_MISS:ScriptEventType = 'NOTE_MISS';

  /**
   * Called when a character presses a note when there was none there, causing them to lose health.
   * Important information such as direction pressed, etc. are all provided.
   *
   * This event IS cancelable! Canceling this event prevents the note from being considered missed,
   *   avoiding lost health/score and preventing the miss animation.
   */
  public static inline final NOTE_GHOST_MISS:ScriptEventType = 'NOTE_GHOST_MISS';

  /**
   * Called when a song event is reached in the chart.
   *
   * This event IS cancelable! Cancelling this event prevents the event from being triggered,
   *   thus blocking its normal functionality.
   */
  public static inline final SONG_EVENT:ScriptEventType = 'SONG_EVENT';

  /**
   * Called when the song starts. This occurs as the countdown ends and the instrumental and vocals begin.
   *
   * This event is not cancelable.
   */
  public static inline final SONG_START:ScriptEventType = 'SONG_START';

  /**
   * Called when the song ends. This happens as the instrumental and vocals end.
   *
   * This event is not cancelable.
   */
  public static inline final SONG_END:ScriptEventType = 'SONG_END';

  /**
   * Called when the countdown begins. This occurs before the song starts.
   *
   * This event IS cancelable! Canceling this event will prevent the countdown from starting.
   * - The song will not start until you call Countdown.performCountdown() later.
   * - Note that calling performCountdown() will trigger this event again, so be sure to add logic to ignore it.
   */
  public static inline final COUNTDOWN_START:ScriptEventType = 'COUNTDOWN_START';

  /**
   * Called when a step of the countdown happens.
   * Includes information about what step of the countdown was hit.
   *
   * This event IS cancelable! Canceling this event will pause the countdown.
   * - The countdown will not resume until you call PlayState.resumeCountdown().
   */
  public static inline final COUNTDOWN_STEP:ScriptEventType = 'COUNTDOWN_STEP';

  /**
   * Called when the countdown is done but just before the song starts.
   *
   * This event is not cancelable.
   */
  public static inline final COUNTDOWN_END:ScriptEventType = 'COUNTDOWN_END';

  /**
   * Called before the game over screen triggers and the death animation plays.
   *
   * This event is not cancelable.
   */
  public static inline final GAME_OVER:ScriptEventType = 'GAME_OVER';

  /**
   * Called after the player presses a key to restart the game.
   * This can happen from the pause menu or the game over screen.
   *
   * This event IS cancelable! Canceling this event will prevent the game from restarting.
   */
  public static inline final SONG_RETRY:ScriptEventType = 'SONG_RETRY';

  /**
   * Called when the player pushes down any key on the keyboard.
   *
   * This event is not cancelable.
   */
  public static inline final KEY_DOWN:ScriptEventType = 'KEY_DOWN';

  /**
   * Called when the player releases a key on the keyboard.
   *
   * This event is not cancelable.
   */
  public static inline final KEY_UP:ScriptEventType = 'KEY_UP';

  /**
   * Called when the game has finished loading the notes from JSON.
   * This allows modders to mutate the notes before they are used in the song.
   *
   * This event is not cancelable.
   */
  public static inline final SONG_LOADED:ScriptEventType = 'SONG_LOADED';

  /**
   * Called when the game is about to switch the current FlxState.
   *
   * This event is not cancelable.
   */
  public static inline final STATE_CHANGE_BEGIN:ScriptEventType = 'STATE_CHANGE_BEGIN';

  /**
   * Called when the game has finished switching the current FlxState.
   *
   * This event is not cancelable.
   */
  public static inline final STATE_CHANGE_END:ScriptEventType = 'STATE_CHANGE_END';

  /**
   * Called when the game is about to open a new FlxSubState.
   *
   * This event is not cancelable.
   */
  public static inline final SUBSTATE_OPEN_BEGIN:ScriptEventType = 'SUBSTATE_OPEN_BEGIN';

  /**
   * Called when the game has finished opening a new FlxSubState.
   *
   * This event is not cancelable.
   */
  public static inline final SUBSTATE_OPEN_END:ScriptEventType = 'SUBSTATE_OPEN_END';

  /**
   * Called when the game is about to close the current FlxSubState.
   *
   * This event is not cancelable.
   */
  public static inline final SUBSTATE_CLOSE_BEGIN:ScriptEventType = 'SUBSTATE_CLOSE_BEGIN';

  /**
   * Called when the game has finished closing the current FlxSubState.
   *
   * This event is not cancelable.
   */
  public static inline final SUBSTATE_CLOSE_END:ScriptEventType = 'SUBSTATE_CLOSE_END';

  /**
   * Called when the game starts a conversation.
   *
   * This event is not cancelable.
   */
  public static inline final DIALOGUE_START:ScriptEventType = 'DIALOGUE_START';

  /**
   * Called to display the next line of conversation.
   *
   * This event IS cancelable! Canceling this event will prevent the conversation from moving to the next line.
   * - This event is called when the conversation starts, or when the user presses ACCEPT to advance the conversation.
   */
  public static inline final DIALOGUE_LINE:ScriptEventType = 'DIALOGUE_LINE';

  /**
   * Called to skip scrolling the current line of conversation.
   *
   * This event IS cancelable! Canceling this event will prevent the conversation from skipping to the next line.
   * - This event is called when the user presses ACCEPT to advance the conversation while it is already advancing.
   */
  public static inline final DIALOGUE_COMPLETE_LINE:ScriptEventType = 'DIALOGUE_COMPLETE_LINE';

  /**
   * Called to skip the conversation.
   *
   * This event IS cancelable! Canceling this event will prevent the conversation from skipping.
   */
  public static inline final DIALOGUE_SKIP:ScriptEventType = 'DIALOGUE_SKIP';

  /**
   * Called when the game ends a conversation.
   *
   * This event is not cancelable.
   */
  public static inline final DIALOGUE_END:ScriptEventType = 'DIALOGUE_END';

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
