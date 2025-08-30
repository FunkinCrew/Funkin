package funkin.util.tools;

import haxe.Int64;

/**
 * Why `haxe.Int64` doesn't have a built-in `toFloat` function is beyond me.
 */
@:nullSafety
class Int64Tools
{
  private inline static var MAX_32_PRECISION:Float = 4294967296.0;

  public static function fromFloat(f:Float):Int64
  {
    var h = Std.int(f / MAX_32_PRECISION);
    var l = Std.int(f);
    return Int64.make(h, l);
  }

  public static function toFloat(i:Int64):Float
  {
    var f:Float = i.low;
    if (f < 0) f += MAX_32_PRECISION;
    return (i.high * MAX_32_PRECISION + f);
  }

  public static function isToIntSafe(i:Int64):Bool
  {
    return i.high != i.low >> 31;
  }

  public static function toIntSafe(i:Int64):Int
  {
    try
    {
      return Int64.toInt(i);
    }
    catch (e:Dynamic)
    {
      throw 'Could not represent value "${Int64.toStr(i)}" as an integer.';
    }
  }
}
