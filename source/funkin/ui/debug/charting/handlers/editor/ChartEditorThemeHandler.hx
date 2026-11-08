package funkin.ui.debug.charting.handlers.editor;

#if FEATURE_CHART_EDITOR
import flixel.addons.display.FlxSliceSprite;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import funkin.data.song.SongData.SongTimeChange;
import funkin.ui.debug.charting.ChartEditorState.ChartEditorTheme;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
 * Static functions which handle building themed UI elements for a provided ChartEditorState.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorThemeHandler
{
  // TODO: There's probably a better system of organization for these colors.
  // An enum of typedefs or something?
  // ================================
  static final BACKGROUND_COLOR_LIGHT:FlxColor = 0xFF4A3D66;
  static final BACKGROUND_COLOR_DARK:FlxColor = 0xFF241C36;
  // Color 1 of the grid pattern. Alternates with Color 2.
  public static final GRID_COLOR_1_LIGHT:FlxColor = 0xFFE7E6E6;
  public static final GRID_COLOR_1_DARK:FlxColor = 0xFF181919;
  // Color 2 of the grid pattern. Alternates with Color 1.
  public static final GRID_COLOR_2_LIGHT:FlxColor = 0xFFF8F8F8;
  public static final GRID_COLOR_2_DARK:FlxColor = 0xFF202020;
  // Color 3 of the grid pattern. Borders the other colors.
  public static final GRID_COLOR_3_LIGHT:FlxColor = 0xFFD9D5D5;
  public static final GRID_COLOR_3_DARK:FlxColor = 0xFF262A2A;
  // Vertical divider between characters.
  public static final GRID_STRUMLINE_DIVIDER_COLOR_LIGHT:FlxColor = 0xFF111111;
  public static final GRID_STRUMLINE_DIVIDER_COLOR_DARK:FlxColor = 0xFFC4C4C4;
  static final GRID_STRUMLINE_DIVIDER_WIDTH:Float = ChartEditorState.GRID_SELECTION_BORDER_WIDTH;
  // Horizontal divider between measures.
  public static final GRID_MEASURE_DIVIDER_COLOR_LIGHT:FlxColor = 0xFF111111;
  public static final GRID_MEASURE_DIVIDER_COLOR_DARK:FlxColor = 0xFFC4C4C4;
  static final GRID_MEASURE_DIVIDER_WIDTH:Float = ChartEditorState.GRID_SELECTION_BORDER_WIDTH;
  public static final MEASTURE_TICKS_BACKING_COLOR_LIGHT:FlxColor = 0xFFB4B6C0;
  public static final MEASTURE_TICKS_BACKING_COLOR_DARK:FlxColor = 0xFF24242E;
  // Border on the square highlighting selected notes.
  static final SELECTION_SQUARE_BORDER_COLOR_LIGHT:FlxColor = 0xFF339933;
  static final SELECTION_SQUARE_BORDER_COLOR_DARK:FlxColor = 0xFF339933;

  /**
   * The width of the opaque border around the square highlighting selected notes.
   */
  public static final SELECTION_SQUARE_BORDER_WIDTH:Int = 1;

  // Fill on the square highlighting selected notes.
  // Make sure this is transparent so you can see the notes underneath.
  static final SELECTION_SQUARE_FILL_COLOR_LIGHT:FlxColor = 0x4033FF33;
  static final SELECTION_SQUARE_FILL_COLOR_DARK:FlxColor = 0x4033FF33;
  static final PLAYHEAD_BLOCK_BORDER_WIDTH:Int = 2;
  static final PLAYHEAD_BLOCK_BORDER_COLOR:FlxColor = 0xFF9D0011;
  static final PLAYHEAD_BLOCK_FILL_COLOR:FlxColor = 0xFFBD0231;
  // Lines on the measure ticks.
  public static final MEASURE_TICKS_MEASURE_WIDTH:Int = 6;
  public static final MEASURE_TICKS_BEAT_WIDTH:Int = 4;
  public static final MEASURE_TICKS_STEP_WIDTH:Int = 2;
  // Border on the square over the note preview.
  static final NOTE_PREVIEW_VIEWPORT_BORDER_COLOR_LIGHT = 0xFFF8A657;
  static final NOTE_PREVIEW_VIEWPORT_BORDER_COLOR_DARK = 0xFFF8A657;
  // Fill on the square over the note preview.
  static final NOTE_PREVIEW_VIEWPORT_FILL_COLOR_LIGHT = 0x80F8A657;
  static final NOTE_PREVIEW_VIEWPORT_FILL_COLOR_DARK = 0x80F8A657;
  public static final TOTAL_COLUMN_COUNT:Int = ChartEditorState.STRUMLINE_SIZE * 2 + 1;

  /**
   * Height of the grid backing bitmap.
   */
  public static final BACKING_PIXELS:Int = 2;

  // Backing behind the notes and waveforms.
  static final GRID_BACKING_COLOR_LIGHT:FlxColor = 0xFFA9ABB4;
  static final GRID_BACKING_COLOR_DARK:FlxColor = 0xFF060608;
  public static final GRID_BACKING_ALPHA:Float = 0.92;

  // Faint vertical divider between the opponent, player and event columns.
  static final GRID_SIDE_DIVIDER_COLOR_LIGHT:FlxColor = 0xFF6E717C;
  static final GRID_SIDE_DIVIDER_COLOR_DARK:FlxColor = 0xFF3A3A48;
  public static final GRID_SIDE_DIVIDER_WIDTH:Int = 2;

  public static function getSideDividerColor(theme:ChartEditorTheme):FlxColor
  {
    return (theme == Dark) ? GRID_SIDE_DIVIDER_COLOR_DARK : GRID_SIDE_DIVIDER_COLOR_LIGHT;
  }

  // Thin horizontal lines on the grid.
  static final GRID_LINE_COLOR_LIGHT:FlxColor = 0xFF0E0E14;
  static final GRID_LINE_COLOR_DARK:FlxColor = 0xFFD0D0D8;

  public static final GRID_MEASURE_LINE_WIDTH:Int = 2;
  public static final GRID_MEASURE_LINE_ALPHA:Float = 0.75;
  public static final GRID_BEAT_LINE_WIDTH:Int = 1;
  public static final GRID_BEAT_LINE_ALPHA:Float = 0.4;
  public static final GRID_SNAP_LINE_WIDTH:Int = 1;
  public static final GRID_SNAP_LINE_ALPHA:Float = 0.12;
  public static final GRID_HALF_SNAP_LINE_ALPHA:Float = 0.26;

  // Solid waveform drawn across each side's lanes.
  static final WAVEFORM_OVERLAY_COLOR_LIGHT:FlxColor = 0xFF2E4F9C;
  static final WAVEFORM_OVERLAY_COLOR_DARK:FlxColor = 0xFF2F5CC4;

  public static function getGridLineColor(theme:ChartEditorTheme):FlxColor
  {
    return (theme == Dark) ? GRID_LINE_COLOR_DARK : GRID_LINE_COLOR_LIGHT;
  }

  public static function getWaveformOverlayColor(theme:ChartEditorTheme):FlxColor
  {
    return (theme == Dark) ? WAVEFORM_OVERLAY_COLOR_DARK : WAVEFORM_OVERLAY_COLOR_LIGHT;
  }

  // Filtered waveform overlay color.
  static final WAVEFORM_FILTER_COLOR_LIGHT:FlxColor = 0xFF0A8FC4;
  static final WAVEFORM_FILTER_COLOR_DARK:FlxColor = 0xFF5CE1FF;

  // Waveform inner color.
  static final WAVEFORM_CORE_COLOR_LIGHT:FlxColor = 0xFF8DB3FF;
  static final WAVEFORM_CORE_COLOR_DARK:FlxColor = 0xFF8FB8FF;

  /**
   * How opaque waveforms drawn over the grid are, filter overlay included.
   */
  public static final WAVEFORM_OVERLAY_ALPHA:Float = 0.7;

  public static function getWaveformCoreColor(theme:ChartEditorTheme):FlxColor
  {
    return (theme == Dark) ? WAVEFORM_CORE_COLOR_DARK : WAVEFORM_CORE_COLOR_LIGHT;
  }

  public static function getWaveformFilterColor(theme:ChartEditorTheme):FlxColor
  {
    return (theme == Dark) ? WAVEFORM_FILTER_COLOR_DARK : WAVEFORM_FILTER_COLOR_LIGHT;
  }

  /**
   * Beat lines closer together than this many pixels are not drawn.
   */
  public static final GRID_MIN_BEAT_PIXELS:Float = 8;

  /**
   * Snap lines closer together than this many pixels are not drawn.
   */
  public static final GRID_MIN_SNAP_PIXELS:Float = 6;

  /**
   * When the theme is changed, this function updates all of the UI elements to match the new theme.
   * @param state The ChartEditorState to update.
   */
  public static function updateTheme(state:ChartEditorState):Void
  {
    updateBackground(state);
    updateGridBitmap(state);
    updateOffsetTicks(state);
    updateSelectionSquare(state);
    updateNotePreview(state);
    updateMeasureTicks(state);
  }

  /**
   * Updates the tint of the background sprite to match the current theme.
   * @param state The ChartEditorState to update.
   */
  static function updateBackground(state:ChartEditorState):Void
  {
    if (state.menuBG == null) return;
    state.menuBG.color = switch (state.currentTheme)
    {
      case ChartEditorTheme.Light:
        BACKGROUND_COLOR_LIGHT;
      case ChartEditorTheme.Dark:
        BACKGROUND_COLOR_DARK;
      default:
        BACKGROUND_COLOR_LIGHT;
    }
  }

  /**
   * Builds the backing image of the chart editor grid.
   * @param state The ChartEditorState to update.
   */
  static function updateGridBitmap(state:ChartEditorState):Void
  {
    var backingColor:FlxColor = switch (state.currentTheme)
    {
      case Dark:
        GRID_BACKING_COLOR_DARK;
      default:
        GRID_BACKING_COLOR_LIGHT;
    };

    // A thin strip, stretched over the visible part of the grid.
    var gridWidth:Int = ChartEditorState.GRID_SIZE * TOTAL_COLUMN_COUNT;
    state.gridBitmap = new BitmapData(gridWidth, BACKING_PIXELS, true, backingColor);

    state.gridLines?.updateTheme();
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
    state.offsetTickBitmap?.dispose();
    state.offsetTickBitmap = new BitmapData(ticksWidth, ticksHeight, true);
    state.offsetTickBitmap.fillRect(new Rectangle(0, 0, ticksWidth, ticksHeight), 0xFFC4C4C4);

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
    var selectionSquareBorderColor:FlxColor = switch (state.currentTheme)
    {
      case Light:
        SELECTION_SQUARE_BORDER_COLOR_LIGHT;
      case Dark:
        SELECTION_SQUARE_BORDER_COLOR_DARK;
      default:
        SELECTION_SQUARE_BORDER_COLOR_LIGHT;
    };

    var selectionSquareFillColor:FlxColor = switch (state.currentTheme)
    {
      case Light:
        SELECTION_SQUARE_FILL_COLOR_LIGHT;
      case Dark:
        SELECTION_SQUARE_FILL_COLOR_DARK;
      default:
        SELECTION_SQUARE_FILL_COLOR_LIGHT;
    };

    state.selectionSquareBitmap = new BitmapData(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE, true);

    state.selectionSquareBitmap.fillRect(new Rectangle(0, 0, ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE), selectionSquareBorderColor);
    state.selectionSquareBitmap.fillRect(
      new Rectangle(
        SELECTION_SQUARE_BORDER_WIDTH,
        SELECTION_SQUARE_BORDER_WIDTH,
        ChartEditorState.GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2),
        ChartEditorState.GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2)
      ),
      selectionSquareFillColor
    );

    var oldGraphic:Null<flixel.graphics.FlxGraphic> = state.selectionSquareGraphic;
    if (oldGraphic != null)
    {
      oldGraphic.persist = false;
      oldGraphic.destroyOnNoUse = true;
    }
    var squareBitmap:BitmapData = state.selectionSquareBitmap ?? new BitmapData(1, 1, true, 0);
    var selectionSquareGraphic:flixel.graphics.FlxGraphic = flixel.graphics.FlxGraphic.fromBitmapData(squareBitmap, false, null, false);
    selectionSquareGraphic.persist = true;
    selectionSquareGraphic.destroyOnNoUse = false;
    state.selectionSquareGraphic = selectionSquareGraphic;

    var existingBox:Null<FlxSliceSprite> = state.selectionBoxSprite;
    if (existingBox != null)
    {
      existingBox.loadGraphic(squareBitmap);
      state.setSelectionBoxBounds();
      return;
    }

    state.selectionBoxSprite = new FlxSliceSprite(
      state.selectionSquareBitmap,
      new FlxRect(
        SELECTION_SQUARE_BORDER_WIDTH + 4,
        SELECTION_SQUARE_BORDER_WIDTH + 4,
        ChartEditorState.GRID_SIZE - (2 * SELECTION_SQUARE_BORDER_WIDTH + 8),
        ChartEditorState.GRID_SIZE - (2 * SELECTION_SQUARE_BORDER_WIDTH + 8)
      ),
      32,
      32
    );

    state.selectionBoxSprite.scrollFactor.set(0, 0);
    state.selectionBoxSprite.zIndex = 30;
    state.add(state.selectionBoxSprite);

    state.setSelectionBoxBounds();
  }

  static function updateNotePreview(state:ChartEditorState):Void
  {
    var viewportBorderColor:FlxColor = switch (state.currentTheme)
    {
      case Light:
        NOTE_PREVIEW_VIEWPORT_BORDER_COLOR_LIGHT;
      case Dark:
        NOTE_PREVIEW_VIEWPORT_BORDER_COLOR_DARK;
      default:
        NOTE_PREVIEW_VIEWPORT_BORDER_COLOR_LIGHT;
    };

    var viewportFillColor:FlxColor = switch (state.currentTheme)
    {
      case Light:
        NOTE_PREVIEW_VIEWPORT_FILL_COLOR_LIGHT;
      case Dark:
        NOTE_PREVIEW_VIEWPORT_FILL_COLOR_DARK;
      default:
        NOTE_PREVIEW_VIEWPORT_FILL_COLOR_LIGHT;
    };

    state.notePreviewViewportBitmap = new BitmapData(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE, true);

    state.notePreviewViewportBitmap.fillRect(new Rectangle(0, 0, ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE), viewportBorderColor);
    state.notePreviewViewportBitmap.fillRect(
      new Rectangle(
        SELECTION_SQUARE_BORDER_WIDTH,
        SELECTION_SQUARE_BORDER_WIDTH,
        ChartEditorState.GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2),
        ChartEditorState.GRID_SIZE - (SELECTION_SQUARE_BORDER_WIDTH * 2)
      ),
      viewportFillColor
    );

    if (state.notePreviewViewport != null)
    {
      state.notePreviewViewport.loadGraphic(state.notePreviewViewportBitmap);
    }
    else
    {
      state.notePreviewViewport = new FlxSliceSprite(
        state.notePreviewViewportBitmap,
        new FlxRect(
          SELECTION_SQUARE_BORDER_WIDTH + 1,
          SELECTION_SQUARE_BORDER_WIDTH + 1,
          ChartEditorState.GRID_SIZE - (2 * SELECTION_SQUARE_BORDER_WIDTH + 2),
          ChartEditorState.GRID_SIZE - (2 * SELECTION_SQUARE_BORDER_WIDTH + 2)
        ),
        32,
        32
      );
    }
  }

  static function updateMeasureTicks(state:ChartEditorState):Void
  {
    state.measureTicks?.updateTheme();
  }

  public static function buildPlayheadBlock():FlxSprite
  {
    var playheadBlock:FlxSprite = new FlxSprite();

    var playheadBlockBitmap:BitmapData = new BitmapData(ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH, ChartEditorState.PLAYHEAD_HEIGHT * 2, true);

    playheadBlockBitmap.fillRect(
      new Rectangle(0, 0, ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH, ChartEditorState.PLAYHEAD_HEIGHT * 2),
      PLAYHEAD_BLOCK_BORDER_COLOR
    );
    playheadBlockBitmap.fillRect(
      new Rectangle(
        PLAYHEAD_BLOCK_BORDER_WIDTH,
        PLAYHEAD_BLOCK_BORDER_WIDTH,
        ChartEditorState.PLAYHEAD_SCROLL_AREA_WIDTH - (2 * PLAYHEAD_BLOCK_BORDER_WIDTH),
        ChartEditorState.PLAYHEAD_HEIGHT * 2 - (2 * PLAYHEAD_BLOCK_BORDER_WIDTH)
      ),
      PLAYHEAD_BLOCK_FILL_COLOR
    );

    return playheadBlock.loadGraphic(playheadBlockBitmap);
  }
}
#end
