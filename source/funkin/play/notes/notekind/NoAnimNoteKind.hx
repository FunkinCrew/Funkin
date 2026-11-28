package funkin.play.notes.notekind;

/**
 * A custom note kind which has custom functionality, preventing singing animations from playing.
 */
class NoAnimNoteKind extends NoteKind
{
  public function new()
  {
    super('noanim', 'No Animation', null, [], true, null);
  }
}
