package funkin.ui.debug.stats;

import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

/**
 * This is a modified StatsGraph class for Funkin.
 */
class FunkinStatsGraph extends Sprite
{
  static inline var AXIS_COLOR:FlxColor = 0xffffff;
  static inline var AXIS_ALPHA:Float = 0.5;
  static inline var HISTORY_MAX:Int = 100;

  public var minValue:Float = FlxMath.MAX_VALUE_FLOAT;
  public var maxValue:Float = FlxMath.MIN_VALUE_FLOAT;

  public var graphColor:FlxColor;

  public var history:Array<Float> = [];

  var textDisplay:TextField;

  var _axis:Shape;
  var _width:Int;
  var _height:Int;

  public function new(X:Int, Y:Int, Width:Int, Height:Int, GraphColor:FlxColor, name:String)
  {
    super();
    x = X;
    y = Y;
    _width = Width;
    _height = Height;
    graphColor = GraphColor;

    textDisplay = new TextField();
    textDisplay.y -= 22;
    textDisplay.width = 500;
    textDisplay.selectable = false;
    textDisplay.mouseEnabled = false;
    textDisplay.defaultTextFormat = new TextFormat('Monsterrat', 12, graphColor, JUSTIFY);
    textDisplay.antiAliasType = NORMAL;
    textDisplay.sharpness = 100;
    textDisplay.multiline = true;
    textDisplay.text = name;
    addChild(textDisplay);

    _axis = new Shape();
    _axis.x += 4;

    addChild(_axis);

    drawAxes();
  }

  /**
   * Redraws the axes of the graph.
   */
  function drawAxes():Void
  {
    var gfx = _axis.graphics;
    gfx.clear();
    gfx.lineStyle(1, AXIS_COLOR, AXIS_ALPHA);

    // y-Axis
    gfx.moveTo(0, 0);
    gfx.lineTo(0, _height);

    // x-Axis
    gfx.moveTo(0, _height);
    gfx.lineTo(_width, _height);
  }

  /**
   * Redraws the graph based on the values stored in the history.
   */
  function drawGraph():Void
  {
    var gfx:Graphics = graphics;
    gfx.clear();
    gfx.lineStyle(1, graphColor, 1);

    var inc:Float = _width / (HISTORY_MAX - 1);
    var range:Float = Math.max(maxValue - minValue, maxValue * 0.1);
    var graphX = _axis.x + 1;

    for (i in 0...history.length)
    {
      var value = (history[i] - minValue) / range;

      var pointY = (-value * _height - 1) + _height;
      if (i == 0) gfx.moveTo(graphX, _axis.y + pointY);
      gfx.lineTo(graphX + (i * inc), pointY);
    }
  }

  public function update(Value:Float):Void
  {
    history.unshift(Value);
    if (history.length > HISTORY_MAX) history.pop();

    // Update range
    maxValue = Math.max(maxValue, Value);
    minValue = Math.min(minValue, Value);

    drawGraph();
  }

  public function average():Float
  {
    var sum:Float = 0;
    for (value in history)
      sum += value;
    return sum / history.length;
  }

  public function lowest():Float
  {
    var val:Float = history[0] ?? 0;
    for (value in history)
    {
      if (value < val) val = value;
    }
    return val;
  }

  public function destroy():Void
  {
    _axis = FlxDestroyUtil.removeChild(this, _axis);
    textDisplay = FlxDestroyUtil.removeChild(this, textDisplay);
    history = null;
  }
}
