package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.ui.haxeui.components.editors.timeline.TimelineLayerData;

@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class GenerateEventsCommand implements CameraEditorCommand
{
  var events:Array<SongEventData>;

  var newLayerName:String;

  // Layer created by execute(), or null if the target layer already existed.
  // Undo reverses the creation only if no other events are still referencing it.
  var addedLayer:Null<TimelineLayerData>;

  public function new(events:Array<SongEventData>, newLayerName:String)
  {
    this.events = events;
    this.newLayerName = newLayerName;
  }

  public function execute(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    var panel = state.timeline.layerPanel;

    if (viewport.findLayerByName(newLayerName) == null)
    {
      var colorIdx:Int = viewport.layers.length % TimelineLayerData.DEFAULT_LAYER_COLORS.length;
      addedLayer = new TimelineLayerData(newLayerName, TimelineLayerData.DEFAULT_LAYER_COLORS[colorIdx]);
      viewport.layers.push(addedLayer);
      panel.insertLayerRow(addedLayer, viewport.layers.length - 1);
    }
    else
    {
      addedLayer = null;
    }

    for (event in events)
    {
      event.editorLayer = newLayerName;
      state.currentSongChartData.events.push(event);
    }

    state.currentSongChartData.events.sort(function(a:SongEventData, b:SongEventData):Int
    {
      if (a.time < b.time) return -1;
      if (a.time > b.time) return 1;
      return 0;
    });

    for (event in events) viewport.addEventBlock(event);
    viewport.refreshLayout();

    state.saved = false;
  }

  /**
   * Undo the `execute()` function.
   * @param state
   */
  public function undo(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    for (event in events)
    {
      state.currentSongChartData.events.remove(event);
      viewport.removeEventBlock(event);
    }

    if (addedLayer != null && !_layerStillReferenced(state, addedLayer.name))
    {
      var idx:Int = viewport.layers.indexOf(addedLayer);
      if (idx >= 0)
      {
        viewport.layers.remove(addedLayer);
        viewport.remapForRemove(idx);
        state.timeline.layerPanel.removeLayerRow(addedLayer);

        if (viewport.selectedLayerIndex >= viewport.layers.length) viewport.selectedLayerIndex = viewport.layers.length - 1;
        if (viewport.selectedLayerIndex < 0) viewport.selectedLayerIndex = 0;
      }
      addedLayer = null;
    }

    viewport.refreshLayout();

    state.saved = false;
  }

  function _layerStillReferenced(state:CameraEditorState, layerName:String):Bool
  {
    for (event in state.currentSongChartData.events)
    {
      var eventLayer:String = event.editorLayer ?? "Default";
      if (eventLayer == layerName) return true;
    }
    return false;
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
    return this.events.length > 0;
  }

  public function toString():String
  {
    return 'Auto Generate ${this.events.length} Events';
  }
}
#end
