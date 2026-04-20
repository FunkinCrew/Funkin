package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
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
    if (state.selectedSongEvents.contains(event)) state.selectedSongEvents = state.selectedSongEvents.filter(e -> e != event);

    state.timeline.viewport.removeEventBlock(event);
    state.timeline.viewport.refreshLayout();

    state.saved = false;
  }

  public function undo(state:CameraEditorState):Void
  {
    if (index >= 0 && index <= state.currentSongChartData.events.length)
      state.currentSongChartData.events.insert(index, event);
    else
      state.currentSongChartData.events.push(event);
    state.selectedSongEvents = [event];

    state.timeline.viewport.addEventBlock(event);
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
    return 'Remove ${event.eventKind} Event';
  }
}
#end
