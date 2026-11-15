package funkin.ui.debug.charting.components.grid;

#if FEATURE_CHART_EDITOR
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;

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
   * The backing strip underneath the numbers.
   */
  var measureTicksSprite:FunkinSprite = new FunkinSprite();

  /**
   * The numbers that display the current measure number.
   * This is a group so we can kill and recycle its members.
   */
  var measureNumbers:FlxTypedSpriteGroup<FlxText> = new FlxTypedSpriteGroup<FlxText>();

  var ticksHeight:Float = ChartEditorState.GRID_SIZE * 16;

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

    buildMeasureTicksSprite();
    updateMeasureNumbers(true);
  }

  /**
   * Set the overall height of the measure ticks.
   * @param height The desired height in pixels.
   */
  public function setHeight(height:Float):Void
  {
    ticksHeight = height;
    measureTicksSprite.setGraphicSize(ChartEditorState.GRID_SIZE, Math.max(1, height) + FlxG.height * 2);
    measureTicksSprite.updateHitbox();
    measureTicksSprite.y = this.y - FlxG.height - chartEditorState.countdownLengthInPixels;
    updateMeasureNumbers(true);
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
      case Light:
        ChartEditorThemeHandler.MEASTURE_TICKS_BACKING_COLOR_LIGHT;
      case Dark:
        ChartEditorThemeHandler.MEASTURE_TICKS_BACKING_COLOR_DARK;
      default:
        ChartEditorThemeHandler.MEASTURE_TICKS_BACKING_COLOR_LIGHT;
    };
    measureTicksSprite.makeSolidColor(2, 2, backingColor);
    measureTicksSprite.setGraphicSize(ChartEditorState.GRID_SIZE, Math.max(1, ticksHeight) + FlxG.height * 2);
    measureTicksSprite.updateHitbox();
    measureTicksSprite.y = this.y - FlxG.height - chartEditorState.countdownLengthInPixels;

    // Destroy these so they get rebuilt with the right theme later.
    measureNumbers.forEach(function(measureNumber:FlxText)
    {
      measureNumber.destroy();
    });
    measureNumbers.clear();
  }

  // The last measure number we updated the ticks on.
  var previousMeasure:Int = -1;

  public function updateMeasureNumbers(force:Bool = false):Void
  {
    if (chartEditorState == null || Conductor.instance == null) return;

    // Get the time at the top of the screen, in measures, rounded down.
    // This is the earliest measure we'll need to display a tick for.
    var currentMeasure:Int = Math.floor(Conductor.instance.getTimeInMeasures(chartEditorState.scrollPositionInMs));
    if (previousMeasure == currentMeasure && !force) return;

    previousMeasure = currentMeasure;

    // Remove existing measure numbers.
    measureNumbers.forEachAlive(function(measureNumber:FlxText)
    {
      measureNumber.kill();
    });

    // The maximum number of measures to render at once.
    final MEASURE_LIMIT = 64;

    for (i in 0...MEASURE_LIMIT)
    {
      // NOTE: i = 0 when rendering Measure 1 here.
      var targetMeasure:Int = currentMeasure + i - 1;
      var measureTimeInMs:Float = Conductor.instance.getMeasureTimeInMs(targetMeasure);
      if (targetMeasure < 0)
      {
        // Display beat ticks for the countdown instead.
        var beatStart:Int = Math.floor(Conductor.instance.getTimeInSteps(measureTimeInMs) / Constants.STEPS_PER_BEAT);
        var beatEnd:Int = Math.floor(beatStart + Constants.STEPS_PER_BEAT);

        for (i in beatStart...beatEnd)
        {
          var beatTimeInPixels:Float = ChartEditorTimeScale.stepToPixels(i * Constants.STEPS_PER_BEAT);
          var display:String = '${Math.abs(i) - 1}';
          if (display == '0') display = 'Go!';

          placeMeasureNumber(beatTimeInPixels, display, true);
        }

        continue;
      }

      var measureTimeInPixels:Float = ChartEditorTimeScale.msToPixels(measureTimeInMs);

      // If we've gone past the end of the song, we're done.
      if (measureTimeInPixels > chartEditorState.songLengthInPixels) break;

      final SCREEN_PADDING:Float = FlxG.height;
      var relativeMeasureTimeInPixels:Float = measureTimeInPixels + this.y;

      // Far below the visible area, quit it.
      if (relativeMeasureTimeInPixels > FlxG.height + SCREEN_PADDING)
      {
        break;
      }

      placeMeasureNumber(measureTimeInPixels, '${targetMeasure + 1}');
    }
  }

  function placeMeasureNumber(height:Float, text:String, isCountdown:Bool = false)
  {
    // Handle the case where the measure at the end of the song is too short to display a measure number.
    final MIN_MEASURE_HEIGHT:Float = 24; // The minimum height of a measure, in pixels, in order for a measure number to display.
    var shouldDisplayMeasureNumber:Bool = height + MIN_MEASURE_HEIGHT <= chartEditorState.songLengthInPixels;

    if (!shouldDisplayMeasureNumber) return;

    // Else, display a number and divider.

    // Reuse an existing number. If we need a new number, create one with makeMeasureNumber().
    final REVIVE:Bool = true;
    var measureNumber = measureNumbers.recycle(makeMeasureNumber, false, REVIVE);

    // Measures are base ZERO gah!
    final OFFSET = 2;
    measureNumber.text = text;
    measureNumber.y = height + this.y + OFFSET;
    measureNumber.x = this.x;

    measureNumber.color = isCountdown ? FlxColor.YELLOW : FlxColor.WHITE;
  }

  function makeMeasureNumber():FlxText
  {
    var measureNumber:FlxText = new haxe.ui.backend.flixel.HiResFlxText(0, 0, ChartEditorState.GRID_SIZE, "1");
    measureNumber.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 20, FlxColor.WHITE);
    measureNumber.borderStyle = FlxTextBorderStyle.OUTLINE;
    measureNumber.borderColor = FlxColor.BLACK;
    return measureNumber;
  }
}
#end
