package funkin.api.newgrounds;

#if FEATURE_NEWGROUNDS_EVENTS
import io.newgrounds.Call.CallOutcome;
import io.newgrounds.NG;
import io.newgrounds.objects.events.Outcome;
import io.newgrounds.objects.events.Result;
#end

/**
 * Use Newgrounds to perform basic telemetry. Ignore if not logged in to Newgrounds.
 */
@:nullSafety
class Events
{
  // Only allow letters, numbers, spaces, dashes, and underscores.
  static final EVENT_NAME_REGEX:EReg = ~/[^a-zA-Z0-9 -_]/g;

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
        trace('[NEWGROUNDS] Logged event: ${data.eventName}');
      case FAIL(outcome):
        switch (outcome)
        {
          case HTTP(error):
            trace('[NEWGROUNDS] HTTP error while logging event: ${error}');
          case RESPONSE(error):
            trace('[NEWGROUNDS] Response error (${error.code}) while logging event: ${error.message}');
          case RESULT(error):
            switch (error.code)
            {
              case 103: // Invalid custom event name
                trace('[NEWGROUNDS] Invalid custom event name: ${eventName}');
              default:
                trace('[NEWGROUNDS] Result error (${error.code}) while logging event: ${error.message}');
            }
        }
    }
  }
  #end

  public static inline function logStartGame():Void
  {
    logEvent('start-game');
  }

  public static inline function logStartSong(songId:String, variation:String):Void
  {
    logEvent('start-song_${songId}-${variation}');
  }

  public static inline function logFailSong(songId:String, variation:String):Void
  {
    logEvent('blueballs_${songId}-${variation}');
  }

  public static inline function logCompleteSong(songId:String, variation:String):Void
  {
    logEvent('complete-song_${songId}-${variation}');
  }

  public static inline function logStartLevel(levelId:String):Void
  {
    logEvent('start-level_${levelId}');
  }

  public static inline function logCompleteLevel(levelId:String):Void
  {
    logEvent('complete-level_${levelId}');
  }

  public static inline function logEarnRank(rankName:String):Void
  {
    logEvent('earn-rank_${rankName}');
  }

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
