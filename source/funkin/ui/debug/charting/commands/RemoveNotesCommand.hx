package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to remove a list of notes from a chart.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class RemoveNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;

  public function new(notes:Array<SongNoteData>)
  {
    this.notes = notes;
  }

  /**
   * Perform the action, removing the notes from the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    if (notes.length == 0) return;

    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    state.playSound(Paths.sound('chartingSounds/noteErase'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;

    state.sortChartData();
  }

  /**
   * Reverse the action, restoring the notes to the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    if (notes.length == 0) return;

    for (note in notes)
    {
      state.currentSongChartNoteData.push(note);
    }
    state.currentNoteSelection = notes;
    state.currentEventSelection = [];
    state.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;

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
    return (notes.length > 0);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    if (notes.length == 1 && notes[0] != null)
    {
      var dir:String = notes[0].getDirectionName();
      return 'Remove $dir Note';
    }

    return 'Remove ${notes.length} Notes';
  }
}
#end
