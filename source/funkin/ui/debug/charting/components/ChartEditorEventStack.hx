package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import funkin.ui.debug.charting.handlers.ChartEditorThemeHandler;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorTheme;
import openfl.geom.Rectangle;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorEventStack extends FlxSprite
{
  /**
   * The actual event stack. Don't add directly to it, but rather use `addToStack()` to apply the position changes!
   */
  public var stack:Array<ChartEditorEventSprite> = [];

  /**
   * The event tied to this stack. Overlapping this event will cause the stack to be made visible.
   */
  public var parentEvent:Null<ChartEditorEventSprite> = null;

  var state:ChartEditorState;

  public function new(state:ChartEditorState)
  {
    super();

    this.active = false;
    this.state = state;
  }

  /**
   * Add multiple events to the stack. Also updates the background after fully adding them.
   */
  public function addMultipleToStack(events:Array<ChartEditorEventSprite>)
  {
    for (event in events) addToStack(event);
    updateBackground();
  }

  /**
   * Adds an event to the stack and applies the relevant positions.
   */
  public function addToStack(event:ChartEditorEventSprite)
  {
    event.x = this.x + ChartEditorState.GRID_SIZE * stack.length;
    event.y = this.y;
    event.updateTooltipPosition();
    stack.push(event);
  }

  /**
   * Fully clear the stack while repositioning the event sprites back to normal.
   */
  public function clearStack()
  {
    while (stack.length > 0)
    {
      var event:ChartEditorEventSprite = stack.pop();
      event.updateEventPosition(state.renderedEvents);
    }

    stack.resize(0);
  }

  /**
   * Update the background if the theme or the stack size has updated.
   */
  public function updateBackground()
  {
    var cellSize:Int = ChartEditorState.GRID_SIZE;
    var gridWidth:Int = Std.int(cellSize * stack.length);

    var isDark:Bool = (state.currentTheme == Dark);
    var gridColor1:FlxColor = (isDark ? ChartEditorThemeHandler.GRID_COLOR_1_DARK : ChartEditorThemeHandler.GRID_COLOR_1_LIGHT);
    var gridColor2:FlxColor = (isDark ? ChartEditorThemeHandler.GRID_COLOR_2_DARK : ChartEditorThemeHandler.GRID_COLOR_2_LIGHT);

    var bitmap:openfl.display.BitmapData = FlxGridOverlay.createGrid(cellSize, cellSize, gridWidth, cellSize, true, gridColor2, gridColor1);

    var selectionBorderColor:FlxColor = (isDark ? ChartEditorThemeHandler.GRID_COLOR_3_DARK : ChartEditorThemeHandler.GRID_COLOR_3_LIGHT);

    // Create borders for the outer edges.
    bitmap.fillRect(new Rectangle(0, -(ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), bitmap.width, ChartEditorState.GRID_SELECTION_BORDER_WIDTH),
      selectionBorderColor);

    bitmap.fillRect(new Rectangle(0, bitmap.height - (ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), bitmap.width,
      ChartEditorState.GRID_SELECTION_BORDER_WIDTH),
      selectionBorderColor);

    bitmap.fillRect(new Rectangle(-(ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), 0, ChartEditorState.GRID_SELECTION_BORDER_WIDTH, bitmap.height),
      selectionBorderColor);

    bitmap.fillRect(new Rectangle(bitmap.width - (ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), 0, ChartEditorState.GRID_SELECTION_BORDER_WIDTH,
      bitmap.height),
      selectionBorderColor);

    // Selection borders across the middle.
    for (i in 1...stack.length)
    {
      bitmap.fillRect(new Rectangle((cellSize * i) - (ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), 0, ChartEditorState.GRID_SELECTION_BORDER_WIDTH,
        bitmap.height),
        selectionBorderColor);
    }

    this.loadGraphic(bitmap);
  }

  override public function kill()
  {
    // Clear the stack and the parent event link when killing.
    clearStack();
    parentEvent = null;

    super.kill();
  }
}
#end
