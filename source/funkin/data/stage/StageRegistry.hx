package funkin.data.stage;

import funkin.play.stage.Stage;
import funkin.play.stage.ScriptedStage;
import funkin.util.tools.ISingleton;

class StageRegistry extends BaseRegistry<Stage, StageData, 'stages'> implements ISingleton
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final STAGE_DATA_VERSION:thx.semver.Version = "1.0.3";

  public static final STAGE_DATA_VERSION_RULE:thx.semver.VersionRule = ">=1.0.0 <1.1.0";

  public function new()
  {
    super('STAGE', STAGE_DATA_VERSION_RULE);
  }
}
