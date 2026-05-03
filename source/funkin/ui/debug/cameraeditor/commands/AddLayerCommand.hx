package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.haxeui.components.editors.timeline.TimelineLayerData;
import funkin.audio.FunkinSound;

/**
 * Represents a reversible action to add a new layer to the timeline.
 */
@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class AddLayerCommand implements CameraEditorCommand
{
  var layer:TimelineLayerData;
  var insertIndex:Int;

  public function new(layer:TimelineLayerData, insertIndex:Int)
  {
    this.layer = layer;
    this.insertIndex = insertIndex;
  }

  /**
   * Reverse the action, adding the new layer to the timeline.
   * @param state The CameraEditorState to perform the command on.
   */
  public function execute(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    var layers = viewport.layers;
    var idx = (insertIndex >= 0 && insertIndex <= layers.length) ? insertIndex : layers.length;

    viewport.remapForInsert(idx);
    layers.insert(idx, layer);

    viewport.selectedLayerIndex = (idx < layers.length) ? idx : layers.length - 1;

    FunkinSound.playOnce(Paths.sound('chartingSounds/noteLay'));

    state.timeline.layerPanel.insertLayerRow(layer, idx);
    viewport.ensureLayerVisible(viewport.selectedLayerIndex);

    state.saved = false;
  }

  /**
   * Reverse the action, removing the layer from the timeline.
   * @param state The CameraEditorState to perform the command on.
   */
  public function undo(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    var idx = viewport.layers.indexOf(layer);
    if (idx < 0) return;

    viewport.layers.remove(layer);
    viewport.remapForRemove(idx);

    if (viewport.selectedLayerIndex >= viewport.layers.length) viewport.selectedLayerIndex = viewport.layers.length - 1;
    if (viewport.selectedLayerIndex < 0) viewport.selectedLayerIndex = 0;

    FunkinSound.playOnce(Paths.sound('chartingSounds/undo'));

    state.timeline.layerPanel.removeLayerRow(layer);
    viewport.ensureLayerVisible(viewport.selectedLayerIndex);

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
    return 'Add Layer "${layer.name}"';
  }
}
#end
