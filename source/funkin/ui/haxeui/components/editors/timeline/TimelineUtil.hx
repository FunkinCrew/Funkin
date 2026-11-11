package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.data.event.SongEventSchema;
import funkin.data.song.SongData.SongEventData;
import funkin.play.event.FocusCameraSongEvent;
import funkin.play.event.ZoomCameraSongEvent;

class TimelineUtil
{
  public static final TIMELINE_EVENT_KINDS:Array<String> = ['FocusCamera', 'ZoomCamera', 'PlayAnimation', 'CustomEvent'];

  public static inline function isTimelineEvent(eventKind:String):Bool
  {
    return TIMELINE_EVENT_KINDS.contains(eventKind);
  }

  /**
   * Cache for schema information per event kind.
   */
  static var schemaInfoCache:Map<String, TimelineSchemaInfo> = [];

  /**
   * Clears the cached schema info.
   */
  public static function clearSchemaCache():Void
  {
    schemaInfoCache.clear();
  }

  static function getSchemaInfo(event:SongEventData):TimelineSchemaInfo
  {
    var info:Null<TimelineSchemaInfo> = schemaInfoCache.get(event.eventKind);
    if (info != null) return info;

    var schema:Null<SongEventSchema> = event.getSchema();
    var field = schema?.getByName('duration');
    info = {
      hasSchema: schema != null,
      hasDuration: field != null,
      minSteps: (field != null && field.step != null) ? field.step : 0.5
    };
    schemaInfoCache.set(event.eventKind, info);
    return info;
  }

  public static function isFixedDuration(event:SongEventData):Bool
  {
    // If the event's schema has no 'duration' field, it is inherently fixed-duration.
    // Prevents edge-drag from writing a spurious 'duration' key into event.value.
    var info:TimelineSchemaInfo = getSchemaInfo(event);
    if (info.hasSchema && !info.hasDuration) return true;

    if (event.eventKind != "FocusCamera" && event.eventKind != "ZoomCamera") return false;
    var ease:Null<String> = event.getString('ease');
    // FocusCamera historically treats a missing ease as classic/instant; ZoomCamera's
    // missing ease resolves to the default easing at runtime, which is not instant.
    if (ease == null) return event.eventKind == "FocusCamera";
    return ease == 'CLASSIC' || ease == 'INSTANT';
  }

  /**
   * Whether the event has a duration that can be dragged on the timeline.
   */
  public static function canResize(event:SongEventData):Bool
  {
    var info:TimelineSchemaInfo = getSchemaInfo(event);
    if (info.hasSchema) return info.hasDuration;
    return !isFixedDuration(event);
  }

  /**
   * Sets or removes a single field in the event's value.
   */
  public static function setEventField(event:SongEventData, field:String, value:Dynamic):Void
  {
    var struct:haxe.DynamicAccess<Dynamic> = cast event.valueAsStruct();
    if (value == null) struct.remove(field);
    else
      struct.set(field, value);
    event.value = cast struct;
  }

  public static function getMinDurationSteps(event:SongEventData):Float
  {
    return getSchemaInfo(event).minSteps;
  }

  public static function getEventDurationSteps(event:SongEventData):Float
  {
    // TODO: This could probably be a function of `funkin.play.event.SongEvent` instead,
    // where you can override the `getDuration()` function to provide custom logic.

    if (isFixedDuration(event))
    {
      return event.eventKind == "ZoomCamera" ? ZoomCameraSongEvent.DEFAULT_DURATION : FocusCameraSongEvent.DEFAULT_DURATION;
    }
    var duration:Null<Float> = event.getFloat('duration');
    var minSteps:Float = getMinDurationSteps(event);
    if (duration == null || duration < minSteps) return minSteps;
    return duration;
  }

  public static function setEventDurationSteps(event:SongEventData, steps:Float):Void
  {
    var struct:haxe.DynamicAccess<Dynamic> = cast event.valueAsStruct();
    var rounded:Float = Math.fround(steps * TimelineViewport.DURATION_PRECISION) / TimelineViewport.DURATION_PRECISION;
    struct.set('duration', Math.max(getMinDurationSteps(event), rounded));
    event.value = cast struct;
  }
}
typedef TimelineSchemaInfo =
{
  hasSchema:Bool,
  hasDuration:Bool,
  minSteps:Float
};
#end
