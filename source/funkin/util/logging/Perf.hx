package funkin.util.logging;

/**
 * A small utility class for timing how long functions take.
 * Specify a string as a label (or don't, by default it uses the name of the function it was called from.)
 *
 * Example:
 * ```haxe
 *
 * var perf = new Perf();
 * ...
 * perf.print();
 * ```
 */
@:nullSafety
class Perf
{
  final startTime:Float;
  final label:Null<String>;
  final posInfos:Null<haxe.PosInfos>;

  /**
   * Create a new performance marker.
   * @param label Optionally specify a label to use for the performance marker. Defaults to the function name.
   * @param posInfos The position of the calling function. Used to build the default label.
   *   Note: `haxe.PosInfos` is magic and automatically populated by the compiler!
   */
  public function new(?label:String, ?posInfos:haxe.PosInfos)
  {
    this.label = label;
    this.posInfos = posInfos;
    startTime = current();
  }

  /**
   * The current timestamp, in fractional seconds.
   * @return The current timestamp.
   */
  static function current():Float
  {
    #if sys
    // This one is more accurate if it's available.
    return Sys.time();
    #else
    return haxe.Timer.stamp();
    #end
  }

  /**
   * The duration in seconds since this `Perf` was created.
   * @return The duration in seconds
   */
  public function duration():Float
  {
    return current() - startTime;
  }

  /**
   * A rounded millisecond duration
   * @return The duration in milliseconds
   */
  public function durationClean():Float
  {
    var round:Float = 100;
    return Math.floor(duration() * Constants.MS_PER_SEC * round) / round;
  }

  /**
   * Cleanly prints the duration since this `Perf` was created.
   */
  public function print():Void
  {
    var label:String = label ?? (posInfos == null ? 'unknown' : '${posInfos.className}#${posInfos.methodName}()');

    trace('[PERF] [$label] Took ${durationClean()}ms.');
  }
}
