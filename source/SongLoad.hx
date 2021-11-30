package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<Array<SwagSection>>;
	var bpm:Float;
	var needsVoices:Bool;
	var voiceList:Array<String>;
	var speed:Array<Float>;

	var player1:String;
	var player2:String;
	var validScore:Bool;
}

class SongLoad
{
	public static var curDiff(default, set):Int = 0;
	public static var curNotes:Array<SwagSection>;
	public static var songData:SwagSong;

	static function set_curDiff(val:Int):Int
	{
		// automatically changes the selected NOTES?
		return val;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = Assets.getText(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())).trim();

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		// FIX THE CASTING ON WINDOWS/NATIVE
		// Windows???
		// trace(songData);

		// trace('LOADED FROM JSON: ' + songData.notes);
		/* 
			for (i in 0...songData.notes.length)
			{
				trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
				// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
			}

				daNotes = songData.notes;
				daSong = songData.song;
				daBpm = songData.bpm; */

		return parseJSONshit(rawJson);
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		// swagShit.notes[0] = cast Json.parse(rawJson).song.notes[SongLoad.curDiff]; // by default uses

		songData = swagShit;

		return swagShit;
	}
}
