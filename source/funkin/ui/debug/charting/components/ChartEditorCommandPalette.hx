package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import flixel.input.keyboard.FlxKey;
import funkin.ui.debug.charting.ChartEditorState;
import haxe.ui.containers.Panel;
import haxe.ui.core.Screen;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.events.ItemEvent;
import haxe.ui.events.KeyboardEvent;

using funkin.ui.debug.charting.components.palette.ChartEditorCommandPaletteItemBuilder;

/**
 * This component blatantly rips off the command palette from VSCode.
 * Type in the box to navigate the chart, or perform almost any command.
 *
 * @see https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette
 */
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/components/command-palette.xml'))
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorCommandPalette extends Panel
{
  /**
   * The current command palette instance, if any.
   */
  public static var instance:Null<ChartEditorCommandPalette> = null;

  /**
   * The Chart Editor State to operate on.
   */
  public final chartEditorState:ChartEditorState;

  /**
   * The current user input to the palette.
   */
  public var input(get, set):String;

  function get_input():String
  {
    return commandPaletteInput.text;
  }

  function set_input(value:String):String
  {
    if (value == commandPaletteInput.text) return value;
    commandPaletteInput.text = value;
    selectionIndex = 0;
    return value;
  }

  /**
   * The currently selected item in the list of commands (base-0).
   */
  var selectionIndex:Int = 0;

  public function new(chartEditorState:ChartEditorState)
  {
    super();

    this.chartEditorState = chartEditorState;

    commandPaletteList.dataSource = new ArrayDataSource();

    initEvents();

    this.populatePaletteItems();
  }

  var previousValue:String = null;

  /**
   * Called when the command palette input text changes.
   */
  function onInputChanged(_:UIEvent):Void
  {
    // Repopulate only if the value has changed.
    if (previousValue == commandPaletteInput.text) return;
    previousValue = commandPaletteInput.text;

    this.populatePaletteItems();
  }

  /**
   * Called when a UI event is called on a list item.
   * @param event The event that was called.
   */
  function onItemInteract(event:ItemEvent):Void
  {
    if (event.sourceEvent.type == MouseEvent.CLICK)
    {
      // The user clicked on a list item.

      // Get the data for that list item, then execute the associated command.
      var paletteCommand:PaletteCommand = event.data;

      var shouldClosePalette:Bool = paletteCommand.execute(this);

      // Clean up and close the palette.
      if (shouldClosePalette) close();
    }
  }

  /**
   * Setup mouse events tied to this command palette.
   */
  function initEvents():Void
  {
    Screen.instance.registerEvent(KeyboardEvent.KEY_DOWN, onScreenKeyDown);
    Screen.instance.registerEvent(MouseEvent.MOUSE_DOWN, onScreenMouseDown);
    Screen.instance.registerEvent(MouseEvent.RIGHT_MOUSE_DOWN, onScreenMouseDown);
    commandPaletteInput.onChange = onInputChanged;
    commandPaletteList.onComponentEvent = onItemInteract;
  }

  /**
   * Cleanup mouse events tied to this command palette.
   */
  function cleanupEvents():Void
  {
    Screen.instance.unregisterEvent(KeyboardEvent.KEY_DOWN, onScreenKeyDown);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_DOWN, onScreenMouseDown);
    Screen.instance.unregisterEvent(MouseEvent.RIGHT_MOUSE_DOWN, onScreenMouseDown);
  }

  /**
   * Fetch the data for the currently selected command palette list item.
   * @return The command
   */
  public function fetchCurrentCommand():Null<PaletteCommand>
  {
    if (commandPaletteList.dataSource.size == 0) return null;
    if (commandPaletteList.dataSource.size == 1) return commandPaletteList.dataSource.get(0);

    return commandPaletteList.dataSource.get(selectionIndex);
  }

  /**
   * Clear all list items from the command palette.
   */
  public function clearPalette():Void
  {
    commandPaletteList.dataSource.clear();
  }

  /**
   * Handle selection index behavior for the command palette,
   * including looping the selection and highlighting the corresponding list item.
   */
  public function handleSelection():Void
  {
    // Clamp the selection index.
    var itemCount:Int = commandPaletteList.dataSource.size;

    // Make it loop around
    if (selectionIndex < 0) selectionIndex = itemCount - 1;
    if (selectionIndex >= itemCount) selectionIndex = 0;

    if (itemCount > 1)
    {
      // Select the correct element.
      commandPaletteList.selectedIndex = selectionIndex;
    }
    else
    {
      // Don't select the only element.
      commandPaletteList.selectedIndex = -1;
    }
  }

  /**
   * Try and execute the currently selected command.
   *
   * @param palette The CommandPalette to operate on.
   */
  function tryPerformCommand():Void
  {
    var paletteCommand = fetchCurrentCommand();

    if (paletteCommand == null) return;

    var shouldClosePalette:Bool = paletteCommand.execute(this);

    // Clean up and close the palette.
    if (shouldClosePalette) close();
  }

  /**
   * Called when clicking anywhere on the screen.
   *
   * @param event Details on the mouse event that occurred.
   */
  function onScreenMouseDown(event:MouseEvent)
  {
    var wasCommandPaletteClicked = this.hitTest(event.screenX, event.screenY);

    if (!wasCommandPaletteClicked)
    {
      // User clicked outside of the command palette, so close it.

      var beforeCloseEvent = new UIEvent(UIEvent.BEFORE_CLOSE);
      beforeCloseEvent.relatedEvent = event;
      this.dispatch(beforeCloseEvent);
      if (beforeCloseEvent.canceled) return;

      close();
      this.dispatch(new UIEvent(UIEvent.CLOSE));
    }
  }

  /**
   * Called when pressing a key on the keyboard while the palette is open.
   * @param event Details on the keyboard event that occurred.
   */
  function onScreenKeyDown(event:KeyboardEvent)
  {
    switch ([event.keyCode, event.ctrlKey, event.altKey, event.shiftKey])
    {
      case [FlxKey.UP, _, _, _]:
        // Move selection up.
        selectionIndex -= 1;
        this.populatePaletteItems();
      case [FlxKey.DOWN, _, _, _]:
        // Move selection down.
        selectionIndex += 1;
        this.populatePaletteItems();
      case [FlxKey.ENTER, _, _, _]:
        // Pressed ENTER, perform the selected command.
        this.tryPerformCommand();
      case [FlxKey.ESCAPE, _, _, _]:
        // Close the palette.
        this.close();
      default:
        // No action bound, do nothing
    }
  }

  /**
   * Put the user's text cursor in the input field.
   */
  public function focusInput():Void
  {
    // Move focus so that typing puts text in the field immediately.
    instance.commandPaletteInput.focus = true;
    // Move the caret to the end.
    instance.commandPaletteInput.caretIndex = instance.commandPaletteInput.text.length;
  }

  /**
   * Close this command palette.
   */
  public function close():Void
  {
    chartEditorState.isHaxeUIDialogOpen = false;
    cleanupEvents();
    instance = null;
    Screen.instance.removeComponent(this);
  }

  /**
   * Open the command palette over the Chart Editor.
   *
   * @param state The Chart Editor to operate on.
   * @param startingInput The initial input for the text field.
   */
  public static function openPalette(state:ChartEditorState, startingInput:String = '')
  {
    if (instance != null)
    {
      // Focus on the existing instance.
      instance.input = startingInput;
      instance.focusInput();
      return;
    }

    instance = new ChartEditorCommandPalette(state);
    Screen.instance.addComponent(instance);

    // Center in the view
    instance.x = FlxG.width * (0.55 / 2);
    // Position just under the menubar.
    instance.y = ChartEditorState.MENU_BAR_HEIGHT + 8;

    instance.input = startingInput;
    instance.focusInput();

    state.isHaxeUIDialogOpen = true;
  }
}

/**
 * The data for displaying a single command in the command palette.
 */
typedef PaletteCommand =
{
  var title:String;
  var ?html:Bool;
  var subtitle:String;
  var shortcut:String;

  /**
   * The command to execute.
   * @param palette The palette that is executing the command.
   * @return Whether the palette should close after executing the command.
   */
  var execute:(ChartEditorCommandPalette) -> Bool;
}
#end
