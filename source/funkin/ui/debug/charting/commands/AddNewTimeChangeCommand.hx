package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongTimeChange;
import funkin.ui.debug.charting.toolboxes.ChartEditorMetadataToolbox;

/**
 * Represents a reversible action to add a new time change.
 * The time change will be added after the index value given, at the given timestamp.
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

  /**
   * Perform the action, adding a new time change to the song.
   *
   * @param state The ChartEditorState to perform the command on.
   */
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
      timeChanges.insert(
        timeChangeIndex + 1,
        new SongTimeChange(
          targetTimeStamp,
          timeChanges[timeChangeIndex].bpm,
          timeChanges[timeChangeIndex].timeSignatureNum,
          timeChanges[timeChangeIndex].timeSignatureDen
        )
      );
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

  /**
   * Reverse the action, removing the new time change from the song.
   *
   * @param state The ChartEditorState to perform the command on.
   */
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

  /**
   * Whether the command should display in the undo/redo menu.
   *
   * @param state The ChartEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return true;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return 'Added new TimeChange ${timeChangeIndex + 1} at ${targetTimeStamp}';
  }
}
#end
