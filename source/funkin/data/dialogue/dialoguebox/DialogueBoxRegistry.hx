package funkin.data.dialogue.dialoguebox;

import funkin.play.cutscene.dialogue.DialogueBox;
import funkin.data.dialogue.dialoguebox.DialogueBoxData;
import funkin.play.cutscene.dialogue.ScriptedDialogueBox;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class DialogueBoxRegistry extends BaseRegistry<DialogueBox, DialogueBoxData> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the dialogue box data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateDialogueBoxData()` function.
   */
  public static final DIALOGUEBOX_DATA_VERSION:thx.semver.Version = "1.1.0";

  public static final DIALOGUEBOX_DATA_VERSION_RULE:thx.semver.VersionRule = ">=1.0.0 <1.2.0";

  public function new()
  {
    super('DIALOGUEBOX', 'dialogue/boxes', DIALOGUEBOX_DATA_VERSION_RULE);
  }
}
