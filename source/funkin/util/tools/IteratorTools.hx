package funkin.util.tools;

/**
 * A static extension which provides utility functions for Iterators.
 *
 * For example, add `using IteratorTools` then call `iterator.array()`.
 *
 * @see https://haxe.org/manual/lf-static-extension.html
 */
@:nullSafety
class IteratorTools
{
  public static function array<T>(iterator:Iterator<T>):Array<T>
  {
    return [for (i in iterator) i];
  }

  public static function count<T>(iterator:Iterator<T>, ?predicate:(item:T) -> Bool):Int
  {
    var n = 0;

    if (predicate == null)
    {
      for (_ in iterator)
        n++;
    }
    else
    {
      for (x in iterator)
        if (predicate(x)) n++;
    }

    return n;
  }
}
