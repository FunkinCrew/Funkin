package funkin.ui.haxeui.components.editors.timeline;

import funkin.data.song.SongData.SongEventData;
import funkin.play.event.FocusCameraSongEvent;

class TimelineUtil
{
  public static function isFixedDuration(event:SongEventData):Bool
  {
    if (event.eventKind != "FocusCamera")
      return false;
    var ease = event.getString('ease');
    if (ease == null)
      return true;
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
      return FocusCameraSongEvent.DEFAULT_DURATION;
    var duration:Null<Float> = event.getFloat('duration');
    var minSteps = getMinDurationSteps(event);
    if (duration == null || duration < minSteps)
      return minSteps;
    return duration;
  }

  public static function setEventDurationSteps(event:SongEventData, steps:Float):Void
  {
    var struct:haxe.DynamicAccess<Dynamic> = cast event.valueAsStruct();
    struct.set('duration', Math.max(getMinDurationSteps(event), steps));
    event.value = cast struct;
  }
}
