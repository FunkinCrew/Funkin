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

    measureNumber.text = '${measureNumberInViewport + 1}';
    measureNumber.y = measureNumberPosition + this.y;

    // trace(measureNumber.text + ' at ' + measureNumber.y);
  }

  public function setHeight(songLengthInPixels:Float):Void
  {
    tickTiledSprite.height = songLengthInPixels;
  }
}
