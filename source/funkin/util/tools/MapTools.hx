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
  public static function values<K, T>(map:Map<K, T>):Array<T>
  {
    return [for (i in map.iterator()) i];
  }
}
