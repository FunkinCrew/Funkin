package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;

/**
 * Command to set the current selection in the chart editor (rather than appending it).
 * Deselects any notes that are not in the new selection.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SetItemSelectionCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;
  var previousNoteSelection:Array<SongNoteData>;
  var previousEventSelection:Array<SongEventData>;

  public function new(notes:Array<SongNoteData>, events:Array<SongEventData>, previousNoteSelection:Array<SongNoteData>,
      previousEventSelection:Array<SongEventData>)
  {
    this.notes = notes;
    this.events = events;
    this.previousNoteSelection = previousNoteSelection == null ? [] : previousNoteSelection;
    this.previousEventSelection = previousEventSelection == null ? [] : previousEventSelection;
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentNoteSelection = notes;
    state.currentEventSelection = events;

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
    return 'Select ${notes.length} Items';
  }
}
