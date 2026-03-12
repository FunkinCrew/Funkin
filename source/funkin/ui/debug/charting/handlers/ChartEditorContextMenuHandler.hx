package funkin.ui.debug.charting.handlers;

#if FEATURE_CHART_EDITOR
import funkin.ui.debug.charting.contextmenus.ChartEditorDefaultContextMenu;
import funkin.ui.debug.charting.contextmenus.ChartEditorEventContextMenu;
import funkin.ui.debug.charting.contextmenus.ChartEditorHoldNoteContextMenu;
import funkin.ui.debug.charting.contextmenus.ChartEditorNoteContextMenu;
import funkin.ui.debug.charting.contextmenus.ChartEditorSelectionContextMenu;
import haxe.ui.containers.menus.Menu;
import haxe.ui.core.Screen;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongEventData;
import haxe.ui.events.UIEvent;

/**
 * Handles context menus (the little menus that appear when you right click on stuff) for the new Chart Editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorContextMenuHandler
{
  static var existingMenu:Null<Menu>;
  static var existingDefaultContextMenu:Null<ChartEditorDefaultContextMenu>;
  static var existingSelectionContextMenu:Null<ChartEditorSelectionContextMenu>;
  static var existingNoteContextMenu:Null<ChartEditorNoteContextMenu>;
  static var existingHoldNoteContextMenu:Null<ChartEditorHoldNoteContextMenu>;
  static var existingEventContextMenu:Null<ChartEditorEventContextMenu>;

  public static function openDefaultContextMenu(state:ChartEditorState, xPos:Float, yPos:Float)
  {
    if (existingDefaultContextMenu != null)
    {
      existingDefaultContextMenu.left = xPos;
      existingDefaultContextMenu.top = yPos;
      Screen.instance.addComponent(existingDefaultContextMenu);
    }
    else
    {
      var targetMenu = new ChartEditorDefaultContextMenu(state, xPos, yPos);
      displayMenu(state, targetMenu);
      existingDefaultContextMenu = targetMenu;
    }
  }

  /**
   * Opened when shift+right-clicking a selection of multiple items.
   */
  public static function openSelectionContextMenu(state:ChartEditorState, xPos:Float, yPos:Float)
  {
    if (existingSelectionContextMenu != null)
    {
      existingSelectionContextMenu.left = xPos;
      existingSelectionContextMenu.top = yPos;
      existingSelectionContextMenu.initialize();
      Screen.instance.addComponent(existingSelectionContextMenu);
    }
    else
    {
      var targetMenu = new ChartEditorSelectionContextMenu(state, xPos, yPos);
      displayMenu(state, targetMenu);
      existingSelectionContextMenu = targetMenu;
    }
  }

  /**
   * Opened when shift+right-clicking a single note.
   */
  public static function openNoteContextMenu(state:ChartEditorState, xPos:Float, yPos:Float, data:SongNoteData)
  {
    if (existingNoteContextMenu != null)
    {
      existingNoteContextMenu.left = xPos;
      existingNoteContextMenu.top = yPos;
      existingNoteContextMenu.data = data;
      existingNoteContextMenu.initialize();
      Screen.instance.addComponent(existingNoteContextMenu);
    }
    else
    {
      var targetMenu = new ChartEditorNoteContextMenu(state, xPos, yPos, data);
      displayMenu(state, targetMenu);
      existingNoteContextMenu = targetMenu;
    }
  }

  /**
   * Opened when shift+right-clicking a single hold note.
   */
  public static function openHoldNoteContextMenu(state:ChartEditorState, xPos:Float, yPos:Float, data:SongNoteData)
  {
    if (existingHoldNoteContextMenu != null)
    {
      existingHoldNoteContextMenu.left = xPos;
      existingHoldNoteContextMenu.top = yPos;
      existingHoldNoteContextMenu.data = data;
      existingHoldNoteContextMenu.initialize();
      Screen.instance.addComponent(existingHoldNoteContextMenu);
    }
    else
    {
      var targetMenu = new ChartEditorHoldNoteContextMenu(state, xPos, yPos, data);
      displayMenu(state, targetMenu);
      existingHoldNoteContextMenu = targetMenu;
    }
  }

  /**
   * Opened when shift+right-clicking a single event.
   */
  public static function openEventContextMenu(state:ChartEditorState, xPos:Float, yPos:Float, data:SongEventData)
  {
    if (existingEventContextMenu != null)
    {
      existingEventContextMenu.left = xPos;
      existingEventContextMenu.top = yPos;
      existingEventContextMenu.data = data;
      existingEventContextMenu.initialize();
      Screen.instance.addComponent(existingEventContextMenu);
    }
    else
    {
      var targetMenu = new ChartEditorEventContextMenu(state, xPos, yPos, data);
      displayMenu(state, targetMenu);
      existingEventContextMenu = targetMenu;
    }
  }

  static function displayMenu(state:ChartEditorState, targetMenu:Menu)
  {
    // Close the existing menu because it's of a different type
    closeExistingMenu(state);

    // Show the new menu
    Screen.instance.addComponent(targetMenu);
    existingMenu = targetMenu;
  }

  public static function closeExistingMenu(state:ChartEditorState)
  {
    if (existingMenu != null)
    {
      Screen.instance.removeComponent(existingMenu);

      existingDefaultContextMenu = null;
      existingSelectionContextMenu = null;
      existingNoteContextMenu = null;
      existingHoldNoteContextMenu = null;
      existingEventContextMenu = null;
      existingMenu = null;
    }
  }
}
#end
