package funkin.ui.debug.charting.contextmenus;

import haxe.ui.containers.menus.Menu;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorBaseContextMenu extends Menu
{
  var chartEditorState:ChartEditorState;

  public function new(chartEditorState:ChartEditorState, xPos:Float = 0, yPos:Float = 0)
  {
    super();

    this.chartEditorState = chartEditorState;

    this.left = xPos;
    this.top = yPos;
  }
}
