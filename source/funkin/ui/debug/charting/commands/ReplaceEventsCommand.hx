package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Replaces existing events with new events in the current chart.
 */
@:nullSafety @:access(funkin.ui.debug.charting.ChartEditorState)
class ReplaceEventsCommand implements ChartEditorCommand
{
  var oldEvents:Array<SongEventData>;
  var newEvents:Array<SongEventData>;

  public function new(oldEvents:Array<SongEventData>, newEvents:Array<SongEventData>)
  {
    this.oldEvents = oldEvents;
    this.newEvents = newEvents;
  }

  public function execute(state:ChartEditorState):Void
  {
    if (oldEvents.length > 0)
    {
      state.currentSongChartEventData = SongDataUtils.subtractMatchingEvents(state.currentSongChartEventData, oldEvents);
    }

    for (event in newEvents)
    {
      state.currentSongChartEventData.push(event);
    }

    state.currentNoteSelection = [];
    state.currentEventSelection = newEvents;
    state.playSound(Paths.sound('chartingSounds/noteLay'));
    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;
    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    if (newEvents.length > 0)
    {
      state.currentSongChartEventData = SongDataUtils.subtractMatchingEvents(state.currentSongChartEventData, newEvents);
    }

    for (event in oldEvents)
    {
      state.currentSongChartEventData.push(event);
    }

    state.currentNoteSelection = [];
    state.currentEventSelection = oldEvents;
    state.playSound(Paths.sound('chartingSounds/undo'));
    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;
    state.sortChartData();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return (newEvents.length > 0 || oldEvents.length > 0);
  }

  public function toString():String
  {
    return 'Replace ${oldEvents.length} Event${oldEvents.length == 1 ? '' : 's'}';
  }
}
#end
