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
   * @param notes Sorted notes by time
   * @param threshold Threshold in ms
   * @return Stacked notes
   */
  public static function listStackedNotes(notes:Array<SongNoteData>, threshold:Float):Array<SongNoteData>
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
   * This does not modify the original array.
   * @param notesA An array of notes into which `notesB` will be concatenated.
   * @param notesB Another array of notes that will be concated into `notesA`.
   * @param threshold Threshold in ms
   * @param modifyB If `true`, `notesB` will be modified in-place by removing the notes that overlap notes from `notesA`.
   * @return Array<SongNoteData>
   */
  public static function concatNoOverlap(notesA:Array<SongNoteData>, notesB:Array<SongNoteData>, threshold:Float, modifyB:Bool = false):Array<SongNoteData>
  {
    if (notesA == null || notesA.length == 0) return notesB;
    if (notesB == null || notesB.length == 0) return notesA;

    var result:Array<SongNoteData> = notesA.copy();
    var overlappingNotes:Array<SongNoteData> = [];

    for (noteB in notesB)
    {
      var hasOverlap:Bool = false;

      for (noteA in notesA)
      {
        if (doNotesStack(noteA, noteB, threshold))
        {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap)
      {
        result.push(noteB);
      }
      else if (modifyB)
      {
        overlappingNotes.push(noteB);
      }
    }

    if (modifyB)
    {
      for (note in overlappingNotes)
        notesB.remove(note);
    }

    return result;
  }

  /**
   * Concatenates two arrays of notes but overwrites notes in `lhs` that are overlapped by notes from `rhs`.
   * This does not modify the fist array but does modify the second.
   * @param lhs
   * @param rhs
   * @param threshold Threshold in ms
   * @param overwrittenNotes An array that is modified in-place with the notes in `lhs` that were overwritten.
   * @return `lhs` + `rhs`
   */
  public static function concatOverwrite(lhs:Array<SongNoteData>, rhs:Array<SongNoteData>, threshold:Float,
      ?overwrittenNotes:Array<SongNoteData>):Array<SongNoteData>
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
            // Do not resize array with remove() now to not screw with loop
            rhs[i] = null;
          }
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) result.push(noteB);
    }

    // Now we can safely resize it
    rhs = rhs.filterNull();

    return result;
  }

  /**
   * @param threshold
   * @return Returns `true` if both notes are on the same strumline, have the same direction and their time difference is less than `threshold`.
   */
  public static function doNotesStack(noteA:SongNoteData, noteB:SongNoteData, threshold:Float):Bool
  {
    return noteA.data == noteB.data && Math.fceil(Math.abs(noteA.time - noteB.time)) <= threshold;
  }

  // This is replacing SongNoteData's equals operator because for some reason its params check is unreliable.
  static function noteEquals(noteA:SongNoteData, other:SongNoteData):Bool
  {
    if (noteA == null) return other == null;
    if (other == null) return false;

    // TESTME: These checks seem redundant when kind's getter already returns null if it's an empty string.
    if (noteA.kind == null || noteA.kind == '')
    {
      if (other.kind != '' && noteA.kind != null) return false;
    }
    else
    {
      if (other.kind == '' || noteA.kind == null) return false;
    }

    // params check is unreliable and doNotesStack already checks data
    return noteA.time == other.time && noteA.length == other.length;
  }
}
