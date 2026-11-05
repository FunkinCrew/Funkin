package funkin.ui.debug.charting.commands.items;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Allows for notes to be dragged freely (creating sub-beats where possible)
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class AlignItemsToSubBeatsCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var movedNotes:Array<SongNoteData> = [];
  var events:Array<SongEventData>;
  var movedEvents:Array<SongEventData> = [];
  var noteTimes:Array<Float>;
  var eventTimes:Array<Float>;
  var columns:Int;
  var newSubBeats:Array<Float>;

  var subBeatsBefore:Null<Array<Float>> = null;

  /**
   * @param notes The notes to move.
   * @param events The events to move.
   * @param noteTimes The new time of each note, in milliseconds.
   * @param eventTimes The new time of each event, in milliseconds.
   * @param columns How many columns the notes move by.
   * @param newSubBeats Sub-beats to add, in milliseconds.
   */
  public function new(notes:Array<SongNoteData>, events:Array<SongEventData>, noteTimes:Array<Float>, eventTimes:Array<Float>, columns:Int,
      ?newSubBeats:Array<Float>)
  {
    this.newSubBeats = newSubBeats?.copy() ?? [];
    this.notes = notes.copy();
    this.events = events.copy();
    this.noteTimes = noteTimes.copy();
    this.eventTimes = eventTimes.copy();
    this.columns = columns;
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, notes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

    var maxTime:Float = Conductor.instance.getStepTimeInMs(state.lastSnappedGridStep);
    movedNotes = [];
    movedEvents = [];

    for (i in 0...notes.length)
    {
      var resultNote:SongNoteData = notes[i].clone();
      resultNote.time = noteTimes[i].clamp(0, maxTime);
      resultNote.data = ChartEditorNoteUtil.gridColumnToNoteData(
        (ChartEditorNoteUtil.noteDataToGridColumn(resultNote.data) + columns).clamp(0, ChartEditorState.STRUMLINE_SIZE * 2 - 1)
      );
      movedNotes.pushUnique(resultNote);
    }

    for (i in 0...events.length)
    {
      var resultEvent:SongEventData = events[i].clone();
      resultEvent.time = eventTimes[i].clamp(0, maxTime);
      movedEvents.pushUnique(resultEvent);
    }

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(movedNotes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(movedEvents);
    state.currentNoteSelection = movedNotes;
    state.currentEventSelection = movedEvents;

    if (newSubBeats.length > 0)
    {
      var before:Array<Float> = state.currentSubBeats().copy();
      subBeatsBefore = before;
      setSubBeats(state, before.concat([for (time in newSubBeats) time.clamp(0, maxTime)]));
    }

    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'));

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

    var before:Null<Array<Float>> = subBeatsBefore;
    if (before != null)
    {
      setSubBeats(state, before);
      subBeatsBefore = null;
    }

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  function setSubBeats(state:ChartEditorState, times:Array<Float>):Void
  {
    var subBeats:Array<Float> = state.currentSubBeats();
    subBeats.resize(0);
    for (time in times)
    {
      if (!subBeats.contains(time)) subBeats.push(time);
    }
    subBeats.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
    state.gridLinesDirty = true;
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return (notes.length > 0 || events.length > 0);
  }

  public function toString():String
  {
    var len:Int = notes.length + events.length;
    return 'Align $len Items to Sub-Beats';
  }
}
#end
