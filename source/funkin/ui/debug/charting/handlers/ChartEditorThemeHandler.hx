package funkin.ui.debug.charting.handlers;

import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxSliceSprite;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorTheme;
import funkin.ui.debug.theme.EditorTheme;
import funkin.data.theme.ThemeRegistry;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
 * Static functions which handle building themed UI elements for a provided ChartEditorState.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorThemeHandler
{
  public static var theme:Null<EditorTheme>;

  static final BACKGROUND_COLOR_LIGHT:FlxColor = 0xFF673AB7;

  // Color 1 of the grid pattern. Alternates with Color 2.
  static final GRID_COLOR_1_LIGHT:FlxColor = 0xFFE7E6E6;

  // Color 2 of the grid pattern. Alternates with Color 1.
  static final GRID_COLOR_2_LIGHT:FlxColor = 0xFFF8F8F8;

  // Color 3 of the grid pattern. Borders the other colors.
  static final GRID_COLOR_3_LIGHT:FlxColor = 0xFFD9D5D5;

  // Vertical divider between characters.
  static final GRID_STRUMLINE_DIVIDER_COLOR_LIGHT:FlxColor = 0xFF111111;
  static final GRID_STRUMLINE_DIVIDER_WIDTH:Float = ChartEditorState.GRID_SELECTION_BORDER_WIDTH;

  // Horizontal divider between measures.
  static final GRID_MEASURE_DIVIDER_COLOR_LIGHT:FlxColor = 0xFF111111;
  static final GRID_MEASURE_DIVIDER_COLOR_DARK:FlxColor = 0xFFC4C4C4;
  static final GRID_MEASURE_DIVIDER_WIDTH:Float = ChartEditorState.GRID_SELECTION_BORDER_WIDTH;

  // Horizontal divider between beats.
  static final GRID_BEAT_DIVIDER_COLOR_LIGHT:FlxColor = 0xFFC1C1C1;
  static final GRID_BEAT_DIVIDER_COLOR_DARK:FlxColor = 0xFF848484;
  static final GRID_BEAT_DIVIDER_WIDTH:Float = ChartEditorState.GRID_SELECTION_BORDER_WIDTH;

  // Border on the square highlighting selected notes.
  static final SELECTION_SQUARE_BORDER_COLOR_LIGHT:FlxColor = 0xFF339933;
  public static final SELECTION_SQUARE_BORDER_WIDTH:Int = 1;

  // Fill on the square highlighting selected notes.
  static final SELECTION_SQUARE_FILL_COLOR_LIGHT:FlxColor = 0x4033FF33;

  // Make sure this is transparent so you can see the notes underneath.
  static final PLAYHEAD_BLOCK_BORDER_WIDTH:Int = 2;
  static final PLAYHEAD_BLOCK_BORDER_COLOR:FlxColor = 0xFF9D0011;
  static final PLAYHEAD_BLOCK_FILL_COLOR:FlxColor = 0xFFBD0231;

  // Border on the square over the note preview.
  static final NOTE_PREVIEW_VIEWPORT_BORDER_COLOR_LIGHT = 0xFFF8A657;

  // Fill on the square over the note preview.
  static final NOTE_PREVIEW_VIEWPORT_FILL_COLOR_LIGHT = 0x80F8A657;

  static final TOTAL_COLUMN_COUNT:Int = ChartEditorState.STRUMLINE_SIZE * 2 + 1;

  /**
   * When the theme is changed, this function updates all of the UI elements to match the new theme.
   * @param state The ChartEditorState to update.
   */
  public static function updateTheme(state:ChartEditorState):Void
  {
    theme = ThemeRegistry.instance.fetchEntry(state.themeId);
    if (theme == null) theme = ThemeRegistry.instance.fetchDefault();

    updateBackground(state);
    updateGridBitmap(state);
    updateMeasureTicks(state);
    updateOffsetTicks(state);
    updateSelectionSquare(state);
    updateNotePreview(state);
  }

  /**
   * Updates the tint of the background sprite to match the current theme.
   * @param state The ChartEditorState to update.
   */
  static function updateBackground(state:ChartEditorState):Void
  {
    if (theme == null || state.menuBG == null) return;
    state.menuBG.color = theme.getColor("background", BACKGROUND_COLOR_LIGHT);
  }

  /**
   * Builds the checkerboard background image of the chart editor, and adds dividing lines to it.
   * @param state The ChartEditorState to update.
   */
  static function updateGridBitmap(state:ChartEditorState):Void
  {
    if (theme == null) return;
    var gridColor1:FlxColor = theme.getColor("gridColors[0]", GRID_COLOR_1_LIGHT);

    var gridColor2:FlxColor = theme.getColor("gridColors[1]", GRID_COLOR_2_LIGHT);

    // Draw the base grid.

    // 2 * (Strumline Size) + 1 grid squares wide, by (4 * quarter notes per measure) grid squares tall.
    // This gets reused to fill the screen.
    var gridWidth:Int = Std.int(ChartEditorState.GRID_SIZE * TOTAL_COLUMN_COUNT);
    var gridHeight:Int = Std.int(ChartEditorState.GRID_SIZE * Conductor.instance.stepsPerMeasure);
    state.gridBitmap = FlxGridOverlay.createGrid(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE, gridWidth, gridHeight, true, gridColor1, gridColor2);

    // Selection borders
    var selectionBorderColor:FlxColor = theme.getColor("gridColors[2]", GRID_COLOR_3_LIGHT);

    // Selection border at top.
    state.gridBitmap.fillRect(new Rectangle(0, -(ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), state.gridBitmap.width,
      ChartEditorState.GRID_SELECTION_BORDER_WIDTH),
      selectionBorderColor);

    // Selection borders horizontally along the middle.
    for (i in 1...(Conductor.instance.stepsPerMeasure))
    {
      state.gridBitmap.fillRect(new Rectangle(0, (ChartEditorState.GRID_SIZE * i) - (ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2),
        state.gridBitmap.width, ChartEditorState.GRID_SELECTION_BORDER_WIDTH),
        selectionBorderColor);
    }

    // Selection border at bottom.
    state.gridBitmap.fillRect(new Rectangle(0, state.gridBitmap.height - (ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), state.gridBitmap.width,
      ChartEditorState.GRID_SELECTION_BORDER_WIDTH),
      selectionBorderColor);

    // Selection border at left.
    state.gridBitmap.fillRect(new Rectangle(-(ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), 0, ChartEditorState.GRID_SELECTION_BORDER_WIDTH,
      state.gridBitmap.height),
      selectionBorderColor);

    // Selection borders vertically along the middle.
    for (i in 1...TOTAL_COLUMN_COUNT)
    {
      state.gridBitmap.fillRect(new Rectangle((ChartEditorState.GRID_SIZE * i) - (ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), 0,
        ChartEditorState.GRID_SELECTION_BORDER_WIDTH, state.gridBitmap.height),
        selectionBorderColor);
    }

    // Selection border at right.
    state.gridBitmap.fillRect(new Rectangle(state.gridBitmap.width - (ChartEditorState.GRID_SELECTION_BORDER_WIDTH / 2), 0,
      ChartEditorState.GRID_SELECTION_BORDER_WIDTH, state.gridBitmap.height),
      selectionBorderColor);

    // Draw horizontal dividers between the measures.

    var gridMeasureDividerColor:FlxColor = theme.getColor("gridMeasureDivider", GRID_MEASURE_DIVIDER_COLOR_LIGHT);

    // Divider at top
    state.gridBitmap.fillRect(new Rectangle(0, 0, state.gridBitmap.width, GRID_MEASURE_DIVIDER_WIDTH / 2), gridMeasureDividerColor);
    // Divider at bottom
    var dividerLineBY:Float = state.gridBitmap.height - (GRID_MEASURE_DIVIDER_WIDTH / 2);
    state.gridBitmap.fillRect(new Rectangle(0, dividerLineBY, state.gridBitmap.width, GRID_MEASURE_DIVIDER_WIDTH / 2), gridMeasureDividerColor);

    // Draw horizontal dividers between the beats.

    var gridBeatDividerColor:FlxColor = theme.getColor("gridBeatDivider", GRID_BEAT_DIVIDER_COLOR_LIGHT);

    // Selection borders horizontally in the middle.
    for (i in 1...(Conductor.instance.stepsPerMeasure))
    {
      // There may be a different number of beats per measure, but there's always 4 steps per beat.
      if ((i % Constants.STEPS_PER_BEAT) == 0)
      {
        state.gridBitmap.fillRect(new Rectangle(0, (ChartEditorState.GRID_SIZE * i) - (GRID_BEAT_DIVIDER_WIDTH / 2), state.gridBitmap.width,
          GRID_BEAT_DIVIDER_WIDTH),
          gridBeatDividerColor);
      }
    }

    // Draw vertical dividers between the strumlines.

    var gridStrumlineDividerColor:FlxColor = theme.getColor("gridStrumlineDivider", GRID_STRUMLINE_DIVIDER_COLOR_LIGHT);

    // Divider at 1 * (Strumline Size)
    var dividerLineAX:Float = ChartEditorState.GRID_SIZE * (ChartEditorState.STRUMLINE_SIZE) - (GRID_STRUMLINE_DIVIDER_WIDTH / 2);
    state.gridBitmap.fillRect(new Rectangle(dividerLineAX, 0, GRID_STRUMLINE_DIVIDER_WIDTH, state.gridBitmap.height), gridStrumlineDividerColor);
    // Divider at 2 * (Strumline Size)
    var dividerLineBX:Float = ChartEditorState.GRID_SIZE * (ChartEditorState.STRUMLINE_SIZE * 2) - (GRID_STRUMLINE_DIVIDER_WIDTH / 2);
    state.gridBitmap.fillRect(new Rectangle(dividerLineBX, 0, GRID_STRUMLINE_DIVIDER_WIDTH, state.gridBitmap.height), gridStrumlineDividerColor);

    if (state.gridTiledSprite != null)
    {
      state.gridTiledSprite.loadGraphic(state.gridBitmap);
    }
    // Else, gridTiledSprite will be built later.
  }

  /**
   * Vertical measure ticks.
   */
  static function updateMeasureTicks(state:ChartEditorState):Void
  {
    var measureTickWidth:Int = 6;
    var beatTickWidth:Int = 4;
    var stepTickWidth:Int = 2;

    // Draw the measure ticks.
    var ticksWidth:Int = Std.int(ChartEditorState.GRID_SIZE); // 1 grid squares wide.
    var ticksHeight:Int = Std.int(ChartEditorState.GRID_SIZE * Conductor.instance.stepsPerMeasure); // 1 measure tall.
    state.measureTickBitmap = new BitmapData(ticksWidth, ticksHeight, true);
    state.measureTickBitmap.fillRect(new Rectangle(0, 0, ticksWidth, ticksHeight), GRID_BEAT_DIVIDER_COLOR_DARK);

    // Draw the measure ticks.
    state.measureTickBitmap.fillRect(new Rectangle(0, 0, state.measureTickBitmap.width, measureTickWidth / 2), GRID_MEASURE_DIVIDER_COLOR_LIGHT);
    var bottomTickY:Float = state.measureTickBitmap.height - (measureTickWidth / 2);
    state.measureTickBitmap.fillRect(new Rectangle(0, bottomTickY, state.measureTickBitmap.width, measureTickWidth / 2), GRID_MEASURE_DIVIDER_COLOR_LIGHT);

    // Draw the beat and step ticks. No need for two seperate loops thankfully.
    // This'll be fun to update when beat tuplets become functional.
    for (i in 1...(Conductor.instance.stepsPerMeasure))
    {
      if ((i % Constants.STEPS_PER_BEAT) == 0) // If we're on a beat, draw a beat tick.
      {
        var beatTickY:Float = state.measureTickBitmap.height * i / Conductor.instance.stepsPerMeasure - (beatTickWidth / 2);
        var beatTickLength:Float = state.measureTickBitmap.width * 2 / 3;
        state.measureTickBitmap.fillRect(new Rectangle(0, beatTickY, beatTickLength, beatTickWidth), GRID_MEASURE_DIVIDER_COLOR_LIGHT);
      }
      else // Else, draw a step tick.
      {
        var stepTickY:Float = state.measureTickBitmap.height * i / Conductor.instance.stepsPerMeasure - (stepTickWidth / 2);
        var stepTickLength:Float = state.measureTickBitmap.width * 1 / 3;
        state.measureTickBitmap.fillRect(new Rectangle(0, stepTickY, stepTickLength, stepTickWidth), GRID_MEASURE_DIVIDER_COLOR_LIGHT);
      }
    }
  }

  /**
   * Horizontal offset ticks.
   */
  static function updateOffsetTicks(state:ChartEditorState):Void
  {
    var majorTickWidth:Int = 6;
    var minorTickWidth:Int = 3;

    var ticksWidth:Int = Std.int(ChartEditorState.GRID_SIZE * Conductor.instance.stepsPerMeasure); // 10 minor ticks wide.
    var ticksHeight:Int = Std.int(ChartEditorState.GRID_SIZE); // 1 grid squares tall.
    state.offsetTickBitmap = new BitmapData(ticksWidth, ticksHeight, true);
    state.offsetTickBitmap.fillRect(new Rectangle(0, 0, ticksWidth, ticksHeight), GRID_BEAT_DIVIDER_COLOR_DARK);

    // Draw the major ticks.
    var leftTickX:Float = 0;
    var middleTickX:Float = state.offsetTickBitmap.width / 2 - (majorTickWidth / 2);
    var rightTickX:Float = state.offsetTickBitmap.width - (majorTickWidth / 2);
    var majorTickLength:Float = state.offsetTickBitmap.height;
    state.offsetTickBitmap.fillRect(new Rectangle(leftTickX, 0, majorTickWidth / 2, majorTickLength), GRID_MEASURE_DIVIDER_COLOR_LIGHT);
    state.offsetTickBitmap.fillRect(new Rectangle(middleTickX, 0, majorTickWidth, majorTickLength), GRID_MEASURE_DIVIDER_COLOR_LIGHT);
    state.offsetTickBitmap.fillRect(new Rectangle(rightTickX, 0, majorTickWidth / 2, majorTickLength), GRID_MEASURE_DIVIDER_COLOR_LIGHT);

    // Draw the minor ticks.
    for (i in 1...11)
    {
      if (i % 5 == 0)
      {
        continue;
      }
      var minorTickX:Float = state.offsetTickBitmap.width * i / 10 - (minorTickWidth / 2);
      var minorTickLength:Float = state.offsetTickBitmap.height * 1 / 3;
      state.offsetTickBitmap.fillRect(new Rectangle(minorTickX, 0, minorTickWidth, minorTickLength), GRID_MEASURE_DIVIDER_COLOR_LIGHT);
    }

    // Draw the offset ticks.
    // var ticksWidth:Int = Std.int(ChartEditorState.GRID_SIZE * TOTAL_COLUMN_COUNT); // 1 grid squares wide.
    // var ticksHeight:Int = Std.int(ChartEditorState.GRID_SIZE); // 1 measure tall.
    // state.offsetTickBitmap = new BitmapData(ticksWidth, ticksHeight, true);
    // state.offsetTickBitmap.fillRect(new Rectangle(0, 0, ticksWidth, ticksHeight), GRID_BEAT_DIVIDER_COLOR_DARK);
    //
    //// Draw the offset ticks.
    // state.offsetTickBitmap.fillRect(new Rectangle(0, 0, offsetTickWidth / 2, state.offsetTickBitmap.height), GRID_MEASURE_DIVIDER_COLOR_LIGHT);
    // var rightTickX:Float = state.offsetTickBitmap.width - (offsetTickWidth / 2);
    // state.offsetTickBitmap.fillRect(new Rectangle(rightTickX, 0, offsetTickWidth / 2, state.offsetTickBitmap.height), GRID_MEASURE_DIVIDER_COLOR_LIGHT);
  }

  static function updateSelectionSquare(state:ChartEditorState):Void
  {
    if (theme == null) return;
    var selectionSquareBorderColor:FlxColor = theme.getColor("selectionSquareBorder", SELECTION_SQUARE_BORDER_COLOR_LIGHT);

    var selectionSquareFillColor:FlxColor = theme.getColor("selectionSquareFill", SELECTION_SQUARE_FILL_COLOR_LIGHT);

    state.selectionSquareBitmap = new BitmapData(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE, true);

    state.selectionSquareBitmap.fillRect(new Rectangle(0, 0, ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE), selectionSquareBorderColor);
    state.selectionSquareBitmap.fillRect(new Rectangle(SELECTION_SQUARE_BORDER_WIDTH, SELECTION_SQUARE_BORDER_WIDTH,
      ChartEditorState.GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2), ChartEditorState.GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2)),
      selectionSquareFillColor);

    state.selectionBoxSprite = new FlxSliceSprite(state.selectionSquareBitmap,
      new FlxRect(SELECTION_SQUARE_BORDER_WIDTH
        + 4, SELECTION_SQUARE_BORDER_WIDTH
        + 4, ChartEditorState.GRID_SIZE
        - (2 * SELECTION_SQUARE_BORDER_WIDTH + 8),
        ChartEditorState.GRID_SIZE
        - (2 * SELECTION_SQUARE_BORDER_WIDTH + 8)),
      32, 32);

    state.selectionBoxSprite.scrollFactor.set(0, 0);
    state.selectionBoxSprite.zIndex = 30;
    state.add(state.selectionBoxSprite);

    state.setSelectionBoxBounds();
  }

  static function updateNotePreview(state:ChartEditorState):Void
  {
    if (theme == null) return;
    var viewportBorderColor:FlxColor = theme.getColor("notePreviewViewportBorder", NOTE_PREVIEW_VIEWPORT_BORDER_COLOR_LIGHT);

    var viewportFillColor:FlxColor = theme.getColor("notePreviewViewportFill", NOTE_PREVIEW_VIEWPORT_FILL_COLOR_LIGHT);

    state.notePreviewViewportBitmap = new BitmapData(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE, true);

    state.notePreviewViewportBitmap.fillRect(new Rectangle(0, 0, ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE), viewportBorderColor);
    state.notePreviewViewportBitmap.fillRect(new Rectangle(SELECTION_SQUARE_BORDER_WIDTH, SELECTION_SQUARE_BORDER_WIDTH,
      ChartEditorState.GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2), ChartEditorState.GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2)),
      viewportFillColor);

    if (state.notePreviewViewport != null)
    {
      state.notePreviewViewport.loadGraphic(state.notePreviewViewportBitmap);
    }
    else
    {
      state.notePreviewViewport = new FlxSliceSprite(state.notePreviewViewportBitmap,
        new FlxRect(SELECTION_SQUARE_BORDER_WIDTH
          + 1, SELECTION_SQUARE_BORDER_WIDTH
          + 1,
          ChartEditorState.GRID_SIZE
          - (2 * SELECTION_SQUARE_BORDER_WIDTH + 2), ChartEditorState.GRID_SIZE
          - (2 * SELECTION_SQUARE_BORDER_WIDTH + 2)),
        32, 32);
    }
  }

  public static function buildPlayheadBlock():FlxSprite
  {
    var playheadBlock:FlxSprite = new FlxSprite();

    var playheadBlockBitmap:BitmapData = new BitmapData(ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH, ChartEditorState.PLAYHEAD_HEIGHT * 2, true);

    playheadBlockBitmap.fillRect(new Rectangle(0, 0, ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH, ChartEditorState.PLAYHEAD_HEIGHT * 2),
      PLAYHEAD_BLOCK_BORDER_COLOR);
    playheadBlockBitmap.fillRect(new Rectangle(PLAYHEAD_BLOCK_BORDER_WIDTH, PLAYHEAD_BLOCK_BORDER_WIDTH,
      ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH - (2 * PLAYHEAD_BLOCK_BORDER_WIDTH),
      ChartEditorState.PLAYHEAD_HEIGHT * 2 - (2 * PLAYHEAD_BLOCK_BORDER_WIDTH)),
      PLAYHEAD_BLOCK_FILL_COLOR);

    return playheadBlock.loadGraphic(playheadBlockBitmap);
  }
}
