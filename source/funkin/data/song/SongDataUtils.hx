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
   */
  public static function offsetSongNoteData(notes:Array<SongNoteData>, offset:Float):Array<SongNoteData>
  {
    var offsetNote = function(note:SongNoteData):SongNoteData {
      var time:Float = note.time + offset;
      var data:Int = note.data;
      var length:Float = note.length;
      var kind:Null<String> = note.kind;
      return new SongNoteData(time, data, length, kind);
    };

    var result = [for (i in 0...notes.length) offsetNote(notes[i])];
    return result;
  }

  /**
   * Given an array of SongEventData objects, return a new array of SongEventData objects
   * whose timestamps are shifted by the given amount.
   * Does not mutate the original array.
   *
   * @param events The events to modify.
   * @param offset The time difference to apply in milliseconds.
   */
  public static function offsetSongEventData(events:Array<SongEventData>, offset:Float):Array<SongEventData>
  {
    return events.map(function(event:SongEventData):SongEventData {
      return new SongEventData(event.time + offset, event.eventKind, event.value);
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
    return notes.filter(function(note:SongNoteData):Bool {
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
    return events.filter(function(event:SongEventData):Bool {
      return event.time >= startTime && event.time <= endTime;
    });
  }

  /**
   * Return a new array without a certain subset of notes from an array of SongNoteData objects.
   * Does not mutate the original array.
   *
   * @param notes The array of notes to be subtracted from.
   * @param subtrahend The notes to remove from the `notes` array. Yes, subtrahend is a real word.
   */
  public static function subtractNotes(notes:Array<SongNoteData>, subtrahend:Array<SongNoteData>)
  {
    if (notes.length == 0 || subtrahend.length == 0) return notes;

    var result = notes.filter(function(note:SongNoteData):Bool {
      for (x in subtrahend)
      {
        // The currently iterated note is in the subtrahend array.
        // SongNoteData's == operation has been overridden so that this will work.
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
   */
  public static function subtractEvents(events:Array<SongEventData>, subtrahend:Array<SongEventData>)
  {
    if (events.length == 0 || subtrahend.length == 0) return events;

    return events.filter(function(event:SongEventData):Bool {
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
   */
  public static function flipNotes(notes:Array<SongNoteData>, strumlineSize:Int = 4):Array<SongNoteData>
  {
    return notes.map(function(note:SongNoteData):SongNoteData {
      var newData = note.data;

      if (newData < strumlineSize) newData += strumlineSize;
      else
        newData -= strumlineSize;

      return new SongNoteData(note.time, newData, note.length, note.kind);
    });
  }

  /**
   * Prepare an array of notes to be used as the clipboard data.
   *
   * Offset the provided array of notes such that the first note is at 0 milliseconds.
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
   */
  public static function buildEventClipboard(events:Array<SongEventData>, ?timeOffset:Int):Array<SongEventData>
  {
    if (events.length == 0) return events;
    if (timeOffset == null) timeOffset = Std.int(events[0].time);
    return offsetSongEventData(sortEvents(events), -timeOffset);
  }

  /**
   * Sort an array of notes by strum time.
   */
  public static function sortNotes(notes:Array<SongNoteData>, desc:Bool = false):Array<SongNoteData>
  {
    // TODO: Modifies the array in place. Is this okay?
    notes.sort(function(a:SongNoteData, b:SongNoteData):Int {
      return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time);
    });
    return notes;
  }

  /**
   * Sort an array of events by strum time.
   */
  public static function sortEvents(events:Array<SongEventData>, desc:Bool = false):Array<SongEventData>
  {
    // TODO: Modifies the array in place. Is this okay?
    events.sort(function(a:SongEventData, b:SongEventData):Int {
      return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time);
    });
    return events;
  }

  /**
   * Sort an array of notes by strum time.
   */
  public static function sortTimeChanges(timeChanges:Array<SongTimeChange>, desc:Bool = false):Array<SongTimeChange>
  {
    // TODO: Modifies the array in place. Is this okay?
    timeChanges.sort(function(a:SongTimeChange, b:SongTimeChange):Int {
      return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.timeStamp, b.timeStamp);
    });
    return timeChanges;
  }

  /**
   * Serialize note and event data and write it to the clipboard.
   */
  public static function writeItemsToClipboard(data:SongClipboardItems):Void
  {
    var ignoreNullOptionals = true;
    var writer = new json2object.JsonWriter<SongClipboardItems>(ignoreNullOptionals);
    var dataString:String = writer.write(data, '  ');

    ClipboardUtil.setClipboard(dataString);

    trace('Wrote ' + data.notes.length + ' notes and ' + data.events.length + ' events to clipboard.');
  }

  /**
   * Read an array of note data from the clipboard and deserialize it.
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
      for (error in parser.errors)
        DataError.printError(error);
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
   */
  public static function getNotesInTimeRange(notes:Array<SongNoteData>, start:Float, end:Float):Array<SongNoteData>
  {
    return notes.filter(function(note:SongNoteData):Bool {
      return note.time >= start && note.time <= end;
    });
  }

  /**
   * Filter a list of events to only include events that are within the given time range.
   */
  public static function getEventsInTimeRange(events:Array<SongEventData>, start:Float, end:Float):Array<SongEventData>
  {
    return events.filter(function(event:SongEventData):Bool {
      return event.time >= start && event.time <= end;
    });
  }

  /**
   * Filter a list of notes to only include notes whose data is within the given range, inclusive.
   */
  public static function getNotesInDataRange(notes:Array<SongNoteData>, start:Int, end:Int):Array<SongNoteData>
  {
    return notes.filter(function(note:SongNoteData):Bool {
      return note.data >= start && note.data <= end;
    });
  }

  /**
   * Filter a list of notes to only include notes whose data is one of the given values.
   */
  public static function getNotesWithData(notes:Array<SongNoteData>, data:Array<Int>):Array<SongNoteData>
  {
    return notes.filter(function(note:SongNoteData):Bool {
      return data.indexOf(note.data) != -1;
    });
  }

  /**
   * Filter a list of events to only include events whose kind is one of the given values.
   */
  public static function getEventsWithKind(events:Array<SongEventData>, kinds:Array<String>):Array<SongEventData>
  {
    return events.filter(function(event:SongEventData):Bool {
      return kinds.indexOf(event.eventKind) != -1;
    });
  }
}

typedef SongClipboardItems =
{
  @:optional
  var valid:Bool;
  var notes:Array<SongNoteData>;
  var events:Array<SongEventData>;
}
