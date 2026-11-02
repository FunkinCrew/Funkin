package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
/**
 * A block representing a single event on the timeline.
 */
class TimelineEventBlock
{
  public static inline var CORNER_RADIUS:Int = 5;
  public static inline var TRIANGLE_OPACITY:Float = 0.3;
  public static inline var EDGE_DRAG_ZONE:Float = 6.0;
  public static inline var INSTANT_EDGE_DRAG_ZONE:Float = 4.0;
  public static final ICON_RESOURCES:Map<String, String> = [
    "FocusCamera" => "assets/ui/editors/camera-editor/event-icons/focus_event.png",
    "ZoomCamera" => "assets/ui/editors/camera-editor/event-icons/zoom_event.png",
    "PlayAnimation" => "assets/ui/editors/camera-editor/event-icons/playanim_event.png",
  ];
  public static inline var TRIANGLE_RESOURCE:String = 'assets/ui/editors/camera-editor/triangle.png';

  public var eventData:SongEventData;
  public var layerIndex:Int = 0;
  public var selected:Bool = false;

  /**
   * Whether the block is out of view.
   */
  public var hidden:Bool = true;

  /**
   * Where the event starts and how long it is on screen.
   */
  public var blockLeft:Float = 0;
  public var blockTop:Float = 0;
  public var blockWidth:Float = 0;

  /**
   * The part of the block that gets drawn, cut down to the visible area.
   */
  public var drawLeft:Float = 0;
  public var drawWidth:Float = 0;

  /**
   * Which edge is highlighted for resizing, if any.
   */
  public var hoverEdge:Null<TimelineBlockHitZone> = null;

  /**
   * Cached result of `isInstant()`, refreshed by `updateVisuals()`.
   */
  public var instant:Bool = false;

  public function new() {}

  /**
   * Colors the block based on the layer it is on.
   * @param layerColor The color of the layer the block is on.
   */
  public function applyColor(layerColor:Int):Void
  {
    updateVisuals();
  }

  /**
   * Refreshes state that depends on the event's values.
   */
  public function updateVisuals():Void
  {
    instant = isInstant();
  }

  public function getHitZone(localX:Float):TimelineBlockHitZone
  {
    if (isInstant())
    {
      if (TimelineUtil.canResize(eventData) && localX > blockWidth - INSTANT_EDGE_DRAG_ZONE) return RIGHT_EDGE;
      return BODY;
    }
    if (localX < EDGE_DRAG_ZONE) return LEFT_EDGE;
    if (localX > blockWidth - EDGE_DRAG_ZONE) return RIGHT_EDGE;
    return BODY;
  }

  public static function getIconResource(eventKind:String):Null<String>
  {
    return ICON_RESOURCES.get(eventKind);
  }

  public function isInstant():Bool
  {
    return TimelineUtil.isFixedDuration(eventData);
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
  PANNING;
  BOX_SELECTING;
}
#end
