package funkin.ui.debug.charting.components;

import flixel.addons.display.FlxSliceSprite;
import flixel.math.FlxRect;
import funkin.ui.debug.charting.handlers.ChartEditorThemeHandler;

/**
 * A sprite that can be used to display a square.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorHintSquareSprite extends FlxSliceSprite
{
  public function new(chartEditorState:ChartEditorState)
  {
    super(chartEditorState.hintSquareBitmap,
      new FlxRect(ChartEditorThemeHandler.HINT_SQUARE_BORDER_WIDTH
        + 4, ChartEditorThemeHandler.HINT_SQUARE_BORDER_WIDTH
        + 4,
        ChartEditorState.GRID_SIZE
        - (2 * ChartEditorThemeHandler.HINT_SQUARE_BORDER_WIDTH + 8),
        ChartEditorState.GRID_SIZE
        - (2 * ChartEditorThemeHandler.HINT_SQUARE_BORDER_WIDTH + 8)),
      32, 32);
  }
}
