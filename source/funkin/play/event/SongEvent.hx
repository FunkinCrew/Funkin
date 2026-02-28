package funkin.play.event;

import funkin.data.song.SongData.SongEventData;
import funkin.data.event.SongEventSchema;

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
  ?processOldEvents:Bool
}

/**
 * This class provides a handler for a type of song event.
 * It is used by the ScriptedSongEvent class to handle user-defined events,
 * and also used by other classes in this package to provide default behavior for built-in events.
 */
class SongEvent
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

  public function new(id:String, ?params:SongEventParams)
  {
    this.id = id;

    this.processOldEvents = params?.processOldEvents ?? false;
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
   * Retrieves the chart editor schema for this song event type.
   * @return The schema, or null if this event type does not have a schema.
   */
  public function getEventSchema():SongEventSchema
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
}
