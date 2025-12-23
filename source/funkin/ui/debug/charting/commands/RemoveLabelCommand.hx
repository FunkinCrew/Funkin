package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongLabel;
import funkin.ui.debug.charting.toolboxes.ChartEditorMetadataToolbox;

/**
 * Adds the given notes to the current chart in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class RemoveLabelCommand implements ChartEditorCommand
{
  var labelIndex:Int;

  var prevSongLabels:Array<SongLabel> = [];

  public function new(labelIndex:Int)
  {
    this.labelIndex = labelIndex;
  }

  public function execute(state:ChartEditorState):Void
  {
    var labels:Array<SongLabel> = state.currentSongMetadata.labels;

    var newIndex = labelIndex - 1;
    if (newIndex < 0) newIndex = 0;

    prevSongLabels = labels.copy();

    labels.splice(labelIndex, 1);

    state.currentSongMetadata.labels = labels;

    var metadataToolbox:ChartEditorMetadataToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    if (metadataToolbox != null)
    {
      metadataToolbox.inputLabel.selectedIndex = newIndex;
      metadataToolbox.refreshLabels();
    }
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongMetadata.labels = prevSongLabels;

    var metadataToolbox:ChartEditorMetadataToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    if (metadataToolbox != null)
    {
      metadataToolbox.inputLabel.selectedIndex = labelIndex;
      metadataToolbox.refreshLabels();
    }
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    return 'Remove Label';
  }
}
#end
