package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.haxeui.components.editors.timeline.TimelineLayerData;

/**
 * Represents a reversible action to rename a camera layer in the timeline.
 */
@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class RenameLayerCommand implements CameraEditorCommand
{
  var layer:TimelineLayerData;
  var oldName:String;
  var newName:String;

  public function new(layer:TimelineLayerData, oldName:String, newName:String)
  {
    this.layer = layer;
    this.oldName = oldName;
    this.newName = newName;
  }

  /**
   * Perform the action, renaming a camera layer in the timeline.
   *
   * @param state The CameraEditorState to perform the command on.
   */
  public function execute(state:CameraEditorState):Void
  {
    _apply(state, oldName, newName);
  }

  /**
   * Reverse the action, restoring the original name of the layer on the timeline.
   *
   * @param state The CameraEditorState to perform the command on.
   */
  public function undo(state:CameraEditorState):Void
  {
    _apply(state, newName, oldName);
  }

  function _apply(state:CameraEditorState, from:String, to:String):Void
  {
    layer.name = to;

    for (event in state.currentSongChartData.events)
    {
      var currentLayer:String = event.editorLayer ?? 'Default';
      if (currentLayer != from) continue;
      var raw:SongEventDataRaw = event;
      raw.editorLayer = (to == 'Default') ? null : to;
    }

    state.timeline.layerPanel.refreshLayerName(layer);
    state.timeline.layerPanel.refreshSelectedHighlight();

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
    return oldName != newName;
  }

  public function toString():String
  {
    return 'Rename Layer "$oldName" → "$newName"';
  }
}
#end
