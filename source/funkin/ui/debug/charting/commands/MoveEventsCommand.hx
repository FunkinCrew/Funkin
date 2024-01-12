package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Move the given events by the given offset and shift them by the given number of columns in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class MoveEventsCommand implements ChartEditorCommand
{
  var events:Array<SongEventData>;
  var movedEvents:Array<SongEventData>;
  var offset:Float;

  public function new(events:Array<SongEventData>, offset:Float)
  {
    // Clone the notes to prevent editing from affecting the history.
    this.events = [for (event in events) event.clone()];
    this.offset = offset;
    this.movedEvents = [];
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

    movedEvents = [];

    for (event in events)
    {
      // Clone the notes to prevent editing from affecting the history.
      var resultEvent = event.clone();
      resultEvent.time = (resultEvent.time + offset).clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps - (1 * state.noteSnapRatio)));

      movedEvents.push(resultEvent);
    }

    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(movedEvents);
    state.currentEventSelection = movedEvents;

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, movedEvents);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(events);

    state.currentEventSelection = events;

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
    return 'Move $len Events';
  }
}
