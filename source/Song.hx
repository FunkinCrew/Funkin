package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class SwagSong
{
	public var file:String;
	public var metadata:SongMetadata;
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Int;
	public var sections:Int;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';

	public function new()
	{
	}

	public static function loadFromJson(path:String, meta:SongMetadata):SwagSong
	{
		#if sys
		var rawJson = File.getContent(path).trim();
		#else
		var rawJson = Assets.getText(path).trim();
		#end

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var swagJson = Json.parse(rawJson).song;
		var swag = new SwagSong();
		swag.file = path;
		swag.metadata = meta;
		swag.song = swagJson.song;
		swag.notes = swagJson.notes;
		swag.bpm = swagJson.bpm;
		swag.sections = swagJson.sections;
		swag.speed = swagJson.speed;
		swag.player1 = swagJson.player1;
		swag.player2 = swagJson.player2;

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
				daSections = songData.sections;
				daBpm = songData.bpm;
				daSectionLengths = songData.sectionLengths; */

		return swag;
	}
}
