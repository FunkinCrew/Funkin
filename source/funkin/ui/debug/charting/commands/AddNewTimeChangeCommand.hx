package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongTimeChange;
import funkin.ui.debug.charting.toolboxes.ChartEditorMetadataToolbox;

/**
 * A command which adds a new timechange to the current song's timechanges, after the index value given, at the given timestamp.
 * Will clamp the target timestamp to a valid value.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class AddNewTimeChangeCommand implements ChartEditorCommand
{
  var timeChangeIndex:Int;

  var previousTimeChanges:Null<Array<SongTimeChange>>;

  var targetTimeStamp:Float;

  public function new(timeChangeIndex:Int, targetTimeStamp:Float)
  {
    this.timeChangeIndex = timeChangeIndex;
    this.targetTimeStamp = thx.Floats.ceilTo(targetTimeStamp, 4);
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
      // Clamp the target timestamp to a valid value.
      targetTimeStamp.clamp((timeChanges[timeChangeIndex - 1]?.timeStamp ?? 0) + 1, (timeChanges[timeChangeIndex + 1]?.timeStamp ?? state.songLengthInMs) - 1);
      timeChanges.insert(timeChangeIndex + 1,
        new SongTimeChange(targetTimeStamp, timeChanges[timeChangeIndex].bpm, timeChanges[timeChangeIndex].timeSignatureNum,
          timeChanges[timeChangeIndex].timeSignatureDen));
    }

    state.currentSongMetadata.timeChanges = timeChanges;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.scrollPositionInPixels = 0;

    var metadataToolbox:ChartEditorMetadataToolbox = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_METADATA_LAYOUT);

    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);

    if (metadataToolbox != null) metadataToolbox.refreshTimeChanges(timeChangeIndex + 1);

    state.updateSongTime(); // basically will update the time signature for the editor if necessary.
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
    state.scrollPositionInPixels = 0;

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
    return 'Added new TimeChange ${timeChangeIndex + 1} at ${targetTimeStamp}';
  }
}
#end
