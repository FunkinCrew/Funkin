package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Adds the given notes to the current chart in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class GenerateNotesCommand implements ChartEditorCommand
{
  var previousNotes:Null<Array<SongNoteData>>;
  var previousHints:Null<Array<SongNoteData>>;
  var previousDifficultyId:Null<String>;
  var notes:Null<Array<SongNoteData>>;
  var hints:Null<Array<SongNoteData>>;
  var difficultyId:Null<String>;

  public function new(?notes:Array<SongNoteData>, ?hints:Array<SongNoteData>, ?difficultyId:String)
  {
    this.previousNotes = null;
    this.previousHints = null;
    this.previousDifficultyId = null;
    this.notes = notes;
    this.hints = hints;
    this.difficultyId = difficultyId;
  }

  public function execute(state:ChartEditorState):Void
  {
    if (previousNotes != null || previousHints != null || previousDifficultyId != null)
    {
      return;
    }

    var originalDifficulty:String = state.selectedDifficulty;

    previousDifficultyId = difficultyId ?? state.selectedDifficulty;
    state.selectedDifficulty = difficultyId ?? state.selectedDifficulty;

    previousNotes = state.currentSongChartNoteData.copy(); // should this be a deep copy?
    previousHints = state.currentHints.copy();

    if (notes != null)
    {
      state.currentSongChartNoteData = notes;
    }

    if (hints != null)
    {
      state.currentHints = hints;
    }

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();

    state.selectedDifficulty = originalDifficulty;
  }

  public function undo(state:ChartEditorState):Void
  {
    if (previousNotes == null || previousHints == null || previousDifficultyId == null)
    {
      return;
    }

    var originalDifficulty:String = state.selectedDifficulty;

    state.selectedDifficulty = previousDifficultyId;

    state.currentSongChartNoteData = previousNotes;
    state.currentHints = previousHints;
    state.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();

    state.selectedDifficulty = originalDifficulty;

    previousNotes = null;
    previousHints = null;
    previousDifficultyId = null;
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return previousNotes != null && previousHints != null && previousDifficultyId != null;
  }

  public function toString():String
  {
    var message:String = 'Generate ';

    if (notes != null)
    {
      message += '${notes.length} Note${notes.length > 1 ? 's' : ''}';
      if (hints != null)
      {
        message += ' and ';
      }
    }

    if (hints != null)
    {
      message += '${hints.length} Hint${hints.length > 1 ? 's' : ''}';
    }

    return message;
  }
}
