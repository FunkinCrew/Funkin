package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Move the given notes by the given offset and shift them by the given number of columns in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class MoveNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var movedNotes:Array<SongNoteData>;
  var offset:Float;
  var columns:Int;

  public function new(notes:Array<SongNoteData>, offset:Float, columns:Int)
  {
    // Clone the notes to prevent editing from affecting the history.
    this.notes = [for (note in notes) note.clone()];
    this.offset = offset;
    this.columns = columns;
    this.movedNotes = [];
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);

    movedNotes = [];

    for (note in notes)
    {
      // Clone the notes to prevent editing from affecting the history.
      var resultNote = note.clone();
      resultNote.time = (resultNote.time + offset).clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps - (1 * state.noteSnapRatio)));
      resultNote.data = ChartEditorState.gridColumnToNoteData((ChartEditorState.noteDataToGridColumn(resultNote.data) + columns).clamp(0,
        ChartEditorState.STRUMLINE_SIZE * 2 - 1));

      movedNotes.push(resultNote);
    }

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(movedNotes);
    state.currentNoteSelection = movedNotes;

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, movedNotes);
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
    return 'Move $len Notes';
  }
}
