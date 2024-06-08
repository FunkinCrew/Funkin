package funkin.effects;

import flixel.FlxObject;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxPool;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.util.FlxAxes;
import flixel.tweens.FlxEase.EaseFunction;
import flixel.math.FlxMath;

/**
 * pretty much a copy of FlxFlicker geared towards making sprites
 * shake around at a set interval and slow down over time.
 */
class IntervalShake implements IFlxDestroyable
{
  static var _pool:FlxPool<IntervalShake> = new FlxPool<IntervalShake>(IntervalShake.new);

  /**
   * Internal map for looking up which objects are currently shaking and getting their shake data.
   */
  static var _boundObjects:Map<FlxObject, IntervalShake> = new Map<FlxObject, IntervalShake>();

  /**
   * An effect that shakes the sprite on a set interval and a starting intensity that goes down over time.
   *
   * @param   Object               The object to shake.
   * @param   Duration             How long to shake for (in seconds). `0` means "forever".
   * @param   Interval             In what interval to update the shake position. Set to `FlxG.elapsed` if `<= 0`!
   * @param   StartIntensity       The starting intensity of the shake.
   * @param   EndIntensity         The ending intensity of the shake.
   * @param   Ease                 Control the easing of the intensity over the shake.
   * @param   CompletionCallback   Callback on shake completion
   * @param   ProgressCallback     Callback on each shake interval
   * @return The `IntervalShake` object. `IntervalShake`s are pooled internally, so beware of storing references.
   */
  public static function shake(Object:FlxObject, Duration:Float = 1, Interval:Float = 0.04, StartIntensity:Float = 0, EndIntensity:Float = 0,
      Ease:EaseFunction, ?CompletionCallback:IntervalShake->Void, ?ProgressCallback:IntervalShake->Void):IntervalShake
  {
    if (isShaking(Object))
    {
      // if (ForceRestart)
      // {
      //   stopShaking(Object);
      // }
      // else
      // {
      // Ignore this call if object is already flickering.
      return _boundObjects[Object];
      // }
    }

    if (Interval <= 0)
    {
      Interval = FlxG.elapsed;
    }

    var shake:IntervalShake = _pool.get();
    shake.start(Object, Duration, Interval, StartIntensity, EndIntensity, Ease, CompletionCallback, ProgressCallback);
    return _boundObjects[Object] = shake;
  }

  /**
   * Returns whether the object is shaking or not.
   *
   * @param   Object The object to test.
   */
  public static function isShaking(Object:FlxObject):Bool
  {
    return _boundObjects.exists(Object);
  }

  /**
   * Stops shaking the object.
   *
   * @param   Object The object to stop shaking.
   */
  public static function stopShaking(Object:FlxObject):Void
  {
    var boundShake:IntervalShake = _boundObjects[Object];
    if (boundShake != null)
    {
      boundShake.stop();
    }
  }

  /**
   * The shaking object.
   */
  public var object(default, null):FlxObject;

  /**
   * The shaking timer. You can check how many seconds has passed since shaking started etc.
   */
  public var timer(default, null):FlxTimer;

  /**
   * The starting intensity of the shake.
   */
  public var startIntensity(default, null):Float;

  /**
   * The ending intensity of the shake.
   */
  public var endIntensity(default, null):Float;

  /**
   * How long to shake for (in seconds). `0` means "forever".
   */
  public var duration(default, null):Float;

  /**
   * The interval of the shake.
   */
  public var interval(default, null):Float;

  /**
   * Defines on what axes to `shake()`. Default value is `XY` / both.
   */
  public var axes(default, null):FlxAxes;

  /**
   * Defines the initial position of the object at the beginning of the shake effect.
   */
  public var initialOffset(default, null):FlxPoint;

  /**
   * The callback that will be triggered after the shake has completed.
   */
  public var completionCallback(default, null):IntervalShake->Void;

  /**
   * The callback that will be triggered every time the object shakes.
   */
  public var progressCallback(default, null):IntervalShake->Void;

  /**
   * The easing of the intensity over the shake.
   */
  public var ease(default, null):EaseFunction;

  /**
   * Nullifies the references to prepare object for reuse and avoid memory leaks.
   */
  public function destroy():Void
  {
    object = null;
    timer = null;
    ease = null;
    completionCallback = null;
    progressCallback = null;
  }

  /**
   * Starts shaking behavior.
   */
  function start(Object:FlxObject, Duration:Float = 1, Interval:Float = 0.04, StartIntensity:Float = 0, EndIntensity:Float = 0, Ease:EaseFunction,
      ?CompletionCallback:IntervalShake->Void, ?ProgressCallback:IntervalShake->Void):Void
  {
    object = Object;
    duration = Duration;
    interval = Interval;
    completionCallback = CompletionCallback;
    startIntensity = StartIntensity;
    endIntensity = EndIntensity;
    initialOffset = new FlxPoint(Object.x, Object.y);
    ease = Ease;
    axes = FlxAxes.XY;
    _secondsSinceStart = 0;
    timer = new FlxTimer().start(interval, shakeProgress, Std.int(duration / interval));
  }

  /**
   * Prematurely ends shaking.
   */
  public function stop():Void
  {
    timer.cancel();
    // object.visible = true;
    object.x = initialOffset.x;
    object.y = initialOffset.y;
    release();
  }

  /**
   * Unbinds the object from shaking and releases it into pool for reuse.
   */
  function release():Void
  {
    _boundObjects.remove(object);
    _pool.put(this);
  }

  public var _secondsSinceStart(default, null):Float = 0;

  public var scale(default, null):Float = 0;

  /**
   * Just a helper function for shake() to update object's position.
   */
  function shakeProgress(timer:FlxTimer):Void
  {
    _secondsSinceStart += interval;
    scale = _secondsSinceStart / duration;
    if (ease != null)
    {
      scale = 1 - ease(scale);
      // trace(scale);
    }

    var curIntensity:Float = 0;
    curIntensity = FlxMath.lerp(endIntensity, startIntensity, scale);

    if (axes.x) object.x = initialOffset.x + FlxG.random.float((-curIntensity) * object.width, (curIntensity) * object.width);
    if (axes.y) object.y = initialOffset.y + FlxG.random.float((-curIntensity) * object.width, (curIntensity) * object.width);

    // object.visible = !object.visible;

    if (progressCallback != null) progressCallback(this);

    if (timer.loops > 0 && timer.loopsLeft == 0)
    {
      object.x = initialOffset.x;
      object.y = initialOffset.y;
      if (completionCallback != null)
      {
        completionCallback(this);
      }

      if (this.timer == timer) release();
    }
  }

  /**
   * Internal constructor. Use static methods.
   */
  @:keep
  function new() {}
}
