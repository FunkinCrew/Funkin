package funkin.data.song;

using SongData.SongNoteData;

/**
 * Utility class for extra handling of song notes
 */
@:nullSafety
class SongNoteDataUtils
{
  static final CHUNK_INTERVAL_MS:Float = 2500;

  /**
   * Retrieves all stacked notes. It does this by cycling through "chunks" of notes within a certain interval.
   *
   * @param notes Sorted notes by time.
   * @param threshold The note stack threshold. Refer to `doNotesStack` for more details.
   * @param includeOverlapped (Optional) If overlapped notes should be included.
   * @param overlapped (Optional) An array that gets populated with overlapped notes.
   * Note that it's only guaranteed to work properly if the provided notes are sorted.
   * @return Stacked notes.
   */
  public static function listStackedNotes(notes:Array<SongNoteData>, threshold:Float, includeOverlapped:Bool = true,
      ?overlapped:Array<SongNoteData>):Array<SongNoteData>
  {
    var stackedNotes:Array<SongNoteData> = [];

    var chunkTime:Float = 0;
    var chunks:Array<Array<SongNoteData>> = [[]];

    for (note in notes)
    {
      if (note == null)
      {
        continue;
      }

      while (note.time >= chunkTime + CHUNK_INTERVAL_MS)
      {
        chunkTime += CHUNK_INTERVAL_MS;
        chunks.push([]);
      }

      chunks[chunks.length - 1].push(note);
    }

    for (chunk in chunks)
    {
      for (i in 0...(chunk.length - 1))
      {
        for (j in (i + 1)...chunk.length)
        {
          var noteI:SongNoteData = chunk[i];
          var noteJ:SongNoteData = chunk[j];

          if (doNotesStack(noteI, noteJ, threshold))
          {
            if (!stackedNotes.fastContains(noteI))
            {
              if (includeOverlapped) stackedNotes.push(noteI);

              if (overlapped != null && !overlapped.contains(noteI)) overlapped.push(noteI);
            }

            if (!stackedNotes.fastContains(noteJ))
            {
              stackedNotes.push(noteJ);
            }
          }
        }
      }
    }

    return stackedNotes;
  }

  /**
   * Concatenates two arrays of notes but overwrites notes in `lhs` that are overlapped by notes in `rhs`.
   * Hold notes are only overwritten by longer hold notes.
   * This operation only modifies the second array and `overwrittenNotes`.
   *
   * @param lhs An array of notes
   * @param rhs An array of notes to concatenate into `lhs`
   * @param overwrittenNotes An optional array that is modified in-place with the notes in `lhs` that were overwritten.
   * @param threshold The note stack threshold. Refer to `doNotesStack` for more details.
   * @return The unsorted resulting array.
   */
  public static function concatOverwrite(lhs:Array<SongNoteData>, rhs:Array<SongNoteData>, ?overwrittenNotes:Array<SongNoteData>,
      threshold:Float = 0):Array<SongNoteData>
  {
    if (lhs == null || rhs == null || rhs.length == 0) return lhs;
    if (lhs.length == 0) return rhs;

    var result = lhs.copy();
    for (i in 0...rhs.length)
    {
      var noteB:SongNoteData = rhs[i];
      var hasOverlap:Bool = false;

      for (j in 0...lhs.length)
      {
        var noteA:SongNoteData = lhs[j];
        if (doNotesStack(noteA, noteB, threshold))
        {
          // Long hold notes should have priority over shorter hold notes
          if (noteA.length <= noteB.length)
          {
            overwrittenNotes?.push(result[j].clone());
            result[j] = noteB;
          }
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) result.push(noteB);
    }

    return result;
  }

  /**
   * @param noteA First note.
   * @param noteB Second note.
   * @param threshold The note stack threshold, in steps.
   * @return Returns `true` if both notes are on the same strumline, have the same direction
   * and their time difference in steps is less than the step-based threshold.
   * A threshold of 0 will return `true` if notes are nearly perfectly aligned.
   */
  public static function doNotesStack(noteA:SongNoteData, noteB:SongNoteData, threshold:Float = 0):Bool
  {
    if (noteA.data != noteB.data) return false;
    else if (threshold == 0) return Math.ffloor(Math.abs(noteA.time - noteB.time)) < 1;

    final stepDiff:Float = Math.abs(noteA.getStepTime() - noteB.getStepTime());
    return stepDiff <= threshold + 0.001;
  }
}
