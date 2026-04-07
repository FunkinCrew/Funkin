package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.haxeui.components.editors.timeline.TimelineLayerData;

@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class RemoveLayerCommand implements CameraEditorCommand
{
  var layer:TimelineLayerData;
  var layerIndex:Int;
  var deletedEvents:Array<{event:SongEventData, originalLayer:Null<String>}>;

  public function new(layer:TimelineLayerData, layerIndex:Int)
  {
    this.layer = layer;
    this.layerIndex = layerIndex;
    this.deletedEvents = [];
  }

  public function execute(state:CameraEditorState):Void
  {
    deletedEvents = [];

    var eventsToRemove:Array<SongEventData> = [];
    for (event in state.currentSongChartData.events)
    {
      var eventLayer:String = event.editorLayer ?? "Default";
      if (layer.name == eventLayer)
      {
        deletedEvents.push({event: event, originalLayer: eventLayer});
        eventsToRemove.push(event);
      }
    }

    for (event in eventsToRemove)
      state.currentSongChartData.events.remove(event);

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

    for (entry in deletedEvents)
      state.currentSongChartData.events.push(entry.event);

    state.currentSongChartData.events.sort(function(a:SongEventData, b:SongEventData):Int
    {
      if (a.time < b.time) return -1;
      if (a.time > b.time) return 1;
      return 0;
    });

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
    var eventCount = deletedEvents.length;
    if (eventCount > 0)
      return 'Remove Layer "${layer.name}" (${eventCount} events deleted)';
    return 'Remove Layer "${layer.name}"';
  }
}
#end
