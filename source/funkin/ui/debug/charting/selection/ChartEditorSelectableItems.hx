package funkin.ui.debug.charting.selection;

#if FEATURE_CHART_EDITOR
import funkin.input.Cursor;
import funkin.ui.debug.charting.toolboxes.ChartEditorListKeyTarget;

/**
 * A collection of selectable items in the chart editor.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorSelectableItems<T> implements ChartEditorSelectable implements ChartEditorListKeyTarget
{
  /**
   * How far the mouse has to move, in pixels, before holding an item turns into dragging it.
   */
  static final DRAG_THRESHOLD:Float = 4;

  var state:ChartEditorState;

  /**
   * The picked items. The first one is the one panels show.
   */
  public var selected(default, null):Array<T> = [];

  var drag:Null<SelectableDrag<T>> = null;

  /**
   * The kind of item copied last. Ctrl+V pastes these when nothing is picked, until notes or events get copied.
   */
  public static var lastCopied:Null<ChartEditorListKeyTarget> = null;

  /**
   * Paste whatever kind of item was copied last.
   * @return Whether there was one, otherwise notes and events paste as usual.
   */
  public static function pasteLastCopied():Bool
  {
    var target:Null<ChartEditorListKeyTarget> = lastCopied;
    if (target == null) return false;
    target.pasteSelection();
    return true;
  }

  public function new(state:ChartEditorState)
  {
    this.state = state;
    lastCopied = null;
  }

  /**
   * Replace the picked items.
   * @param takeKeys Send copy, paste and delete to these items. Off when a panel picks them and keeps the keys itself.
   */
  public function select(items:Array<T>, takeKeys:Bool = true):Void
  {
    selected = items;
    if (items.length > 0 && takeKeys) state.listKeyTarget = this;
    else if (items.length == 0 && state.listKeyTarget == this) state.listKeyTarget = null;
    onSelectionChanged();
  }

  public function contains(item:T):Bool
  {
    return selected.contains(item);
  }

  /**
   * Drop one item from the pick, like when it gets removed.
   */
  public function deselect(item:T):Void
  {
    if (!selected.remove(item)) return;
    if (selected.length == 0 && state.listKeyTarget == this) state.listKeyTarget = null;
    onSelectionChanged();
  }

  public function hasSelection():Bool
  {
    return selected.length > 0;
  }

  public function clearSelection():Void
  {
    if (selected.length > 0) select([]);
  }

  public function hasItemUnderMouse():Bool
  {
    return itemUnderMouse() != null;
  }

  public function hasItemsInBox(left:Float, right:Float, startMs:Float, endMs:Float):Bool
  {
    return itemsInBox(left, right, startMs, endMs).length > 0;
  }

  public function selectInBox(left:Float, right:Float, startMs:Float, endMs:Float, additive:Bool):Bool
  {
    var found:Array<T> = itemsInBox(left, right, startMs, endMs);
    if (found.length == 0) return false;
    var picked:Array<T> = additive ? selected.copy() : [];
    for (item in found)
    {
      if (!picked.contains(item)) picked.push(item);
    }
    select(picked);
    return true;
  }

  public function handleMouse(otherItemUnderMouse:Bool):Void
  {
    var current:Null<SelectableDrag<T>> = drag;
    if (current != null)
    {
      updateDrag(current);
      return;
    }

    var item:Null<T> = itemUnderMouse();
    if (item != null && canGrab(item)) Cursor.cursorMode = Grabbing;
    if (!FlxG.mouse.justPressed) return;

    var ctrl:Bool = state.pressingControl();
    if (item == null)
    {
      // Clicking empty grid or another kind of item lets go. Ctrl keeps them, so a Ctrl selection box can add to them.
      if (!ctrl && (otherItemUnderMouse || !state.isCursorOverHaxeUI)) clearSelection();
      return;
    }

    if (ctrl)
    {
      var picked:Array<T> = selected.copy();
      if (!picked.remove(item)) picked.push(item);
      select(picked);
      return;
    }

    var wasOnlySelection:Bool = selected.length == 1 && selected[0] == item;
    select(contains(item) ? selected.copy() : [item]);

    var grabbable:Bool = canGrab(item);
    onPress(item, grabbable);
    var items:Array<T> = dragItems(item);
    drag =
      {
        item: item,
        startY: FlxG.mouse.viewY,
        grabOffset: FlxG.mouse.viewY - itemScreenY(item),
        moved: false,
        grabbable: grabbable,
        wasOnlySelection: wasOnlySelection,
        items: items,
        originalTimes: [for (i in items) getTime(i)]
      };
  }

  function updateDrag(current:SelectableDrag<T>):Void
  {
    if (!FlxG.mouse.pressed)
    {
      drag = null;
      if (!current.moved)
      {
        onClickReleased(current.item, current.wasOnlySelection);
        return;
      }
      var targets:Array<Float> = [for (i in current.items) getTime(i)];
      var changed:Bool = false;
      for (i in 0...targets.length)
      {
        if (targets[i] != current.originalTimes[i]) changed = true;
      }
      if (!changed) return;
      // Put them back first, so the command records where the drag started and undo returns there.
      setTimes(current.items, current.originalTimes);
      commitMove(current.items, targets);
      return;
    }

    if (!current.grabbable) return;
    Cursor.cursorMode = Grabbing;
    if (!current.moved && Math.abs(FlxG.mouse.viewY - current.startY) < DRAG_THRESHOLD) return;
    current.moved = true;

    var index:Int = current.items.indexOf(current.item);
    if (index < 0) return;
    var step:Float = ChartEditorTimeScale.pixelsToStep(FlxG.mouse.viewY - current.grabOffset - state.gridTiledSprite.y);
    var snappedStep:Float = snapStep(step);
    var delta:Float = clampDelta(current.items, current.originalTimes, timeAtStep(current.item, snappedStep) - current.originalTimes[index]);
    if (Math.abs(getTime(current.item) - (current.originalTimes[index] + delta)) < 0.0001) return;

    // Shown live without going into the undo history, the release adds one command for the whole drag.
    setTimes(current.items, [for (time in current.originalTimes) time + delta]);
  }

  // Overridden by each kind of item.

  /**
   * The item under the mouse, if any.
   */
  function itemUnderMouse():Null<T>
  {
    return null;
  }

  /**
   * Whether the mouse is on a part of the item that drags it.
   */
  function canGrab(item:T):Bool
  {
    return true;
  }

  function itemsInBox(left:Float, right:Float, startMs:Float, endMs:Float):Array<T>
  {
    return [];
  }

  function getTime(item:T):Float
  {
    return 0;
  }

  /**
   * Move items while dragging, without a command.
   */
  function setTimes(items:Array<T>, times:Array<Float>):Void {}

  /**
   * Turn a finished drag into an undoable command.
   */
  function commitMove(items:Array<T>, targetTimes:Array<Float>):Void {}

  /**
   * Where a dragged item lands, in steps. By default the current snap.
   */
  function snapStep(step:Float):Float
  {
    return Math.fround(step / state.noteSnapRatio) * state.noteSnapRatio;
  }

  /**
   * The time a grid step lands on for this item.
   */
  function timeAtStep(item:T, step:Float):Float
  {
    return Conductor.instance.getStepTimeInMs(step);
  }

  /**
   * Keep a drag in range. By default the items stay inside the song together.
   */
  function clampDelta(items:Array<T>, originalTimes:Array<Float>, delta:Float):Float
  {
    var earliest:Float = Math.POSITIVE_INFINITY;
    var latest:Float = Math.NEGATIVE_INFINITY;
    for (time in originalTimes)
    {
      earliest = Math.min(earliest, time);
      latest = Math.max(latest, time);
    }
    return Math.max(-earliest, Math.min(delta, state.songLengthInMs - latest));
  }

  function itemScreenY(item:T):Float
  {
    return ChartEditorTimeScale.msToPixels(getTime(item)) + state.gridTiledSprite.y;
  }

  /**
   * The items a drag on this one moves. By default every picked item.
   */
  function dragItems(item:T):Array<T>
  {
    return selected.copy();
  }

  function onPress(item:T, grabbing:Bool):Void {}

  /**
   * The mouse came up without dragging.
   * @param wasOnlySelection Whether this item was already the only picked one before the click.
   */
  function onClickReleased(item:T, wasOnlySelection:Bool):Void {}

  function onSelectionChanged():Void {}

  // ChartEditorListKeyTarget

  public function containsMouse():Bool
  {
    var item:Null<T> = itemUnderMouse();
    return item != null && contains(item);
  }

  public function isListShown():Bool
  {
    return hasSelection();
  }

  public function copySelection():Void {}

  public function pasteSelection():Void {}

  public function deleteSelection():Void {}
}

typedef SelectableDrag<T> =
{
  var item:T;
  var startY:Float;
  var grabOffset:Float;
  var moved:Bool;
  var grabbable:Bool;
  var wasOnlySelection:Bool;
  var items:Array<T>;
  var originalTimes:Array<Float>;
}
#end
