package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Snap the given notes to the current note snap in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SnapNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var snappedNotes:Array<SongNoteData>;

  public function new(notes:Array<SongNoteData>)
  {
    // Clone the notes to prevent editing from affecting the history.
    this.notes = [for (note in notes) note.clone()];

    this.snappedNotes = [];
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);

    snappedNotes = [];

    for (note in notes)
    {
      // Clone the notes to prevent editing from affecting the history.
      var resultNote = note.clone();

      var targetStep:Float = Conductor.instance.getTimeInSteps(resultNote.time);
      var targetSnappedStep:Float = Math.round(targetStep / state.noteSnapRatio) * state.noteSnapRatio;
      var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);

      if (targetSnappedMs != resultNote.time) resultNote.time = targetSnappedMs.clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps));

      snappedNotes.push(resultNote);
    }

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(snappedNotes);
    state.currentNoteSelection = snappedNotes;

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, snappedNotes);
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);

    state.currentNoteSelection = notes;

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (notes.length > 0);
  }

  public function toString():String
  {
    var len:Int = notes.length;
    return 'Snap $len Notes';
  }
}
