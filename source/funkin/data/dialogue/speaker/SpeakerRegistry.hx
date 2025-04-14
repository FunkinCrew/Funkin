package funkin.data.dialogue.speaker;

import funkin.play.cutscene.dialogue.Speaker;
import funkin.play.cutscene.dialogue.ScriptedSpeaker;
import funkin.util.tools.ISingleton;

class SpeakerRegistry extends BaseRegistry<Speaker, SpeakerData, 'dialogue/speakers'> implements ISingleton
{
  /**
   * The current version string for the speaker data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateSpeakerData()` function.
   */
  public static final SPEAKER_DATA_VERSION:thx.semver.Version = "1.0.0";

  public static final SPEAKER_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";

  public function new()
  {
    super('SPEAKER', SPEAKER_DATA_VERSION_RULE);
  }
}
