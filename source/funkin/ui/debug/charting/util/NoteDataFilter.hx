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
      if (note == null)
      {
        continue;
      }

      if (note.time >= chunkTime && note.time < chunkTime + CHUNK_INTERVAL_MS)
      {
        chunks[chunks.length - 1].push(note);
      }
      else
      {
        chunks.push([]);
        chunkTime += CHUNK_INTERVAL_MS;
      }
    }

    for (chunk in chunks)
    {
      for (i in 0...chunk.length - 1)
      {
        for (j in i...chunk.length)
        {
          var noteI:SongNoteData = chunk[i];
          var noteJ:SongNoteData = chunk[j];

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

    return stackedNotes;
  }
}
