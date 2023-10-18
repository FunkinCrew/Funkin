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
}
