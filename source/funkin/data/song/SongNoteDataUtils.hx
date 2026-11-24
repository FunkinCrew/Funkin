package funkin.data.song;

using SongData.SongNoteData;

/**
 * Utility class for extra handling of song notes
 */
@:nullSafety
class SongNoteDataUtils
{
  /**
   * Retrieves all stacked notes. It does this by checking each note against the ones right after it in time.
   *
   * @param notes Sorted notes by time.
   * @param threshold The note stack threshold. Refer to `doNotesStack` for more details.
   * @param includeOverlapped (Optional) If overlapped notes should be included.
   * @param overlapped (Optional) An array that gets populated with overlapped notes.
   * Note that it's only guaranteed to work properly if the provided notes are sorted.
   * @return Stacked notes.
   */
  public static function listStackedNotes(notes:Array<SongNoteData>, threshold:Float, includeOverlapped:Bool = true, ?overlapped:Array<SongNoteData>):Array<SongNoteData>
  {
    var stackedNotes:Array<SongNoteData> = [];
    var stackedSet:haxe.ds.ObjectMap<SongNoteData, Bool> = new haxe.ds.ObjectMap();
    var overlappedSet:haxe.ds.ObjectMap<SongNoteData, Bool> = new haxe.ds.ObjectMap();
    if (overlapped != null)
    {
      for (note in overlapped) overlappedSet.set(note, true);
    }

    var sorted:Array<SongNoteData> = [for (note in notes) if (note != null) note];
    sorted.sort((a, b) -> a.time < b.time ? -1 : (a.time > b.time ? 1 : 0));

    var stepTimes:Array<Float> = threshold == 0 ? [] : [for (note in sorted) note.getStepTime()];
    for (i in 0...sorted.length)
    {
      var noteI:SongNoteData = sorted[i];
      for (j in (i + 1)...sorted.length)
      {
        var noteJ:SongNoteData = sorted[j];
        if (threshold == 0)
        {
          if (noteJ.time - noteI.time >= 1) break;
        }
        else if (stepTimes[j] - stepTimes[i] > threshold + 0.001) break;

        if (!doNotesStack(noteI, noteJ, threshold)) continue;

        if (!stackedSet.exists(noteI))
        {
          if (includeOverlapped)
          {
            stackedNotes.push(noteI);
            stackedSet.set(noteI, true);
          }

          if (overlapped != null && !overlappedSet.exists(noteI))
          {
            overlapped.push(noteI);
            overlappedSet.set(noteI, true);
          }
        }

        if (!stackedSet.exists(noteJ))
        {
          stackedNotes.push(noteJ);
          stackedSet.set(noteJ, true);
        }
      }
    }

    return stackedNotes;
  }

  /**
   * Concatenates two arrays of notes, removing any notes in `lhs` that are stacked under a note in `rhs`.
   * Incoming notes always win, and if several notes in `rhs` stack with each other, only the last one is kept.
   * Does not modify `lhs`; `rhs` is modified in place to remove the incoming notes that were dropped.
   *
   * @param lhs An array of notes
   * @param rhs An array of notes to concatenate into `lhs`
   * @param overwrittenNotes An optional array that is modified in-place with the original notes from `lhs` that were overwritten.
   * @param threshold The note stack threshold. Refer to `doNotesStack` for more details.
   * @return The unsorted resulting array.
   */
  public static function concatOverwrite(lhs:Array<SongNoteData>, rhs:Array<SongNoteData>, ?overwrittenNotes:Array<SongNoteData>, threshold:Float = 0):Array<SongNoteData>
  {
    if (lhs == null || rhs == null || rhs.length == 0) return lhs;

    var kept:Array<SongNoteData> = [];
    var i:Int = rhs.length;
    while (i-- > 0)
    {
      var note:SongNoteData = rhs[i];
      var stacked:Bool = false;
      for (other in kept)
      {
        if (doNotesStack(note, other, threshold))
        {
          stacked = true;
          break;
        }
      }
      if (!stacked) kept.push(note);
    }
    kept.reverse();
    if (kept.length != rhs.length)
    {
      rhs.resize(0);
      for (note in kept) rhs.push(note);
    }

    // Group the incoming notes by direction so each existing note only checks notes it could stack with.
    var rhsByData:Map<Int, Array<SongNoteData>> = [];
    for (note in rhs)
    {
      var bucket:Null<Array<SongNoteData>> = rhsByData.get(note.data);
      if (bucket == null) rhsByData.set(note.data, [note]);
      else
        bucket.push(note);
    }

    var result:Array<SongNoteData> = [];
    for (noteA in lhs)
    {
      var overwritten:Bool = false;
      for (noteB in rhsByData.get(noteA.data) ?? [])
      {
        if (doNotesStack(noteA, noteB, threshold))
        {
          overwritten = true;
          break;
        }
      }

      if (overwritten) overwrittenNotes?.push(noteA);
      else
        result.push(noteA);
    }

    return result.concat(rhs);
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
