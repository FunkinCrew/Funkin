package funkin.ui.debug.charting.commands.notes;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongNoteDataUtils;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a reversible action to mirror a list of notes in the chart.
 * Notes can be mirrored horizontally or vertically, or both.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class MirrorNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData> = [];
  var mirroredNotes:Array<SongNoteData> = [];
  var overwrittenNotes:Array<SongNoteData> = [];
  var mirrorX:Bool = true;
  var mirrorY:Bool = true;

  public function new(notes:Array<SongNoteData>, mirrorIndividually:Bool = true, flipMiddle:Bool = false, mirrorX:Bool = true, mirrorY:Bool = true)
  {
    this.notes = notes.copy();
    this.mirrorX = mirrorX;
    this.mirrorY = mirrorY;
    this.mirroredNotes = SongDataUtils.mirrorNotes(this.notes, ChartEditorState.STRUMLINE_SIZE, flipMiddle && !mirrorIndividually, mirrorX, mirrorY);
  }

  /**
   * Perform the action, mirroring the list of notes.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    // Delete the notes.
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);

    overwrittenNotes = [];
    state.currentSongChartNoteData = SongNoteDataUtils.concatOverwrite(state.currentSongChartNoteData, mirroredNotes, overwrittenNotes);

    state.currentNoteSelection = mirroredNotes;
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.sortChartData();
  }

  /**
   * Reverse the action, restoring the original notes.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, mirroredNotes);
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes).concat(overwrittenNotes);

    state.currentNoteSelection = notes;
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  /**
   * Whether the command should display in the undo/redo menu.
   * This should be `false` if no real actions were actually performed.
   *
   * @param state The ChartEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (notes.length > 0 && mirrorX || !mirrorX && mirrorY && notes.length > 1);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    var len:Int = notes.length;
    return 'Mirror ${(notes.length > 1) ? '$len Notes' : 'Note'} on ${(mirrorX) ? 'X' : (mirrorY) ? 'Y' : 'huh?'} Axis';
  }
}
