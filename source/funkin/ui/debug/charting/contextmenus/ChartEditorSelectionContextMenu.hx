package funkin.ui.debug.charting.contextmenus;

#if FEATURE_CHART_EDITOR
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.properties.Property;
import haxe.ui.components.DropDown;
import haxe.ui.core.Screen;
import haxe.ui.events.UIEvent;
import funkin.ui.debug.charting.commands.MoveItemsCommand;
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
  var contextmenuOffset:Property;
  var contextmenuUnit:DropDown;
  var contextmenuOffsetMove:MenuItem;
  var contextmenuCut:MenuItem;
  var contextmenuCopy:MenuItem;
  var contextmenuPaste:MenuItem;
  var contextmenuDelete:MenuItem;
  var contextmenuFlip:MenuItem;
  var contextmenuSelectAll:MenuItem;
  var contextmenuSelectInverse:MenuItem;
  var contextmenuSelectNone:MenuItem;

  public var selectedUnit:Int;

  public function new(chartEditorState2:ChartEditorState, xPos2:Float = 0, yPos2:Float = 0, selectedUnit:Int = 0)
  {
    super(chartEditorState2, xPos2, yPos2);

    contextmenuOffset.value = 0;
    this.selectedUnit = selectedUnit;
    contextmenuUnit.selectedIndex = selectedUnit;
    contextmenuUnit.value = contextmenuUnit.dataSource.get(contextmenuUnit.selectedIndex);

    initialize();
  }

  public function initialize():Void
  {
    // NOTE: Remember to use commands here to ensure undo/redo works properly
    contextmenuUnit.onChange = function(_) {
      // Why does the dropdown do this after I specifically set the value of the damn thing?
      if (contextmenuUnit.selectedIndex == -1)
      {
        contextmenuUnit.pauseEvent(UIEvent.CHANGE, true);
        contextmenuUnit.selectedIndex = selectedUnit;
        contextmenuUnit.resumeEvent(UIEvent.CHANGE, true, true);
      }
      switch (contextmenuUnit.value.id)
      {
        case "MILLISECONDS":
          contextmenuOffset.label = "Offset (MS)";
          if (contextmenuOffset.value != 0)
          {
            contextmenuOffset.value = Conductor.instance.getStepTimeInMs(contextmenuOffset.value);
          }

        case "STEPS":
          contextmenuOffset.label = "Offset (Steps)";
          if (contextmenuOffset.value != 0)
          {
            contextmenuOffset.value = Conductor.instance.getTimeInSteps(contextmenuOffset.value);
          }

        default:
          contextmenuOffset.label = "Offset (MS)";
          if (contextmenuOffset.value != 0)
          {
            contextmenuOffset.value = Conductor.instance.getStepTimeInMs(contextmenuOffset.value);
          }
      }
    }
    var id:String = contextmenuUnit.dataSource.get(contextmenuUnit.selectedIndex).id;

    contextmenuOffsetMove.onClick = (_) -> {
      if (contextmenuUnit.selectedIndex == -1)
      {
        contextmenuUnit.pauseEvent(UIEvent.CHANGE, true);
        contextmenuUnit.selectedIndex = selectedUnit;
        contextmenuUnit.resumeEvent(UIEvent.CHANGE, true, true);
      }
      switch (contextmenuUnit.value.id)
      {
        case "MILLISECONDS":
          if (contextmenuOffset.value != 0)
          {
            chartEditorState.performCommand(new MoveItemsCommand(chartEditorState.currentNoteSelection, chartEditorState.currentEventSelection,
              contextmenuOffset.value, 0));
          }
        case "STEPS":
          if (contextmenuOffset.value != 0)
          {
            chartEditorState.performCommand(new MoveItemsCommand(chartEditorState.currentNoteSelection, chartEditorState.currentEventSelection,
              contextmenuOffset.value, 0, true));
          }
        default:
          if (contextmenuOffset.value != 0)
          {
            chartEditorState.performCommand(new MoveItemsCommand(chartEditorState.currentNoteSelection, chartEditorState.currentEventSelection,
              contextmenuOffset.value, 0));
          }
      }
    }

    contextmenuCut.onClick = (_) -> {
      chartEditorState.performCommand(new CutItemsCommand(chartEditorState.currentNoteSelection, chartEditorState.currentEventSelection));
    }

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
#end
