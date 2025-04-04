package funkin.ui.debug.charting.contextmenus;

import haxe.ui.containers.menus.MenuItem;
import funkin.data.song.SongData.SongEventData;
import funkin.ui.debug.charting.commands.RemoveEventsCommand;

@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/context-menus/event.xml"))
class ChartEditorEventContextMenu extends ChartEditorBaseContextMenu
{
  var contextmenuEdit:MenuItem;
  var contextmenuDelete:MenuItem;

  var data:SongEventData;

  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0, data:SongEventData)
  {
    super(chartEditorState2, xPos2, yPos2);
    this.data = data;

    initialize();
  }

  function initialize()
  {
    contextmenuEdit.onClick = function(_) {
      chartEditorState.showToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
    }

    contextmenuDelete.onClick = function(_) {
      chartEditorState.performCommand(new RemoveEventsCommand([data]));
    }
  }
}
