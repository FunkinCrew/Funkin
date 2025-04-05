package funkin.ui.debug.charting.components;

import flixel.addons.display.FlxSliceSprite;
import flixel.math.FlxRect;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.handlers.ChartEditorThemeHandler;

/**
 * A sprite that can be used to display a square over a selected note or event in the chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorSelectionSquareSprite extends FlxSliceSprite
{
  public var noteData:Null<SongNoteData>;
  public var eventData:Null<SongEventData>;

  public function new(chartEditorState:ChartEditorState)
  {
    super(chartEditorState.selectionSquareBitmap,
      new FlxRect(ChartEditorThemeHandler.SELECTION_SQUARE_BORDER_WIDTH
        + 4, ChartEditorThemeHandler.SELECTION_SQUARE_BORDER_WIDTH
        + 4,
        ChartEditorState.GRID_SIZE
        - (2 * ChartEditorThemeHandler.SELECTION_SQUARE_BORDER_WIDTH + 8),
        ChartEditorState.GRID_SIZE
        - (2 * ChartEditorThemeHandler.SELECTION_SQUARE_BORDER_WIDTH + 8)),
      32, 32);
  }
}
