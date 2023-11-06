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
  var previousNoteSelection:Array<SongNoteData>;
  var previousEventSelection:Array<SongEventData>;

  public function new(?previousNoteSelection:Array<SongNoteData>, ?previousEventSelection:Array<SongEventData>)
  {
    this.previousNoteSelection = previousNoteSelection == null ? [] : previousNoteSelection;
    this.previousEventSelection = previousEventSelection == null ? [] : previousEventSelection;
  }

  public function execute(state:ChartEditorState):Void
  {
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

  public function toString():String
  {
    return 'Invert Selected Items';
  }
}
