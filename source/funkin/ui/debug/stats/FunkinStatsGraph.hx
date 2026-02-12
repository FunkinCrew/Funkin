package funkin.ui.debug.stats;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

class FunkinStatsGraph extends Sprite
{
  static inline var AXIS_COLOR:FlxColor = 0xffffff;
  static inline var AXIS_ALPHA:Float = 0.5;
  static inline var HISTORY_MAX:Int = 1000;

  public var minValue:Float = FlxMath.MAX_VALUE_FLOAT;

  public var maxValue:Float = FlxMath.MIN_VALUE_FLOAT;

  public var graphColor:FlxColor;

  public var history:Array<Float> = [];
  var sortedHistory:Array<Float> = [];
  var historyDirty:Bool = true;

  public var textDisplay:TextField;

  public var axis:Shape;

  public var axisWidth:Int;

  public var axisHeight:Int;

  public function new(x:Int, y:Int, width:Int, height:Int, graphColor:FlxColor):Void
  {
    super();

    this.x = x;
    this.y = y;
    this.graphColor = graphColor;
    this.axisWidth = width;
    this.axisHeight = height;

    textDisplay = new TextField();
    textDisplay.width = 500;
    textDisplay.y -= 22;
    textDisplay.selectable = false;
    textDisplay.mouseEnabled = false;
    textDisplay.defaultTextFormat = new TextFormat('Monsterrat', 12, graphColor, JUSTIFY);
    textDisplay.antiAliasType = NORMAL;
    textDisplay.sharpness = 100;
    textDisplay.multiline = true;
    addChild(textDisplay);

    axis = new Shape();
    axis.x += 4;
    addChild(axis);

    drawAxes();
  }

  function drawAxes():Void
  {
    axis.graphics.clear();

    axis.graphics.lineStyle(1, AXIS_COLOR, AXIS_ALPHA, false, null, null, MITER, 255);

    axis.graphics.moveTo(0, 0);

    axis.graphics.lineTo(0, axisHeight);

    axis.graphics.moveTo(0, axisHeight);

    axis.graphics.lineTo(axisWidth, axisHeight);
  }

  function drawGraph():Void
  {
    graphics.clear();

    graphics.lineStyle(1, graphColor, 1, false, null, null, MITER, 255);

    if (history.length == 0)
    {
      return;
    }

    var inc:Float = (axisWidth - 2) / (HISTORY_MAX - 1);
    var range:Float = Math.max(maxValue - minValue, maxValue * 0.1);
    var scale:Float = axisHeight / range;

    for (i in 0...history.length)
    {
      final pointY:Float = axisHeight - ((history[i] - minValue) * scale) - 1;

      if (i == 0) graphics.moveTo(axis.x, pointY);

      graphics.lineTo(axis.x + 1 + (i * inc), pointY);
    }
  }

  public function update(value:Float):Void
  {
    history.push(value);

    if (history.length > HISTORY_MAX)
    {
      history.shift();
    }

    maxValue = Math.max(maxValue, value);
    minValue = Math.min(minValue, value);
    historyDirty = true;

    drawGraph();
  }

  public function average():Float
  {
    if (history.length == 0)
    {
      return 0;
    }

    var sum:Float = 0;

    for (v in history)
    {
      sum += v;
    }

    return sum / history.length;
  }

  public function averageNonZero():Float
  {
    if (history.length == 0) return 0;

    var sum:Float = 0;
    var count:Int = 0;
    for (v in history)
    {
      if (v <= 0) continue;
      sum += v;
      count++;
    }
    if (count == 0) return 0;
    return sum / count;
  }

  public function lowest():Float
  {
    if (history.length == 0) return 0;
    return getSortedHistory()[0];
  }

  public function lowPercentile(percent:Float):Float
  {
    if (history.length == 0) return 0;

    var clampedPercent:Float = Math.min(1.0, Math.max(0.0, percent));
    var sorted:Array<Float> = getSortedHistory();
    var index:Int = Std.int(Math.ceil(sorted.length * clampedPercent)) - 1;
    if (index < 0) index = 0;
    if (index >= sorted.length) index = sorted.length - 1;
    return sorted[index];
  }

  public function lowPercentileNonZero(percent:Float):Float
  {
    if (history.length == 0) return 0;

    var clampedPercent:Float = Math.min(1.0, Math.max(0.0, percent));
    var filtered:Array<Float> = [];
    for (value in history)
    {
      if (value > 0) filtered.push(value);
    }
    if (filtered.length == 0) return 0;

    filtered.sort(sortAscending);
    var index:Int = Std.int(Math.ceil(filtered.length * clampedPercent)) - 1;
    if (index < 0) index = 0;
    if (index >= filtered.length) index = filtered.length - 1;
    return filtered[index];
  }

  function getSortedHistory():Array<Float>
  {
    // Cache sorted samples so percentile lows do not sort every query.
    if (historyDirty)
    {
      sortedHistory = history.copy();
      sortedHistory.sort(sortAscending);
      historyDirty = false;
    }
    return sortedHistory;
  }

  static inline function sortAscending(a:Float, b:Float):Int
  {
    return (a < b) ? -1 : (a > b ? 1 : 0);
  }

  public function destroy():Void
  {
    if (axis != null)
    {
      removeChild(axis);
      axis = null;
    }

    history = null;
    sortedHistory = null;
  }
}
