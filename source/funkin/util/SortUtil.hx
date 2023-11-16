package funkin.util;

import flixel.graphics.frames.FlxFrame;
#if !macro
import flixel.FlxBasic;
import flixel.util.FlxSort;
#end
import funkin.play.notes.NoteSprite;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;

/**
 * Utility functions related to sorting.
 *
 * NOTE: `Array.sort()` takes a function `(x, y) -> Int`.
 * If the objects are in the correct order (x before y), return a negative value.
 * If the objects need to be swapped (y before x), return a negative value.
 * If the objects are equal, return 0.
 *
 * NOTE: `Array.sort()` does NOT guarantee that the order of equal elements. `haxe.ds.ArraySort.sort()` does guarantee this.
 * NOTE: `Array.sort()` may not be the most efficient sorting algorithm for all use cases (especially if the array is known to be mostly sorted).
 *    You may consider using one of the functions in `funkin.util.tools.ArraySortTools` instead.
 * NOTE: Both sort functions modify the array in-place. You may consider using `Reflect.copy()` to make a copy of the array before sorting.
 */
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
    return noteDataByTime(order, a.noteData, b.noteData);
  }

  public static inline function noteDataByTime(order:Int, a:SongNoteData, b:SongNoteData)
  {
    return FlxSort.byValues(order, a.time, b.time);
  }

  public static inline function eventDataByTime(order:Int, a:SongEventData, b:SongEventData)
  {
    return FlxSort.byValues(order, a.time, b.time);
  }

  /**
   * Given two FlxFrames, sort their names alphabetically.
   *
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   */
  public static inline function byFrameName(a:FlxFrame, b:FlxFrame)
  {
    return alphabetically(a.name, b.name);
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
  public static function defaultThenAlphabetically(defaultValue:String, a:String, b:String):Int
  {
    if (a == b) return 0;
    if (a == defaultValue) return -1;
    if (b == defaultValue) return 1;
    return alphabetically(a, b);
  }

  /**
   * Sort predicate which sorts two strings alphabetically, but prioritizes a specific string first.
   * Example usage: `array.sort(defaultsThenAlphabetical.bind(['test']))` will sort the array so that the string 'test' is first.
   * @param a The first string to compare.
   * @param b The second string to compare.
   * @param defaultValues The values to prioritize.
   */
  public static function defaultsThenAlphabetically(defaultValues:Array<String>, a:String, b:String):Int
  {
    if (a == b) return 0;
    if (defaultValues.contains(a) && defaultValues.contains(b))
    {
      // Sort by index in defaultValues
      return defaultValues.indexOf(a) - defaultValues.indexOf(b);
    };
    if (defaultValues.contains(a)) return -1;
    if (defaultValues.contains(b)) return 1;
    return alphabetically(a, b);
  }
}
