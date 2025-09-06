package funkin.ui.debug;

import haxe.Timer;
import openfl.display.Sprite;
import openfl.text.TextField;
import openfl.text.TextFormat;
import funkin.util.MemoryUtil;

class FunkinCounter extends Sprite
{
  static final FPS_UPDATE_DELAY:Int = 200;
  static final BYTES_PER_MEG:Float = 1024 * 1024;
  static final ROUND_TO:Float = 1 / 100;

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

  public var textDisplay:TextField;

  public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
  {
    super();

    this.x = x;
    this.y = y;

    textDisplay = new TextField();
    textDisplay.width = 500;
    textDisplay.selectable = false;
    textDisplay.mouseEnabled = false;
    textDisplay.defaultTextFormat = new TextFormat("_sans", 12, color);
    textDisplay.text = "";
    addChild(textDisplay);
  }

  @:noCompletion
  private override function __enterFrame(deltaTime:Float):Void
  {
    final currentTime:Float = Timer.stamp() * 1000;

    times.push(currentTime);

    frameCount++;

    while (times[0] < currentTime - 1000)
      times.shift();

    if (deltaTimeout < FPS_UPDATE_DELAY)
    {
      deltaTimeout += deltaTime;
      return;
    }

    currentFPS = times.length;

    averageFPS = Math.floor(frameCount / currentTime * 1000);

    if (onePercFPS < times.length / 10)
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
    var mem:Float = Math.fround(MemoryUtil.getMemoryUsed() / BYTES_PER_MEG / ROUND_TO) * ROUND_TO;

    if (mem > memPeak) memPeak = mem;

    textDisplay.text += '\nRAM: ${mem}mb / ${memPeak}mb';
    #end
  }
}
