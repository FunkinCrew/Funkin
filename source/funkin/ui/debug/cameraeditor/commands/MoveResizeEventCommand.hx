package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.haxeui.components.editors.timeline.TimelineUtil;

@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class MoveResizeEventCommand implements CameraEditorCommand
{
  var event:SongEventData;
  var oldTime:Float;
  var oldDuration:Float;
  var oldLayerName:String;
  var newTime:Float;
  var newDuration:Float;
  var newLayerName:String;

  public function new(
    event:SongEventData,
    oldTime:Float, oldDuration:Float, oldLayerName:String,
    newTime:Float, newDuration:Float, newLayerName:String
  )
  {
    this.event = event;
    this.oldTime = oldTime;
    this.oldDuration = oldDuration;
    this.oldLayerName = oldLayerName;
    this.newTime = newTime;
    this.newDuration = newDuration;
    this.newLayerName = newLayerName;
  }

  public function execute(state:CameraEditorState):Void
  {
    event.time = newTime;
    TimelineUtil.setEventDurationSteps(event, newDuration);
    var raw:SongEventDataRaw = event;
    raw.editorLayer = newLayerName == "Default" ? null : newLayerName;

    if (oldLayerName != newLayerName)
    {
      var block = state.timeline.viewport.findBlockByEvent(event);
      if (block != null) state.timeline.viewport.syncEventBlockLayer(block, newLayerName);
    }
    state.timeline.viewport.refreshLayout();

    state.saved = false;
  }

  public function undo(state:CameraEditorState):Void
  {
    event.time = oldTime;
    TimelineUtil.setEventDurationSteps(event, oldDuration);
    var raw:SongEventDataRaw = event;
    raw.editorLayer = oldLayerName == "Default" ? null : oldLayerName;

    if (oldLayerName != newLayerName)
    {
      var block = state.timeline.viewport.findBlockByEvent(event);
      if (block != null) state.timeline.viewport.syncEventBlockLayer(block, oldLayerName);
    }
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
    return oldTime != newTime || oldDuration != newDuration || oldLayerName != newLayerName;
  }

  public function toString():String
  {
    return "Move/Resize Event";
  }
}
#end
