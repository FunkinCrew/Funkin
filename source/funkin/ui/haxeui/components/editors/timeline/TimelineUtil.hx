package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.play.event.FocusCameraSongEvent;
import funkin.play.event.ZoomCameraSongEvent;

class TimelineUtil
{
  public static function isFixedDuration(event:SongEventData):Bool
  {
    if (event.eventKind != "FocusCamera" && event.eventKind != "ZoomCamera") return false;
    var ease:Null<String> = event.getString('ease');
    // FocusCamera historically treats a missing ease as classic/instant; ZoomCamera's
    // missing ease resolves to the default easing at runtime, which is not instant.
    if (ease == null) return event.eventKind == "FocusCamera";
    return ease == 'CLASSIC' || ease == 'INSTANT';
  }

  public static function getMinDurationSteps(event:SongEventData):Float
  {
    var schema = event.getSchema();
    if (schema != null)
    {
      var field = schema.getByName('duration');
      if (field != null && field.step != null)
        return field.step;
    }
    return 0.5;
  }

  public static function getEventDurationSteps(event:SongEventData):Float
  {
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
    struct.set('duration', Math.max(getMinDurationSteps(event), steps));
    event.value = cast struct;
  }
}
#end
