package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Adds the given notes to the current chart in the chart editor.
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

  public function execute(state:ChartEditorState):Void
  {
    for (note in notes)
    {
      state.currentSongChartNoteData.push(note);
    }

    if (appendToSelection)
    {
      state.currentNoteSelection = state.currentNoteSelection.concat(notes);
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

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentNoteSelection = [];
    state.currentEventSelection = [];
    state.playSound(Paths.sound('chartingSounds/undo'));

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
    if (notes.length == 1)
    {
      var dir:String = notes[0].getDirectionName();
      return 'Add $dir Note';
    }

    return 'Add ${notes.length} Notes';
  }
}
