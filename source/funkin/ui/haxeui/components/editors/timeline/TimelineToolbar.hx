package funkin.ui.haxeui.components.editors.timeline;

import flixel.util.FlxStringUtil;
import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.containers.HBox;
import haxe.ui.data.ArrayDataSource;

@:xml('
<hbox width="100%" style="background-color: #3A3A3A; padding: 4px;">
  <button id="btnTogglePlayback" text="Play/Pause" allowFocus="false" />
  <label id="lblTime" text="0:00.00/0:00.00" style="vertical-align: center; padding-left: 8px;" />
  <spacer width="100%" />
  <label text="Auto-scroll:" style="vertical-align: center; padding-right: 4px;" />
  <dropdown id="ddAutoScroll" width="130" allowFocus="false" style="vertical-align: center;" />
  <spacer width="8" />
  <label text="Zoom:" style="vertical-align: center; padding-right: 4px;" />
  <slider id="zoomSlider" min="0.1" max="5.0" pos="1.0" width="120" style="vertical-align: center;" />
</hbox>
')
class TimelineToolbar extends HBox
{
  @:clonable @:behaviour(SongLengthBehaviour, 0)
  public var songLength:Float;

  @:clonable @:behaviour(SongPositionBehaviour, 0)
  public var songPosition:Float;

  public function new()
  {
    super();
    songLength = 0;

    var scrollTypes = new ArrayDataSource<Dynamic>();
    scrollTypes.add({text: "No Scroll"});
    scrollTypes.add({text: "Page Scroll"});
    scrollTypes.add({text: "Smooth Scroll"});
    ddAutoScroll.dataSource = scrollTypes;
    ddAutoScroll.selectedIndex = 1;
  }
}

@:dox(hide) @:noCompletion
private class SongPositionBehaviour extends DataBehaviour
{
  override public function validateData():Void
  {
    var toolbar:TimelineToolbar = cast(_component, TimelineToolbar);
    var v:Float = _value;

    if (v < 0) v = 0;
    if (toolbar.songLength > 0 && v > toolbar.songLength) v = toolbar.songLength;
    _value = v;

    toolbar.lblTime.text = FlxStringUtil.formatTime(v / 1000, true)
      + "/"
      + FlxStringUtil.formatTime(toolbar.songLength / 1000, true);
  }
}

@:dox(hide) @:noCompletion
private class SongLengthBehaviour extends DataBehaviour
{
  override public function validateData():Void
  {
    var toolbar:TimelineToolbar = cast(_component, TimelineToolbar);
    var len:Float = _value;

    toolbar.lblTime.text = FlxStringUtil.formatTime(toolbar.songPosition / 1000, true)
      + "/"
      + FlxStringUtil.formatTime(len / 1000, true);
  }
}
