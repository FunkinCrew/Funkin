package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongLabel;
import funkin.ui.debug.charting.toolboxes.ChartEditorMetadataToolbox;
import flixel.util.FlxSort;

/**
 * Adds the given notes to the current chart in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class AddLabelCommand implements ChartEditorCommand
{
  var timeStamp:Float;

  var prevSongLabels:Array<SongLabel> = [];

  var myLabel:SongLabel;

  public function new(timeStamp:Float)
  {
    this.timeStamp = timeStamp;
    this.myLabel = new SongLabel(timeStamp, "Label", false, "");
  }

  public function execute(state:ChartEditorState):Void
  {
    var labels:Array<SongLabel> = state.currentSongMetadata.labels;

    prevSongLabels = labels.copy();

    labels.push(myLabel);

    labels.sort(function(a:SongLabel, b:SongLabel):Int {
      return FlxSort.byValues(FlxSort.ASCENDING, a.timeStamp, b.timeStamp);
    });

    state.currentSongMetadata.labels = labels;

    var metadataToolbox:ChartEditorMetadataToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    if (metadataToolbox != null)
    {
      metadataToolbox.inputLabel.selectedIndex = state.currentSongMetadata.labels.indexOf(myLabel);
      metadataToolbox.refreshLabels();
    }
  }

  public function undo(state:ChartEditorState):Void
  {
    var newIndex = state.currentSongMetadata.labels.indexOf(myLabel) - 1;
    if (newIndex < 0) newIndex = 0;

    state.currentSongMetadata.labels = prevSongLabels;

    var metadataToolbox:ChartEditorMetadataToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    if (metadataToolbox != null)
    {
      metadataToolbox.inputLabel.selectedIndex = newIndex;
      metadataToolbox.refreshLabels();
    }
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    return 'Add Label';
  }
}
#end
