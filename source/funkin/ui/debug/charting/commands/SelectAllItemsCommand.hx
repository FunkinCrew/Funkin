package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;

/**
 * Command to set the selection to all notes and events in the chart editor.
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

  public function execute(state:ChartEditorState):Void
  {
    this.previousNoteSelection = state.currentNoteSelection;
    this.previousEventSelection = state.currentEventSelection;

    state.currentNoteSelection = shouldSelectNotes ? state.currentSongChartNoteData : [];
    state.currentEventSelection = shouldSelectEvents ? state.currentSongChartEventData : [];

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
    return (state.currentNoteSelection.length > 0 || state.currentEventSelection.length > 0);
  }

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
