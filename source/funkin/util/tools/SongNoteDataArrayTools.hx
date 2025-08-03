package funkin.util.tools;

import funkin.data.song.SongData.SongNoteData;

/**
 * A static extension which provides utility functions for `Array<SongNoteData>`s.
 */
@:nullSafety
class SongNoteDataArrayTools
{
  /**
   * Queries whether the provided `SongNoteData` is contained in the provided array.
   * The input array must be already sorted by `time`.
   * Vastly more efficient than `array.indexOf`.
   * This is not crazy or premature optimization, I'm writing this because `ChartEditorState.handleNoteDisplay` is using like 71% of its CPU time on this.
   * @param arr The array to search.
   * @param note The note to search for.
   * @param predicate
   * @return The index of the note in the array, or `-1` if it is not present.
   */
  public static function fastIndexOf(input:Array<SongNoteData>, note:SongNoteData):Int
  {
    // I would have made this use a generic/predicate, but that would have made it slower!

    // Prefix with some simple checks to save time.
    if (input.length == 0) return -1;
    if (note.time < input[0].time || note.time > input[input.length - 1].time) return -1;

    // Thank you Github Copilot for suggesting a binary search!
    var lowIndex:Int = 0;
    var highIndex:Int = input.length - 1;

    // When lowIndex overtakes highIndex
    while (lowIndex <= highIndex)
    {
      // Get the middle index of the range.
      var midIndex = Std.int((lowIndex + highIndex) / 2);

      // Compare the middle note of the range to the note we're looking for.
      // If it matches, return the index, else halve the range and try again.
      var midNote = input[midIndex];
      if (midNote.time < note.time)
      {
        // Search the upper half of the range.
        lowIndex = midIndex + 1;
      }
      else if (midNote.time > note.time)
      {
        // Search the lower half of the range.
        highIndex = midIndex - 1;
      }
      // Found it? Do a more thorough check.
      else if (midNote == note)
      {
        return midIndex;
      }
      else
      {
        // Notes might have same time but not same data, do scans towards both sides
        // Scan left from midIndex
        var i = midIndex;
        while (i >= 0 && input[i].time == note.time)
        {
          if (input[i] == note) return i;
          i--;
        }

        // Scan right from midIndex + 1
        i = midIndex + 1;
        while (i < input.length && input[i].time == note.time)
        {
          if (input[i] == note) return i;
          i++;
        }

        // No matching note found, despite time match
        break;
      }
    }
    return -1;
  }

  public static inline function fastContains(input:Array<SongNoteData>, note:SongNoteData):Bool
  {
    return fastIndexOf(input, note) != -1;
  }
}
