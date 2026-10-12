package funkin.api.newgrounds;

#if FEATURE_NEWGROUNDS_EVENTS
import io.newgrounds.Call.CallOutcome;
import io.newgrounds.NG;
import io.newgrounds.objects.events.Result.LogEventData;
#end

/**
 * Use Newgrounds to perform basic telemetry. Ignore if not logged in to Newgrounds.
 */
@:nullSafety
class Events
{
  // Only allow letters, numbers, spaces, dashes, and underscores.
  static final EVENT_NAME_REGEX:EReg = ~/[^a-zA-Z0-9 -_]/g;
  static final ERROR_CODE_INVALID_EVENT_NAME:Int = 103;

  /**
   * Log an analytics event to Newgrounds. Does nothing if the user is not logged in to Newgrounds.
   *
   * @param eventName The name of the event to log.
   */
  public static function logEvent(eventName:String):Void
  {
    #if (FEATURE_NEWGROUNDS && FEATURE_NEWGROUNDS_EVENTS)
    if (NewgroundsClient.instance.isLoggedIn())
    {
      var eventHandler = NG.core.calls.event;

      if (eventHandler != null)
      {
        var sanitizedEventName = EVENT_NAME_REGEX.replace(eventName, '');
        var outcomeHandler = onEventLogged.bind(sanitizedEventName, _);
        eventHandler.logEvent(sanitizedEventName).addOutcomeHandler(outcomeHandler).send();
      }
    }
    #end
  }

  #if FEATURE_NEWGROUNDS_EVENTS
  static function onEventLogged(eventName:String, outcome:CallOutcome<LogEventData>)
  {
    switch (outcome)
    {
      case SUCCESS(data):
        trace(' NEWGROUNDS '.bold().bg_orange() + ' Logged event: ${data.eventName}');
      case FAIL(outcome):
        switch (outcome)
        {
          case HTTP(error):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' HTTP error while logging event: ${error}');
          case RESPONSE(error):
            trace(' NEWGROUNDS '.bold().bg_orange() + ' Response error (${error.code}) while logging event: ${error.message}');
          case RESULT(error):
            switch (error.code)
            {
              case ERROR_CODE_INVALID_EVENT_NAME: // Invalid custom event name
                trace(' NEWGROUNDS '.bold().bg_orange() + ' Invalid custom event name: ${eventName}');
              default:
                trace(' NEWGROUNDS '.bold().bg_orange() + ' Result error (${error.code}) while logging event: ${error.message}');
            }
        }
    }
  }
  #end

  /**
   * Log an analytics events for the start of the game.
   */
  public static inline function logStartGame():Void
  {
    logEvent('start-game');
  }

  /**
   * Log an analytics events for the completion of a song.
   *
   * @param songId The ID of the song that was played.
   * @param variation The variation of the song that was played (e.g. 'easy', 'normal', 'hard', 'expert').
   */
  public static inline function logStartSong(songId:String, variation:String):Void
  {
    logEvent('start-song_${songId}-${variation}');
  }

  /**
   * Log an analytics event for the failure of a song.
   *
   * @param songId The ID of the song that was failed.
   * @param variation The variation of the song that was failed (e.g. 'easy', 'normal', 'hard', 'expert').
   */
  public static inline function logFailSong(songId:String, variation:String):Void
  {
    logEvent('blueballs_${songId}-${variation}');
  }

  /**
   * Log an analytics event for the completion of a song.
   *
   * @param songId The ID of the song that was completed.
   * @param variation The variation of the song that was completed (e.g. 'easy', 'normal', 'hard', 'expert').
   */
  public static inline function logCompleteSong(songId:String, variation:String):Void
  {
    logEvent('complete-song_${songId}-${variation}');
  }

  /**
   * Log an analytics event for the start of a level.
   *
   * @param levelId The ID of the level that was started.
   */
  public static inline function logStartLevel(levelId:String):Void
  {
    logEvent('start-level_${levelId}');
  }

  /**
   * Log an analytics event for the completion of a level.
   *
   * @param levelId The ID of the level that was completed.
   */
  public static inline function logCompleteLevel(levelId:String):Void
  {
    logEvent('complete-level_${levelId}');
  }

  /**
   * Log an analytics event for earning a rank.
   *
   * @param rankName The name of the rank that was earned.
   */
  public static inline function logEarnRank(rankName:String):Void
  {
    logEvent('earn-rank_${rankName}');
  }

  /**
   * Log an analytics event for watching a cartoon.
   */
  public static inline function logWatchCartoon():Void
  {
    logEvent('watch-cartoon');
  }

  // Note there is already a loadReferral call for the merch link
  // and that gets logged as an event!

  public static inline function logOpenCredits():Void
  {
    logEvent('open-credits');
  }
}
