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
  public static function filterStackedNotes(notes:Array<SongNoteData>, threshold:Float):Array<SongNoteData>
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

          if (noteI.getStrumlineIndex() == noteJ.getStrumlineIndex() && noteI.getDirection() == noteJ.getDirection())
          {
            if (Math.abs(noteJ.time - noteI.time) <= threshold)
            {
              if (!stackedNotes.contains(noteI))
              {
                stackedNotes.push(noteI);
              }

              if (!stackedNotes.contains(noteJ))
              {
                stackedNotes.push(noteJ);
              }
            }
          }
        }
      }
    }

    return stackedNotes;
  }
}
