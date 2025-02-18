package funkin.data.stage;

import funkin.data.stage.StageData;
import funkin.play.stage.Stage;
import funkin.play.stage.ScriptedStage;
import funkin.data.DefaultRegistryImpl;

class StageRegistry extends BaseRegistry<Stage, StageData> implements DefaultRegistryImpl
{
  /**
   * The current version string for the stage data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStageData()` function.
   */
  public static final STAGE_DATA_VERSION:thx.semver.Version = "1.0.3";

  public static final STAGE_DATA_VERSION_RULE:thx.semver.VersionRule = ">=1.0.0 <=1.0.3";

  public function new()
  {
    super('STAGE', 'stages', STAGE_DATA_VERSION_RULE);
  }

  /**
   * A list of all the stages from the base game, in order.
   * TODO: Should this be hardcoded?
   */
  public function listBaseGameStageIds():Array<String>
  {
    return [
      "mainStage",
      "mainStageErect",
      "spookyMansion",
      "phillyTrain",
      "phillyTrainErect",
      "limoRide",
      "limoRideErect",
      "mallXmas",
      "mallXmasErect",
      "mallEvil",
      "school",
      "schoolEvil",
      "tankmanBattlefield",
      "phillyStreets",
      "phillyStreetsErect",
      "phillyBlazin",
    ];
  }

  /**
   * A list of all installed story weeks that are not from the base game.
   */
  public function listModdedStageIds():Array<String>
  {
    return listEntryIds().filter(function(id:String):Bool {
      return listBaseGameStageIds().indexOf(id) == -1;
    });
  }
}
