package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.audio.FunkinSound;
import funkin.util.SortUtil;
import flixel.util.FlxSort;

/**
 * Represents a reversible action to add a new camera event to the timeline.
 */
@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class AddEventCommand implements CameraEditorCommand
{
  var event:SongEventData;

  public function new(event:SongEventData)
  {
    this.event = event;
  }

  /**
   * Perform the action, adding a new camera event to the timeline.
   *
   * @param state The CameraEditorState to perform the command on.
   */
  public function execute(state:CameraEditorState):Void
  {
    state.currentSongChartData.events.push(event);
    state.currentSongChartData.events.sort(SortUtil.eventDataByTime.bind(FlxSort.ASCENDING));

    FunkinSound.playOnce(Paths.sound('chartingSounds/noteLay'));

    state.timeline.viewport.addEventBlock(event);
    state.timeline.viewport.refreshLayout();

    state.saved = false;
  }

  /**
   * Reverse the action, removing the camera event from the timeline.
   *
   * @param state The CameraEditorState to perform the command on.
   */
  public function undo(state:CameraEditorState):Void
  {
    state.currentSongChartData.events.remove(event);

    FunkinSound.playOnce(Paths.sound('chartingSounds/undo'));

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
