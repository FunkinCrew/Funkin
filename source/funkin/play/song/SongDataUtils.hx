package funkin.play.song;

import flixel.util.FlxSort;
import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongNoteData;
import funkin.util.ClipboardUtil;
import funkin.util.SerializerUtil;

using Lambda;

class SongDataUtils
{
	/**
	 * Given an array of SongNoteData objects, return a new array of SongNoteData objects
	 * whose timestamps are shifted by the given amount.
	 * 
	 * @param notes The notes to modify.
	 * @param offset The time difference to apply in milliseconds.
	 */
	public static function offsetSongNoteData(notes:Array<SongNoteData>, offset:Int):Array<SongNoteData>
	{
		return notes.map(function(note:SongNoteData):SongNoteData
		{
			return new SongNoteData(note.time + offset, note.data, note.length, note.kind);
		});
	}

	/**
	 * Remove a certain subset of notes from an array of SongNoteData objects.
	 * 
	 * @param notes The array of notes to be subtracted from.
	 * @param subtrahend The notes to remove from the `notes` array. Yes, subtrahend is a real word.
	 */
	public static function subtractNotes(notes:Array<SongNoteData>, subtrahend:Array<SongNoteData>)
	{
		if (notes.length == 0 || subtrahend.length == 0)
			return notes;

		var result = notes.filter(function(note:SongNoteData):Bool
		{
			for (x in subtrahend)
				// SongNoteData's == operation has been overridden so that this will work.
				if (x == note)
					return false;

			return true;
		});

		return result;
	}

	/**
	 * Remove a certain subset of events from an array of SongEventData objects.
	 * 
	 * @param events The array of events to be subtracted from.
	 * @param subtrahend The events to remove from the `events` array. Yes, subtrahend is a real word.
	 */
	public static function subtractEvents(events:Array<SongEventData>, subtrahend:Array<SongEventData>)
	{
		if (events.length == 0 || subtrahend.length == 0)
			return events;

		return events.filter(function(event:SongEventData):Bool
		{
			// SongEventData's == operation has been overridden so that this will work.
			return !subtrahend.has(event);
		});
	}

	/**
	 * Prepare an array of notes to be used as the clipboard data.
	 * 
	 * Offset the provided array of notes such that the first note is at 0 milliseconds.
	 */
	public static function buildClipboard(notes:Array<SongNoteData>):Array<SongNoteData>
	{
		return offsetSongNoteData(sortNotes(notes), -Std.int(notes[0].time));
	}

	public static function sortNotes(notes:Array<SongNoteData>, ?desc:Bool = false):Array<SongNoteData>
	{
		// TODO: Modifies the array in place. Is this okay?
		notes.sort(function(a:SongNoteData, b:SongNoteData):Int
		{
			return FlxSort.byValues(desc ? FlxSort.DESCENDING : FlxSort.ASCENDING, a.time, b.time);
		});
		return notes;
	}

	public static function writeNotesToClipboard(notes:Array<SongNoteData>):Void
	{
		var notesString = SerializerUtil.toJSON(notes);

		ClipboardUtil.setClipboard(notesString);

		trace('Wrote ' + notes.length + ' notes to clipboard.');

		trace(notesString);
	}

	public static function readNotesFromClipboard():Array<SongNoteData>
	{
		var notesString = ClipboardUtil.getClipboard();

		trace('Read ' + notesString.length + ' characters from clipboard.');

		var notes:Array<SongNoteData> = SerializerUtil.fromJSON(notesString);

		if (notes == null)
		{
			trace('Failed to parse notes from clipboard.');
			return [];
		}
		else
		{
			trace('Parsed ' + notes.length + ' notes from clipboard.');
			return notes;
		}
	}
}
