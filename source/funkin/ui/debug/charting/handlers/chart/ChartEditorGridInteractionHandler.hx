package funkin.ui.debug.charting.handlers.chart;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.util.Constants;
import funkin.graphics.FunkinSprite;
import flixel.util.FlxColor;
import funkin.ui.debug.charting.commands.selection.SetItemSelectionCommand;
import funkin.ui.debug.charting.toolboxes.ChartEditorEventDataToolbox;
import funkin.ui.debug.charting.selection.ChartEditorSelectable;
import funkin.data.event.SongEventRegistry;
import funkin.data.event.SongEventSchema;
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
    var clickedNote:Null<SongNoteData> = null;
    if (target == null)
    {
      for (noteSprite in state.renderedNotes.members)
      {
        if (noteSprite != null && noteSprite.alive && noteSprite.noteData != null && FlxG.mouse.overlaps(noteSprite))
        {
          clickedNote = noteSprite.noteData;
          target = 'note:${clickedNote.time}:${clickedNote.data}';
          break;
        }
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
    else if (clickedNote != null)
    {
      if (!state.currentNoteSelection.contains(clickedNote)) state.performCommand(new SetItemSelectionCommand([clickedNote], []));
      state.openToolboxFromGrid(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT, state.menubarItemToggleToolboxNoteData);
      state.refreshToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT);
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

  /**
   * Deselects all selectables except the one passed in.
   */
  public static function deselectAllExcept(state:ChartEditorState, keep:ChartEditorSelectable):Void
  {
    for (selectable in state.selectables)
    {
      if (selectable != keep) selectable.clearSelection();
    }
    if (state.currentNoteSelection.length > 0 || state.currentEventSelection.length > 0)
    {
      state.currentNoteSelection = [];
      state.currentEventSelection = [];
      state.noteDisplayDirty = true;
    }
  }

  public static final EVENT_DURATION_COLOR:FlxColor = 0xC0FFC34D;

  /**
   * How wide the event duration bar is, in pixels.
   */
  static final EVENT_DURATION_WIDTH:Int = 6;

  /**
   * Space between the grid and the duration bar, leaving room for the sub-beat tags.
   */
  static final EVENT_DURATION_GAP:Int = 14;

  /**
   * Which event kinds have a duration in steps, so the schema is only searched once per kind.
   */
  static var durationKinds:Map<String, Bool> = [];

  static function hasStepsDuration(kind:String):Bool
  {
    var known:Null<Bool> = durationKinds.get(kind);
    if (known != null) return known;
    var found:Bool = false;
    var schema:Null<SongEventSchema> = SongEventRegistry.getEventSchema(kind);
    if (schema != null)
    {
      for (field in schema)
      {
        if (field != null && field.name == 'duration' && field.units == 'steps') found = true;
      }
    }
    durationKinds.set(kind, found);
    return found;
  }

  /**
   * Show how long the event being edited lasts, in beats, as a bar and label to the right of the grid.
   */
  public static function handleEventDurationBar(state:ChartEditorState):Void
  {
    var bar:Null<FunkinSprite> = state.gridEventDurationBar;
    var text:Null<flixel.text.FlxText> = state.gridEventDurationText;
    if (bar == null || text == null) return;

    var event:Null<SongEventData> = null;
    if (state.currentEventSelection.length > 0 && state.currentNoteSelection.length == 0 && state.isOneEventChain(state.currentEventSelection))
    {
      for (selected in state.currentEventSelection)
      {
        if (selected.eventKind == state.eventKindToPlace && hasStepsDuration(selected.eventKind))
        {
          event = selected;
          break;
        }
      }
    }
    var steps:Float = (event != null) ? (event.getFloat('duration') ?? 0) : 0;
    if (event == null || steps <= 0 || state.gridTiledSprite == null)
    {
      bar.visible = false;
      text.visible = false;
      return;
    }

    var startStep:Float = event.getStepTime();
    var top:Float = state.gridTiledSprite.y + ChartEditorTimeScale.stepToPixels(startStep);
    var bottom:Float = state.gridTiledSprite.y + ChartEditorTimeScale.stepToPixels(startStep + steps);
    var left:Float = state.gridTiledSprite.x + ChartEditorState.GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT + EVENT_DURATION_GAP;
    bar.visible = true;
    bar.setPosition(left, top);
    bar.offset.set(0, 0);
    bar.scale.set(EVENT_DURATION_WIDTH, Math.max(1, bottom - top));

    var beats:Float = Math.round(steps / Constants.STEPS_PER_BEAT * 100) / 100;
    var label:String = '$beats ${beats == 1 ? 'beat' : 'beats'}';
    if (text.text != label) text.text = label;
    text.visible = true;
    text.setPosition(left + EVENT_DURATION_WIDTH + 4, Math.max(top, bottom - text.height));
  }

  public static function openToolboxFromGrid(state:ChartEditorState, id:String, menuItem:MenuCheckBox):Void
  {
    if (!menuItem.selected) menuItem.selected = true;
    state.setToolboxState(id, true);
  }
}
#end
