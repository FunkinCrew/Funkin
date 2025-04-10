package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;

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
      timeChanges = [new SongTimeChange(0, targetBPM)];
    }
    else
    {
      previousBPM = timeChanges[0].bpm;
      timeChanges[0].bpm = targetBPM;
    }

    state.currentSongMetadata.timeChanges = timeChanges;

    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);

    state.updateGridHeight();

    // Fix the positions of the notes and events (don't ask me how this works, I have no clue). It just works!
    // I considered putting this in updateGridHeight() but I've noticed it gets updated in a lot of places, so I won't.

    state.currentSongChartNoteData = SongDataUtils.offsetSongNoteData(state.currentSongChartNoteData, 0);
    state.currentSongChartEventData = SongDataUtils.offsetSongEventData(cstate.currentSongChartEventData, 0);
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

    Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);

    state.updateGridHeight();

    state.currentSongChartNoteData = SongDataUtils.offsetSongNoteData(state.currentSongChartNoteData, 0);
    state.currentSongChartEventData = SongDataUtils.offsetSongEventData(cstate.currentSongChartEventData, 0);
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (targetBPM != previousBPM);
  }

  public function toString():String
  {
    return 'Change Starting BPM to ${targetBPM}';
  }
}
