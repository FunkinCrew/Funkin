package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Command that flips a given array of notes from the player's side of the chart editor to the opponent's side, or vice versa.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class FlipNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData> = [];
  var flippedNotes:Array<SongNoteData> = [];

  public function new(notes:Array<SongNoteData>)
  {
    this.notes = notes;
    this.flippedNotes = SongDataUtils.flipNotes(notes);
  }

  public function execute(state:ChartEditorState):Void
  {
    // Delete the notes.
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);

    // Add the flipped notes.
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(flippedNotes);

    state.currentNoteSelection = flippedNotes;
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, flippedNotes);
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);

    state.currentNoteSelection = notes;
    state.currentEventSelection = [];

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
    return 'Flip $len Notes';
  }
}
