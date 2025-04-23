package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongTimeChange;

/**
 * A command which modifies the current time change's bpm and/or timestamp in the song.
 * Note that this does not have any protection to prevent time changes from being set to invalid or troublesome values.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ModifyCurrentTimeChangeCommand implements ChartEditorCommand
{
  var currentTimeChange:Int;

  var targetBPM:Float;

  var previousBPM:Float = 100;

  var targetTimeStamp:Float;

  var previousTimeStamp:Float = 0;

  var previousTimeChanges:Null<Array<SongTimeChange>>;

  public function new(currentTimeChange:Int, targetBPM:Float, targetTimeStamp:Float)
  {
    this.currentTimeChange = currentTimeChange;
    this.targetBPM = targetBPM;
    this.targetTimeStamp = targetTimeStamp;
  }

  public function execute(state:ChartEditorState):Void
  {
    var timeChanges:Array<SongTimeChange> = state.currentSongMetadata.timeChanges;
    previousTimeChanges = timeChanges;
    if (timeChanges == null || timeChanges.length == 0)
    {
      previousBPM = 100;
      previousTimeStamp = 0;
      timeChanges = [new SongTimeChange(previousTimeStamp, targetBPM)];
    }
    else
    {
      previousBPM = timeChanges[currentTimeChange].bpm;
      previousTimeStamp = timeChanges[currentTimeChange].timeStamp;
      timeChanges[currentTimeChange].bpm = targetBPM;
      timeChanges[currentTimeChange].timeStamp = targetTimeStamp;
    }

    state.currentSongMetadata.timeChanges = timeChanges;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.scrollPositionInPixels = 0;

    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);

    state.updateGridHeight();
  }

  public function undo(state:ChartEditorState):Void
  {
    if (previousTimeChanges == null)
    {
      previousTimeChanges = [new SongTimeChange(previousTimeStamp, previousBPM)];
    }

    state.currentSongMetadata.timeChanges = previousTimeChanges;

    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.notePreviewViewportBoundsDirty = true;
    state.scrollPositionInPixels = 0;

    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);

    state.updateGridHeight();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (targetBPM != previousBPM || targetTimeStamp != previousTimeStamp);
  }

  public function toString():String
  {
    if (targetBPM == previousBPM && targetTimeStamp != previousTimeStamp) return 'Changed TimeChange ${currentTimeChange} BPM to ${targetBPM}';
    else if (targetBPM != previousBPM && targetTimeStamp == previousTimeStamp) return 'Changed TimeChange ${currentTimeChange} timestamp to ${targetTimeStamp}';
    else
      return 'Changed TimeChange ${currentTimeChange} BPM to ${targetBPM} & timestamp to ${targetTimeStamp}';
  }
}
