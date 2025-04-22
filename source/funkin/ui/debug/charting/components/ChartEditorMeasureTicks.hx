package funkin.ui.debug.charting.components;

import flixel.FlxSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorMeasureTicks extends FlxTypedSpriteGroup<FlxSprite>
{
  var chartEditorState:ChartEditorState;

  var tickTiledSprite:FlxTiledSprite;
  var measureNumbers:Array<FlxText> = [];

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

    tickTiledSprite = new FlxTiledSprite(chartEditorState.measureTickBitmap, chartEditorState.measureTickBitmap.width, 1000, false, true);
    add(tickTiledSprite);

    for (i in 0...5)
    {
      var measureNumber = new FlxText(0, 0, ChartEditorState.GRID_SIZE, "1");
      measureNumber.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE);
      measureNumber.borderStyle = FlxTextBorderStyle.OUTLINE;
      measureNumber.borderColor = FlxColor.BLACK;
      add(measureNumber);
      measureNumbers.push(measureNumber);
    }
  }

  public function reloadTickBitmap():Void
  {
    tickTiledSprite.loadGraphic(chartEditorState.measureTickBitmap);
  }

  /**
   * Update all 5 measure numbers, since that's the most we can really see at a time, even if barely.
   * Please excuse the horror you're about to witness.
   */
  function updateMeasureNumber()
  {
    var currentPixelScrollPositionInMs = Conductor.instance?.getStepTimeInMs((this.chartEditorState?.scrollPositionInPixels + 1) / ChartEditorState.GRID_SIZE);
    var measureNumberInViewport = Math.floor(Conductor.instance?.getTimeInMeasures(currentPixelScrollPositionInMs));

    for (i in 0...measureNumbers.length)
    {
      var measureNumber:FlxText = measureNumbers[i];
      if (measureNumber == null) continue;

      var measureNumberPosition = Math.floor(Conductor.instance?.getTimeInSteps(Conductor.instance?.getMeasureTimeInMs(measureNumberInViewport +
        i)) * ChartEditorState.GRID_SIZE);

      measureNumber.y = measureNumberPosition + this.y;

      // Show the measure number only if it isn't beneath the end of the note grid.
      // Using measureNumber + 1 because the cut-off bar at the bottom is technically a bar, but it looks bad if a measure number shows up there.
      var fixedMeasureNumberValue = measureNumberInViewport + i + 1;
      if (fixedMeasureNumberValue < Math.ceil(Conductor.instance?.getTimeInMeasures(chartEditorState.songLengthInMs)))
        measureNumber.text = '${fixedMeasureNumberValue}';
      else
        measureNumber.text = '';
    }
  }

  public function setHeight(songLengthInPixels:Float):Void
  {
    tickTiledSprite.height = songLengthInPixels;
  }
}
