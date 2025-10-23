package funkin.util;

import flixel.graphics.frames.FlxFrame;
#if !macro
import flixel.FlxBasic;
import flixel.util.FlxSort;
#end
import funkin.play.notes.NoteSprite;
import funkin.play.notes.SustainTrail;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongTimeChange;

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
@:nullSafety
class SortUtil
{
  /**
   * You can use this function in FlxTypedGroup.sort() to sort FlxObjects by their z-index values.
   * The value defaults to 0, but by assigning it you can easily rearrange objects as desired.
   *
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   * @param a The first FlxObject to compare.
   * @param b The second FlxObject to compare.
   * @return 1 if `a` has a higher z-index, -1 if `b` has a higher z-index.
   */
  public static inline function byZIndex(order:Int, a:FlxBasic, b:FlxBasic):Int
  {
    if (a == null || b == null) return 0;
    return FlxSort.byValues(order, a.zIndex, b.zIndex);
  }

  /**
   * Given two Notes, returns 1 or -1 based on whether `a` or `b` has an earlier strumtime.
   *
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   * @param a The first Note to compare.
   * @param b The second Note to compare.
   * @return 1 if `a` has an earlier strumtime, -1 if `b` has an earlier strumtime.
   */
  public static inline function notebyStrumtime(order:Int, a:NoteSprite, b:NoteSprite):Int
  {
    if (a == null || b == null) return 0;
    return noteDataByTime(order, a.noteData, b.noteData);
  }

  /**
   * Given two hold note sprites, returns 1 or -1 based on whether `a` or `b` has an earlier strumtime.
   *
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   * @param a The first hold note sprite to compare.
   * @param b The second hold note sprite to compare.
   * @return 1 if `a` has an earlier strumtime, -1 if `b` has an earlier strumtime.
   */
  public static inline function sustainTrailbyStrumtime(order:Int, a:SustainTrail, b:SustainTrail):Int
  {
    if (a == null || b == null) return 0;
    return FlxSort.byValues(order, a.strumTime, b.strumTime);
  }

  /**
   * Given two Note Data objects, returns 1 or -1 based on whether `a` or `b` has an earlier time.
   *
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   * @param a The first Event to compare.
   * @param b The second Event to compare.
   * @return 1 if `a` has an earlier time, -1 if `b` has an earlier time.
   */
  public static inline function noteDataByTime(order:Int, a:SongNoteData, b:SongNoteData):Int
  {
    if (a == null || b == null) return 0;

    var result = FlxSort.byValues(order, a.time, b.time);
    if (result == 0) result = FlxSort.byValues(order, a.length, b.length);
    return result;
  }

  /**
   * Given two Event Data objects, returns 1 or -1 based on whether `a` or `b` has an earlier time.
   *
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   * @param a The first Event to compare.
   * @param b The second Event to compare.
   * @return 1 if `a` has an earlier time, -1 if `b` has an earlier time.
   */
  public static inline function eventDataByTime(order:Int, a:SongEventData, b:SongEventData):Int
  {
    if (a == null || b == null) return 0;
    return FlxSort.byValues(order, a.time, b.time);
  }

  /**
   * Given two Time Change objects, returns 1 or -1 based on whether `a` or `b` has an earlier time.
   *
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   * @param a The first Event to compare.
   * @param b The second Event to compare.
   * @return 1 if `a` has an earlier time, -1 if `b` has an earlier time.
   */
  public static inline function timeChangeByTime(order:Int, a:SongTimeChange, b:SongTimeChange):Int
  {
    if (a == null || b == null) return 0;
    return FlxSort.byValues(order, a.timeStamp, b.timeStamp);
  }

  /**
   * Given two FlxFrames, sort their names alphabetically.
   *
   * @param order Either `FlxSort.ASCENDING` or `FlxSort.DESCENDING`
   * @param a The first Frame to compare.
   * @param b The second Frame to compare.
   * @return 1 if `a` has an earlier time, -1 if `b` has an earlier time.
   */
  public static inline function byFrameName(a:FlxFrame, b:FlxFrame):Int
  {
    return alphabetically(a.name, b.name);
  }

  /**
   * Sort predicate for sorting strings alphabetically.
   * @param a The first string to compare.
   * @param b The second string to compare.
   * @return 1 if `a` comes before `b`, -1 if `b` comes before `a`, 0 if they are equal
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
   *
   * @param defaultValue The value to prioritize.
   * @param a The first string to compare.
   * @param b The second string to compare.
   * @return 1 if `a` comes before `b`, -1 if `b` comes before `a`, 0 if they are equal
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
   *
   * @param defaultValues The values to prioritize.
   * @param a The first string to compare.
   * @param b The second string to compare.
   * @return 1 if `a` comes before `b`, -1 if `b` comes before `a`, 0 if they are equal
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
