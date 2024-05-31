package funkin.play.notes.notekind;

import funkin.modding.IScriptedClass.INoteScriptedClass;
import funkin.modding.events.ScriptEvent;

/**
 * Class for note scripts
 */
class NoteKind implements INoteScriptedClass
{
  /**
   * the name of the note kind
   */
  public var noteKind:String;

  /**
   * description used in chart editor
   */
  public var description:String = "";

  /**
   * this only exists for people that don't like calling functions
   */
  var notes(get, never):Array<NoteSprite>;

  function get_notes():Array<NoteSprite>
  {
    return this.getNotes();
  }

  public function new(noteKind:String, description:String = "")
  {
    this.noteKind = noteKind;
    this.description = description;
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
