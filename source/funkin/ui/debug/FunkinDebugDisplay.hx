package funkin.ui.debug;

import flixel.util.FlxStringUtil;
import funkin.util.MemoryUtil;
import funkin.ui.debug.stats.FunkinStatsGraph;
import haxe.Timer;
import openfl.display.Sprite;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * A debug overlay showing useful info.
 */
class FunkinDebugDisplay extends Sprite
{
  static final FPS_UPDATE_DELAY:Int = 200;
  static final INNER_RECT_DIFF:Int = 3;
  static final OUTER_RECT_DIMENSIONS:Array<Int> = [215, 150];

  var deltaTimeout:Float;
  var times:Array<Float>;

  #if !html5
  var gcMemPeak:Float;
  var taskMemPeak:Float;
  #end

  var background:Shape;

  var textDisplay:TextField;

  var fpsGraph:FunkinStatsGraph;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
  {
    super();

    this.x = x;
    this.y = y;
    this.deltaTimeout = 0.0;
    this.gcMemPeak = 0.0;
    this.taskMemPeak = 0.0;
    this.times = [];

    final background:Shape = new Shape();
    background.graphics.beginFill(0x3d3f41, 0.5);
    background.graphics.drawRect(0, 0, OUTER_RECT_DIMENSIONS[0] + (INNER_RECT_DIFF * 2), OUTER_RECT_DIMENSIONS[1] + (INNER_RECT_DIFF * 2));
    background.graphics.endFill();
    background.graphics.beginFill(0x2c2f30, 0.5);
    background.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF, OUTER_RECT_DIMENSIONS[0], OUTER_RECT_DIMENSIONS[1]);
    background.graphics.endFill();
    addChild(background);

    final othersOffset:Int = 8;

    textDisplay = new TextField();
    textDisplay.x += othersOffset;
    textDisplay.y += othersOffset;
    textDisplay.width = 500;
    textDisplay.selectable = false;
    textDisplay.mouseEnabled = false;
    textDisplay.defaultTextFormat = new TextFormat("Monsterrat", 12, color, JUSTIFY);
    textDisplay.antiAliasType = NORMAL;
    textDisplay.sharpness = 100;
    textDisplay.multiline = true;
    addChild(textDisplay);

    fpsGraph = new FunkinStatsGraph(othersOffset, 110 + othersOffset, 100, 25, color, "FPS Graph:");
    fpsGraph.maxValue = FlxG.drawFramerate;
    fpsGraph.minValue = 0;
    addChild(fpsGraph);

    updateDisplay();
  }

  override function __enterFrame(deltaTime:Float):Void
  {
    final currentTime:Float = Timer.stamp() * 1000;

    times.push(currentTime);

    while (times[0] < currentTime - 1000)
    {
      times.shift();
    }

    if (deltaTimeout < FPS_UPDATE_DELAY)
    {
      deltaTimeout += deltaTime;
      return;
    }

    fpsGraph.update(times.length);

    updateDisplay(times.length, Math.floor(fpsGraph.average()), Math.floor(fpsGraph.lowest()));

    deltaTimeout = 0.0;
  }

  function updateDisplay(?currentFPS:Int = 0, ?averageFPS:Int = 0, ?lowestFPS:Int = 0):Void
  {
    final info:Array<String> = [];

    info.push('FPS: $currentFPS');

    info.push('AVG FPS: $averageFPS');

    info.push('1% LOW FPS: $lowestFPS');

    #if !html5
    final gcMem:Float = MemoryUtil.getGCMemory();

    if (gcMem > gcMemPeak)
    {
      gcMemPeak = gcMem;
    }

    info.push('GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}');

    if (MemoryUtil.supportsTaskMem())
    {
      final taskMem:Float = MemoryUtil.getTaskMemory();

      if (taskMem > taskMemPeak)
      {
        taskMemPeak = taskMem;
      }

      info.push('TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}');
    }
    #end

    textDisplay.text = info.join('\n');
  }
}
