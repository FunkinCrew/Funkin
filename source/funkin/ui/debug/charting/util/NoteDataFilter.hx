package funkin.ui.debug.charting.util;

import funkin.data.song.SongData.SongNoteData;

/**
 * Helper class for filtering notes
 */
class NoteDataFilter
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
      // noticed a bug that displayedNoteData somehow can have duplicate notes
      // thats why we need `chunks[chunks.length - 1].contains(note)`
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
   * @param notesA An array of notes into which `notesB` will be concatenated.
   * @param notesB Another array of notes that will be concated into `notesA`.
   * @param threshold Threshold in ms
   * @param modifyB If `true`, `notesB` will be modified in-place by removing the notes that overlap notes from `notesA`.
   * @return Array<SongNoteData>
   */
  public static function concatNoOverlap(notesA:Array<SongNoteData>, notesB:Array<SongNoteData>, threshold:Float, modifyB:Bool = false):Array<SongNoteData>
  {
    // TODO: Maybe this whole function should be moved to SongNoteDataArrayTools
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
   * @param threshold
   * @return Returns `true` if both notes are on the same strumline, have the same direction and their time difference is less than `threshold`.
   */
  static inline function doNotesStack(noteA:SongNoteData, noteB:SongNoteData, threshold:Float):Bool
  {
    return noteA.data == noteB.data && Math.abs(noteA.time - noteB.time) <= threshold;
  }
}
