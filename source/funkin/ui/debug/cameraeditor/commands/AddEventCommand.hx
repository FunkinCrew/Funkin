package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;

@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class AddEventCommand implements CameraEditorCommand
{
  var event:SongEventData;

  public function new(event:SongEventData)
  {
    this.event = event;
  }

  public function execute(state:CameraEditorState):Void
  {
    state.currentSongChartData.events.push(event);
    state.currentSongChartData.events.sort(function(a:SongEventData, b:SongEventData):Int
    {
      if (a.time < b.time) return -1;
      if (a.time > b.time) return 1;
      return 0;
    });
    state.saved = false;
    state.loadTimeline();
  }

  public function undo(state:CameraEditorState):Void
  {
    state.currentSongChartData.events.remove(event);
    state.saved = false;
    state.loadTimeline();
  }

  public function shouldAddToHistory(state:CameraEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    return 'Add ${event.eventKind} Event';
  }
}
#end
