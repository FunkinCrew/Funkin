package funkin.ui.haxeui.components.editors.timeline;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;

class TimelineLayerData
{
  public var name:String;
  public var color:Int;
  // TODO: Wire up visibility toggling in TimelineViewport
  public var visible:Bool;
  // TODO: Wire up layer locking in TimelineViewportEvents
  public var locked:Bool;

  public function new(name:String, color:Int)
  {
    this.name = name;
    this.color = color;
    this.visible = true;
    this.locked = false;
  }

  // Some default colors from fabs mockups
  public static final DEFAULT_LAYER_COLORS:Array<Int> = [
    0x99C198,
    0x70959D,
    0x8070A0,
    0xC19FB1,
    0xFFFFCC
  ];

  public static function buildLayersFromEvents(events:Array<SongEventData>):Array<TimelineLayerData>
  {
    var layerNames:Array<String> = ["Default"];
    for (event in events)
    {
      if (event.eventKind != "FocusCamera" && event.eventKind != "ZoomCamera")
        continue;
      var raw:SongEventDataRaw = event;
      var layer:String = raw.editorLayer != null ? raw.editorLayer : "Default";
      if (!layerNames.contains(layer))
        layerNames.push(layer);
    }

    var result:Array<TimelineLayerData> = [];
    for (i => name in layerNames)
    {
      result.push(new TimelineLayerData(name, DEFAULT_LAYER_COLORS[i % DEFAULT_LAYER_COLORS.length]));
    }
    return result;
  }
}
