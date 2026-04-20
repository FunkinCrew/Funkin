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

    var viewport = state.timeline.viewport;
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
    {
      state.currentSongChartData.events.remove(event);
      viewport.removeEventBlock(event);
    }

    var removedIdx = viewport.layers.indexOf(layer);
    viewport.layers.remove(layer);
    if (removedIdx >= 0) viewport.remapForRemove(removedIdx);

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

    for (entry in deletedEvents)
      state.currentSongChartData.events.push(entry.event);

    state.currentSongChartData.events.sort(function(a:SongEventData, b:SongEventData):Int
    {
      if (a.time < b.time) return -1;
      if (a.time > b.time) return 1;
      return 0;
    });

    for (entry in deletedEvents) viewport.addEventBlock(entry.event);

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
    var eventCount = deletedEvents.length;
    if (eventCount > 0)
      return 'Remove Layer "${layer.name}" (${eventCount} events deleted)';
    return 'Remove Layer "${layer.name}"';
  }
}
#end
