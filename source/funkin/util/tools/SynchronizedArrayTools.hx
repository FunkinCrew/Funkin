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
}
#end
