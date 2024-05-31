package funkin.play.notes.notekind;

import funkin.data.notestyle.NoteStyleRegistry;
import funkin.play.notes.notestyle.NoteStyle;
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
   * Changes the note style of the given note. Use this in `onNoteIncoming`
   * @param note
   * @param noteStyle
   */
  function setNoteStyle(note:NoteSprite, noteStyleId:String):Void
  {
    var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
    noteStyle.buildNoteSprite(note);

    note.setGraphicSize(Strumline.STRUMLINE_SIZE);
    note.updateHitbox();

    // this calls the setter for playing the correct animation
    note.direction = note.direction;
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
