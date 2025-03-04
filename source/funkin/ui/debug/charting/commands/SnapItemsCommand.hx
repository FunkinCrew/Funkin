package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Snap the given items to the current note snap in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SnapItemsCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var snappedNotes:Array<SongNoteData>;
  var events:Array<SongEventData>;
  var snappedEvents:Array<SongEventData>;

  public function new(notes:Array<SongNoteData>, events:Array<SongEventData>)
  {
    // Clone the notes to prevent editing from affecting the history.
    this.notes = notes.clone();
    this.events = events.clone();

    this.snappedNotes = [];
    this.snappedEvents = [];
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

    snappedNotes = [];
    snappedEvents = [];

    for (note in notes)
    {
      // Clone the notes to prevent editing from affecting the history.
      var resultNote = note.clone();

      var targetStep:Float = Conductor.instance.getTimeInSteps(resultNote.time);
      var targetSnappedStep:Float = Math.round(targetStep / state.noteSnapRatio) * state.noteSnapRatio;
      var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);

      if (targetSnappedMs != resultNote.time) resultNote.time = targetSnappedMs.clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps));

      snappedNotes.push(resultNote);
    }

    for (event in events)
    {
      // Clone the notes to prevent editing from affecting the history.
      var resultEvent = event.clone();

      var targetStep:Float = Conductor.instance.getTimeInSteps(resultEvent.time);
      var targetSnappedStep:Float = Math.round(targetStep / state.noteSnapRatio) * state.noteSnapRatio;
      var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);

      if (targetSnappedMs != resultEvent.time) resultEvent.time = targetSnappedMs.clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps));

      snappedEvents.push(resultEvent);
    }

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(snappedNotes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(snappedEvents);
    state.currentNoteSelection = snappedNotes;
    state.currentEventSelection = snappedEvents;

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {

    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, snappedNotes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, snappedEvents);
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
    return 'Snap $len Items';
  }
}
