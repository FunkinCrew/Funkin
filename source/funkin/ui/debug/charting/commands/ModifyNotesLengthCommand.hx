package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;

/**
 * Represents a reversible action to modifie the length of a group of hold notes.
 * If a note in the group is not a hold note, it will become one, and if it is already a hold note, its length will change.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ModifyNotesLengthCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var lengthChange:Float;

  public function new(notes:Array<SongNoteData>, lengthChange:Float)
  {
    this.notes = notes;
    this.lengthChange = lengthChange;
  }

  /**
   * Perform the action, changing the length of the note.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    adjustNotesLength(state, false);
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'));
  }

  inline private function adjustNotesLength(state:ChartEditorState, undo:Bool):Void
  {
    // Undoing just removes length
    final change:Float = undo ? -lengthChange : lengthChange;

    for (note in notes)
    {
      if (note == null) continue;
      var len:Float = note.length + change;
      if (len <= 0) len = 0;
      note.length = len;
    }

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  /**
   * Reverse the action, reverting the length of the notes.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));
    adjustNotesLength(state, true);
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
    // Only one note length changed
    if (notes.length == 1)
    {
      if (lengthChange > 0) {
        return 'Extended Hold Note Length';
      }
      return 'Reduced Hold Note Length';
    }
    else
    {
      // Multiple notes length changed
      if (lengthChange > 0)
      {
        return 'Extended Hold Notes Length';
      }
      return 'Reduced Hold Notes Length';
    }
  }
}
#end
