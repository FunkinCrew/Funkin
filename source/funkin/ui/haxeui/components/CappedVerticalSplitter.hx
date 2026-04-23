package funkin.ui.haxeui.components;

import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.behaviours.DefaultBehaviour;
import haxe.ui.containers.VerticalSplitter;
import haxe.ui.containers.Splitter.SplitterEvents;
import haxe.ui.containers.Splitter.SplitterBuilder;

@:composite(CappedVerticalSplitterEvents, CappedVerticalSplitterBuilder)
class CappedVerticalSplitter extends VerticalSplitter
{
  /**
   * The lowest height an item may have. Leave the value `null` to prevent capping.
   */
  @:clonable @:behaviour(DefaultBehaviour, null)
  public var minItemHeight:Null<Float>;

  /**
   * The highest height an item may have. Leave the value `null` to prevent capping.
   */
  @:clonable @:behaviour(DefaultBehaviour, null)
  public var maxItemHeight:Null<Float>;
}

@:dox(hide) @:noCompletion
private class CappedVerticalSplitterEvents extends SplitterEvents
{
  private var _cappedSplitter:CappedVerticalSplitter;

  public function new(splitter:CappedVerticalSplitter)
  {
    super(splitter);
    _cappedSplitter = splitter;
  }

  private override function onGripperMouseDown(event:MouseEvent)
  {
    super.onGripperMouseDown(event);
    #if haxeui_html5
    js.Browser.document.body.style.cursor = "row-resize";
    #end
  }

  private override function handleResize(prev:Component, next:Component, event:MouseEvent)
  {
    var screenY = _splitter.screenTop;
    var delta = event.screenY - screenY - _currentOffset.y;
    var ucy = _splitter.layout.usableHeight;

    var prevCY = delta;
    var nextCY = ucy - delta;

    var minHeight:Null<Float> = _cappedSplitter.minItemHeight;
    var maxHeight:Null<Float> = _cappedSplitter.maxItemHeight;

    // limit to min sizes
    if (minHeight != null && prevCY <= minHeight)
    {
      prevCY = minHeight;
      nextCY = ucy - minHeight;
    }
    if (minHeight != null && nextCY <= minHeight)
    {
      prevCY = ucy - minHeight;
      nextCY = minHeight;
    }

    // limit to max sizes
    if (maxHeight != null && prevCY > maxHeight)
    {
      prevCY = maxHeight;
      nextCY = ucy - maxHeight;
    }
    if (maxHeight != null && nextCY > maxHeight)
    {
      prevCY = ucy - maxHeight;
      nextCY = maxHeight;
    }

    // bit of a hack to make things look a little nicer
    @:privateAccess prev.handleVisibility(prevCY > 0);
    @:privateAccess next.handleVisibility(nextCY > 0);

    // assign new sizes
    if (prev.percentHeight != null)
    {
      prev.percentHeight = (prevCY / ucy) * 100;
    }
    else
    {
      prev.height = prevCY;
    }

    if (next.percentHeight != null)
    {
      next.percentHeight = (nextCY / ucy) * 100;
    }
    else
    {
      next.height = nextCY;
    }
  }
}

@:dox(hide) @:noCompletion @:access(haxe.ui.core.Component)
private class CappedVerticalSplitterBuilder extends SplitterBuilder
{
  public override function getSplitterClass():String
  {
    return "vertical-splitter-gripper";
  }
}
