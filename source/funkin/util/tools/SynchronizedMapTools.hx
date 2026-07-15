package funkin.util.tools;

#if FEATURE_MULTITHREADING
import hx.concurrent.collection.SynchronizedMap;

/**
 * A static extension which provides utility functions for SynchronizedMaps.
 */
@:nullSafety
class SynchronizedMapTools
{
  /**
   * Alias from the standard `size` method to `length`.
   * Why is this locked behind Haxe 5? IDK
   */
  public static inline function size<K, V>(map:SynchronizedMap<K, V>):Int
  {
    return map.length;
  }
}
#end
