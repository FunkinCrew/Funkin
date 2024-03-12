package funkin.util.tools;

import funkin.util.tools.FloatTools;
import haxe.Timer;

class TimerTools
{
  public static function start():Float
  {
    return Timer.stamp();
  }

  private static function took(start:Float, ?end:Float):Float
  {
    var endOrNow:Float = end != null ? end : Timer.stamp();
    return endOrNow - start;
  }

  public static function seconds(start:Float, ?end:Float, ?precision = 2):String
  {
    var seconds:Float = FloatTools.round(took(start, end), precision);
    return '${seconds} seconds';
  }

  public static function ms(start:Float, ?end:Float):String
  {
    var seconds:Float = took(start, end);
    return '${seconds * 1000} ms';
  }
}
