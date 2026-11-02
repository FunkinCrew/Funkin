package funkin.ui.haxeui.components;

import haxe.ui.containers.Box;
import haxe.ui.containers.Splitter.SplitterBuilder;
import haxe.ui.containers.Splitter.SplitterEvents;
import haxe.ui.containers.VerticalSplitter;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;

/**
 * A vertical splitter that only resizes its panes when the gripper is let go.
 */
@:composite(DeferredVerticalSplitterEvents, DeferredVerticalSplitterBuilder)
class DeferredVerticalSplitter extends VerticalSplitter
{
  public function new()
  {
    super();
    addClass('splitter');
    addClass('vertical-splitter');
  }
}

@:dox(hide)
@:noCompletion
@:access(haxe.ui.core.Component)
private class DeferredVerticalSplitterEvents extends SplitterEvents
{
  static inline var GUIDE_HEIGHT:Float = 3;
  static inline var GUIDE_COLOR:Int = 0x5BA3FF;

  var guide:Null<Box> = null;
  var lastScreenY:Null<Float> = null;

  override function onScreenMouseMove(event:MouseEvent):Void
  {
    var gripper:Null<Component> = _currentGripper;
    if (gripper == null) return;
    gripper.addClass(':down');
    lastScreenY = event.screenY;
    showGuide(gripper, event.screenY);
  }

  override function onScreenMouseUp(event:MouseEvent):Void
  {
    var gripper:Null<Component> = _currentGripper;
    if (gripper != null && lastScreenY != null)
    {
      var index:Int = _splitter.getComponentIndex(gripper);
      var prev:Null<Component> = _splitter.getComponentAt(index - 1);
      var next:Null<Component> = _splitter.getComponentAt(index + 1);
      if (prev != null && next != null) applyResize(prev, next, lastScreenY);
    }
    lastScreenY = null;
    hideGuide();
    super.onScreenMouseUp(event);
  }

  function showGuide(gripper:Component, screenY:Float):Void
  {
    if (guide == null || guide.parentComponent != gripper)
    {
      guide = new Box();
      guide.includeInLayout = false;
      guide.customStyle.backgroundColor = GUIDE_COLOR;
      guide.customStyle.pointerEvents = 'none';
      guide.height = GUIDE_HEIGHT;
      gripper.addComponent(guide);
    }

    var top:Float = clampSplit(screenY - _splitter.screenTop - _currentOffset.y);
    guide.left = 0;
    guide.width = gripper.width;
    guide.top = top + _splitter.screenTop - gripper.screenTop;
    guide.hidden = false;
  }

  function hideGuide():Void
  {
    if (guide != null) guide.hidden = true;
  }

  function clampSplit(value:Float):Float
  {
    var usable:Float = _splitter.layout.usableHeight;
    if (value < 0) return 0;
    if (value > usable) return usable;
    return value;
  }

  /**
   * The same sizing the regular vertical splitter does, just done once.
   */
  function applyResize(prev:Component, next:Component, screenY:Float):Void
  {
    var usable:Float = _splitter.layout.usableHeight;
    if (usable <= 0) return;

    var prevHeight:Float = clampSplit(screenY - _splitter.screenTop - _currentOffset.y);
    var nextHeight:Float = usable - prevHeight;

    prev.handleVisibility(prevHeight > 0);
    next.handleVisibility(nextHeight > 0);

    if (prev.percentHeight != null) prev.percentHeight = (prevHeight / usable) * 100;
    else
      prev.height = prevHeight;

    if (next.percentHeight != null) next.percentHeight = (nextHeight / usable) * 100;
    else
      next.height = nextHeight;
  }
}

@:dox(hide)
@:noCompletion
private class DeferredVerticalSplitterBuilder extends SplitterBuilder
{
  override public function getSplitterClass():String
  {
    return 'vertical-splitter-gripper';
  }
}
