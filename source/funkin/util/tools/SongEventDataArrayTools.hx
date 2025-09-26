package funkin.util.tools;

import funkin.data.song.SongData.SongEventData;

/**
 * A static extension which provides utility functions for `Array<SongEventData>`s.
 */
@:nullSafety
class SongEventDataArrayTools
{
  /**
   * Queries whether the provided `SongEventData` is contained in the provided array.
   * The input array must be already sorted by `time`.
   * Vastly more efficient than `array.indexOf`.
   * This is not crazy or premature optimization, I'm writing this because `ChartEditorState.handleNoteDisplay` is using like 71% of its CPU time on this.
   * @param arr The array to search.
   * @param note The note to search for.
   * @param predicate
   * @return The index of the note in the array, or `-1` if it is not present.
   */
  public static function fastIndexOf(input:Array<SongEventData>, note:SongEventData):Int
  {
    // I would have made this use a generic/predicate, but that would have made it slower!

    // Thank you Github Copilot for suggesting a binary search!
    var lowIndex:Int = 0;
    var highIndex:Int = input.length - 1;
    var midIndex:Int;
    var midNote:SongEventData;

    // When lowIndex overtakes highIndex
    while (lowIndex <= highIndex)
    {
      // Get the middle index of the range.
      midIndex = Std.int((lowIndex + highIndex) / 2);

      // Compare the middle note of the range to the note we're looking for.
      // If it matches, return the index, else halve the range and try again.
      midNote = input[midIndex];
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
      // Found it? Make a more thorough check.
      else if (midNote == note)
      {
        return midIndex;
      }
      else
      {
        // We may be close, so constrain the range (but only a little) and try again.
        highIndex -= 1;
      }
    }
    return -1;
  }

  public static inline function fastContains(input:Array<SongEventData>, note:SongEventData):Bool
  {
    return fastIndexOf(input, note) != -1;
  }
}
