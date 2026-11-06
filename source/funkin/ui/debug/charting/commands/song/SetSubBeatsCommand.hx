package funkin.ui.debug.charting.commands.song;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a change to the list of sub-beats in the chart.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SetSubBeatsCommand implements ChartEditorCommand
{
  var before:Array<Float>;
  var after:Array<Float>;

  var pickAfter:Array<Float>;
  var label:String;

  var notes:Array<SongNoteData>;

  var notesBefore:Array<Float>;
  var notesAfter:Array<Float>;

  var events:Array<SongEventData>;
  var eventsBefore:Array<Float>;
  var eventsAfter:Array<Float>;

  public function new(before:Array<Float>, after:Array<Float>, pickAfter:Array<Float>, label:String, ?notes:Array<SongNoteData>, ?notesBefore:Array<Float>,
      ?notesAfter:Array<Float>, ?events:Array<SongEventData>, ?eventsBefore:Array<Float>, ?eventsAfter:Array<Float>)
  {
    this.events = events ?? [];
    this.eventsBefore = eventsBefore ?? [];
    this.eventsAfter = eventsAfter ?? [];
    this.before = before.copy();
    this.after = after.copy();
    this.pickAfter = pickAfter.copy();
    this.label = label;
    this.notes = notes ?? [];
    this.notesBefore = notesBefore ?? [];
    this.notesAfter = notesAfter ?? [];
  }

  /**
   * Perform the action, putting the new list in place.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    apply(state, after);
    moveNotes(state, notesAfter);
    moveEvents(state, eventsAfter);
    state.subBeatItems.selectTimes(pickAfter);
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/${after.length < before.length ? 'note-erase' : 'note-place'}'));
  }

  /**
   * Reverse the action, putting the old list back.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    apply(state, before);
    moveNotes(state, notesBefore);
    moveEvents(state, eventsBefore);
    state.subBeatItems.clearSelection();
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));
  }

  function moveNotes(state:ChartEditorState, times:Array<Float>):Void
  {
    if (notes.length == 0) return;
    for (i in 0...notes.length)
    {
      notes[i].time = times[i];
    }
    state.sortChartData();
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
  }

  function moveEvents(state:ChartEditorState, times:Array<Float>):Void
  {
    if (events.length == 0) return;
    for (i in 0...events.length)
    {
      events[i].time = times[i];
    }
    state.sortChartData();
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
  }

  function apply(state:ChartEditorState, times:Array<Float>):Void
  {
    var subBeats:Array<Float> = state.currentSubBeats();
    subBeats.resize(0);
    for (time in times)
    {
      if (!subBeats.contains(time)) subBeats.push(time);
    }
    subBeats.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));

    state.saveDataDirty = true;
    state.gridLinesDirty = true;
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
    if (before.length != after.length) return true;
    for (i in 0...before.length)
    {
      if (before[i] != after[i]) return true;
    }
    return false;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return label;
  }
}
#end
