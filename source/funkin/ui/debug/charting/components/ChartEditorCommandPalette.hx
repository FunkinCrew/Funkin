package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import flixel.input.keyboard.FlxKey;
import funkin.ui.debug.charting.ChartEditorState;
import haxe.ui.containers.Panel;
import haxe.ui.core.Screen;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.events.KeyboardEvent;

using funkin.ui.debug.charting.components.palette.ChartEditorCommandPaletteItemBuilder;
using funkin.ui.debug.charting.components.palette.ChartEditorCommandPaletteRunner;

/**
 * This component blatantly rips off the command palette from VSCode.
 * Type in the box to navigate the chart, or perform almost any command.
 *
 * @see https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/components/command-palette.xml'))
class ChartEditorCommandPalette extends Panel
{
  /**
   * The current command palette instance, if any.
   */
  public static var instance:Null<ChartEditorCommandPalette> = null;

  var input(get, set):String;

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

  var selectionIndex:Int = 0;
  var chartEditorState:ChartEditorState;

  public function new(chartEditorState:ChartEditorState)
  {
    super();

    this.chartEditorState = chartEditorState;

    commandPaletteList.dataSource = new ArrayDataSource();

    initEvents();

    this.populatePaletteItems();
  }

  var previousValue:String = null;

  function onInputChanged(event:UIEvent):Void
  {
    trace('Command Palette: Input changed to "${commandPaletteInput.text}"');

    if (previousValue == commandPaletteInput.text) return;
    previousValue = commandPaletteInput.text;

    this.populatePaletteItems();
  }

  /**
   * Setup mouse events tied to this command palette.
   */
  function initEvents():Void
  {
    trace('Registering events...');
    Screen.instance.registerEvent(KeyboardEvent.KEY_DOWN, onScreenKeyDown);
    Screen.instance.registerEvent(MouseEvent.MOUSE_DOWN, onScreenMouseDown);
    Screen.instance.registerEvent(MouseEvent.RIGHT_MOUSE_DOWN, onScreenMouseDown);
    commandPaletteInput.onChange = onInputChanged;
  }

  /**
   * Cleanup mouse events tied to this command palette.
   */
  function cleanupEvents():Void
  {
    trace('Unregistering events...');
    Screen.instance.unregisterEvent(KeyboardEvent.KEY_DOWN, onScreenKeyDown);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_DOWN, onScreenMouseDown);
    Screen.instance.unregisterEvent(MouseEvent.RIGHT_MOUSE_DOWN, onScreenMouseDown);
  }

  /**
   * Called when clicking anywhere on the screen.
   *
   * @param event Details on the mouse event that occurred.
   */
  private function onScreenMouseDown(event:MouseEvent)
  {
    var wasCommandPaletteClicked = this.hitTest(event.screenX, event.screenY);

    if (!wasCommandPaletteClicked)
    {
      var beforeCloseEvent = new UIEvent(UIEvent.BEFORE_CLOSE);
      beforeCloseEvent.relatedEvent = event;
      this.dispatch(beforeCloseEvent);
      if (beforeCloseEvent.canceled) return;

      close();
      this.dispatch(new UIEvent(UIEvent.CLOSE));
    }
  }

  private function onScreenKeyDown(event:KeyboardEvent)
  {
    switch ([event.keyCode, event.ctrlKey, event.altKey, event.shiftKey])
    {
      case [FlxKey.UP, _, _, _]:
        this.selectionIndex -= 1;
        this.populatePaletteItems();
      case [FlxKey.DOWN, _, _, _]:
        this.selectionIndex += 1;
        this.populatePaletteItems();
      case [FlxKey.ENTER, _, _, _]:
        this.tryPerformCommand();
      case [FlxKey.ESCAPE, _, _, _]:
        this.close();
      default:
        // unbound/do nothing
    }
  }

  /**
   * Put the user's cursor on the input field.
   */
  public function focusInput():Void
  {
    trace('Command Palette: Focusing input...');
    instance.commandPaletteInput.focus = true;
    instance.commandPaletteInput.caretIndex = 1;
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
#end
