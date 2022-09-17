package funkin.noteStuff;

import haxe.Json;
import openfl.Assets;

/**
 * Just various functions that IDK where to put em!!!
 * Semi-temp for now? the note stuff is super clutter-y right now
 * so I am putting this new stuff here right now XDD
 * 
 * A lot of this stuff can probably be moved to where appropriate!
 * i dont care about NoteUtil.hx at all!!!
 */
class NoteUtil
{
	/**
	 * IDK THING FOR BOTH LOL! DIS SHIT HACK-Y
	 * @param jsonPath 
	 * @return Map<Int, Array<SongEventInfo>>
	 */
	public static function loadSongEvents(jsonPath:String):Map<Int, Array<SongEventInfo>>
	{
		return parseSongEvents(loadSongEventFromJson(jsonPath));
	}

	public static function loadSongEventFromJson(jsonPath:String):Array<SongEvent>
	{
		var daEvents:Array<SongEvent>;
		daEvents = cast Json.parse(Assets.getText(jsonPath)).events; // DUMB LIL DETAIL HERE: MAKE SURE THAT .events IS THERE??
		trace('GET JSON SONG EVENTS:');
		trace(daEvents);
		return daEvents;
	}

	/**
	 * Parses song event json stuff into a neater lil map grouping?
	 * @param songEvents 
	 */
	public static function parseSongEvents(songEvents:Array<SongEvent>):Map<Int, Array<SongEventInfo>>
	{
		var songData:Map<Int, Array<SongEventInfo>> = new Map();

		for (songEvent in songEvents)
		{
			trace(songEvent);
			if (songData[songEvent.t] == null)
				songData[songEvent.t] = [];

			songData[songEvent.t].push({songEventType: songEvent.e, value: songEvent.v, activated: false});
		}

		trace("FINISH SONG EVENTS!");
		trace(songData);

		return songData;
	}

	public static function checkSongEvents(songData:Map<Int, Array<SongEventInfo>>, time:Float)
	{
		for (eventGrp in songData.keys())
		{
			if (time >= eventGrp)
			{
				for (events in songData[eventGrp])
				{
					if (!events.activated)
					{
						// TURN TO NICER SWITCH STATEMENT CHECKER OF EVENT TYPES!!
						trace(events.value);
						trace(eventGrp);
						trace(Conductor.songPosition);
						events.activated = true;
					}
				}
			}
		}
	}
}

typedef SongEventInfo =
{
	var songEventType:SongEventType;
	var value:Dynamic;
	var activated:Bool;
}

typedef SongEvent =
{
	var t:Int;
	var e:SongEventType;
	var v:Dynamic;
}

enum abstract SongEventType(String)
{
	var FocusCamera;
	var PlayCharAnim;
	var Trace;
}
