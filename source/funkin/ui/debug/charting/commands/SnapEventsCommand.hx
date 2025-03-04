package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;

/**
 * Snap the given events to the current note snap in the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SnapEventsCommand implements ChartEditorCommand
{
  var events:Array<SongEventData>;
  var snappedEvents:Array<SongEventData>;

  public function new(events:Array<SongEventData>)
  {
    // Clone the events to prevent editing from affecting the history.
    this.events = [for (event in events) event.clone()];

    this.snappedEvents = [];
  }

  public function execute(state:ChartEditorState):Void
  {
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);

    snappedEvents = [];



    for (event in events)
    {
      // Clone the events to prevent editing from affecting the history.
      var resultEvent = event.clone();

      var targetStep:Float = Conductor.instance.getTimeInSteps(resultEvent.time);
      var targetSnappedStep:Float = Math.round(targetStep / state.noteSnapRatio) * state.noteSnapRatio;
      var targetSnappedMs:Float = Conductor.instance.getStepTimeInMs(targetSnappedStep);

      if (targetSnappedMs != resultEvent.time) resultEvent.time = targetSnappedMs.clamp(0, Conductor.instance.getStepTimeInMs(state.songLengthInSteps));

      snappedEvents.push(resultEvent);
    }

    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, events);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(snappedEvents);
    state.currentEventSelection = snappedEvents;

    state.playSound(Paths.sound('chartingSounds/noteLay'));

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function undo(state:ChartEditorState):Void
  {
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, snappedEvents);
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
    return 'Snap $len Events';
  }
}
