package funkin.play.notes.notekind;

import funkin.data.note.SongNoteSchema;
import funkin.modding.IScriptedClass.INoteScriptedClass;
import funkin.modding.events.ScriptEvent;

/**
 * Class for note scripts
 */
class NoteKind implements INoteScriptedClass
{
  /**
   * The name of the Note Kind.
   */
  public var noteKind:String;

  /**
   * Description used in the Chart Editor.
   */
  public var description:String;

  /**
   * Custom Note Style of this Note Style.
   */
  public var noteStyleId:Null<String>;

  /**
   * Whether or not the sing animation should play.
   */
  public var noanim:Bool;

  /**
   * The animation suffix to use.
   */
  public var suffix:String;

  /**
   * Set this to `false` to disable scoring for this note.
   * The note will no longer count towards ratings, points, or accuracy.
   * @default `true` to enable scoring.
   */
  public var scoreable(default, default):Bool = true;

  public function new(noteKind:String, description:String = '', ?noteStyleId:String, ?noanim:Bool, ?suffix:String)
  {
    this.noteKind = noteKind;
    this.description = description;
    this.noteStyleId = noteStyleId;
    this.noanim = noanim ?? false;
    this.suffix = suffix ?? '';
  }

  /**
   * Retrieves the chart editor schema for this note kind.
   * @return The schema, or null if this note kind does not have a schema.
   */
  public function getNoteSchema():SongNoteSchema
  {
    return null;
  }

  /**
   * Retrieves the human readable title of this note kind.
   * Used for the chart editor.
   * @return The title.
   */
  public function getDescription():String
  {
    return this.description;
  }

  public function toString():String
  {
    return noteKind;
  }

  /**
   * Retrieve all notes of this kind
   * @param visibleCheck If true, only visible notes will be returned
   * @return Array<NoteSprite>
   */
  function getNotes(visibleCheck:Bool = false):Array<NoteSprite>
  {
    var allNotes:Array<NoteSprite> = PlayState.instance.playerStrumline.notes.members.concat(PlayState.instance.opponentStrumline.notes.members);
    return allNotes.filter(function(note:NoteSprite)
    {
      return note != null && note.noteData.kind == this.noteKind && (!visibleCheck || note.visible);
    });
  }

  /**
   * Retrieve all notes NOT of this kind
   * @param visibleCheck If true, only visible notes will be returned
   * @return Array<NoteSprite>
   */
  function getOtherNotes(visibleCheck:Bool = false):Array<NoteSprite>
  {
    var allNotes:Array<NoteSprite> = PlayState.instance.playerStrumline.notes.members.concat(PlayState.instance.opponentStrumline.notes.members);
    return allNotes.filter(function(note:NoteSprite)
    {
      return note != null && note.noteData.kind != this.noteKind && (!visibleCheck || note.visible);
    });
  }

  public function onScriptEvent(event:ScriptEvent):Void
  {
  }

  public function onCreate(event:ScriptEvent):Void
  {
  }

  public function onDestroy(event:ScriptEvent):Void
  {
  }

  public function onUpdate(event:UpdateScriptEvent):Void
  {
  }

  public function onNoteIncoming(event:NoteScriptEvent):Void
  {
  }

  public function onNoteHit(event:HitNoteScriptEvent):Void
  {
  }

  public function onNoteMiss(event:NoteScriptEvent):Void
  {
  }

  public function onNoteHoldDrop(event:HoldNoteScriptEvent)
  {
  }
}
