package funkin.data.song;

using SongData.SongNoteData;

/**
 * Utility class for extra handling of song notes
 */
class SongNoteDataUtils
{
  static final CHUNK_INTERVAL_MS:Float = 2500;

  /**
   * Retrieves all stacked notes
   *
   * @param notes Sorted notes by time
   * @param threshold Threshold in ms
   * @return Stacked notes
   */
  public static function listStackedNotes(notes:Array<SongNoteData>, threshold:Float = 20):Array<SongNoteData>
  {
    var stackedNotes:Array<SongNoteData> = [];

    var chunkTime:Float = 0;
    var chunks:Array<Array<SongNoteData>> = [[]];

    for (note in notes)
    {
      if (note == null || chunks[chunks.length - 1].contains(note))
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
              stackedNotes.push(noteI);
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
   * Tries to concatenate two arrays of notes together but skips notes from `notesB` that overlap notes from `noteA`.
   * This operation modifies the second array by removing the overlapped notes
   *
   * @param notesA An array of notes into which `notesB` will be concatenated.
   * @param notesB Another array of notes that will be concatenated into `notesA`.
   * @param threshold Threshold in ms.
   * @return The unsorted resulting array.
   */
  public static function concatNoOverlap(notesA:Array<SongNoteData>, notesB:Array<SongNoteData>, threshold:Float = 20):Array<SongNoteData>
  {
    if (notesA == null || notesA.length == 0) return notesB;
    if (notesB == null || notesB.length == 0) return notesA;

    var addend = notesB.copy();
    addend = addend.filter((noteB) -> {
      for (noteA in notesA)
      {
        if (doNotesStack(noteA, noteB, threshold))
        {
          notesB.remove(noteB);
          return false;
        }
      }
      return true;
    });

    return notesA.concat(addend);
  }

  /**
   * Concatenates two arrays of notes but overwrites notes in `lhs` that are overlapped by notes from `rhs`.
   * This operation only modifies the second array and `overwrittenNotes`.
   *
   * @param lhs An array of notes
   * @param rhs An array of notes to concatenate into `lhs`
   * @param overwrittenNotes An optional array that is modified in-place with the notes in `lhs` that were overwritten.
   * @param threshold Threshold in ms
   * @return The resulting array, note that the added notes are placed at the end of the array.
   */
  public static function concatOverwrite(lhs:Array<SongNoteData>, rhs:Array<SongNoteData>, ?overwrittenNotes:Array<SongNoteData>,
      threshold:Float = 20):Array<SongNoteData>
  {
    if (lhs == null || rhs == null || rhs.length == 0) return lhs;

    var result = lhs.copy();
    for (i in 0...rhs.length)
    {
      if (rhs[i] == null) continue;

      var noteB:SongNoteData = rhs[i];
      var hasOverlap:Bool = false;
      for (j in 0...lhs.length)
      {
        var noteA:SongNoteData = lhs[j];
        if (doNotesStack(noteA, noteB, threshold))
        {
          if (noteA.length < noteB.length || !noteEquals(noteA, noteB))
          {
            overwrittenNotes?.push(result[j].clone());
            result[j] = noteB;
            rhs[i] = null;
          }
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) result.push(noteB);
    }
    rhs = rhs.filterNull();

    return result;
  }

  /**
   * @param threshold Time difference in milliseconds.
   * @return Returns `true` if both notes are on the same strumline, have the same direction and their time difference is less than `threshold`.
   */
  public static function doNotesStack(noteA:SongNoteData, noteB:SongNoteData, threshold:Float = 20):Bool
  {
    // TODO: Make this function inline again when I'm done debugging.
    return noteA.data == noteB.data && Math.ffloor(Math.abs(noteA.time - noteB.time)) <= threshold;
  }

  // This is replacing SongNoteData's equals operator because for some reason its params check is unreliable.
  static function noteEquals(note:SongNoteData, other:SongNoteData):Bool
  {
    if (note == null) return other == null;
    if (other == null) return false;

    // TESTME: These checks seem redundant when get_kind already returns null if it's an empty string.
    /*if (noteA.kind == null)
      {
        if (other.kind != null) return false;
      }
      else
      {
        if (other.kind == null) return false;
    }*/

    // params check is unreliable and doNotesStack already checks data
    return note.time == other.time && note.length == other.length && note.kind == other.kind;
  }
}
