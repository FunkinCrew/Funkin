package funkin.ui.debug.charting.components;

#if FEATURE_CHART_EDITOR
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorMeasureTicks extends FlxTypedSpriteGroup<FlxSprite>
{
  var chartEditorState:ChartEditorState;

  var measureTicksSprite:FlxSprite;
  var measureNumbers:Array<FlxText> = [];

  public var measureLengthsInPixels:Array<Int> = [];

  override function set_y(value:Float):Float
  {
    var result = super.set_y(value);

    updateMeasureNumber();

    return result;
  }

  public function new(chartEditorState:ChartEditorState)
  {
    super();

    this.chartEditorState = chartEditorState;

    measureTicksSprite = new FlxSprite(0, 0);
    add(measureTicksSprite);

    for (i in 0...5)
    {
      var measureNumber = new FlxText(0, 0, ChartEditorState.GRID_SIZE, "1");
      measureNumber.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE);
      measureNumber.borderStyle = FlxTextBorderStyle.OUTLINE;
      measureNumber.borderColor = FlxColor.BLACK;
      add(measureNumber);
      measureNumbers.push(measureNumber);
    }
    // Need these two lines or the ticks don't render before loading a chart!
    chartEditorState.updateMeasureTicks(true);
    reloadTickBitmap();
  }

  public function reloadTickBitmap():Void
  {
    measureTicksSprite.loadGraphic(chartEditorState.measureTickBitmap);
  }

  public function setClipRect(rect:Null<FlxRect>):Void
  {
    measureTicksSprite.clipRect = rect;
  }

  /**
   * Update all 5 measure numbers, since that's the most we can really see at a time, even if barely.
   * Please excuse the horror you're about to witness.
   * Welp, you gotta go back in commits to see it now.
   */
  function updateMeasureNumber()
  {
    if (measureLengthsInPixels.length == 0 || measureLengthsInPixels == null) return;

    var currentMeasure:Int = Math.floor(Conductor.instance?.getTimeInMeasures(chartEditorState.scrollPositionInMs));
    for (i in 0...measureNumbers.length)
    {
      var measureNumber:FlxText = measureNumbers[i];
      if (measureNumber == null) continue;

      var measureNumberPosition = measureLengthsInPixels[i];
      measureNumber.y = this.y + measureNumberPosition;

      // Show the measure number only if it isn't beneath the end of the note grid.
      // Using measureNumber + 1 because the cut-off bar at the bottom is technically a bar, but it looks bad if a measure number shows up there.
      var fixedMeasureNumberValue = currentMeasure + i + 1;
      if (fixedMeasureNumberValue < Math.ceil(Conductor.instance?.getTimeInMeasures(chartEditorState.songLengthInMs)))
        measureNumber.text = '${fixedMeasureNumberValue}';
      else
        measureNumber.text = '';
    }
  }
}
#end
