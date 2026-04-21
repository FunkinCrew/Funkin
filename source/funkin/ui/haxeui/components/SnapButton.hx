package funkin.ui.haxeui.components;

import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.util.Variant;

/** Toggle button with two icon pairs (snap / shift); `shiftActive` picks the pair, `selected` picks within it. **/
class SnapButton extends IconButton
{
  @:clonable @:behaviour(SnapIconBehaviour)
  public var iconSnapOn:Variant;

  @:clonable @:behaviour(SnapIconBehaviour)
  public var iconSnapOff:Variant;

  @:clonable @:behaviour(SnapIconBehaviour)
  public var iconShiftOn:Variant;

  @:clonable @:behaviour(SnapIconBehaviour)
  public var iconShiftOff:Variant;

  @:clonable @:behaviour(SnapIconBehaviour)
  public var shiftActive:Bool;

  public function new()
  {
    super();
    toggle = true;
  }

  public function refreshIconPair():Void
  {
    if (shiftActive)
    {
      icon = iconShiftOn;
      selectedIcon = iconShiftOff;
    }
    else
    {
      icon = iconSnapOff;
      selectedIcon = iconSnapOn;
    }
  }
}

@:dox(hide) @:noCompletion
private class SnapIconBehaviour extends DataBehaviour
{
  override function validateData():Void
  {
    cast(_component, SnapButton).refreshIconPair();
  }
}
