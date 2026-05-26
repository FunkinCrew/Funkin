package funkin.play.event;

import funkin.data.song.SongData.SongEventData;
import funkin.data.event.SongEventSchema;
import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import funkin.modding.events.ScriptEvent;

/**
 * Parameters used to initialize a song event.
 */
typedef SongEventParams =
{
  /**
   * Defaults to `false`, causing events to get skipped when starting mid-song,
   *   or when skipping forward past an event.
   * If `true`, the song event will be handled and executed, even if it is old.
   * @default `false`
   */
  ?processOldEvents:Bool,
  /**
   * An offset to apply to each event's timestamp when activating, in milliseconds.
   */
  ?activationOffsetMs:Float,
  /**
   * An offset to apply to each event's timestamp when activating, in steps.
   */
  ?activationOffsetSteps:Float,
}

/**
 * This class provides a handler for a type of song event.
 * It is used by the ScriptedSongEvent class to handle user-defined events,
 * and also used by other classes in this package to provide default behavior for built-in events.
 */
@:nullSafety
class SongEvent implements IPlayStateScriptedClass
{
  /**
   * These variables are used in two different events (and may be in more), and in order not to create unnecessary variables, we store them here
   */
  public static final DEFAULT_EASE:String = 'linear';

  /**
   * The default ease direction for events which use FlxEase.
   */
  public static final DEFAULT_EASE_DIR:String = 'In';

  /**
   * A regular expression to detect the current ease direction for ease function names from FlxEase.
   */
  public static final EASE_TYPE_DIR_REGEX:EReg = ~/(In|Out|InOut)$/i;

  /**
   * The internal song event ID that this handler is responsible for.
   */
  public var id:String;

  /**
   * If `false`, skipping forward in the song will ignore this event.
   * If `true`, events will always be handled, in order.
   */
  public var processOldEvents:Bool = false;

  /**
   * If not `0`, the offset to apply to each timestamp, in milliseconds.
   * For example, `-1000` will activate `handleEvent()` 1 second earlier than it appears in the chart.
   */
  public var activationOffsetMs:Float = 0.0;

  /**
   * If not `0`, the offset to apply to each timestamp, in BPM-dependant steps.
   * For example, `-16` will activate `handleEvent()` 1 measure earlier than it appears in the chart (at 4/4 signature).
   */
  public var activationOffsetSteps:Float = 0.0;

  public function new(id:String, ?params:SongEventParams)
  {
    this.id = id;

    this.processOldEvents = params?.processOldEvents ?? false;
    this.activationOffsetMs = params?.activationOffsetMs ?? 0.0;
    this.activationOffsetSteps = params?.activationOffsetSteps ?? 0.0;
  }

  /**
   * Handles a song event that matches this handler's ID.
   * @param data The data associated with the event.
   */
  public function handleEvent(data:SongEventData):Void
  {
    throw 'SongEvent.handleEvent() must be overridden!';
  }

  /**
   * Determine the timestamp at which `handleEvent()` should be called for the given event data.
   *
   * @param data The event data to calculate the timestamp for.
   * @param conductor The conductor to use for BPM calculations.
   * @return The calculated timestamp, in milliseconds.
   */
  public function calculateActivationTime(data:SongEventData, conductor:Conductor):Float
  {
    // Add offset in steps
    var tsSteps:Float = data.getStepTime(conductor);
    var tsOffsetSteps:Float = tsSteps + this.activationOffsetSteps;

    // Add offset in milliseconds
    var tsOffsetMs:Float = conductor.getStepTimeInMs(tsOffsetSteps);
    var result:Float = tsOffsetMs + this.activationOffsetMs;

    return result;
  }

  /**
   * Retrieves the Chart Editor schema for this song event type.
   * Used to build the form on the event properties panel.
   *
   * @return The schema, or `null` if this event type does not have a schema.
   */
  public function getEventSchema():Null<SongEventSchema>
  {
    return null;
  }

  /**
   * Retrieves the asset path to the icon this event type should use in the chart editor.
   * To customize this, override getIconPath().
   * @return The path to the icon to display.
   */
  public function getIconPath():String
  {
    return 'ui/chart-editor/events/default';
  }

  /**
   * Retrieves the human readable title of this song event type.
   * Used for the chart editor.
   * @return The title.
   */
  public function getTitle():String
  {
    return this.id.toTitleCase();
  }

  public function toString():String
  {
    return 'SongEvent(${this.id})';
  }

  public function onScriptEvent(event:ScriptEvent)
  {
  }

  public function onCreate(event:ScriptEvent)
  {
  }

  public function onDestroy(event:ScriptEvent)
  {
  }

  public function onUpdate(event:UpdateScriptEvent)
  {
  }

  public function onStepHit(event:SongTimeScriptEvent)
  {
  }

  public function onBeatHit(event:SongTimeScriptEvent)
  {
  }

  public function onPause(event:PauseScriptEvent)
  {
  }

  public function onResume(event:ScriptEvent)
  {
  }

  public function onSongStart(event:ScriptEvent)
  {
  }

  public function onSongEnd(event:ScriptEvent)
  {
  }

  public function onGameOver(event:ScriptEvent)
  {
  }

  public function onNoteIncoming(event:NoteScriptEvent)
  {
  }

  public function onNoteHit(event:HitNoteScriptEvent)
  {
  }

  public function onNoteMiss(event:NoteScriptEvent)
  {
  }

  public function onNoteHoldDrop(event:HoldNoteScriptEvent)
  {
  }

  public function onSongEvent(event:SongEventScriptEvent)
  {
  }

  public function onNoteGhostMiss(event:GhostMissNoteScriptEvent)
  {
  }

  public function onCountdownStart(event:CountdownScriptEvent)
  {
  }

  public function onCountdownStep(event:CountdownScriptEvent)
  {
  }

  public function onCountdownEnd(event:CountdownScriptEvent)
  {
  }

  public function onSongLoaded(event:SongLoadScriptEvent)
  {
  }

  public function onSongRetry(event:SongRetryEvent)
  {
  }
}
