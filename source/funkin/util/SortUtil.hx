package funkin.util;

#if !macro
import flixel.FlxBasic;
import flixel.util.FlxSort;
#end
import funkin.play.notes.NoteSprite;

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
  public static inline function byStrumtime(order:Int, a:NoteSprite, b:NoteSprite)
  {
    return FlxSort.byValues(order, a.noteData.time, b.noteData.time);
  }

  /**
   * Sort predicate for sorting strings alphabetically.
   * @param a The first string to compare.
   * @param b The second string to compare.
   */
  public static function alphabetically(a:String, b:String):Int
  {
    a = a.toUpperCase();
    b = b.toUpperCase();

    // Sort alphabetically. Yes that's how this works.
    return a == b ? 0 : a > b ? 1 : -1;
  }

  /**
   * Sort predicate which sorts two strings alphabetically, but prioritizes a specific string first.
   * Example usage: `array.sort(defaultThenAlphabetical.bind('test'))` will sort the array so that the string 'test' is first.
   * @param a The first string to compare.
   * @param b The second string to compare.
   * @param defaultValue The value to prioritize.
   */
  public static function defaultThenAlphabetically(a:String, b:String, defaultValue:String):Int
  {
    if (a == b) return 0;
    if (a == defaultValue) return 1;
    if (b == defaultValue) return -1;
    return alphabetically(a, b);
  }

  /**
   * Sort predicate which sorts two strings alphabetically, but prioritizes a specific string first.
   * Example usage: `array.sort(defaultsThenAlphabetical.bind(['test']))` will sort the array so that the string 'test' is first.
   * @param a The first string to compare.
   * @param b The second string to compare.
   * @param defaultValues The values to prioritize.
   */
  public static function defaultsThenAlphabetically(a:String, b:String, defaultValues:Array<String>):Int
  {
    if (a == b) return 0;
    if (defaultValues.contains(a) && defaultValues.contains(b))
    {
      // Sort by index in defaultValues
      return defaultValues.indexOf(a) - defaultValues.indexOf(b);
    };
    if (defaultValues.contains(a)) return 1;
    if (defaultValues.contains(b)) return -1;
    return alphabetically(a, b);
  }
}
