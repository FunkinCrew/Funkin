package funkin.ui.debug.charting.commands;

/**
 * A command which changes the starting BPM of the song.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChangeStartingBPMCommand implements ChartEditorCommand
{
  var targetBPM:Float;

  var previousBPM:Float = 100;

  public function new(targetBPM:Float)
  {
    this.targetBPM = targetBPM;
  }

  public function execute(state:ChartEditorState):Void
  {
    var timeChanges:Array<SongTimeChange> = state.currentSongMetadata.timeChanges;
    if (timeChanges == null || timeChanges.length == 0)
    {
      previousBPM = 100;
      timeChanges = [new SongTimeChange(0, event.value)];
    }
    else
    {
      previousBPM = timeChanges[0].bpm;
      timeChanges[0].bpm = event.value;
    }

    state.currentSongMetadata.timeChanges = timeChanges;

    Conductor.mapTimeChanges(state.currentSongMetadata.timeChanges);
  }

  public function undo(state:ChartEditorState):Void
  {
    var timeChanges:Array<SongTimeChange> = state.currentSongMetadata.timeChanges;
    if (timeChanges == null || timeChanges.length == 0)
    {
      timeChanges = [new SongTimeChange(0, previousBPM)];
    }
    else
    {
      timeChanges[0].bpm = previousBPM;
    }

    state.currentSongMetadata.timeChanges = timeChanges;

    Conductor.mapTimeChanges(state.currentSongMetadata.timeChanges);
  }
}
