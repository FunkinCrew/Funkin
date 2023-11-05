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

  public function new(note:SongNoteData, newLength:Float)
  {
    this.note = note;
    this.oldLength = note.length;
    this.newLength = newLength;
  }

  public function execute(state:ChartEditorState):Void
  {
    note.length = newLength;

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.playSound(Paths.sound('chartingSounds/undo'));

    note.length = oldLength;

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    return 'Extend Note Length';
  }
}
