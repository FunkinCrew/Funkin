package funkin.util.plugins;

import flixel.FlxBasic;

/**
 * A plugin which keeps a smoothed frame time.
 */
@:nullSafety
class SmoothTimePlugin extends FlxBasic
{
  /**
   * How much each new frame counts towards the smoothed frame time.
   */
  static final SMOOTHING:Float = 0.1;

  static var smoothedFrameMs:Float = 0;

  public function new()
  {
    super();
  }

  public static function initialize():Void
  {
    FlxG.plugins.addPlugin(new SmoothTimePlugin());
  }

  /**
   * Half of the smoothed frame time, in milliseconds.
   */
  public static function getHalfFrameMs():Float
  {
    return smoothedFrameMs / 2;
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    var frameMs:Float = elapsed * Constants.MS_PER_SEC;

    if (smoothedFrameMs <= 0)
    {
      smoothedFrameMs = frameMs;
    }
    else
    {
      smoothedFrameMs += (Math.min(frameMs, smoothedFrameMs * 2) - smoothedFrameMs) * SMOOTHING;
    }
  }
}
