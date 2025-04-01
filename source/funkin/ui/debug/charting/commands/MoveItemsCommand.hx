package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Move the given notes by the given offset and shift them by the given number of columns in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class MoveItemsCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var movedNotes:Array<SongNoteData>;
  var events:Array<SongEventData>;
  var movedEvents:Array<SongEventData>;
  var offset:Float;
  var columns:Int;

  public function new(notes:Array<SongNoteData>, events:Array<SongEventData>, offset:Float, columns:Int)
  {
    // Clone the notes to prevent editing from affecting the history.
    this.notes = notes.clone();
    this.events = events.clone();
    this.offset = offset;
    this.columns = columns;
    this.movedNotes = [];
    this.movedEvents = [];
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

    movedNotes = [];
    movedEvents = [];

    for (note in notes)
    {
      // Clone the notes to prevent editing from affecting the history.
      var resultNote = note.clone();
      resultNote.time = (resultNote.time + offset).clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps - (1 * state.noteSnapRatio)));
      resultNote.data = ChartEditorState.gridColumnToNoteData((ChartEditorState.noteDataToGridColumn(resultNote.data) + columns).clamp(0,
        ChartEditorState.STRUMLINE_SIZE * 2 - 1));

      movedNotes.push(resultNote);
    }

    for (event in events)
    {
      // Clone the notes to prevent editing from affecting the history.
      var resultEvent = event.clone();
      resultEvent.time = (resultEvent.time + offset).clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps - (1 * state.noteSnapRatio)));

      movedEvents.push(resultEvent);
    }

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(movedNotes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(movedEvents);
    state.currentNoteSelection = movedNotes;
    state.currentEventSelection = movedEvents;

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, movedNotes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, movedEvents);
    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(notes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(events);

    state.currentNoteSelection = notes;
    state.currentEventSelection = events;

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (notes.length > 0 || events.length > 0);
  }

  public function toString():String
  {
    var len:Int = notes.length + events.length;
    return 'Move $len Items';
  }
}
