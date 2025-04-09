package funkin.util;

import funkin.Conductor;
import flixel.util.FlxColor;

class QuantizeUtil
{
  public static final quantizeColors16:Array<FlxColor> = [
    0xFFFF0000, 0xFFFFA500, 0xFFFFFF00, 0xFF00FF00, 0xFF008000, 0xFF00FFFF, 0xFF0000FF, 0xFF800080, 0xFFFFC0CB, 0xFFFF00FF, 0xFF8A2BE2, 0xFFA52A2A,
    0xFF808000, 0xFF000080, 0xFF800000, 0xFF808080
  ];

  /**
   * Returns an index from 0 to 15
   * @param time Time in MS
   * @param conductor The Conductor to use
   * @return Index
   */
  public static function quantizeTime16(time:Float, ?conductor:Conductor):Int
  {
    conductor = conductor ?? Conductor.instance;
    trace('INDEX: ${Math.floor(time / conductor.stepLengthMs) % 16}', time);
    return Math.floor(time / conductor.stepLengthMs) % 16;
  }

  /**
   * Returns an index from 0 to 15
   * @param time Time in MS
   * @param conductor The Conductor to use
   * @return Index
   */
  public static function quantizeTime16Color(time:Float, ?conductor:Conductor):FlxColor
  {
    return quantizeColors16[quantizeTime16(time, conductor)];
  }
}
