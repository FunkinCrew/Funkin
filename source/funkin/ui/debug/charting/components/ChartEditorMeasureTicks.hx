package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import flixel.addons.display.FlxTiledSprite;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
 * Handles the display of the measure ticks and numbers on the left side.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorMeasureTicks extends FlxTypedSpriteGroup<FlxSprite>
{
  /**
   * The owning ChartEditorState.
   */
  var chartEditorState:ChartEditorState;

  /**
   * The measure ticks underneath the numbers.
   */
  var measureTicksSprite:FlxTiledSprite = new FlxTiledSprite(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE * 16);

  /**
   * The numbers that display the current measure number.
   * This is a group so we can kill and recycle its members.
   */
  var measureNumbers:FlxTypedSpriteGroup<FlxText> = new FlxTypedSpriteGroup<FlxText>();

  /**
   * The horizontal bars over the grid at each measure tick.
   */
  var measureDividers:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>();

  /**
   * The positions of each measure tick, in pixels, relative to the start of the song.
   */
  var measurePositions:Array<Float> = [];

  /**
   * A map of the
   * @param value
   * @return Float
   */
  override function set_y(value:Float):Float
  {
    // Don't update if the value hasn't changed.
    if (this.y == value) return value;

    super.set_y(value);

    updateMeasureNumbers();

    return this.y;
  }

  public function new(chartEditorState:ChartEditorState)
  {
    super();

    this.chartEditorState = chartEditorState;

    add(measureTicksSprite);
    add(measureNumbers);
    add(measureDividers);

    buildMeasureTicksSprite();
    updateMeasureNumbers(true);
  }

  /**
   * Set the overall height of the measure ticks.
   * @param height The desired height in pixels.
   */
  public function setHeight(height:Float):Void
  {
    measureTicksSprite.height = height;
  }

  public function updateTheme():Void
  {
    buildMeasureTicksSprite();
    updateMeasureNumbers(true);
  }

  function buildMeasureTicksSprite():Void
  {
    var backingColor:FlxColor = switch (chartEditorState.currentTheme)
    {
      case Light: ChartEditorThemeHandler.MEASTURE_TICKS_BACKING_COLOR_LIGHT;
      case Dark: ChartEditorThemeHandler.MEASTURE_TICKS_BACKING_COLOR_DARK;
      default: ChartEditorThemeHandler.MEASTURE_TICKS_BACKING_COLOR_LIGHT;
    };
    var dividerColor:FlxColor = switch (chartEditorState.currentTheme)
    {
      case Light: ChartEditorThemeHandler.GRID_MEASURE_DIVIDER_COLOR_LIGHT;
      case Dark: ChartEditorThemeHandler.GRID_MEASURE_DIVIDER_COLOR_DARK;
      default: ChartEditorThemeHandler.GRID_MEASURE_DIVIDER_COLOR_LIGHT;
    };

    // TODO: This does NOT account for time signature, and always assumes 4/4!
    // Better to have the little lines not line up than be required to redraw the image every frame,
    // but we need to fix this eventually.
    var stepsPerMeasure:Int = Constants.STEPS_PER_BEAT * 4;

    // Start the bitmap with the basic gray color.
    var measureTickBitmap = new BitmapData(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE * 16, true, backingColor);

    // Draw the measure ticks at the top and bottom.
    measureTickBitmap.fillRect(new Rectangle(0, 0, ChartEditorState.GRID_SIZE, ChartEditorThemeHandler.MEASURE_TICKS_MEASURE_WIDTH / 2), dividerColor);
    var bottomTickY:Float = measureTickBitmap.height - (ChartEditorThemeHandler.MEASURE_TICKS_MEASURE_WIDTH / 2);
    measureTickBitmap.fillRect(new Rectangle(0, bottomTickY, ChartEditorState.GRID_SIZE, ChartEditorThemeHandler.MEASURE_TICKS_MEASURE_WIDTH / 2),
      dividerColor);

    // Draw the beat ticks and dividers, and step ticks. No need for two seperate loops thankfully.
    for (i in 1...stepsPerMeasure)
    {
      if ((i % Constants.STEPS_PER_BEAT) == 0) // If we're on a beat, draw a beat tick and divider.
      {
        var beatTickY:Float = ChartEditorState.GRID_SIZE * i - (ChartEditorThemeHandler.MEASURE_TICKS_BEAT_WIDTH / 2);
        var beatTickLength:Float = ChartEditorState.GRID_SIZE * 2 / 3;
        measureTickBitmap.fillRect(new Rectangle(0, beatTickY, beatTickLength, ChartEditorThemeHandler.MEASURE_TICKS_BEAT_WIDTH), dividerColor);
      }
      else
      {
        // Draw a step tick.
        var stepTickY:Float = ChartEditorState.GRID_SIZE * i - (ChartEditorThemeHandler.MEASURE_TICKS_STEP_WIDTH / 2);
        var stepTickLength:Float = ChartEditorState.GRID_SIZE * 1 / 3;
        measureTickBitmap.fillRect(new Rectangle(0, stepTickY, stepTickLength, ChartEditorThemeHandler.MEASURE_TICKS_STEP_WIDTH), dividerColor);
      }
    }

    // Finally, set the sprite to use the image.
    measureTicksSprite.loadGraphic(measureTickBitmap);

    // Destroy these so they get rebuilt with the right theme later.
    measureNumbers.forEach(function(measureNumber:FlxText)
    {
      measureNumber.destroy();
    });
    measureNumbers.clear();
    // Destroy these so they get rebuilt with the right theme later.
    measureDividers.forEach(function(measureDivider:FlxSprite)
    {
      measureDivider.destroy();
    });
    measureDividers.clear();
  }

  // The last measure number we updated the ticks on.
  var previousMeasure:Int = -1;

  function updateMeasureNumbers(force:Bool = false):Void
  {
    if (chartEditorState == null || Conductor.instance == null) return;

    // Get the time at the top of the screen, in measures, rounded down.
    // This is the earliest measure we'll need to display a tick for.
    var currentMeasure:Int = Math.floor(Conductor.instance.getTimeInMeasures(chartEditorState.scrollPositionInMs));
    if (previousMeasure == currentMeasure && !force) return;
    if (currentMeasure < 0) currentMeasure = previousMeasure = 0;
    else
      previousMeasure = currentMeasure;

    // Remove existing measure numbers.
    measureNumbers.forEachAlive(function(measureNumber:FlxText)
    {
      measureNumber.kill();
    });
    measureDividers.forEachAlive(function(measureDivider:FlxSprite)
    {
      measureDivider.kill();
    });

    final ARBITRARY_LIMIT = 5;

    for (i in 0...ARBITRARY_LIMIT)
    {
      // NOTE: i = 0 when rendering Measure 1 here.
      var targetMeasure:Int = currentMeasure + i - 1;
      if (targetMeasure < 0) continue;

      var measureTimeInMs:Float = Conductor.instance.getMeasureTimeInMs(targetMeasure);

      var measureTimeInSteps:Float = Conductor.instance.getTimeInSteps(measureTimeInMs);
      var measureTimeInPixels:Float = measureTimeInSteps * ChartEditorState.GRID_SIZE;

      // If we've gone past the end of the song, we're done.
      if (measureTimeInPixels > chartEditorState.songLengthInPixels) break;

      // Handle the case where the measure at the end of the song is too short to display a measure number.
      final MIN_MEASURE_HEIGHT:Float = 24; // The minimum height of a measure, in pixels, in order for a measure number to display.
      var shouldDisplayMeasureNumber:Bool = measureTimeInPixels + MIN_MEASURE_HEIGHT <= chartEditorState.songLengthInPixels;
      var shouldDisplayMeasureDivider:Bool = true;

      var relativeMeasureTimeInPixels:Float = measureTimeInPixels + this.y;

      final SCREEN_PADDING:Float = ChartEditorState.GRID_SIZE / 2;

      // Below the visible area, quit it.
      if (relativeMeasureTimeInPixels > FlxG.height + SCREEN_PADDING)
      {
        break;
      }

      // Else, display a number and divider.

      if (shouldDisplayMeasureNumber)
      {
        // Reuse an existing number. If we need a new number, create one with makeMeasureNumber().
        final REVIVE:Bool = true;
        var measureNumber = measureNumbers.recycle(makeMeasureNumber, false, REVIVE);

        // Measures are base ZERO gah!
        final OFFSET = 2;
        measureNumber.text = '${targetMeasure + 1}';
        measureNumber.y = relativeMeasureTimeInPixels + OFFSET;
        measureNumber.x = this.x;
      }

      if (shouldDisplayMeasureDivider)
      {
        // Reuse an existing divider. If we need a new divider, create one with makeMeasureDivider().
        final REVIVE:Bool = true;
        var measureDivider = measureDividers.recycle(makeMeasureDivider, false, REVIVE);
        measureDivider.y = relativeMeasureTimeInPixels - (ChartEditorThemeHandler.MEASURE_TICKS_MEASURE_WIDTH / 2);
        measureDivider.x = this.x + (measureTicksSprite.width);
      }
    }
  }

  function makeMeasureNumber():FlxText
  {
    var measureNumber = new FlxText(0, 0, ChartEditorState.GRID_SIZE, "1");
    measureNumber.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE);
    measureNumber.borderStyle = FlxTextBorderStyle.OUTLINE;
    measureNumber.borderColor = FlxColor.BLACK;
    return measureNumber;
  }

  function makeMeasureDivider():FlxSprite
  {
    var dividerColor:FlxColor = switch (chartEditorState.currentTheme)
    {
      case Light: ChartEditorThemeHandler.GRID_MEASURE_DIVIDER_COLOR_LIGHT;
      case Dark: ChartEditorThemeHandler.GRID_MEASURE_DIVIDER_COLOR_DARK;
      default: ChartEditorThemeHandler.GRID_MEASURE_DIVIDER_COLOR_LIGHT;
    };

    var measureDivider = new FunkinSprite().makeSolidColor(ChartEditorState.GRID_SIZE * ChartEditorThemeHandler.TOTAL_COLUMN_COUNT,
      ChartEditorThemeHandler.MEASURE_TICKS_MEASURE_WIDTH, dividerColor);
    return measureDivider;
  }
}
#end
