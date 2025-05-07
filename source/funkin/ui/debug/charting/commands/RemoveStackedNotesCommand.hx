package funkin.ui.debug.charting.commands;

import funkin.data.song.SongNoteDataUtils;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Deletes the given notes from the current chart in the chart editor if any overlap another.
 * Use only when ONLY notes are being deleted.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class RemoveStackedNotesCommand implements ChartEditorCommand
{
  var notes:Null<Array<SongNoteData>>;
  var removedNotes:Array<SongNoteData>;

  public function new(?notes:Array<SongNoteData>)
  {
    this.notes = notes;
    this.removedNotes = [];
  }

  public function execute(state:ChartEditorState):Void
  {
    var isSelection:Bool = notes != null;
    var notes:Array<SongNoteData> = notes ?? state.currentSongChartNoteData;

    if (notes.length == 0) return;

    removedNotes = SongNoteDataUtils.listStackedNotes(notes, ChartEditorState.stackedNoteThreshold, false);
    if (removedNotes.length == 0) return;

    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, removedNotes);
    state.currentNoteSelection = isSelection ? notes : [];
    state.currentEventSelection = [];

    state.playSound(Paths.sound('chartingSounds/noteErase'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    if (removedNotes.length == 0) return;

    state.currentSongChartNoteData = SongNoteDataUtils.concatOverwrite(state.currentSongChartNoteData, removedNotes);
    state.currentNoteSelection = (notes ?? []).concat(removedNotes.copy());
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
    return removedNotes.length > 0;
  }

  public function toString():String
  {
    if (removedNotes.length == 1 && removedNotes[0] != null)
    {
      var dir:String = removedNotes[0].getDirectionName();
      return 'Remove $dir Stacked Note';
    }

    return 'Remove ${removedNotes.length} Stacked Notes';
  }
}
