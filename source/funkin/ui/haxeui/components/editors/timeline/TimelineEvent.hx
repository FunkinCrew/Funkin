package funkin.ui.haxeui.components.editors.timeline;

import funkin.data.song.SongData.SongEventData;
import haxe.ui.events.EventType;
import haxe.ui.events.UIEvent;

class TimelineEvent extends UIEvent
{
  public static inline var EVENT_MOVED:EventType<TimelineEvent> = "timelineEventMoved";
  public static inline var EVENT_RESIZED:EventType<TimelineEvent> = "timelineEventResized";
  /** Reserved for future use — not currently dispatched. */
  public static inline var EVENT_LAYER_CHANGED:EventType<TimelineEvent> = "timelineEventLayerChanged";
  public static inline var EVENT_SELECTED:EventType<TimelineEvent> = "timelineEventSelected";
  public static inline var SEEK:EventType<TimelineEvent> = "timelineSeek";
  public static inline var ZOOM_CHANGED:EventType<TimelineEvent> = "timelineZoomChanged";
  public static inline var ADD_EVENT_REQUESTED:EventType<TimelineEvent> = "timelineAddEventRequested";

  public var eventData:Null<SongEventData>;
  public var oldTime:Float = 0;
  public var newTime:Float = 0;
  public var oldDuration:Float = 0;
  public var newDuration:Float = 0;
  public var oldLayerName:Null<String>;
  public var newLayerName:Null<String>;
  public var seekPositionMs:Float = 0;

  public function new(type:String)
  {
    super(type);
  }

  override public function clone():TimelineEvent
  {
    var c:TimelineEvent = new TimelineEvent(type);
    c.type = type;
    c.bubble = bubble;
    c.target = target;
    c.data = data;
    c.canceled = canceled;
    c.eventData = eventData;
    c.oldTime = oldTime;
    c.newTime = newTime;
    c.oldDuration = oldDuration;
    c.newDuration = newDuration;
    c.oldLayerName = oldLayerName;
    c.newLayerName = newLayerName;
    c.seekPositionMs = seekPositionMs;
    postClone(c);
    return c;
  }
}
