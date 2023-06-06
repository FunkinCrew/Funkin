package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import sys.FileSystem;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson:String;
		if (FileSystem.exists(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())))
        {
			rawJson = Assets.getText(Paths.json(folder.toLowerCase() + '/' + jsonInput.toLowerCase())).trim();
        }
        else
        {
			rawJson = '{"song": {"song": "' + folder + '","bpm": 100.0,"needsVoices": true,"player1": "bf","player2": "dad","speed": 1.3,"notes": [{"lengthInSteps": 16,"mustHitSection": false,"sectionNotes": []},{"lengthInSteps": 16,"mustHitSection": false,"sectionNotes": []},{"lengthInSteps": 16,"mustHitSection": false,"sectionNotes": []},{"lengthInSteps": 16,"mustHitSection": false,"sectionNotes": []},{"lengthInSteps": 16,"mustHitSection": false,"sectionNotes": []},{"lengthInSteps": 16,"mustHitSection": false,"sectionNotes": []},{"lengthInSteps": 16,"mustHitSection": false,"sectionNotes": []},{"lengthInSteps": 16,"mustHitSection": false,"sectionNotes": []},{"lengthInSteps": 16,"mustHitSection": false,"sectionNotes": []}]},"generatedBy": "SNIFF ver.6"}';
        }
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
		return swagShit;
	}
}
