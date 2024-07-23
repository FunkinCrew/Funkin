package funkin.play.notes.notekind;

import funkin.data.notes.SongNoteSchema;
import funkin.modding.IScriptedClass.INoteScriptedClass;
import funkin.modding.events.ScriptEvent;
import flixel.math.FlxMath;

/**
 * Class for note scripts
 */
class NoteKind implements INoteScriptedClass
{
  /**
   * The name of the note kind
   */
  public var noteKind:String;

  /**
   * Title used in chart editor
   */
  public var title:String;

  /**
   * Custom note style
   */
  public var noteStyleId:Null<String>;

  /**
   * Schema for the chart editor
   */
  public var schema:Null<SongNoteSchema>;

  public function new(noteKind:String, title:String = "", ?noteStyleId:String, ?schema:SongNoteSchema)
  {
    this.noteKind = noteKind;
    this.title = title;
    this.noteStyleId = noteStyleId;
    this.schema = schema;
  }

  public function toString():String
  {
    return noteKind;
  }

  /**
   * Retrieve all notes of this kind
   * @return Array<NoteSprite>
   */
  function getNotes():Array<NoteSprite>
  {
    var allNotes:Array<NoteSprite> = PlayState.instance.playerStrumline.notes.members.concat(PlayState.instance.opponentStrumline.notes.members);
    return allNotes.filter(function(note:NoteSprite) {
      return note != null && note.noteData.kind == this.noteKind;
    });
  }

  public function onScriptEvent(event:ScriptEvent):Void {}

  public function onCreate(event:ScriptEvent):Void {}

  public function onDestroy(event:ScriptEvent):Void {}

  public function onUpdate(event:UpdateScriptEvent):Void {}

  public function onNoteIncoming(event:NoteScriptEvent):Void {}

  public function onNoteHit(event:HitNoteScriptEvent):Void {}

  public function onNoteMiss(event:NoteScriptEvent):Void {}
}
