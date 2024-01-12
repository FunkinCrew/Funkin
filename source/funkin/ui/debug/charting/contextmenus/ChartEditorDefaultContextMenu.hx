package funkin.ui.debug.charting.contextmenus;

import haxe.ui.containers.menus.Menu;
import haxe.ui.core.Screen;

@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/context-menus/default.xml"))
class ChartEditorDefaultContextMenu extends ChartEditorBaseContextMenu
{
  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0)
  {
    super(chartEditorState2, xPos2, yPos2);
  }
}
