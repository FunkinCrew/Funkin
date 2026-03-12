package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongTimeChange;
import funkin.ui.debug.charting.toolboxes.ChartEditorMetadataToolbox;

/**
 * A command which removes the given timechange from the current song's timechanges.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class RemoveTimeChangeCommand implements ChartEditorCommand
{
  var timeChangeIndex:Int;

  var previousTimeChanges:Null<Array<SongTimeChange>>;

  var removedTimeChange:Null<Array<SongTimeChange>>;

  public function new(timeChangeIndex:Int)
  {
    this.timeChangeIndex = timeChangeIndex;
  }

  public function execute(state:ChartEditorState):Void
  {
    var timeChanges:Array<SongTimeChange> = state.currentSongMetadata.timeChanges;
    previousTimeChanges = timeChanges.copy();
    if (timeChanges == null || timeChanges.length == 0)
    {
      timeChanges = [new SongTimeChange(0, 100)];
    }
    else
    {
      removedTimeChange = timeChanges.splice(timeChangeIndex, 1);
    }

    state.currentSongMetadata.timeChanges = timeChanges;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;

    var metadataToolbox:ChartEditorMetadataToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);

    if (metadataToolbox != null) metadataToolbox.refreshTimeChanges(timeChangeIndex - 1);

    state.updateSongTime();
    state.updateGridHeight();
    state.updateTimeSignature();
  }

  public function undo(state:ChartEditorState):Void
  {
    if (previousTimeChanges == null)
    {
      previousTimeChanges = [new SongTimeChange(0, 100)];
    }

    state.currentSongMetadata.timeChanges = previousTimeChanges;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;

    var metadataToolbox:ChartEditorMetadataToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);

    if (metadataToolbox != null) metadataToolbox.refreshTimeChanges(timeChangeIndex);

    state.updateSongTime();
    state.updateGridHeight();
    state.updateTimeSignature();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    if (removedTimeChange != null && removedTimeChange.length > 0) return
      'TimeChange ${timeChangeIndex} : ${removedTimeChange[0].timeStamp} ms : BPM: ${removedTimeChange[0].bpm} in ${removedTimeChange[0].timeSignatureNum}/${removedTimeChange[0].timeSignatureDen} removed'
    else
      return 'huh?';
  }
}
#end
