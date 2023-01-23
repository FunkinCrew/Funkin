package funkin.util;

#if !macro
import flixel.FlxBasic;
import flixel.util.FlxSort;
#end

class SortUtil
{
  /**
   * You can use this function in FlxTypedGroup.sort() to sort FlxObjects by their z-index values.
   * The value defaults to 0, but by assigning it you can easily rearrange objects as desired.
   */
  public static inline function byZIndex(Order:Int, Obj1:FlxBasic, Obj2:FlxBasic):Int
  {
    if (Obj1 == null || Obj2 == null) return 0;
    return FlxSort.byValues(Order, Obj1.zIndex, Obj2.zIndex);
  }

  /**
   * Given two Notes, returns 1 or -1 based on whether `a` or `b` has an earlier strumtime.
   * 
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   */
  public static inline function byStrumtime(order:Int, a:Note, b:Note)
  {
    return FlxSort.byValues(order, a.data.strumTime, b.data.strumTime);
  }
}
