package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongNoteData;

/**
 * Represents a reversible action to modifies the length of a hold note.
 * If it is not a hold note, it will become one, and if it is already a hold note, its length will change.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ExtendNoteLengthCommand implements ChartEditorCommand
{
  var note:SongNoteData;
  var oldLength:Float;
  var newLength:Float;
  var unit:Unit;

  public function new(note:SongNoteData, newLength:Float, unit:Unit = MILLISECONDS)
  {
    this.note = note;
    this.oldLength = note.length;
    this.newLength = newLength;
    this.unit = unit;
  }

  /**
   * Perform the action, changing the length of the note.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    switch (unit)
    {
      case MILLISECONDS:
        this.note.length = newLength;
      case STEPS:
        this.note.setStepLength(newLength);
    }

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  /**
   * Reverse the action, reverting the length of the note.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.playSound(Paths.sound('chartingSounds/undo'));

    // Always use milliseconds for undoing
    this.note.length = oldLength;

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
    return (oldLength != newLength);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    if (oldLength == 0)
    {
      return 'Add Hold to Note';
    }
    else if (newLength == 0)
    {
      return 'Remove Hold from Note';
    }
    else
    {
      return 'Extend Hold Note Length';
    }
  }
}

/**
 * The unit of measurement for the change in length.
 */
enum Unit
{
  /**
   * 1000ths of a second.
   */
  MILLISECONDS;

  /**
   * 1/4th of a beat.
   */
  STEPS;
}
#end
