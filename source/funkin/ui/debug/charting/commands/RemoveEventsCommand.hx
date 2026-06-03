package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to remove a list of song events from a chart.
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

  /**
   * Perform the action, removing the events from the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    if (events.length == 0) return;

    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);
    state.currentEventSelection = [];

    state.playSound(Paths.sound('chartingSounds/noteErase'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;

    state.sortChartData();
  }

  /**
   * Reverse the action, restoring the events to the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    if (events.length == 0) return;

    for (event in events)
    {
      state.currentSongChartEventData.pushUnique(event);
    }
    state.currentEventSelection = events;
    state.playSound(Paths.sound('chartingSounds/undo'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;

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
    return (events.length > 0);
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    if (events.length == 1 && events[0] != null)
    {
      return 'Remove Event';
    }

    return 'Remove ${events.length} Events';
  }
}
#end
