package funkin.ui.debug.stageeditor.handlers;

import funkin.data.stage.StageData;
import funkin.data.stage.StageRegistry;
import funkin.play.stage.Stage;

/**
 * Contains functions for importing, loading, saving, and exporting charts.
 */
@:nullSafety
class StageEditorImportExportHandler
{
  public static final BACKUPS_PATH:String = './backups/';

  public static function loadStageAsTemplate(state:StageEditorState, stageId:String):Void
  {
    trace('===============START');

    var stage:Null<Stage> = StageRegistry.instance.fetchEntry(stageId);

    if (stage == null) return;

    var stageData:Null<StageData> = stage?._data;

    if (stageData == null) return;

    loadStage(state, stageData);
  }

  public static function loadStage(state:StageEditorState, newStageData:StageData):Void
  {

  }
}
