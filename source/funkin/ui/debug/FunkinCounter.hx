package funkin.ui.debug;

import haxe.Timer;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.system.debug.stats.StatsGraph;
import flixel.util.FlxStringUtil;
import funkin.util.MemoryUtil;

class FunkinCounter extends Sprite
{
  static final FPS_UPDATE_DELAY:Int = 200;

  /**
    The current frame rate, expressed using frames-per-second.
  **/
  @:noCompletion
  private var currentFPS(default, null):Int = 0;

  /**
    The average frame rate.
  **/
  @:noCompletion
  private var averageFPS(default, null):Int = 0;

  /**
    The lowest frame rate.
  **/
  @:noCompletion
  private var onePercFPS(default, null):Int = 0;

  /**
    The peak of memory usage.
  **/
  @:noCompletion
  private var memPeak:Float = 0;

  @:noCompletion
  private var times:Array<Float> = [];

  @:noCompletion
  private var fpsValues:Array<Int> = [];

  @:noCompletion
  private var deltaTimeout:Float = 0;

  @:noCompletion
  private var frameCount:Int = 0;

  /**
   * The text which displays all the fps and memory info.
   */
  public var textDisplay:TextField;

  /**
   * A graph which outputs fps info.
   */
  public var fpsGraph:StatsGraph;

  private var canUpdateFPS:Bool = true;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
  {
    super();

    this.x = x;
    this.y = y;

    textDisplay = new TextField();
    textDisplay.width = 500;
    textDisplay.selectable = false;
    textDisplay.mouseEnabled = false;
    textDisplay.defaultTextFormat = new TextFormat("Monsterrat", 12, color);
    textDisplay.text = "";
    addChild(textDisplay);

    fpsGraph = new StatsGraph(0, 80, 75, 25, color, "FPS");
    fpsGraph.maxValue = FlxG.drawFramerate;
    fpsGraph.minValue = 0;
    addChild(fpsGraph);

    FlxG.signals.focusGained.add(() -> canUpdateFPS = true);
    FlxG.signals.focusLost.add(() -> canUpdateFPS = false);
  }

  @:noCompletion
  private override function __enterFrame(deltaTime:Float):Void
  {
    final currentTime:Float = Timer.stamp() * 1000;

    times.push(currentTime);

    frameCount++;

    while (times[0] < currentTime - 1000)
      times.shift();

    if (!canUpdateFPS) return;

    if (deltaTimeout < FPS_UPDATE_DELAY)
    {
      deltaTimeout += deltaTime;
      return;
    }

    currentFPS = times.length;

    fpsGraph.update(currentFPS);

    averageFPS = Math.floor(fpsGraph.average());

    if (onePercFPS < currentFPS - averageFPS)
    {
      onePercFPS = currentFPS;
    }
    else if (onePercFPS > currentFPS)
    {
      onePercFPS = currentFPS;
    }

    updateDisplay();

    deltaTimeout = 0.0;
  }

  private function updateDisplay():Void
  {
    textDisplay.text = "FPS: " + currentFPS;
    textDisplay.text += "\nAVG FPS: " + averageFPS;
    textDisplay.text += "\n1% LOW FPS: " + onePercFPS;

    #if !html5
    var mem:Float = MemoryUtil.getMemoryUsed();

    if (mem > memPeak) memPeak = mem;

    textDisplay.text += '\nRAM: ${FlxStringUtil.formatBytes(mem)} / ${FlxStringUtil.formatBytes(memPeak)}';
    #end
  }
}
