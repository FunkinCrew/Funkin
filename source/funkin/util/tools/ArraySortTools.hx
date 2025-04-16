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
   * Written with ChatGPT!
   */
  static function quickSortInner<T>(input:Array<T>, low:Int, high:Int, compare:CompareFunction<T>):Void
  {
    // When low == high, the array is empty or too small to sort.

    // EDIT: Recurse on the smaller partition, and loop for the larger partition.
    while (low < high)
    {
      // Designate the first element in the array as the pivot, then partition the array around it.
      // Elements less than the pivot will be to the left, and elements greater than the pivot will be to the right.
      // Return the index of the pivot.
      var pivot:Int = quickSortPartition(input, low, high, compare);

      if ((pivot) - low <= high - (pivot + 1))
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
   * Internal function for sorting a partition of an array in the quick sort algorithm.
   * Written with ChatGPT!
   */
  static function quickSortPartition<T>(input:Array<T>, low:Int, high:Int, compare:CompareFunction<T>):Int
  {
    // Designate the first element in the array as the pivot.
    var pivot:T = input[low];
    // Designate two pointers, used to divide the array into two partitions.
    var i:Int = low - 1;
    var j:Int = high + 1;

    while (true)
    {
      // Move the left pointer to the right until it finds an element greater than the pivot.
      do
      {
        i++;
      }
      while (compare(input[i], pivot) < 0);

        // Move the right pointer to the left until it finds an element less than the pivot.
      do
      {
        j--;
      }
      while (compare(input[j], pivot) > 0);

        // If i and j have crossed, the array has been partitioned, and the pivot will be at the index j.
      if (i >= j) return j;

      // Else, swap the elements at i and j, and start over.
      // This slowly moves the pivot towards the middle of the partition,
      // while moving elements less than the pivot to the left and elements greater than the pivot to the right.
      var temp:T = input[i];
      input[i] = input[j];
      input[j] = temp;
    }

    // Don't expect to get here.
    return -1;
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
