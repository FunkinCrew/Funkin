package funkin.ui.haxeui.components.editors.camera;

import haxe.ui.containers.HBox;
import flixel.util.FlxStringUtil;

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
  var songLength:Float;

  public function new()
  {
    super();
    songLength = 0;
  }
  /**
   * Updates the total length of the song in the timeline.
   * @param newLength The new length in seconds.
   */
  public function updateLength(newLength:Float):Void
  {
    songLength = newLength;
  }

  /**
   * Updates the time label with the given time in seconds.
   * @param time The time in seconds to display.
   */
  public function updateTime(time:Float):Void
  {
    lblTime.text = FlxStringUtil.formatTime(time, true) + "/" + FlxStringUtil.formatTime(songLength, true);
  }
}
