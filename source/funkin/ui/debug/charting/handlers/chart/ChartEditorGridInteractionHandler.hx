package funkin.ui.debug.charting.handlers.chart;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.ui.debug.charting.commands.selection.SetItemSelectionCommand;
import funkin.ui.debug.charting.toolboxes.ChartEditorEventDataToolbox;
import haxe.ui.containers.menus.MenuCheckBox;
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

  /**
   * Picking and dragging for every kind of selectable item. Each kind is told whether another kind's item is under the mouse,
   * so clicking one kind lets go of the others.
   */
  public static function handleSelectables(state:ChartEditorState):Void
  {
    var hits:Array<Bool> = [for (selectable in state.selectables) selectable.hasItemUnderMouse()];
    for (i in 0...state.selectables.length)
    {
      var otherHit:Bool = false;
      for (j in 0...hits.length)
      {
        if (j != i && hits[j]) otherHit = true;
      }
      state.selectables[i].handleMouse(otherHit);
    }
  }

  public static function openToolboxFromGrid(state:ChartEditorState, id:String, menuItem:MenuCheckBox):Void
  {
    if (!menuItem.selected) menuItem.selected = true;
    state.setToolboxState(id, true);
  }
}
#end
