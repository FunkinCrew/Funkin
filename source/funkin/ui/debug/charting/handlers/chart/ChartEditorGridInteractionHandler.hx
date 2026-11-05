package funkin.ui.debug.charting.handlers.chart;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.ui.debug.charting.commands.selection.SetItemSelectionCommand;
import funkin.ui.debug.charting.components.grid.ChartEditorTimeChangeSelection;
import funkin.ui.debug.charting.toolboxes.ChartEditorEventDataToolbox;
import funkin.ui.debug.charting.toolboxes.ChartEditorTimingToolbox;
import haxe.ui.containers.dialogs.CollapsibleDialog;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.core.Screen;
using Lambda;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorGridInteractionHandler
{
  /**
   * Double clicking an event opens it in the Events panel.
   */
  public static function handleGridDoubleClicks(state:ChartEditorState):Void
  {
    if (!FlxG.mouse.justPressed || state.isCursorOverHaxeUI) return;

    var timeChangeIndex:Int = state.gridLines != null ? state.gridLines.timeChangeUnderMouse() : -1;
    if (timeChangeIndex >= 0)
    {
      state.lastGridClickTarget = null;
      if (state.selectedTimeChangeIndex == timeChangeIndex)
      {
        state.openToolboxFromGrid(ChartEditorState.CHART_EDITOR_TOOLBOX_TIMING_LAYOUT, state.menubarItemToggleToolboxTiming);
        var timingToolbox:Null<ChartEditorTimingToolbox> = cast state.activeToolboxes.get(ChartEditorState.CHART_EDITOR_TOOLBOX_TIMING_LAYOUT);
        if (timingToolbox != null) timingToolbox.refreshTimeChanges(timeChangeIndex);
      }
      else
      {
        state.selectedTimeChangeIndex = timeChangeIndex;
      }
      state.timeChangeSelection ??= new ChartEditorTimeChangeSelection(state);
      state.listKeyTarget = state.timeChangeSelection;
      return;
    }

    state.selectedTimeChangeIndex = -1;
    if (state.listKeyTarget == state.timeChangeSelection) state.listKeyTarget = null;

    var target:Dynamic = null;
    var clickedEvent:Null<SongEventData> = null;
    for (eventSprite in state.renderedEvents.members)
    {
      if (eventSprite != null && eventSprite.alive && eventSprite.eventData != null && FlxG.mouse.overlaps(eventSprite))
      {
        clickedEvent = eventSprite.eventData;
        target = clickedEvent;
        break;
      }
    }

    var now:Float = haxe.Timer.stamp();
    var isDouble:Bool = target != null && target == state.lastGridClickTarget && now - state.lastGridClickTime <= ChartEditorState.DOUBLE_CLICK_SECONDS;
    state.lastGridClickTarget = isDouble ? null : target;
    state.lastGridClickTime = now;
    if (!isDouble) return;

    if (clickedEvent != null)
    {
      // The first click already selected the event and its chain.
      if (!state.isEventSelected(clickedEvent)) state.performCommand(new SetItemSelectionCommand([], [clickedEvent]));
      state.openToolboxFromGrid(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT, state.menubarItemToggleToolboxEventData);
      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
      var eventToolbox:Null<ChartEditorEventDataToolbox> = cast state.activeToolboxes.get(ChartEditorState.CHART_EDITOR_TOOLBOX_EVENT_DATA_LAYOUT);
      if (eventToolbox != null) state.listKeyTarget = eventToolbox;
    }
  }

  public static function openToolboxFromGrid(state:ChartEditorState, id:String, menuItem:MenuCheckBox):Void
  {
    if (!menuItem.selected) menuItem.selected = true;
    state.setToolboxState(id, true);
  }

  /**
   * The time change to box on the grid, or -1 when the Timing panel isn't on screen.
   */
  public static function outlinedTimeChangeIndex(state:ChartEditorState):Int
  {
    var toolbox:Null<CollapsibleDialog> = state.activeToolboxes.get(ChartEditorState.CHART_EDITOR_TOOLBOX_TIMING_LAYOUT);
    if (toolbox == null || toolbox.hidden || !Screen.instance.rootComponents.contains(toolbox)) return -1;
    return state.selectedTimeChangeIndex;
  }
}
#end
