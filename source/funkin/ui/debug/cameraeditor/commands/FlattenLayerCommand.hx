package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.haxeui.components.editors.timeline.TimelineEventBlock;
import funkin.ui.haxeui.components.editors.timeline.TimelineLayerData;

@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class FlattenLayerCommand implements CameraEditorCommand
{
  var layer:TimelineLayerData;
  var layerIndex:Int;
  var flattenedEvents:Array<{event:SongEventData, originalLayer:Null<String>}>;

  public function new(layer:TimelineLayerData, layerIndex:Int)
  {
    this.layer = layer;
    this.layerIndex = layerIndex;
    this.flattenedEvents = [];
  }

  public function execute(state:CameraEditorState):Void
  {
    flattenedEvents = [];
    var viewport = state.timeline.viewport;

    for (event in state.currentSongChartData.events)
    {
      var eventLayer = event.editorLayer ?? "Default";
      if (layer.name == eventLayer)
      {
        flattenedEvents.push({event: event, originalLayer: eventLayer});

        // note: this sets the layer to be "Default" layer which is sorta special right now!
        // todo: we will implement merge above/below logic laterz
        event.editorLayer = null;
      }
    }

    var removedIdx:Int = viewport.layers.indexOf(layer);
    viewport.layers.remove(layer);

    // remap first so indices are consistent, then re-sync flattened blocks to "Default".
    // the sync writes an authoritative index, so doing it after remap makes this order-independent of where "Default" sits.
    if (removedIdx >= 0) viewport.remapForRemove(removedIdx);

    for (entry in flattenedEvents)
    {
      var block:TimelineEventBlock = viewport.findBlockByEvent(entry.event);
      if (block != null) viewport.syncEventBlockLayer(block, "Default");
    }

    if (viewport.selectedLayerIndex >= viewport.layers.length) viewport.selectedLayerIndex = viewport.layers.length - 1;
    if (viewport.selectedLayerIndex < 0) viewport.selectedLayerIndex = 0;

    state.timeline.layerPanel.removeLayerRow(layer);
    viewport.refreshLayout();

    state.saved = false;
  }

  public function undo(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    var layers = viewport.layers;
    var idx = (layerIndex >= 0 && layerIndex <= layers.length) ? layerIndex : layers.length;

    viewport.remapForInsert(idx);
    layers.insert(idx, layer);

    for (entry in flattenedEvents)
    {
      var raw:SongEventDataRaw = entry.event;
      raw.editorLayer = entry.originalLayer;
      var block = viewport.findBlockByEvent(entry.event);
      if (block != null) viewport.syncEventBlockLayer(block, entry.originalLayer ?? "Default");
    }

    viewport.selectedLayerIndex = idx;

    state.timeline.layerPanel.insertLayerRow(layer, idx);
    viewport.refreshLayout();

    state.saved = false;
  }

  public function shouldAddToHistory(state:CameraEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    var eventCount = flattenedEvents.length;
    if (eventCount > 0)
      return 'Flatten Layer "${layer.name}" (${eventCount} events moved to Default)';
    return 'Flatten Layer "${layer.name}"';
  }
}
#end
