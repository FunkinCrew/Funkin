package funkin.ui.debug;

import flixel.util.FlxStringUtil;
import funkin.ui.debug.stats.FunkinStatsGraph;
import funkin.util.MemoryUtil;
import haxe.Timer;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * A debug overlay showing useful info.
 */
class FunkinDebugDisplay extends Sprite
{
  static final UPDATE_DELAY:Int = 100;
  static final INNER_RECT_DIFF:Int = 3;
  static final OUTER_RECT_DIMENSIONS:Array<Int> = [225, 200];
  static final OTHERS_OFFSET:Int = 8;

  var currentFPS:Int;
  var deltaTimeout:Float;
  var times:Array<Float>;

  #if !html5
  var gcMem:Float;
  var gcMemPeak:Float;

  var taskMem:Float;
  var taskMemPeak:Float;
  #end

  var background:Shape;

  var fpsGraph:FunkinStatsGraph;
  var gcMemGraph:FunkinStatsGraph;
  var taskMemGraph:FunkinStatsGraph;

  var infoDisplay:TextField;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
  {
    super();

    this.x = x;
    this.y = y;
    this.currentFPS = 0;
    this.deltaTimeout = 0.0;
    this.gcMem = 0.0;
    this.gcMemPeak = 0.0;
    this.taskMem = 0.0;
    this.taskMemPeak = 0.0;
    this.times = [];

    background = new Shape();
    background.graphics.beginFill(0x3d3f41, 0.5);
    background.graphics.drawRect(0, 0, OUTER_RECT_DIMENSIONS[0] + (INNER_RECT_DIFF * 2), OUTER_RECT_DIMENSIONS[1] + (INNER_RECT_DIFF * 2));
    background.graphics.endFill();
    background.graphics.beginFill(0x2c2f30, 0.5);
    background.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF, OUTER_RECT_DIMENSIONS[0], OUTER_RECT_DIMENSIONS[1]);
    background.graphics.endFill();
    addChild(background);

    fpsGraph = new FunkinStatsGraph(OTHERS_OFFSET, OTHERS_OFFSET + 22, 100, 25, color);
    fpsGraph.minValue = 0;
    addChild(fpsGraph);

    #if !html5
    gcMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (fpsGraph.y + fpsGraph.axisHeight) + 22), 100, 25, color);
    gcMemGraph.minValue = 0;
    addChild(gcMemGraph);

    if (MemoryUtil.supportsTaskMem())
    {
      taskMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (gcMemGraph.y + gcMemGraph.axisHeight) + 22), 100, 25, color);
      taskMemGraph.minValue = 0;
      addChild(taskMemGraph);
    }
    #end

    infoDisplay = new TextField();

    infoDisplay.x = OTHERS_OFFSET;

    if (taskMemGraph != null)
    {
      infoDisplay.y = taskMemGraph.y + taskMemGraph.axisHeight;
    }
    else if (gcMemGraph != null)
    {
      infoDisplay.y = gcMemGraph.y + gcMemGraph.axisHeight;
    }
    else
      infoDisplay.y = fpsGraph.y + fpsGraph.axisHeight;

    infoDisplay.width = 500;
    infoDisplay.selectable = false;
    infoDisplay.mouseEnabled = false;
    infoDisplay.defaultTextFormat = new TextFormat('Monsterrat', 12, color, JUSTIFY);
    infoDisplay.antiAliasType = NORMAL;
    infoDisplay.sharpness = 100;
    infoDisplay.multiline = true;

    addChild(infoDisplay);

    updateFPSGraph();
    updateGcMemGraph();
    updateTaskMemGraph();
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

    if (deltaTimeout < UPDATE_DELAY)
    {
      deltaTimeout += deltaTime;
      return;
    }

    currentFPS = times.length;

    updateFPSGraph();
    updateGcMemGraph();
    updateTaskMemGraph();
    updateDisplay();

    deltaTimeout = 0.0;
  }

  function updateDisplay():Void
  {
    fpsGraph.textDisplay.text = 'FPS: $currentFPS';

    #if !html5
    gcMemGraph.textDisplay.text = 'GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}';

    if (taskMemGraph != null)
    {
      taskMemGraph.textDisplay.text = 'TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}';
    }
    #end

    final info:Array<String> = [];
    info.push('AVG FPS: ${Math.floor(fpsGraph.average())}');
    info.push('1% LOW FPS: ${Math.floor(fpsGraph.lowest())}');
    infoDisplay.text = info.join('\n');
  }

  function updateFPSGraph(?currentFPS:Int = 0):Void
  {
    fpsGraph.maxValue = FlxG.drawFramerate;
    fpsGraph.update(times.length);
  }

  #if !html5
  function updateGcMemGraph(?currentFPS:Int = 0):Void
  {
    gcMem = MemoryUtil.getGCMemory();

    if (gcMem > gcMemPeak)
    {
      gcMemGraph.maxValue = gcMemPeak = gcMem;
    }

    gcMemGraph.update(gcMem);
  }

  function updateTaskMemGraph(?currentFPS:Int = 0):Void
  {
    if (taskMemGraph != null)
    {
      taskMem = MemoryUtil.getTaskMemory();

      if (taskMem > taskMemPeak)
      {
        taskMemGraph.maxValue = taskMemPeak = taskMem;
      }

      taskMemGraph.update(taskMem);
    }
  }
  #end
}
