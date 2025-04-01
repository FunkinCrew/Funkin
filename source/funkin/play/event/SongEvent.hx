package funkin.play.event;

import funkin.data.song.SongData.SongEventData;
import funkin.data.event.SongEventSchema;

/**
 * This class represents a handler for a type of song event.
 * It is used by the ScriptedSongEvent class to handle user-defined events.
 */
class SongEvent
{
  /**
   * The internal song event ID that this handler is responsible for.
   */
  public var id:String;

  public function new(id:String)
  {
    this.id = id;
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
