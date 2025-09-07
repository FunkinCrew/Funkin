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
  static final OUTER_RECT_DIMENSIONS:Array<Int> = [234, 201];
  static final OTHERS_OFFSET:Int = 8;

  var currentFPS:Int;
  var deltaTimeout:Float;
  var times:Array<Float>;
  var color:Int;

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

  public var isAdvanced(default, set):Bool = false;

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
    this.color = color;
    this.isAdvanced = false;
  }

  public function set_isAdvanced(value:Bool):Bool
  {
    buildDebugDisplay(value);

    return isAdvanced = value;
  }

  public function buildDebugDisplay(advanced:Bool):Void
  {
    removeChildren(0, numChildren);

    final BG_HEIGHT_MULTIPLIER:Float = advanced ? 1 : (MemoryUtil.supportsTaskMem()) ? 0.3 : 0.2;
    background = new Shape();
    background.graphics.beginFill(0x3d3f41, 0.5);
    background.graphics.drawRect(0, 0, OUTER_RECT_DIMENSIONS[0] + (INNER_RECT_DIFF * 2),
      (OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER) + (INNER_RECT_DIFF * 2));
    background.graphics.endFill();
    background.graphics.beginFill(0x2c2f30, 0.5);
    background.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF, OUTER_RECT_DIMENSIONS[0], OUTER_RECT_DIMENSIONS[1] * BG_HEIGHT_MULTIPLIER);
    background.graphics.endFill();
    addChild(background);

    if (advanced)
    {
      createAdvancedElements();

      updateFPSGraph();
      updateGcMemGraph();
      updateTaskMemGraph();
      updateAdvancedDisplay();
    }
    else
    {
      createSimpleElements();
      updateSimpleDisplay();
    }
  }

  function createAdvancedElements():Void
  {
    final graphsWidth:Int = OUTER_RECT_DIMENSIONS[0] + (INNER_RECT_DIFF * 2) - (OTHERS_OFFSET * 3);
    final graphsHeight:Int = 25;

    fpsGraph = new FunkinStatsGraph(OTHERS_OFFSET, OTHERS_OFFSET + 49, graphsWidth, graphsHeight, color);
    fpsGraph.textDisplay.y = -49;
    fpsGraph.minValue = 0;
    addChild(fpsGraph);

    #if !html5
    gcMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (fpsGraph.y + fpsGraph.axisHeight) + 22), graphsWidth, graphsHeight, color);
    gcMemGraph.minValue = 0;
    addChild(gcMemGraph);

    if (MemoryUtil.supportsTaskMem())
    {
      taskMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (gcMemGraph.y + gcMemGraph.axisHeight) + 22), graphsWidth, graphsHeight,
        color);
      taskMemGraph.minValue = 0;
      addChild(taskMemGraph);
    }
    #end
  }

  function createSimpleElements():Void
  {
    infoDisplay = new TextField();
    infoDisplay.x = OTHERS_OFFSET;
    infoDisplay.y = OTHERS_OFFSET;
    infoDisplay.width = 500;
    infoDisplay.selectable = false;
    infoDisplay.mouseEnabled = false;
    infoDisplay.defaultTextFormat = new TextFormat('Monsterrat', 12, color, JUSTIFY);
    infoDisplay.antiAliasType = NORMAL;
    infoDisplay.sharpness = 100;
    infoDisplay.multiline = true;

    addChild(infoDisplay);
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

    if (isAdvanced)
    {
      updateFPSGraph();
      updateGcMemGraph();
      updateTaskMemGraph();
      updateAdvancedDisplay();
    }
    else
    {
      updateSimpleDisplay();
    }

    deltaTimeout = 0.0;
  }

  function updateAdvancedDisplay():Void
  {
    final info:Array<String> = [];
    info.push('FPS: $currentFPS');
    info.push('AVG FPS: ${Math.floor(fpsGraph.average())}');
    info.push('1% LOW FPS: ${Math.floor(fpsGraph.lowest())}');
    fpsGraph.textDisplay.text = info.join('\n');

    #if !html5
    gcMemGraph.textDisplay.text = 'GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}';

    if (taskMemGraph != null)
    {
      taskMemGraph.textDisplay.text = 'TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}';
    }
    #end
  }

  function updateSimpleDisplay():Void
  {
    if (infoDisplay == null) return;

    final info:Array<String> = [];

    info.push('FPS: $currentFPS');

    #if !html5
    gcMem = MemoryUtil.getGCMemory();

    if (gcMem > gcMemPeak)
    {
      gcMemPeak = gcMem;
    }

    info.push('GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}');

    if (MemoryUtil.supportsTaskMem())
    {
      taskMem = MemoryUtil.getTaskMemory();

      if (taskMem > taskMemPeak)
      {
        taskMemPeak = taskMem;
      }

      info.push('TASK MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}');
    }
    #end

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

enum abstract DebugDisplayMode(Int) from Int to Int
{
  /**
   * Debug display is disabled.
   */
  var OFF = 0;

  /**
   * Simple debug display.
   * FPS and Memory counters only.
   */
  var SIMPLE = 1;

  /**
   * Advanced debug display.
   * Full FPS and Memory info.
   */
  var ADVANCED = 2;
}
