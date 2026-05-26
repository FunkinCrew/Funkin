package funkin.data.song;

import flixel.util.FlxSort;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongTimeChange;
import funkin.util.ClipboardUtil;

using Lambda;

/**
 * Utility functions for working with song data, including note data, event data, metadata, etc.
 */
@:nullSafety
class SongDataUtils
{
  /**
   * Given an array of SongNoteData objects, return a new array of SongNoteData objects
   * whose timestamps are shifted by the given amount.
   * Does not mutate the original array.
   *
   * @param notes The notes to modify.
   * @param offset The time difference to apply in milliseconds.
   * @return The modified array of notes.
   */
  public static function offsetSongNoteData(notes:Array<SongNoteData>, offset:Float):Array<SongNoteData>
  {
    return notes.map((note:SongNoteData) ->
    {
      var time:Float = note.time + offset;
      var data:Int = note.data;
      var length:Float = note.length;
      var kind:Null<String> = note.kind;
      return new SongNoteData(time, data, length, kind);
    });
  }

  /**
   * Given an array of SongEventData objects, return a new array of SongEventData objects
   * whose timestamps are shifted by the given amount.
   * Does not mutate the original array.
   *
   * @param events The events to modify.
   * @param offset The time difference to apply in milliseconds.
   * @return The modified array of events.
   */
  public static function offsetSongEventData(events:Array<SongEventData>, offset:Float):Array<SongEventData>
  {
    return events.map((event:SongEventData) ->
    {
      return new SongEventData(event.time + offset, event.eventKind, event.value, event.editorLayer);
    });
  }

  /**
   * Given an array of SongNoteData objects, return a new array of SongNoteData objects
   * which excludes any notes whose timestamps are outside of the given range.
   * @param notes The notes to modify.
   * @param startTime The start of the range in milliseconds.
   * @param endTime The end of the range in milliseconds.
   * @return The filtered array of notes.
   */
  public static function clampSongNoteData(notes:Array<SongNoteData>, startTime:Float, endTime:Float):Array<SongNoteData>
  {
    return notes.filter((note:SongNoteData) ->
    {
      return note.time >= startTime && note.time <= endTime;
    });
  }

  /**
   * Given an array of SongEventData objects, return a new array of SongEventData objects
   * which excludes any events whose timestamps are outside of the given range.
   * @param events The events to modify.
   * @param startTime The start of the range in milliseconds.
   * @param endTime The end of the range in milliseconds.
   * @return The filtered array of events.
   */
  public static function clampSongEventData(events:Array<SongEventData>, startTime:Float, endTime:Float):Array<SongEventData>
  {
    return events.filter((event:SongEventData) ->
    {
      return event.time >= startTime && event.time <= endTime;
    });
  }

  /**
   * Return a new array without a certain subset of notes from an array of SongNoteData objects.
   * Does not mutate the original array.
   *
   * @param notes The array of notes to be subtracted from.
   * @param subtrahend The notes to remove from the `notes` array. Yes, subtrahend is a real word.
   * @return The filtered array of notes.
   */
  public static function subtractNotes(notes:Array<SongNoteData>, subtrahend:Array<SongNoteData>):Array<SongNoteData>
  {
    if (notes.length == 0 || subtrahend.length == 0) return notes;

    var result = notes.filter((note:SongNoteData) ->
    {
      // Check if this note is in the `subtrahend` array.
      // We can't just use `.contains()` because we are comparing by value.
      for (x in subtrahend)
      {
        if (x == note) return false;
      }

      return true;
    });

    return result;
  }

  /**
   * Return a new array without a certain subset of events from an array of SongEventData objects.
   * Does not mutate the original array.
   *
   * @param events The array of events to be subtracted from.
   * @param subtrahend The events to remove from the `events` array. Yes, subtrahend is a real word.
   * @return The filtered array of events.
   */
  public static function subtractEvents(events:Array<SongEventData>, subtrahend:Array<SongEventData>):Array<SongEventData>
  {
    if (events.length == 0 || subtrahend.length == 0) return events;

    return events.filter((event:SongEventData) ->
    {
      for (x in subtrahend)
      {
        // The currently iterated event is in the subtrahend array.
        // SongEventData's == operation has been overridden so that this will work.
        if (x == event) return false;
      }
      return true;
    });
  }

  /**
   * Create an array of notes whose note data is flipped (player becomes opponent and vice versa)
   * Does not mutate the original array.
   *
   * @param notes The array of notes to be flipped.
   * @param strumlineSize The size of the strumline.
   * @return The flipped array of notes.
   */
  public static function flipNotes(notes:Array<SongNoteData>, strumlineSize:Int = 4):Array<SongNoteData>
  {
    return notes.map((note:SongNoteData) ->
    {
      var newData = note.data;

      if (newData < strumlineSize)
      {
        newData += strumlineSize;
      }
      else
      {
        newData -= strumlineSize;
      }

      return new SongNoteData(note.time, newData, note.length, note.kind);
    });
  }

