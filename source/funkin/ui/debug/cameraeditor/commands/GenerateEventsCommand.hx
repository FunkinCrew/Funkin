package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;

@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class GenerateEventsCommand implements CameraEditorCommand
{
  var events:Array<SongEventData>;

  var newLayerName:String;

  public function new(events:Array<SongEventData>, newLayerName:String)
  {
    this.events = events;
    this.newLayerName = newLayerName;
  }

  public function execute(state:CameraEditorState):Void
  {
    for (event in events)
    {
      event.editorLayer = newLayerName;
      state.currentSongChartData.events.push(event);
    }

    state.currentSongChartData.events.sort(function(a:SongEventData, b:SongEventData):Int
    {
      if (a.time < b.time) return -1;
      if (a.time > b.time) return 1;
      return 0;
    });
    state.saved = false;
    state.loadTimeline();
  }

  /**
   * Undo the `execute()` function.
   * @param state
   */
  public function undo(state:CameraEditorState):Void
  {
    for (event in events)
    {
      state.currentSongChartData.events.remove(event);
    }

    state.saved = false;
    state.loadTimeline();
  }

  /**
   * Whether the command should display in the undo/redo menu.
   * This should be `false` if no real actions were actually performed.
   *
   * @param state The CameraEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:CameraEditorState):Bool
  {
    return this.events.length > 0;
  }

  public function toString():String
  {
    return 'Auto Generate ${this.events.length} Events';
  }
}
#end
