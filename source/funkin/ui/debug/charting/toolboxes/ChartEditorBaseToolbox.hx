package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import haxe.ui.components.NumberStepper;
import haxe.ui.containers.dialogs.CollapsibleDialog;

/**
 * The base class for the Toolboxes (manipulatable, arrangeable control windows) in the Chart Editor.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorBaseToolbox extends CollapsibleDialog
{
  var chartEditorState:ChartEditorState;

  private function new(chartEditorState:ChartEditorState)
  {
    super();

    this.chartEditorState = chartEditorState;
  }

  /**
   * Sets the value of a NumberStepper without triggering its focus event.
   */
  static function setStepperValue(stepper:NumberStepper, value:Float):Void
  {
    if (stepper.focus) return;
    if (stepper.value != value) stepper.value = value;
  }

  /**
   * Override to implement this.
   */
  public override function refresh()
  {
  }
}
#end
