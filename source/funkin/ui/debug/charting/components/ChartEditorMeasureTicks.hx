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
  var measureNumber:FlxText;

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

    measureNumber = new FlxText(0, 0, ChartEditorState.GRID_SIZE, "1");
    measureNumber.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE);
    measureNumber.borderStyle = FlxTextBorderStyle.OUTLINE;
    measureNumber.borderColor = FlxColor.BLACK;
    add(measureNumber);
  }

  public function reloadTickBitmap():Void
  {
    tickTiledSprite.loadGraphic(chartEditorState.measureTickBitmap);
  }

  /**
   * At time of writing, we only have to manipulate one measure number because we can only see one measure at a time.
   */
  function updateMeasureNumber()
  {
    if (measureNumber == null) return;

    var viewTopPosition = 0 - this.y;
    var viewHeight = FlxG.height - ChartEditorState.MENU_BAR_HEIGHT - ChartEditorState.PLAYBAR_HEIGHT;
    var viewBottomPosition = viewTopPosition + viewHeight;

    var measureNumberInViewport = Math.floor(viewTopPosition / ChartEditorState.GRID_SIZE / Conductor.instance.stepsPerMeasure) + 1;
    var measureNumberPosition = measureNumberInViewport * ChartEditorState.GRID_SIZE * Conductor.instance.stepsPerMeasure;

    measureNumber.y = measureNumberPosition + this.y;

    // Show the measure number only if it isn't beneath the end of the note grid.
    // Using measureNumber + 1 because the cut-off bar at the bottom is technically a bar, but it looks bad if a measure number shows up there.
    if ((measureNumberInViewport + 1) < chartEditorState.songLengthInSteps / Conductor.instance.stepsPerMeasure)
      measureNumber.text = '${measureNumberInViewport + 1}';
    else
      measureNumber.text = '';

    // trace(measureNumber.text + ' at ' + measureNumber.y);
  }

  public function setHeight(songLengthInPixels:Float):Void
  {
    tickTiledSprite.height = songLengthInPixels;
  }
}
