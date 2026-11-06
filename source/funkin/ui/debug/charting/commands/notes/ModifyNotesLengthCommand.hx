package funkin.ui.debug.charting.commands.notes;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

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
  var oldLengths:Array<Float> = [];
  var modifiedNotes:Bool = false;

  public function new(notes:Array<SongNoteData>, lengthChange:Float)
  {
    this.notes = notes;
    this.lengthChange = lengthChange;

    // Stores all the current notes length.
    for (index in 0...notes.length)
    {
      final note:SongNoteData = notes[index];
      if (note?.length == null) continue;
      oldLengths[index] = note.length;
    }
  }

  /**
   * Perform the action, changing the length of the note.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    for (note in notes)
    {
      if (note == null) continue;
      var len:Float = (note.length ?? 0) + lengthChange;
      if (len < 0) len = 0;
      if (len != note.length) modifiedNotes = true;
      note.length = len;
    }

    // If there were no notes or changes, `modifiedNotes` is still false.
    if (!modifiedNotes) return;
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'));

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
    for (index in 0...notes.length)
    {
      if (notes[index] == null) continue;
      notes[index].length = oldLengths[index];
    }

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
    return modifiedNotes;
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
        return 'Extend Hold Note Length';
      }
      return 'Reduce Hold Note Length';
    }
    else
    {
      // Multiple notes length changed
      if (lengthChange > 0)
      {
        return 'Extend Hold Notes Length';
      }
      return 'Reduce Hold Notes Length';
    }
  }
}
#end
