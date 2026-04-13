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
    var layers = state.timeline.viewport.layers;
    if (insertIndex >= 0 && insertIndex <= layers.length)
      layers.insert(insertIndex, layer);
    else
      layers.push(layer);

    state.timeline.viewport.selectedLayerIndex = insertIndex >= 0 && insertIndex < layers.length ? insertIndex : layers.length - 1;
    state.timeline.layerPanel.rebuildLayers(layers);
    state.timeline.viewport.refreshLayout();
    state.saved = false;
  }

  public function undo(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    viewport.layers.remove(layer);
    if (viewport.selectedLayerIndex >= viewport.layers.length)
      viewport.selectedLayerIndex = viewport.layers.length - 1;
    if (viewport.selectedLayerIndex < 0)
      viewport.selectedLayerIndex = 0;
    state.timeline.layerPanel.rebuildLayers(viewport.layers);
    viewport.refreshLayout();
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
