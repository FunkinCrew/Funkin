package funkin.ui.haxeui.components;

import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.behaviours.DefaultBehaviour;
import haxe.ui.containers.HorizontalSplitter;
import haxe.ui.containers.Splitter.SplitterEvents;
import haxe.ui.containers.Splitter.SplitterBuilder;

@:composite(CappedHorizontalSplitterEvents, CappedHorizontalSplitterBuilder)
class CappedHorizontalSplitter extends HorizontalSplitter
{
  /**
   * The lowest width an item may have. Leave the value `null` to prevent capping.
   */
  @:clonable @:behaviour(DefaultBehaviour, null)
  public var minItemWidth:Null<Float>;

  /**
   * The highest width an item may have. Leave the value `null` to prevent capping.
   */
  @:clonable @:behaviour(DefaultBehaviour, null)
  public var maxItemWidth:Null<Float>;
}

@:dox(hide) @:noCompletion
private class CappedHorizontalSplitterEvents extends SplitterEvents
{
  private var _cappedSplitter:CappedHorizontalSplitter;

  public function new(splitter:CappedHorizontalSplitter)
  {
    super(splitter);
    _cappedSplitter = splitter;
  }

  private override function onGripperMouseDown(event:MouseEvent)
  {
    super.onGripperMouseDown(event);
    #if haxeui_html5
    js.Browser.document.body.style.cursor = "col-resize";
    #end
  }

  private override function handleResize(prev:Component, next:Component, event:MouseEvent)
  {
    var screenX = _splitter.screenLeft;
    var delta = event.screenX - screenX - _currentOffset.x;
    var ucx = _splitter.layout.usableWidth;

    var prevCX = delta;
    var nextCX = ucx - delta;

    var minWidth:Null<Float> = _cappedSplitter.minItemWidth;
    var maxWidth:Null<Float> = _cappedSplitter.maxItemWidth;

    // limit to min sizes
    if (minWidth != null && prevCX <= minWidth)
    {
      prevCX = minWidth;
      nextCX = ucx - minWidth;
    }
    if (minWidth != null && nextCX <= minWidth)
    {
      prevCX = ucx - minWidth;
      nextCX = minWidth;
    }

    // limit to max sizes
    if (maxWidth != null && prevCX > maxWidth)
    {
      prevCX = maxWidth;
      nextCX = ucx - maxWidth;
    }
    if (maxWidth != null && nextCX > maxWidth)
    {
      prevCX = ucx - maxWidth;
      nextCX = maxWidth;
    }

    // bit of a hack to make things look a little nicer
    @:privateAccess prev.handleVisibility(prevCX > 0);
    @:privateAccess next.handleVisibility(nextCX > 0);

    // assign new sizes
    if (prev.percentWidth != null)
    {
      prev.percentWidth = (prevCX / ucx) * 100;
    }
    else
    {
      prev.width = prevCX;
    }

    if (next.percentWidth != null)
    {
      next.percentWidth = (nextCX / ucx) * 100;
    }
    else
    {
      next.width = nextCX;
    }
  }
}

@:dox(hide) @:noCompletion @:access(haxe.ui.core.Component)
private class CappedHorizontalSplitterBuilder extends SplitterBuilder
{
  public override function getSplitterClass():String
  {
    return "horizontal-splitter-gripper";
  }
}
