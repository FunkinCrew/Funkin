package funkin.data.dialogue;

import funkin.play.cutscene.dialogue.Speaker;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class SpeakerRegistry extends BaseRegistry<Speaker, SpeakerData, SpeakerEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the speaker data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateSpeakerData()` function.
   */
  public static final SPEAKER_DATA_VERSION:thx.semver.Version = '1.0.0';

  public static final SPEAKER_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super({
      registryId: 'SPEAKER',
      dataFilePath: 'gameplay/dialogue/speakers/',
      nestedEntries: true,
      versionRule: SPEAKER_DATA_VERSION_RULE
    });
  }

  override public function fetchEntry(id:String, ?params:SpeakerEntryParams):Null<Speaker>
  {
    var scriptClass:Null<String> = getScriptedEntryClassName(id, params);
    if (scriptClass != null)
    {
      return Speaker.scriptInit(scriptClass, id);
    }

    if (!hasEntry(id))
    {
      return super.fetchEntry(id, params);
    }

    return new Speaker(id, params);
  }
}

typedef SpeakerEntryParams =
{
}
