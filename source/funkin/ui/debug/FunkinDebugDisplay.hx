package funkin.ui.debug;

import flixel.util.FlxStringUtil;
import funkin.FunkinMemory;
import funkin.ui.debug.stats.FunkinStatsGraph;
import funkin.util.MemoryUtil;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * A debug overlay showing useful info.
 */
#if cpp
@:access(lime._internal.backend.native.NativeCFFI)
#end
class FunkinDebugDisplay extends Sprite
{
  static final UPDATE_DELAY:Int = 100;
  static final INNER_RECT_DIFF:Int = 3;
  static final OUTER_RECT_DIMENSIONS:Array<Int> = [234, 201];
  static final OTHERS_OFFSET:Int = 8;
  static final ADVANCED_FPS_INFO_HEIGHT:Int = 73;

  /**
   * Indicates whether the debug display is in advanced mode.
   */
  public var isAdvanced(default, set):Bool = false;

  /**
   * The opacity of the debug display's background.
   */
  public var backgroundOpacity(default, set):Float = 0.5;

  var currentFPS:Int;
  var deltaTimeout:Float;
  var times:Array<Float>;
  var timesHead:Int;
  var color:Int;

  #if !html5
  var gcMem:Float;
  var gcMemPeak:Float;

  var vramMem:Float;
  var vramMemPeak:Float;

  var taskMem:Float;
  var taskMemPeak:Float;
  #end

  var background:Shape;

  var fpsGraph:FunkinStatsGraph;
  var gcMemGraph:FunkinStatsGraph;
  var vramMemGraph:FunkinStatsGraph;
  var taskMemGraph:FunkinStatsGraph;

