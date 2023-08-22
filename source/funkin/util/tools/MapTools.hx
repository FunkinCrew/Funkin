package funkin.util.tools;

/**
 * A static extension which provides utility functions for Maps.
 *
 * For example, add `using MapTools` then call `map.values()`.
 *
 * @see https://haxe.org/manual/lf-static-extension.html
 */
class MapTools
{
  /**
   * Return the quantity of keys in the map.
   */
  public static function size<K, T>(map:Map<K, T>):Int
  {
    return map.keys().array().length;
  }

  /**
   * Return a list of values from the map, as an array.
   */
  public static function values<K, T>(map:Map<K, T>):Array<T>
  {
    return [for (i in map.iterator()) i];
  }

  /**
   * Return a list of keys from the map (as an array, rather than an iterator).
   * TODO: Rename this?
   */
  public static function keyValues<K, T>(map:Map<K, T>):Array<K>
  {
    return map.keys().array();
  }
}
