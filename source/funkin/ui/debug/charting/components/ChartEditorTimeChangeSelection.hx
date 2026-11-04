package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.toolboxes.ChartEditorListKeyTarget;
import funkin.ui.debug.charting.toolboxes.ChartEditorTimingToolbox;

/**
 * Selection actions for time changes
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorTimeChangeSelection implements ChartEditorListKeyTarget
{
  var chartEditorState:ChartEditorState;

  public function new(chartEditorState:ChartEditorState)
  {
    this.chartEditorState = chartEditorState;
  }

  /**
   * The Timing panel pointed at the picked time change. Built without being shown if it isn't open.
   */
  function timingToolbox():Null<ChartEditorTimingToolbox>
  {
    var toolbox:Null<ChartEditorTimingToolbox> = cast chartEditorState.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_TIMING_LAYOUT);
    if (toolbox != null) toolbox.refreshTimeChanges(chartEditorState.selectedTimeChangeIndex);
    return toolbox;
  }

  public function containsMouse():Bool
  {
    // Clicking the picked tag again keeps it picked; clicking anything else lets go.
    var gridLines = chartEditorState.gridLines;
    return gridLines != null && gridLines.timeChangeUnderMouse() == chartEditorState.selectedTimeChangeIndex;
  }

  public function isListShown():Bool
  {
    return chartEditorState.selectedTimeChangeIndex >= 0;
  }

  public function copySelection():Void
  {
    timingToolbox()?.copySelection();
  }

  public function pasteSelection():Void
  {
    timingToolbox()?.pasteSelection();
  }

  public function deleteSelection():Void
  {
    timingToolbox()?.deleteSelection();
  }
}
#end
