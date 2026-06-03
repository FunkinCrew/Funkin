package funkin.ui.debug.charting.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Represents a reversible action to add one or more song events.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class AddEventsCommand implements ChartEditorCommand
{
  var events:Array<SongEventData>;
  var appendToSelection:Bool;

  public function new(events:Array<SongEventData>, appendToSelection:Bool = false)
  {
    this.events = events;
    this.appendToSelection = appendToSelection;
  }

  /**
   * Perform the action, adding the new song events to the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    for (event in events)
    {
      state.currentSongChartEventData.pushUnique(event);
    }

    if (appendToSelection)
    {
      for (event in events)
      {
        state.currentEventSelection.pushUnique(event);
      }
    }
    else
    {
      state.currentNoteSelection = [];
      state.currentEventSelection = events;
    }

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.editButtonsDirty = true;

    state.sortChartData();
  }

  /**
   * Reverse the action, removing the new song events from the chart.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

    state.currentNoteSelection = [];
    state.currentEventSelection = [];
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
    var len:Int = events.length;
    return 'Add $len Events';
  }
}
#end
