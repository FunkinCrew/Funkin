package funkin.ui.debug;

import flixel.util.FlxStringUtil;
import funkin.util.MemoryUtil;
import funkin.ui.debug.stats.FunkinStatsGraph;
import haxe.Timer;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * A debug overlay showing useful info.
 */
class FunkinDebugDisplay extends Sprite
{
  static final FPS_UPDATE_DELAY:Int = 200;

  var canUpdate:Bool;
  var deltaTimeout:Float;
  var times:Array<Float>;

  #if !html5
  var gcMemPeak:Float;
  var taskMemPeak:Float;
  #end

  var onePercFPS:Int;

  var textDisplay:TextField;

  var fpsGraph:FunkinStatsGraph;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
  {
    super();

    this.x = x;
    this.y = y;
    this.canUpdate = true;
    this.deltaTimeout = 0.0;
    this.gcMemPeak = 0.0;
    this.taskMemPeak = 0.0;
    this.times = [];

    textDisplay = new TextField();
    textDisplay.width = 500;
    textDisplay.selectable = false;
    textDisplay.mouseEnabled = false;
    textDisplay.defaultTextFormat = new TextFormat("Monsterrat", 12, color, JUSTIFY);
    textDisplay.antiAliasType = NORMAL;
    textDisplay.sharpness = 100;
    textDisplay.multiline = true;
    addChild(textDisplay);

    fpsGraph = new FunkinStatsGraph(0, 110, 100, 25, color, "FPS Graph:");
    fpsGraph.maxValue = FlxG.drawFramerate;
    fpsGraph.minValue = 0;
    addChild(fpsGraph);

    FlxG.signals.focusGained.add(function():Void {
      canUpdate = true;
    });

    FlxG.signals.focusLost.add(function():Void {
      canUpdate = false;
    });

    updateDisplay();
  }

  override function __enterFrame(deltaTime:Float):Void
  {
    if (!canUpdate) return;

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

    updateDisplay(times.length, Math.floor(fpsGraph.average()));

    deltaTimeout = 0.0;
  }

  function updateDisplay(?currentFPS:Int = 0, ?averageFPS:Int = 0):Void
  {
    final info:Array<String> = [];

    info.push('FPS: $currentFPS');

    info.push('AVG FPS: $averageFPS');

    if (onePercFPS < currentFPS - averageFPS) onePercFPS = currentFPS;
    else if (onePercFPS > currentFPS) onePercFPS = currentFPS;

    info.push('1% LOW FPS: $onePercFPS');

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
