package funkin.play.notes.notekind;

/**
 * A custom note kind which has custom functionality, preventing singing animations from playing.
 */
class NoAnimNoteKind extends NoteKind
{
  static final DISABLE_ANIMATIONS:Bool = true;

  public function new()
  {
    super("noanim", "Disables singing animations", null, [], DISABLE_ANIMATIONS, null);
  }
}
