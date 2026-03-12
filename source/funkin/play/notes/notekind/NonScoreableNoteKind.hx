package funkin.play.notes.notekind;

import funkin.modding.events.ScriptEvent.NoteScriptEvent;

/**
 * A custom note kind which has custom functionality, preventing notes from being scored in the Results Screen.
 */
class NonScoreableNoteKind extends NoteKind
{
  public function new()
  {
    super('non_scoreable', 'Non-scoreable');
    scoreable = false;
  }

  public override function onNoteMiss(event:NoteScriptEvent):Void
  {
    event.note.visible = false;
    event.cancel();
  }
}
