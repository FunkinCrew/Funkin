package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongTimeChange;

/**
 * A command which adds a new timechange to the current song's timechanges, after the currently selected timechange.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class AddNewTimeChangeCommand implements ChartEditorCommand
{
  var currentTimeChange:Int;

  var previousTimeChanges:Null<Array<SongTimeChange>>;

  public function new(currentTimeChange:Int)
  {
    this.currentTimeChange = currentTimeChange;
  }

  public function execute(state:ChartEditorState):Void
  {
    var timeChanges:Array<SongTimeChange> = state.currentSongMetadata.timeChanges;
    previousTimeChanges = timeChanges;
    if (timeChanges == null || timeChanges.length == 0)
    {
      timeChanges = [new SongTimeChange(0, 100)];
    }
    else
    {
      timeChanges.insert(currentTimeChange + 1,
        new SongTimeChange(timeChanges[currentTimeChange].timeStamp + 1, timeChanges[currentTimeChange].bpm, timeChanges[currentTimeChange].timeSignatureNum,
          timeChanges[currentTimeChange].timeSignatureDen));
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
      previousTimeChanges = [new SongTimeChange(0, 100)];
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
    return true;
  }

  public function toString():String
  {
    return 'Added new TimeChange after TimeChange ${currentTimeChange}';
  }
}
