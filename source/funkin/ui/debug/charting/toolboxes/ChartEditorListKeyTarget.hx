package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
/**
 * Allow for list targets to be copied/pasted/deleted etc
 */
interface ChartEditorListKeyTarget
{
  /**
   * Whether the mouse is over this toolbox.
   */
  public function containsMouse():Bool;

  /**
   * Whether the toolbox is still on screen.
   */
  public function isListShown():Bool;

  public function copySelection():Void;

  public function pasteSelection():Void;

  public function deleteSelection():Void;
}
#end
