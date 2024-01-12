package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;

/**
 * Command that modifies the length of a hold note in the chart editor.
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

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (oldLength != newLength);
  }

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

enum Unit
{
  MILLISECONDS;
  STEPS;
}
