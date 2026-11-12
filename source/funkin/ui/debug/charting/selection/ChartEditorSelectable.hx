package funkin.ui.debug.charting.selection;

#if FEATURE_CHART_EDITOR
/**
 * A selectable item in the chart editor.
 */
interface ChartEditorSelectable
{
  /**
   * Whether one of these items is under the mouse.
   */
  public function hasItemUnderMouse():Bool;

  /**
   * Clicks, Ctrl clicks and drags, run once a frame.
   * @param otherItemUnderMouse Whether another kind's item is under the mouse, so clicking it lets go of these.
   */
  public function handleMouse(otherItemUnderMouse:Bool):Void;

  /**
   * Whether a selection box covers any of these items.
   */
  public function hasItemsInBox(left:Float, right:Float, startMs:Float, endMs:Float):Bool;

  /**
   * Pick the items a selection box covers.
   * @param additive Add them to the current pick instead of replacing it.
   * @return Whether anything got picked.
   */
  public function selectInBox(left:Float, right:Float, startMs:Float, endMs:Float, additive:Bool):Bool;

  public function hasSelection():Bool;

  public function clearSelection():Void;
}
#end
