package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;

@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class RemoveEventCommand implements CameraEditorCommand
{
  var event:SongEventData;
  var index:Int = -1;

  public function new(event:SongEventData)
  {
    this.event = event;
  }

  public function execute(state:CameraEditorState):Void
  {
    index = state.currentSongChartData.events.indexOf(event);
    state.currentSongChartData.events.remove(event);
    if (state.selectedSongEvent == event)
      state.selectedSongEvent = null;
    state.saved = false;
    state.loadTimeline();
  }

  public function undo(state:CameraEditorState):Void
  {
    if (index >= 0 && index <= state.currentSongChartData.events.length)
      state.currentSongChartData.events.insert(index, event);
    else
      state.currentSongChartData.events.push(event);
    state.saved = false;
    state.loadTimeline();
  }

  public function shouldAddToHistory(state:CameraEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    return 'Remove ${event.eventKind} Event';
  }
}
#end
