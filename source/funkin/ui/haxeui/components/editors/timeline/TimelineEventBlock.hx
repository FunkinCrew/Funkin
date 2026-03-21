package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import haxe.ui.behaviours.DefaultBehaviour;
import haxe.ui.components.Image;
import haxe.ui.containers.Box;
import haxe.ui.core.CompositeBuilder;
import flixel.util.FlxColor;

@:composite(TimelineBlockBuilder)
class TimelineEventBlock extends Box
{
  public static inline var BLOCK_HEIGHT:Int = 42;
  static inline var CORNER_RADIUS:Int = 3;
  public static inline var EDGE_DRAG_ZONE:Float = 6.0;

  public static final ICON_RESOURCES:Map<String, String> = [
    "FocusCamera" => "shared:assets/shared/images/ui/camera-editor/event-icons/focus_event.png",
    "ZoomCamera" => "shared:assets/shared/images/ui/camera-editor/event-icons/zoom_event.png",
  ];

  public var eventData:SongEventData;
  public var layerIndex:Int = 0;

  @:clonable @:behaviour(DefaultBehaviour, false)
  public var selected:Bool;

  public var blockLeft:Float = 0;
  public var blockTop:Float = 0;
  public var blockWidth:Float = 0;
  public var _cachedIcon:Image;

  public function new()
  {
    super();
    addClass("timeline-event-block");
    this.height = BLOCK_HEIGHT;
  }

  public function applyColor(layerColor:Int):Void
  {
    var bodyColor = selected ? FlxColor.fromInt(layerColor).getLightened(0.3) : layerColor ;
    var borderColor = selected ? 0xFFFFFF : layerColor;

    customStyle.backgroundColor = bodyColor;
    customStyle.borderColor = borderColor;
    customStyle.borderSize = selected ? 2 : 1;
    customStyle.borderRadius = CORNER_RADIUS;
    invalidateComponentStyle();
  }

  public function getHitZone(localX:Float):TimelineBlockHitZone
  {
    if (localX < EDGE_DRAG_ZONE)
      return LEFT_EDGE;
    if (localX > this.componentWidth - EDGE_DRAG_ZONE)
      return RIGHT_EDGE;
    return BODY;
  }

  public static function getIconResource(eventKind:String):Null<String>
  {
    return ICON_RESOURCES.get(eventKind);
  }
}

@:dox(hide) @:noCompletion
private class TimelineBlockBuilder extends CompositeBuilder
{
  override public function create():Void
  {
    var icon = new Image();
    icon.id = "block-icon";
    icon.addClass("timeline-block-icon");
    icon.customStyle.pointerEvents = "none";
    _component.addComponent(icon);
  }
}

enum TimelineBlockHitZone
{
  LEFT_EDGE;
  RIGHT_EDGE;
  BODY;
}

enum TimelineDragMode
{
  NONE;
  MOVE;
  RESIZE_LEFT;
  RESIZE_RIGHT;
  SEEKING;
}
#end
