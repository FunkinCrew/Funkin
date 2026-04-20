package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.ui.haxeui.components.editors.timeline.TimelineLayerData;

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

  public function execute(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    var layers = viewport.layers;
    var idx = (insertIndex >= 0 && insertIndex <= layers.length) ? insertIndex : layers.length;

    viewport.remapForInsert(idx);
    layers.insert(idx, layer);

    viewport.selectedLayerIndex = (idx < layers.length) ? idx : layers.length - 1;

    state.timeline.layerPanel.insertLayerRow(layer, idx);
    viewport.ensureLayerVisible(viewport.selectedLayerIndex);

    state.saved = false;
  }

  public function undo(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    var idx = viewport.layers.indexOf(layer);
    if (idx < 0) return;

    viewport.layers.remove(layer);
    viewport.remapForRemove(idx);

    if (viewport.selectedLayerIndex >= viewport.layers.length) viewport.selectedLayerIndex = viewport.layers.length - 1;
    if (viewport.selectedLayerIndex < 0) viewport.selectedLayerIndex = 0;

    state.timeline.layerPanel.removeLayerRow(layer);
    viewport.ensureLayerVisible(viewport.selectedLayerIndex);

    state.saved = false;
  }

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
