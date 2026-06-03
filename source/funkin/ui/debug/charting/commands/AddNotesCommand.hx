package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to add one or more notes.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class AddNotesCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var appendToSelection:Bool;

  public function new(notes:Array<SongNoteData>, appendToSelection:Bool = false)
  {
    this.notes = notes;
    this.appendToSelection = appendToSelection;
  }

  /**
   * Perform the action, adding the new song notes to the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    for (note in notes)
    {
      state.currentSongChartNoteData.pushUnique(note);
    }

    if (appendToSelection)
    {
      for (note in notes)
      {
        state.currentNoteSelection.pushUnique(note);
      }
    }
    else
    {
      state.currentNoteSelection = notes;
      state.currentEventSelection = [];
    }

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;

    state.sortChartData();
  }

  /**
   * Reverse the action, removing the added notes from the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentNoteSelection = [];
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
    if (notes.length == 1)
    {
      var dir:String = notes[0].getDirectionName();
      return 'Add $dir Note';
    }

    return 'Add ${notes.length} Notes';
  }
}
#end
