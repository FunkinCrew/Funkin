package funkin.data.notestyle;

import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.notestyle.ScriptedNoteStyle;
import funkin.data.notestyle.NoteStyleData;

@:build(funkin.util.macro.RegistryMacro.buildRegistry())
class NoteStyleRegistry extends BaseRegistry<NoteStyle, NoteStyleData>
{
  /**
   * The current version string for the note style data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateNoteStyleData()` function.
   */
  public static final NOTE_STYLE_DATA_VERSION:thx.semver.Version = "1.1.0";

  public static final NOTE_STYLE_DATA_VERSION_RULE:thx.semver.VersionRule = "1.1.x";

  public function new()
  {
    super('NOTESTYLE', 'notestyles', NOTE_STYLE_DATA_VERSION_RULE);
  }

  public function fetchDefault():NoteStyle
  {
    return fetchEntry(Constants.DEFAULT_NOTE_STYLE);
  }
}
