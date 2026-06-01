package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;

/**
 * Represents a reversible action to select all notes and events in the current chart.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SelectAllItemsCommand implements ChartEditorCommand
{
  var shouldSelectNotes:Bool;
  var shouldSelectEvents:Bool;
  var previousNoteSelection:Array<SongNoteData> = [];
  var previousEventSelection:Array<SongEventData> = [];

  public function new(shouldSelectNotes:Bool, shouldSelectEvents:Bool)
  {
    this.shouldSelectNotes = shouldSelectNotes;
    this.shouldSelectEvents = shouldSelectEvents;
  }

  /**
   * Perform the action, selecting the all notes and events in the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    this.previousNoteSelection = state.currentNoteSelection;
    this.previousEventSelection = state.currentEventSelection;

    state.currentNoteSelection = shouldSelectNotes ? state.currentSongChartNoteData : [];
    state.currentEventSelection = shouldSelectEvents ? state.currentSongChartEventData : [];

    state.noteDisplayDirty = true;
    state.editButtonsDirty = true;
  }

  /**
   * Reverse the action, deselecting the notes and events that were selected.
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
    return (state.currentNoteSelection.length > 0 || state.currentEventSelection.length > 0);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    if (shouldSelectNotes && !shouldSelectEvents)
    {
      return 'Select All Notes';
    }
    else if (shouldSelectEvents && !shouldSelectNotes)
    {
      return 'Select All Events';
    }
    else if (shouldSelectNotes && shouldSelectEvents)
    {
      return 'Select All Notes and Events';
    }
    else
    {
      return 'Select Nothing (Huh?)';
    }
  }
}
#end
