package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongNoteDataUtils;

/**
 * Represents a reversible action to detect and remove stacked notes
 * (i.e. notes placed on top of each other) from the current chart chart.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class RemoveStackedNotesCommand implements ChartEditorCommand
{
  var notes:Null<Array<SongNoteData>>;
  var overlappedNotes:Array<SongNoteData>;
  var removedNotes:Array<SongNoteData>;

  public function new(?notes:Array<SongNoteData>)
  {
    this.notes = notes;
    this.overlappedNotes = [];
    this.removedNotes = [];
  }

  /**
   * Perform the action, detecting and removing stacked notes.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    // Whether we are checking just within a selection, or in the entire chart.
    var isSelection:Bool = notes != null;
    var notesToCheck:Array<SongNoteData> = notes ?? state.currentSongChartNoteData;

    if (notesToCheck.length == 0) return;

    overlappedNotes.clear();
    removedNotes = SongNoteDataUtils.listStackedNotes(notesToCheck, ChartEditorState.stackedNoteThreshold, false, overlappedNotes);
    if (removedNotes.length == 0) return;

    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, removedNotes);
    state.currentNoteSelection = isSelection ? overlappedNotes.copy() : [];
    state.currentEventSelection = [];

    state.playSound(Paths.sound('chartingSounds/noteErase'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  /**
   * Reverse the action, restoring the removed notes.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    if (removedNotes.length == 0) return;

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(removedNotes);
    state.currentNoteSelection = overlappedNotes.concat(removedNotes).copy();
    state.currentEventSelection = [];
    state.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

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
    return removedNotes.length > 0;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
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
#end