  /**
   * Create an array of notes whose note data is mirrored.
   * Does not mutate the original array.
   *
   * @param notes The array of notes to be mirrored.
   * @param strumlineSize The size of the strumline.
   * @param flip Flip the notes if the notes given are in both strumlines, so that result isn't inverted when mirrored.
   * @param mirrorX Mirror along the X axis, aka the directions of the notes.
   * @param mirrorY Mirror along the Y axis, aka the time of the notes.
   * @return The mirrored array of notes.
   */
  public static function mirrorNotes(notes:Array<SongNoteData>, strumlineSize:Int = 4, flip:Bool = false, mirrorX:Bool = true,
      mirrorY:Bool = true):Array<SongNoteData>
  {
    var minTime = notes[0].time;
    var maxTime = notes[0].time;
    var minStrumline = notes[0].data;
    var maxStrumline = notes[0].data;
    for (note in notes)
    {
      // Find the maximum and minimum time and strumline positions
      // I wish there was a better way of doing this
      if (flip)
      {
        if (note.data < minStrumline)
        {
          minStrumline = note.data;
        }
        else if (note.data > maxStrumline)
        {
          maxStrumline = note.data;
        }
      }
      if (note.time < minTime)
      {
        minTime = note.time;
      }
      else if (note.time > maxTime)
      {
        maxTime = note.time;
      }
    }

    var timeDiff = minTime + (maxTime - minTime) / 2;
    if (flip && minStrumline < strumlineSize && strumlineSize < maxStrumline)
    {
      // Flip the notes if one of the notes is on the other strum
      // Otherwise they'll be inverted when mirrored
      notes = flipNotes(notes);
    }

    return notes.map((note:SongNoteData) ->
    {
      var newData = note.data;
      var newTime = note.time;

      if (mirrorX)
      {
        if (newData < strumlineSize)
        {
          newData = strumlineSize - 1 - newData;
        }
        else
        {
          newData = strumlineSize + strumlineSize * 2 - 1 - newData;
        }
      }
      if (mirrorY)
      {
        if (newTime < timeDiff)
        {
          newTime += (timeDiff - newTime) * 2;
        }
        else if (newTime > timeDiff)
        {
          newTime -= (newTime - timeDiff) * 2;
        }
      }

      return new SongNoteData(newTime, newData, note.length, note.kind);
    });
  }

  /**
   * Prepare an array of notes to be used as the clipboard data.
   *
   * Offset the provided array of notes such that the first note is at 0 milliseconds.
   * This is used to ensure events you paste are centered on the cursor.
   *
   * @param notes The notes to offset.
   * @param timeOffset The time offset to apply. If null, the first note's time will be used.
   * @return The offset notes.
   */
  public static function buildNoteClipboard(notes:Array<SongNoteData>, ?timeOffset:Int):Array<SongNoteData>
  {
    if (notes.length == 0) return notes;
    if (timeOffset == null) timeOffset = Std.int(notes[0].time);
    return offsetSongNoteData(sortNotes(notes), -timeOffset);
  }

  /**
   * Prepare an array of events to be used as the clipboard data.
   *
   * Offset the provided array of events such that the first event is at 0 milliseconds.
   * This is used to ensure events you paste are centered on the cursor.
   *
   * @param events The events to offset.
   * @param timeOffset The time offset to apply. If null, the first event's time will be used.
   * @return The offset events.
   */
  public static function buildEventClipboard(events:Array<SongEventData>, ?timeOffset:Int):Array<SongEventData>
  {
    if (events.length == 0) return events;
    if (timeOffset == null) timeOffset = Std.int(events[0].time);
    return offsetSongEventData(sortEvents(events), -timeOffset);
  }

