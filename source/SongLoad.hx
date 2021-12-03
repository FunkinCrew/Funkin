package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Map<String, Array<SwagSection>>;
	var bpm:Float;
	var needsVoices:Bool;
	var voiceList:Array<String>;
	var speed:Map<String, Float>;

	var player1:String;
	var player2:String;
	var validScore:Bool;
	var extraNotes:Map<String, Array<SwagSection>>;
}

class SongLoad
{
	public static var curDiff:String = 'normal';
	public static var curNotes:Array<SwagSection>;
	public static var songData:SwagSong;

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

		trace(swagShit);

		songData = swagShit;
		// curNotes = songData.notes.get('normal');

		return swagShit;
	}
}
