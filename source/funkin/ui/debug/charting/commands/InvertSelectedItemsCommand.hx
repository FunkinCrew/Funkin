package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Command to deselect all items that are currently selected in the chart editor,
 * then select all the items that were previously unselected.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class InvertSelectedItemsCommand implements ChartEditorCommand
{
  var previousNoteSelection:Array<SongNoteData> = [];
  var previousEventSelection:Array<SongEventData> = [];

  public function new() {}

  public function execute(state:ChartEditorState):Void
  {
    this.previousNoteSelection = state.currentNoteSelection;
    this.previousEventSelection = state.currentEventSelection;

    state.currentNoteSelection = SongDataUtils.subtractNotes(state.currentSongChartNoteData, previousNoteSelection);
    state.currentEventSelection = SongDataUtils.subtractEvents(state.currentSongChartEventData, previousEventSelection);

    state.noteDisplayDirty = true;
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentNoteSelection = previousNoteSelection;
    state.currentEventSelection = previousEventSelection;

    state.noteDisplayDirty = true;
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (previousNoteSelection.length > 0 || previousEventSelection.length > 0);
  }

  public function toString():String
  {
    return 'Invert Selected Items';
  }
}