  /**
   * Sort an array of notes by strum time.
   * TODO: Replace with `notes.sort(SortUtil.eventDataByTime)`
   *
   * @param notes The notes to sort.
   * @param desc If true, sort in descending order.
   * @return The sorted notes.
   */
  public static function sortNotes(notes:Array<SongNoteData>, desc:Bool = false):Array<SongNoteData>
  {
    // TODO: Modifies the array in place. Is this okay?
    notes.sort(function(a:SongNoteData, b:SongNoteData):Int
    {
      return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time);
    });
    return notes;
  }

  /**
   * Sort an array of events by strum time.
   * TODO: Replace with `notes.sort(SortUtil.noteDataByTime)`
   *
   * @param events The events to sort.
   * @param desc If true, sort in descending order.
   * @return The sorted events.
   */
  public static function sortEvents(events:Array<SongEventData>, desc:Bool = false):Array<SongEventData>
  {
    // TODO: Modifies the array in place. Is this okay?
    events.sort(function(a:SongEventData, b:SongEventData):Int
    {
      return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time);
    });
    return events;
  }

  /**
   * Sort an array of notes by strum time.
   *
   * @param timeChanges The time changes to sort.
   * @param desc If true, sort in descending order.
   * @return The sorted time changes.
   */
  public static function sortTimeChanges(timeChanges:Array<SongTimeChange>, desc:Bool = false):Array<SongTimeChange>
  {
    // TODO: Modifies the array in place. Is this okay?
    timeChanges.sort(function(a:SongTimeChange, b:SongTimeChange):Int
    {
      return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.timeStamp, b.timeStamp);
    });
    return timeChanges;
  }

  /**
   * Serialize note and event data and write it to the system clipboard.
   * This lets you paste it back into the editor later.
   *
   * @param data The note and event data to write to the clipboard.
   */
  public static function writeItemsToClipboard(data:SongClipboardItems):Void
  {
    var ignoreNullOptionals = true;
    var writer = new json2object.JsonWriter<SongClipboardItems>(ignoreNullOptionals);
    var dataString:String = writer.write(data, ' ');

    ClipboardUtil.setClipboard(dataString);

    trace('Wrote ' + data.notes.length + ' notes and ' + data.events.length + ' events to clipboard.');
  }

  /**
   * Read an array of note data from the clipboard and deserialize it.
   *
   * @return The note and event data, parsed from the user's clipboard.
   *   If it failed to parse, `valid` will be false.
   */
  public static function readItemsFromClipboard():SongClipboardItems
  {
    var notesString = ClipboardUtil.getClipboard();

    trace('Read ${notesString.length} characters from clipboard.');

    var parser = new json2object.JsonParser<SongClipboardItems>();
    parser.ignoreUnknownVariables = false;
    parser.fromJson(notesString, 'clipboard');
    if (parser.errors.length > 0)
    {
      trace('[SongDataUtils] Error parsing note JSON data from clipboard.');
      for (error in parser.errors) DataError.printError(error);
      return {
        valid: false,
        notes: [],
        events: []
      };
    }
    else
    {
      var data:SongClipboardItems = parser.value;
      trace('Parsed ' + data.notes.length + ' notes and ' + data.events.length + ' from clipboard.');
      data.valid = true;
      return data;
    }
  }

  /**
   * Filter a list of notes to only include notes that are within the given time range.
   *
   * @param notes The list of notes to filter.
   * @param start The start of the time range.
   * @param end The end of the time range.
   * @return The filtered list of notes.
   */
  public static function getNotesInTimeRange(notes:Array<SongNoteData>, start:Float, end:Float):Array<SongNoteData>
  {
    return notes.filter((note:SongNoteData) ->
    {
      return note.time >= start && note.time <= end;
    });
  }

  /**
   * Filter a list of events to only include events that are within the given time range.
   *
   * @param events The list of events to filter.
   * @param start The start of the time range.
   * @param end The end of the time range.
   * @return The filtered list of events.
   */
  public static function getEventsInTimeRange(events:Array<SongEventData>, start:Float, end:Float):Array<SongEventData>
  {
    return events.filter((event:SongEventData) ->
    {
      return event.time >= start && event.time <= end;
    });
  }

  /**
   * Filter a list of notes to only include notes whose data is within the given range, inclusive.
   *
   * @param notes The list of notes to filter.
   * @param start The start of the data range.
   * @param end The end of the data range.
   * @return The filtered list of notes.
   */
  public static function getNotesInDataRange(notes:Array<SongNoteData>, start:Int, end:Int):Array<SongNoteData>
  {
    return notes.filter((note:SongNoteData) ->
    {
      return note.data >= start && note.data <= end;
    });
  }

  /**
   * Filter a list of notes to only include notes whose data is one of the given values.
   *
   * @param notes The list of notes to filter.
   * @param data The list of data values to include.
   * @return The filtered list of notes.
   */
  public static function getNotesWithData(notes:Array<SongNoteData>, data:Array<Int>):Array<SongNoteData>
  {
    return notes.filter((note:SongNoteData) ->
    {
      return data.indexOf(note.data) != -1;
    });
  }

  /**
   * Filter a list of events to only include events whose kind is one of the given values.
   *
   * @param events The list of events to filter.
   * @param kinds The list of event kinds to include.
   * @return The filtered list of events.
   */
  public static function getEventsWithKind(events:Array<SongEventData>, kinds:Array<String>):Array<SongEventData>
  {
    return events.filter((event:SongEventData) ->
    {
      return kinds.indexOf(event.eventKind) != -1;
    });
  }
}

/**
 * Represents the data copied to clipboard from the Chart Editor.
 * Gets decoded into text to be put in the system clipboard; this lets you paste the data into a chat or something!
 */
typedef SongClipboardItems =
{
  @:optional
  var valid:Bool;
  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;
}