  var infoDisplay:TextField;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000):Void
  {
    super();

    this.x = x;
    this.y = y;
    this.currentFPS = 0;
    this.deltaTimeout = 0.0;
    #if !html5
    this.gcMem = 0.0;
    this.gcMemPeak = 0.0;
    this.vramMem = 0.0;
    this.vramMemPeak = 0.0;
    this.taskMem = 0.0;
    this.taskMemPeak = 0.0;
    #end
    this.times = [];
    this.timesHead = 0;
    this.color = color;
    this.backgroundOpacity = 0;
    this.isAdvanced = false;
  }

  function buildDebugDisplay(advanced:Bool):Void
  {
    removeChildren(0, numChildren);

    final BG_WIDTH_MULTIPLIER:Float = #if html5 advanced ? 1 : 0.3 #else 1 #end;
    final backgroundWidth:Float = OUTER_RECT_DIMENSIONS[0] * BG_WIDTH_MULTIPLIER;
    final backgroundHeight:Float = calculateBackgroundHeight(advanced);

    background = new Shape();
    background.graphics.beginFill(0x3d3f41, 1);
    background.graphics.drawRect(0, 0, backgroundWidth + (INNER_RECT_DIFF * 2), backgroundHeight + (INNER_RECT_DIFF * 2));
    background.graphics.endFill();
    background.graphics.beginFill(0x2c2f30, 1);
    background.graphics.drawRect(INNER_RECT_DIFF, INNER_RECT_DIFF, backgroundWidth, backgroundHeight);
    background.graphics.endFill();
    background.alpha = backgroundOpacity;
    addChild(background);

    if (advanced)
    {
      createAdvancedElements();
      updateAdvancedDisplay();
    }
    else
    {
      createSimpleElements();
      updateSimpleDisplay();
    }
  }

  function calculateBackgroundHeight(advanced:Bool):Float
  {
    #if html5
    return OUTER_RECT_DIMENSIONS[1] * (advanced ? 0.45 : 0.15);
    #else
    if (!advanced)
    {
      return OUTER_RECT_DIMENSIONS[1] * (MemoryUtil.supportsTaskMem() ? 0.42 : 0.30);
    }

    var graphCount:Int = 3; // FPS + GC + VRAM.
    if (MemoryUtil.supportsTaskMem()) graphCount++;
    return OTHERS_OFFSET + ADVANCED_FPS_INFO_HEIGHT + (graphCount * 25) + ((graphCount - 1) * 22) + OTHERS_OFFSET;
    #end
  }

  function createAdvancedElements():Void
  {
    final graphsWidth:Int = OUTER_RECT_DIMENSIONS[0] + (INNER_RECT_DIFF * 2) - (OTHERS_OFFSET * 3);
    final graphsHeight:Int = 25;

    fpsGraph = new FunkinStatsGraph(OTHERS_OFFSET, OTHERS_OFFSET + ADVANCED_FPS_INFO_HEIGHT, graphsWidth, graphsHeight, color);
    fpsGraph.textDisplay.y = -ADVANCED_FPS_INFO_HEIGHT;
    fpsGraph.minValue = 0;
    addChild(fpsGraph);

    #if !html5
    gcMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (fpsGraph.y + fpsGraph.axisHeight) + 22), graphsWidth, graphsHeight, color);
    gcMemGraph.minValue = 0;
    addChild(gcMemGraph);

    vramMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (gcMemGraph.y + gcMemGraph.axisHeight) + 22), graphsWidth, graphsHeight, color);
    vramMemGraph.minValue = 0;
    addChild(vramMemGraph);

    if (MemoryUtil.supportsTaskMem())
    {
      taskMemGraph = new FunkinStatsGraph(OTHERS_OFFSET, Math.floor(OTHERS_OFFSET + (vramMemGraph.y + vramMemGraph.axisHeight) + 22), graphsWidth, graphsHeight,
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
    infoDisplay.multiline = true;
    addChild(infoDisplay);
  }

  override function __enterFrame(deltaTime:Int):Void
  {
    #if cpp
    final currentTime:Float = lime._internal.backend.native.NativeCFFI.lime_sdl_get_ticks();
    #elseif html5
    final currentTime:Float = js.Browser.window.performance.now();
    #else
    final currentTime:Float = haxe.Timer.stamp() * 1000;
    #end

    times.push(currentTime);
    // Use a moving head index to avoid per-frame O(n) shifts.
    var cutoff:Float = currentTime - 1000;
    while (timesHead < times.length && times[timesHead] < cutoff) timesHead++;
    if (timesHead >= 256 && timesHead * 2 >= times.length)
    {
      times = times.slice(timesHead);
      timesHead = 0;
    }

    if (deltaTimeout < UPDATE_DELAY)
    {
      deltaTimeout += deltaTime;
      return;
    }

    currentFPS = times.length - timesHead;

    #if !html5
    gcMem = MemoryUtil.getGCMemory();
    vramMem = FunkinMemory.getEstimatedTextureVRAM();

    if (gcMem > gcMemPeak) gcMemPeak = gcMem;
    if (vramMem > vramMemPeak) vramMemPeak = vramMem;

    if (MemoryUtil.supportsTaskMem())
    {
      taskMem = MemoryUtil.getTaskMemory();

      if (taskMem > taskMemPeak) taskMemPeak = taskMem;
    }
    #end

    if (isAdvanced)
    {
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
    updateFPSGraph();
    #if !html5
    updateGcMemGraph();
    updateVramMemGraph();
    updateTaskMemGraph();
    #end

    final info:Array<String> = [];
    var onePercentLowFPS:Float = fpsGraph.lowPercentileNonZero(0.01);
    var pointOnePercentLowFPS:Float = fpsGraph.lowPercentileNonZero(0.001);
    if (onePercentLowFPS <= 0) onePercentLowFPS = currentFPS;
    if (pointOnePercentLowFPS <= 0) pointOnePercentLowFPS = onePercentLowFPS;
    info.push('FPS: $currentFPS');
    info.push('AVG FPS: ${Math.floor(fpsGraph.averageNonZero())}');
    info.push('1% LOW FPS: ${Math.floor(onePercentLowFPS)}');
    info.push('0.1% LOW FPS: ${Math.floor(pointOnePercentLowFPS)}');
    info.push('CACHE: ${FunkinMemory.runtimeCacheProfile}');
    fpsGraph.textDisplay.text = info.join('\n');

    #if !html5
    gcMemGraph.textDisplay.text = 'GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}';
    vramMemGraph.textDisplay.text = 'VRAM EST: ${FlxStringUtil.formatBytes(vramMem).toLowerCase()} / ${FlxStringUtil.formatBytes(vramMemPeak).toLowerCase()}';

    if (taskMemGraph != null)
    {
      taskMemGraph.textDisplay.text = 'RAM MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}';
    }
    #end
  }

  function updateSimpleDisplay():Void
  {
    if (infoDisplay != null)
    {
      final info:Array<String> = [];

      info.push('FPS: $currentFPS');

      #if !html5
      info.push('CACHE: ${FunkinMemory.runtimeCacheProfile}');
      info.push('GC MEM: ${FlxStringUtil.formatBytes(gcMem).toLowerCase()} / ${FlxStringUtil.formatBytes(gcMemPeak).toLowerCase()}');
      info.push('VRAM EST: ${FlxStringUtil.formatBytes(vramMem).toLowerCase()} / ${FlxStringUtil.formatBytes(vramMemPeak).toLowerCase()}');

      if (MemoryUtil.supportsTaskMem())
        info.push('RAM MEM: ${FlxStringUtil.formatBytes(taskMem).toLowerCase()} / ${FlxStringUtil.formatBytes(taskMemPeak).toLowerCase()}');
      #end

      infoDisplay.text = info.join('\n');
    }
  }

  function updateFPSGraph(?currentFPS:Int = 0):Void
  {
    fpsGraph.maxValue = FlxG.drawFramerate;
    fpsGraph.update(this.currentFPS);
  }

  #if !html5
  function updateGcMemGraph(?currentFPS:Int = 0):Void
  {
    gcMemGraph.maxValue = gcMemPeak;
    gcMemGraph.update(gcMem);
  }

  function updateVramMemGraph(?currentFPS:Int = 0):Void
  {
    if (vramMemGraph != null)
    {
      vramMemGraph.maxValue = vramMemPeak;
      vramMemGraph.update(vramMem);
    }
  }

  function updateTaskMemGraph(?currentFPS:Int = 0):Void
  {
    if (taskMemGraph != null)
    {
      taskMemGraph.maxValue = taskMemPeak;
      taskMemGraph.update(taskMem);
    }
  }
  #end

  function set_isAdvanced(value:Bool):Bool
  {
    buildDebugDisplay(value);

    return isAdvanced = value;
  }

  function set_backgroundOpacity(value:Float):Float
  {
    if (background != null) background.alpha = value;

    return backgroundOpacity = value;
  }
}

// Note: the string values here are deduced
// so we dont need to do `Off = 'Off'` or nothin
// https://haxe.org/manual/types-abstract-enum.html
enum abstract DebugDisplayMode(String) from String to String
{
  /**
   * Debug display is disabled.
   */
  var Off;

  /**
   * Simple debug display.
   * FPS and Memory counters only.
   */
  var Simple;

  /**
   * Advanced debug display.
   * Full FPS and Memory info.
   */
  var Advanced;
}
