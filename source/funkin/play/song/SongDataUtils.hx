package funkin.play.song;

import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongNoteData;

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

		return notes.filter(function(note:SongNoteData):Bool
		{
			// SongNoteData's == operation has been overridden so that this will work.
			return !subtrahend.has(note);
		});
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
		return offsetSongNoteData(notes, -notes[0].time);
	}
}
