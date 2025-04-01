package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;

/**
 * Adds the given events to the current chart in the chart editor.
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

  public function execute(state:ChartEditorState):Void
  {
    for (event in events)
    {
      state.currentSongChartEventData.push(event);
    }

    if (appendToSelection)
    {
      state.currentEventSelection = state.currentEventSelection.concat(events);
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

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

    state.currentNoteSelection = [];
    state.currentEventSelection = [];

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
    var len:Int = events.length;
    return 'Add $len Events';
  }
}
