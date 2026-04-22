package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.haxeui.components.editors.timeline.TimelineLayerData;

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

  public function execute(state:CameraEditorState):Void
  {
    _apply(state, oldName, newName);
  }

  public function undo(state:CameraEditorState):Void
  {
    _apply(state, newName, oldName);
  }

  function _apply(state:CameraEditorState, from:String, to:String):Void
  {
    layer.name = to;

    for (event in state.currentSongChartData.events)
    {
      var currentLayer:String = event.editorLayer ?? "Default";
      if (currentLayer != from) continue;
      var raw:SongEventDataRaw = event;
      raw.editorLayer = (to == "Default") ? null : to;
    }

    state.timeline.layerPanel.refreshLayerName(layer);
    state.timeline.layerPanel.refreshSelectedHighlight();

    state.saved = false;
  }

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
