package funkin.util.tools;

/**
 * A static extension which provides utility functions for Arrays.
 */
@:nullSafety
class ArrayTools
{
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

  /**
   * Like `join` but adds a word before the last element.
   * @param array The array to join.
   * @param separator The separator to use between elements.
   * @param andWord The word to use before the last element.
   * @return The joined string.
   */
  public static function joinPlural(array:Array<String>, separator:String = ', ', andWord:String = 'and'):String
  {
    if (array.length == 0) return '';
    if (array.length == 1) return array[0];
    return '${array.slice(0, array.length - 1).join(separator)} $andWord ${array[array.length - 1]}';
  }
}
