package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Deletes the given events from the current chart in the chart editor.
 * Use only when ONLY events are being deleted.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class RemoveEventsCommand implements ChartEditorCommand
{
  var events:Array<SongEventData>;

  public function new(events:Array<SongEventData>)
  {
    this.events = events;
  }

  public function execute(state:ChartEditorState):Void
  {
    if (events.length == 0) return;

    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);
    state.currentEventSelection = [];

    state.playSound(Paths.sound('chartingSounds/noteErase'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    if (events.length == 0) return;

    for (event in events)
    {
      state.currentSongChartEventData.push(event);
    }
    state.currentEventSelection = events;
    state.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    // This command is undoable. Add to the history if we actually performed an action.
    return (events.length > 0);
  }

  public function toString():String
  {
    if (events.length == 1 && events[0] != null)
    {
      return 'Remove Event';
    }

    return 'Remove ${events.length} Events';
  }
}
