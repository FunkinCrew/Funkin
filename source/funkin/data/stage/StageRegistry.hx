package funkin.data.stage;

import funkin.data.JsonFile;
import funkin.modding.psych.PsychStageAdapter;
import funkin.play.stage.Stage;
import funkin.play.stage.ScriptedStage;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class StageRegistry extends BaseRegistry<Stage, StageData, StageEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final STAGE_DATA_VERSION:thx.semver.Version = '1.0.2';

  public static final STAGE_DATA_VERSION_RULE:thx.semver.VersionRule = '>=1.0.0 <1.1.0';

  /**
   * Fase 2.4: stages de Psych Engine se convierten al formato de QT Slice al leerlos.
   */
  override function loadEntryFile(id:String):JsonFile
  {
    var file:JsonFile = super.loadEntryFile(id);

    var raw:Dynamic = null;
    try
    {
      raw = haxe.Json.parse(file.contents);
    }
    catch (e:Dynamic)
    {
      return file;
    }

    if (!PsychStageAdapter.isPsychStage(raw)) return file;

    trace('[PSYCH] Stage de Psych convertido: ' + id);
    return {fileName: file.fileName, contents: haxe.Json.stringify(PsychStageAdapter.convert(raw, id))};
  }

  public function new()
  {
    super('STAGE', 'stages', STAGE_DATA_VERSION_RULE);
  }
}

typedef StageEntryParams =
{
}
