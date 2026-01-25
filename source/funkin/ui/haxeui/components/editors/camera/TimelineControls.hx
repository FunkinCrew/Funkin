package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.containers.HBox;
import flixel.util.FlxStringUtil;
import haxe.ui.behaviours.DataBehaviour;

@:xml('
<hbox width="100%" backgroundColor="#222222">
  <label text="Layer Controls!" />
  <button id="btnRemoveLayer" text="Remove Layer" />
  <button id="btnAddLayer" text="Add Layer" />
  <button id="btnTogglePlayback" text="Play/Pause" allowFocus="false" />
  <label id="lblTime" text="0:00.00/0:00.00" />
</hbox>
')
class TimelineControls extends HBox
{
  /**
   * Current length of our song/audio, in milliseconds
   */
  @:clonable @:behaviour(SongLengthBehaviour, 0) public var songLength:Float;

  /**
   * The current position in the song in milliseconds
   */
  @:cloneable @:behaviour(SongPositionBehaviour, 0) public var songPosition:Float;

  @:clonable @:value(songPosition) public var value:Dynamic;

  public function new()
  {
    super();
    songLength = 0;
  }
}

// Behaviours

@:dox(hide) @:noCompletion
private class SongPositionBehaviour extends DataBehaviour
{
  override public function validateData():Void
  {
    var timelineControls:TimelineControls = cast(_component, TimelineControls);

    // clamp to song length
    var clampedValue:Float = _value.toFloat().clamp(0, timelineControls.songLength);
    timelineControls.songPosition = clampedValue;
    _value = clampedValue;

    // Convert ms to seconds for display
    timelineControls.lblTime.text = FlxStringUtil.formatTime(timelineControls.songPosition / 1000, true) + "/" + FlxStringUtil.formatTime(timelineControls.songLength / 1000, true);
  }
}

@:dox(hide) @:noCompletion
private class SongLengthBehaviour extends DataBehaviour
{
  override public function validateData():Void
  {
    var timelineControls:TimelineControls = cast(_component, TimelineControls);

    // clamp songPosition incase we updated our songLength to be shorter than songPosition
    timelineControls.songPosition = _value.toFloat().clamp(0, timelineControls.songLength);

    // Convert ms to seconds for display
    timelineControls.lblTime.text = FlxStringUtil.formatTime(timelineControls.songPosition / 1000, true) + "/" + FlxStringUtil.formatTime(timelineControls.songLength / 1000, true);
  }
}
