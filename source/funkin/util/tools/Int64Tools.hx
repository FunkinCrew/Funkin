package funkin.util.tools;

/**
 * @see https://github.com/fponticelli/thx.core/blob/master/src/thx/Int64s.hx
 */
class Int64Tools
{
  static var min = haxe.Int64.make(0x80000000, 0);
  static var one = haxe.Int64.make(0, 1);
  static var two = haxe.Int64.ofInt(2);
  static var zero = haxe.Int64.make(0, 0);
  static var ten = haxe.Int64.ofInt(10);

  public static function toFloat(i:haxe.Int64):Float
  {
    var isNegative = false;
    if (i < 0)
    {
      if (i < min) return -9223372036854775808.0; // most -ve value can't be made +ve
      isNegative = true;
      i = -i;
    }
    var multiplier = 1.0, ret = 0.0;
    for (_ in 0...64)
    {
      if (haxe.Int64.and(i, one) != zero) ret += multiplier;
      multiplier *= 2.0;
      i = haxe.Int64.shr(i, 1);
    }
    return (isNegative ? -1 : 1) * ret;
  }
}
