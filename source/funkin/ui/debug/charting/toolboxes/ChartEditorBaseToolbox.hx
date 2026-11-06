package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import haxe.ui.containers.dialogs.CollapsibleDialog;

/**
 * The base class for the Toolboxes (manipulatable, arrangeable control windows) in the Chart Editor.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorBaseToolbox extends CollapsibleDialog
{
  var chartEditorState:ChartEditorState;

  /**
   * The height before the window was minimized.
   */
  var expandedHeight:Null<Float> = null;

  private function new(chartEditorState:ChartEditorState)
  {
    super();

    this.chartEditorState = chartEditorState;
  }

  override function set_minimized(value:Bool):Bool
  {
    if (value && !minimized) expandedHeight = this.height;
    var result:Bool = super.set_minimized(value);
    var restore:Null<Float> = expandedHeight;
    if (!value && restore != null)
    {
      expandedHeight = null;
      this.height = restore;
      haxe.ui.Toolkit.callLater(() -> if (!minimized) this.height = restore);
    }
    return result;
  }

  /**
   * Override to implement this.
   */
  public function refresh()
  {
  }
}
#end
