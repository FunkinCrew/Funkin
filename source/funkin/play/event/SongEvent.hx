package funkin.play.event;

import funkin.data.song.SongData.SongEventData;
import funkin.data.event.SongEventSchema;
import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import funkin.modding.events.ScriptEvent;

/**
 * This class represents a handler for a type of song event.
 * It is used by the ScriptedSongEvent class to handle user-defined events.
 */
class SongEvent implements IPlayStateScriptedClass
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

  public function onScriptEvent(event:ScriptEvent) {}

  public function onCreate(event:ScriptEvent) {}

  public function onDestroy(event:ScriptEvent) {}

  public function onUpdate(event:UpdateScriptEvent) {}

  public function onStepHit(event:SongTimeScriptEvent) {}

  public function onBeatHit(event:SongTimeScriptEvent) {}

  public function onPause(event:PauseScriptEvent) {}

  public function onResume(event:ScriptEvent) {}

  public function onSongStart(event:ScriptEvent) {}

  public function onSongEnd(event:ScriptEvent) {}

  public function onGameOver(event:ScriptEvent) {}

  public function onNoteIncoming(event:NoteScriptEvent) {}

  public function onNoteHit(event:HitNoteScriptEvent) {}

  public function onNoteMiss(event:NoteScriptEvent) {}

  public function onSongEvent(event:SongEventScriptEvent) {}

  public function onNoteGhostMiss(event:GhostMissNoteScriptEvent) {}

  public function onCountdownStart(event:CountdownScriptEvent) {}

  public function onCountdownStep(event:CountdownScriptEvent) {}

  public function onCountdownEnd(event:CountdownScriptEvent) {}

  public function onSongLoaded(event:SongLoadScriptEvent) {}

  public function onSongRetry(event:SongRetryEvent) {}
}
