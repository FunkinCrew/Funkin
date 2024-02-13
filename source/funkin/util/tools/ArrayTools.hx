package funkin.util.tools;

/**
 * A static extension which provides utility functions for Arrays.
 */
class ArrayTools
{
  /**
   * Returns a copy of the array with all duplicate elements removed.
   * @param array The array to remove duplicates from.
   * @return A copy of the array with all duplicate elements removed.
   */
  public static function unique<T>(array:Array<T>):Array<T>
  {
    var result:Array<T> = [];
    for (element in array)
    {
      if (!result.contains(element))
      {
        result.push(element);
      }
    }
    return result;
  }

  /**
   * Returns a copy of the array with all `null` elements removed.
   * @param array The array to remove `null` elements from.
   * @return A copy of the array with all `null` elements removed.
   */
  public static function nonNull<T>(array:Array<Null<T>>):Array<T>
  {
    var result:Array<T> = [];
    for (element in array)
    {
      if (element != null)
      {
        result.push(element);
      }
    }
    return result;
  }

  /**
   * Return the first element of the array that satisfies the predicate, or null if none do.
   * @param input The array to search
   * @param predicate The predicate to call
   * @return The result
   */
  public static function find<T>(input:Array<T>, predicate:T->Bool):Null<T>
  {
    for (element in input)
    {
      if (predicate(element)) return element;
    }
    return null;
  }

  /**
   * Return the index of the first element of the array that satisfies the predicate, or `-1` if none do.
   * @param input The array to search
   * @param predicate The predicate to call
   * @return The index of the result
   */
  public static function findIndex<T>(input:Array<T>, predicate:T->Bool):Int
  {
    for (index in 0...input.length)
    {
      if (predicate(input[index])) return index;
    }
    return -1;
  }

  /*
   * Push an element to the array if it is not already present.
   * @param input The array to push to
   * @param element The element to push
   * @return Whether the element was pushed
   */
  public static function pushUnique<T>(input:Array<T>, element:T):Bool
  {
    if (input.contains(element)) return false;
    input.push(element);
    return true;
  }

  /**
   * Remove all elements from the array, without creating a new array.
   * @param array The array to clear.
   */
  public static function clear<T>(array:Array<T>):Void
  {
    // This method is faster than array.splice(0, array.length)
    while (array.length > 0)
      array.pop();
  }

  /**
   * Create a new array with all elements of the given array, to prevent modifying the original.
   */
  public static function clone<T>(array:Array<T>):Array<T>
  {
    return [for (element in array) element];
  }

  /**
   * Create a new array with clones of all elements of the given array, to prevent modifying the original.
   */
  public static function deepClone<T, U:ICloneable<T>>(array:Array<U>):Array<T>
  {
    return [for (element in array) element.clone()];
  }

  /**
   * Return true only if both arrays contain the same elements (possibly in a different order).
   * @param a The first array to compare.
   * @param b The second array to compare.
   * @return Weather both arrays contain the same elements.
   */
  public static function isEqualUnordered<T>(a:Array<T>, b:Array<T>):Bool
  {
    if (a.length != b.length) return false;
    for (element in a)
    {
      if (!b.contains(element)) return false;
    }
    for (element in b)
    {
      if (!a.contains(element)) return false;
    }
    return true;
  }

  /**
   * Returns true if `superset` contains all elements of `subset`.
   * @param superset The array to query for each element.
   * @param subset The array containing the elements to query for.
   * @return Weather `superset` contains all elements of `subset`.
   */
  public static function isSuperset<T>(superset:Array<T>, subset:Array<T>):Bool
  {
    // Shortcuts.
    if (subset.length == 0) return true;
    if (subset.length > superset.length) return false;

    // Check each element.
    for (element in subset)
    {
      if (!superset.contains(element)) return false;
    }
    return true;
  }

  /**
   * Returns true if `superset` contains all elements of `subset`.
   * @param subset The array containing the elements to query for.
   * @param superset The array to query for each element.
   * @return Weather `superset` contains all elements of `subset`.
   */
  public static function isSubset<T>(subset:Array<T>, superset:Array<T>):Bool
  {
    // Switch it around.
    return isSuperset(superset, subset);
  }
}
