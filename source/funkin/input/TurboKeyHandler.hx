package funkin.input;

import flixel.input.keyboard.FlxKey;
import flixel.FlxBasic;

/**
 * Handles repeating behavior when holding down a key or key combination.
 *
 * When the `keys` are pressed, `activated` will be true for the first frame,
 * then wait `delay` seconds before becoming true for one frame every `interval` seconds.
 *
 * Example: Pressing Ctrl+Z will undo, while holding Ctrl+Z will start to undo repeatedly.
 */
@:nullSafety
class TurboKeyHandler extends FlxBasic
{
  /**
   * Default delay before repeating.
   */
  static inline final DEFAULT_DELAY:Float = 0.4;

  /**
   * Default interval between repeats.
   */
  static inline final DEFAULT_INTERVAL:Float = 0.1;

  /**
   * Whether all of the keys for this handler are pressed.
   */
  public var allPressed(get, never):Bool;

  /**
   * Whether all of the keys for this handler are activated,
   * and the handler is ready to repeat.
   */
  public var activated(default, null):Bool = false;

  var keys:Array<FlxKey>;
  var delay:Float;
  var interval:Float;

  var allPressedTime:Float = 0;

  function new(keys:Array<FlxKey>, delay:Float = DEFAULT_DELAY, interval:Float = DEFAULT_INTERVAL)
  {
    super();
    this.keys = keys;
    this.delay = delay;
    this.interval = interval;
  }

  function get_allPressed():Bool
  {
    if (keys == null || keys.length == 0) return false;
    if (keys.length == 1) return FlxG.keys.anyPressed(keys);

    // Check if ANY keys are unpressed
    for (key in keys)
    {
      if (!FlxG.keys.anyPressed([key])) return false;
    }
    return true;
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (allPressed)
    {
      if (allPressedTime == 0)
      {
        activated = true;
      }
      else if (allPressedTime >= (delay + interval))
      {
        activated = true;
        allPressedTime -= interval;
      }
      else
      {
        activated = false;
      }
      allPressedTime += elapsed;
    }
    else
    {
      allPressedTime = 0;
      activated = false;
    }
  }

  /**
   * Builds a TurboKeyHandler that monitors from a single key.
   * @param inputKey The key to monitor.
   * @param delay How long to wait before repeating.
   * @param repeatDelay How long to wait between repeats.
   * @return A TurboKeyHandler
   */
  public static overload inline extern function build(inputKey:FlxKey, ?delay:Float = DEFAULT_DELAY, ?interval:Float = DEFAULT_INTERVAL):TurboKeyHandler
  {
    return new TurboKeyHandler([inputKey], delay, interval);
  }

  /**
   * Builds a TurboKeyHandler that monitors a key combination.
   * @param inputKeys The combination of keys to monitor.
   * @param delay How long to wait before repeating.
   * @param repeatDelay How long to wait between repeats.
   * @return A TurboKeyHandler
   */
  public static overload inline extern function build(inputKeys:Array<FlxKey>, ?delay:Float = DEFAULT_DELAY, ?interval:Float = DEFAULT_INTERVAL):TurboKeyHandler
  {
    return new TurboKeyHandler(inputKeys, delay, interval);
  }
}
