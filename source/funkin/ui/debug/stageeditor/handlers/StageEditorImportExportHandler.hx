package funkin.ui.debug.stageeditor.handlers;

import funkin.data.stage.StageData;
import funkin.data.stage.StageRegistry;
import funkin.play.stage.Stage;

/**
 * Contains functions for importing, loading, saving, and exporting stages.
 */
@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorImportExportHandler
{
  public static final BACKUPS_PATH:String = './stagebackups/';

  public static function loadStageAsTemplate(state:StageEditorState, stageId:String):Void
  {
    trace('===============START===============');

    var stage:Null<Stage> = StageRegistry.instance.fetchEntry(stageId);

    if (stage == null) return;

    var stageData:Null<StageData> = stage?._data;

    if (stageData == null) return;

    loadStage(state, stageData);

    state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_METADATA_LAYOUT);

    state.success('Success', 'Loaded stage (${stageData.name})');

    trace('===============END===============');
  }

  /**
   * Loads the stage from given stage data into the editor.
   * @param newStageData The stage data to load.
   */
  public static function loadStage(state:StageEditorState, newStageData:StageData):Void
  {
    state.stageData = newStageData;

    // Clear the undo and redo history
    state.undoHistory = [];
    state.redoHistory = [];
    state.commandHistoryDirty = true;
  }
}
