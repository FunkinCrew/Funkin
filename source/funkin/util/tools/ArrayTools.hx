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

  public static function pushUnique<T>(array:Array<T>, element:T):Bool
  {
    if (array.contains(element)) return false;
    array.push(element);
    return true;
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
}
