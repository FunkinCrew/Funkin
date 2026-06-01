package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to invert the selection,
 * deselecting all items that are currently selected and selecting all items that are currently unselected.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class InvertSelectedItemsCommand implements ChartEditorCommand
{
  var previousNoteSelection:Array<SongNoteData> = [];
  var previousEventSelection:Array<SongEventData> = [];

  public function new()
  {
  }

  /**
   * Perform the action, inverting the selection.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    this.previousNoteSelection = state.currentNoteSelection;
    this.previousEventSelection = state.currentEventSelection;

    state.currentNoteSelection = SongDataUtils.subtractNotes(state.currentSongChartNoteData, previousNoteSelection);
    state.currentEventSelection = SongDataUtils.subtractEvents(state.currentSongChartEventData, previousEventSelection);

    state.noteDisplayDirty = true;
    state.editButtonsDirty = true;
  }

  /**
   * Reverse the action, restoring the original selection.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = previousNoteSelection;
    state.currentEventSelection = previousEventSelection;

    state.noteDisplayDirty = true;
    state.editButtonsDirty = true;
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
    return (previousNoteSelection.length > 0 || previousEventSelection.length > 0);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return 'Invert Selected Items';
  }
}
#end
