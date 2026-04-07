package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
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

    state.timeline.viewport.layers.remove(layer);

    var viewport = state.timeline.viewport;
    if (viewport.selectedLayerIndex >= viewport.layers.length)
      viewport.selectedLayerIndex = viewport.layers.length - 1;
    if (viewport.selectedLayerIndex < 0)
      viewport.selectedLayerIndex = 0;

    state.saved = false;
    state.loadTimeline();
  }

  public function undo(state:CameraEditorState):Void
  {
    var layers = state.timeline.viewport.layers;
    if (layerIndex >= 0 && layerIndex <= layers.length)
      layers.insert(layerIndex, layer);
    else
      layers.push(layer);

    for (entry in flattenedEvents)
    {
      var raw:SongEventDataRaw = entry.event;
      raw.editorLayer = entry.originalLayer;
    }

    state.timeline.viewport.selectedLayerIndex = layerIndex;

    state.saved = false;
    state.loadTimeline();
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
