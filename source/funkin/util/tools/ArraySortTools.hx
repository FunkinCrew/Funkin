package funkin.util.tools;

/**
 * Contains code for sorting arrays using various algorithms.
 * @see https://algs4.cs.princeton.edu/20sorting/
 */
@:nullSafety
class ArraySortTools
{
  /**
   * Sorts the input array using the merge sort algorithm.
   * Stable and guaranteed to run in linearithmic time `O(n log n)`,
   * but less efficient in "best-case" situations.
   *
   * @param input The array to sort in-place.
   * @param compare The comparison function to use.
   */
  public static function mergeSort<T>(input:Array<T>, compare:CompareFunction<T>):Void
  {
    if (input == null || input.length <= 1) return;
    if (compare == null) throw 'No comparison function provided.';

    // Haxe implements merge sort by default.
    haxe.ds.ArraySort.sort(input, compare);
  }

  /**
   * Sorts the input array using the quick sort algorithm.
   * More efficient on smaller arrays, but is inefficient `O(n^2)` in "worst-case" situations.
   * Not stable; relative order of equal elements is not preserved.
   *
   * @see https://stackoverflow.com/questions/33884057/quick-sort-stackoverflow-error-for-large-arrays
   *      Fix for stack overflow issues.
   * @param input The array to sort in-place.
   * @param compare The comparison function to use.
   */
  public static function quickSort<T>(input:Array<T>, compare:CompareFunction<T>):Void
  {
    if (input == null || input.length <= 1) return;
    if (compare == null) throw 'No comparison function provided.';

    quickSortInner(input, 0, input.length - 1, compare);
  }

  /**
   * Internal recursive function for the quick sort algorithm.
   * Recurses on the smaller partition and loops on the larger one
   * to keep stack depth at O(log n) in the worst case.
   */
  static function quickSortInner<T>(input:Array<T>, low:Int, high:Int, compare:CompareFunction<T>):Void
  {
    while (low < high)
    {
      // Insertion sort is faster for small partitions — quicksort's
      // overhead just isn't worth it below ~16 elements.
      if (high - low < 16)
      {
        insertionSort(input, low, high, compare);
        return;
      }
  
      var pivot:Int = quickSortPartition(input, low, high, compare);
  
      if (pivot - low <= high - (pivot + 1))
      {
        quickSortInner(input, low, pivot, compare);
        low = pivot + 1;
      }
      else
      {
        quickSortInner(input, pivot + 1, high, compare);
        high = pivot;
      }
    }
  }

  /**
   * Partitions a slice of the array around a pivot using median-of-three
   * selection, which avoids O(n²) worst-case on sorted/reverse-sorted input.
   */
  static function quickSortPartition<T>(input:Array<T>, low:Int, high:Int, compare:CompareFunction<T>):Int
  {
    // Pick the median of first, middle, and last as the pivot.
    // We sort these three elements in place as a side effect, which
    // also puts sentinels at the boundaries and lets us skip a bounds check.
    var mid:Int = low + ((high - low) >> 1);
    if (compare(input[mid], input[low]) < 0) { var t:T = input[mid]; input[mid] = input[low]; input[low] = t; }
    if (compare(input[high], input[low]) < 0) { var t:T = input[high]; input[high] = input[low]; input[low] = t; }
    if (compare(input[mid], input[high]) < 0) { var t:T = input[mid]; input[mid] = input[high]; input[high] = t; }
    var pivot:T = input[high];
  
    var i:Int = low - 1;
    var j:Int = high + 1;
  
    while (true)
    {
      do { i++; } while (compare(input[i], pivot) < 0);
      do { j--; } while (compare(input[j], pivot) > 0);
  
      if (i >= j) return j;
  
      var temp:T = input[i];
      input[i] = input[j];
      input[j] = temp;
    }
  
    return -1; // Unreachable.
  }

  /**
   * Sorts the input array using the insertion sort algorithm.
   * Stable and is very fast on nearly-sorted arrays,
   * but is inefficient `O(n^2)` in "worst-case" situations.
   *
   * @param input The array to sort in-place.
   * @param compare The comparison function to use.
   */
  public static function insertionSort<T>(input:Array<T>, compare:CompareFunction<T>):Void
  {
    if (input == null || input.length <= 1) return;
    if (compare == null) throw 'No comparison function provided.';

    // Iterate through the array, starting at the second element.
    for (i in 1...input.length)
    {
      // Store the current element.
      var current:T = input[i];
      // Store the index of the previous element.
      var j:Int = i - 1;

      // While the previous element is greater than the current element,
      // move the previous element to the right and move the index to the left.
      while (j >= 0 && compare(input[j], current) > 0)
      {
        input[j + 1] = input[j];
        j--;
      }

      // Insert the current element into the array.
      input[j + 1] = current;
    }
  }
}

/**
 * A comparison function.
 * Returns a negative number if the first argument is less than the second,
 * a positive number if the first argument is greater than the second,
 * or zero if the two arguments are equal.
 */
typedef CompareFunction<T> = T->T->Int;
