package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.ui.haxeui.components.editors.timeline.TimelineLayerData;
import funkin.audio.FunkinSound;
import funkin.util.SortUtil;
import flixel.util.FlxSort;

/**
 * Represents a reversible action to remove a camera layer from the timeline.
 */
@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class RemoveLayerCommand implements CameraEditorCommand
{
  var layer:TimelineLayerData;
  var layerIndex:Int;
  var deletedEvents:Array<
    {event:SongEventData, originalLayer:Null<String>}>;

  public function new(layer:TimelineLayerData, layerIndex:Int)
  {
    this.layer = layer;
    this.layerIndex = layerIndex;
    this.deletedEvents = [];
  }

  /**
   * Perform the action, removing a camera layer and all its events from the timeline.
   *
   * @param state The CameraEditorState to perform the command on.
   */
  public function execute(state:CameraEditorState):Void
  {
    deletedEvents = [];

    var viewport = state.timeline.viewport;
    var eventsToRemove:Array<SongEventData> = [];

    for (event in state.currentSongChartData.events)
    {
      var eventLayer:String = event.editorLayer ?? 'Default';
      if (layer.name == eventLayer)
      {
        deletedEvents.push({
          event: event,
          originalLayer: eventLayer
        });
        eventsToRemove.push(event);
      }
    }

    FunkinSound.playOnce(Paths.sound('chartingSounds/noteErase'));

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

  /**
   * Reverse the action, restoring the layer and all its events to the timeline.
   *
   * @param state The CameraEditorState to perform the command on.
   */
  public function undo(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    var layers = viewport.layers;
    var idx = (layerIndex >= 0 && layerIndex <= layers.length) ? layerIndex : layers.length;

    viewport.remapForInsert(idx);
    layers.insert(idx, layer);

    for (entry in deletedEvents) state.currentSongChartData.events.push(entry.event);

    state.currentSongChartData.events.sort(SortUtil.eventDataByTime.bind(FlxSort.ASCENDING));

    for (entry in deletedEvents) viewport.addEventBlock(entry.event);

    viewport.selectedLayerIndex = idx;

    FunkinSound.playOnce(Paths.sound('chartingSounds/undo'));

    state.timeline.layerPanel.insertLayerRow(layer, idx);
    viewport.refreshLayout();

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
    var eventCount = deletedEvents.length;
    if (eventCount > 0) return 'Remove Layer "${layer.name}" (${eventCount} events deleted)';
    return 'Remove Layer "${layer.name}"';
  }
}
#end
