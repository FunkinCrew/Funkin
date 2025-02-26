package funkin.ui.debug.charting.contextmenus;

import haxe.ui.containers.menus.MenuItem;
import funkin.ui.debug.charting.commands.CutItemsCommand;
import funkin.ui.debug.charting.commands.RemoveEventsCommand;
import funkin.ui.debug.charting.commands.RemoveItemsCommand;
import funkin.ui.debug.charting.commands.RemoveNotesCommand;
import funkin.ui.debug.charting.commands.FlipNotesCommand;
import funkin.ui.debug.charting.commands.SelectAllItemsCommand;
import funkin.ui.debug.charting.commands.InvertSelectedItemsCommand;
import funkin.ui.debug.charting.commands.DeselectAllItemsCommand;

@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/context-menus/selection.xml"))
class ChartEditorSelectionContextMenu extends ChartEditorBaseContextMenu
{
  var contextmenuCut:MenuItem;
  var contextmenuCopy:MenuItem;
  var contextmenuPaste:MenuItem;
  var contextmenuDelete:MenuItem;
  var contextmenuFlip:MenuItem;
  var contextmenuSelectAll:MenuItem;
  var contextmenuSelectInverse:MenuItem;
  var contextmenuSelectNone:MenuItem;

  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0)
  {
    super(chartEditorState2, xPos2, yPos2);

    initialize();
  }

  function initialize():Void
  {
    contextmenuCut.onClick = (_) -> {
      chartEditorState.performCommand(new CutItemsCommand(chartEditorState.currentNoteSelection, chartEditorState.currentEventSelection));
    };
    contextmenuCopy.onClick = (_) -> {
      chartEditorState.copySelection();
    };
    contextmenuDelete.onClick = (_) -> {
      if (chartEditorState.currentNoteSelection.length > 0 && chartEditorState.currentEventSelection.length > 0)
      {
        chartEditorState.performCommand(new RemoveItemsCommand(chartEditorState.currentNoteSelection, chartEditorState.currentEventSelection));
      }
      else if (chartEditorState.currentNoteSelection.length > 0)
      {
        chartEditorState.performCommand(new RemoveNotesCommand(chartEditorState.currentNoteSelection));
      }
      else if (chartEditorState.currentEventSelection.length > 0)
      {
        chartEditorState.performCommand(new RemoveEventsCommand(chartEditorState.currentEventSelection));
      }
      else
      {
        // Do nothing???
      }
    };

    contextmenuFlip.onClick = function(_) {
      chartEditorState.performCommand(new FlipNotesCommand(chartEditorState.currentNoteSelection));
    }

    contextmenuSelectAll.onClick = function(_) {
      chartEditorState.performCommand(new SelectAllItemsCommand(true, false));
    }
    contextmenuSelectInverse.onClick = function(_) {
      chartEditorState.performCommand(new InvertSelectedItemsCommand());
    }
    contextmenuSelectNone.onClick = function(_) {
      chartEditorState.performCommand(new DeselectAllItemsCommand());
    }
  }
}
