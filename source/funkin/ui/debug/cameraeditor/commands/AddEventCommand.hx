package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
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

    state.timeline.viewport.addEventBlock(event);
    state.timeline.viewport.refreshLayout();

    state.saved = false;
  }

  public function undo(state:CameraEditorState):Void
  {
    state.currentSongChartData.events.remove(event);

    state.timeline.viewport.removeEventBlock(event);
    state.timeline.viewport.refreshLayout();

    state.saved = false;
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
    return true;
  }

  public function toString():String
  {
    return 'Add ${event.eventKind} Event';
  }
}
#end
