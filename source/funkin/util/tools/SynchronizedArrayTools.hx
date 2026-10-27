package funkin.util.tools;

#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedArray;

/**
 * A static extension which provides utility functions for SynchronizedArrays.
 */
@:nullSafety
class SynchronizedArrayTools
{
  /**
   * Alias from the standard `push` method to the `add` method on SynchronizedArray.
   * IDK why this is named different but okay.
   */
  public static inline function push<T>(array:SynchronizedArray<T>, value:T):Void
  {
    array.add(value);
  }

  /**
   * Append each element of the second array to the first array.
   * Modifies the array in place, unlike `Array.concat` which creates a copy.
   *
   * @param array The array to append to.
   * @param elements The elements to append.
   * @return The array with the elements appended.
   */
  public static function append<T>(array:SynchronizedArray<T>, elements:Array<T>):Void
  {
    array.addAll(elements);
  }
}
#end
