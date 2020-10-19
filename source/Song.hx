package;

import haxe.Json;
import lime.utils.Assets;

using StringTools;

class Song
{
	public var song:String;
	public var notes:Array<Section>;
	public var bpm:Int;
	public var sections:Int;
	public var sectionLengths:Array<Dynamic> = [];
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';

	public function new(song, notes, bpm, sections)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
		this.sections = sections;

		for (i in 0...notes.length)
		{
			this.sectionLengths.push(notes[i]);
		}
	}

	public static function loadFromJson(jsonInput:String):Song
	{
		var daNotes:Array<Section> = [];
		var daBpm:Int = 0;
		var daSections:Int = 0;
		var daSong:String = '';
		var daSectionLengths:Array<Int> = [];

		var rawJson = Assets.getText('assets/data/' + jsonInput + '/' + jsonInput + '.json').trim();

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		trace(rawJson);

		var songData:Song = Json.parse(rawJson).song;

		// trace('LOADED FROM JSON: ' + songData.notes);

		for (i in 0...songData.notes.length)
		{
			trace('LOADED FROM JSON: ' + songData.notes[i].sectionNotes);
			// songData.notes[i].sectionNotes = songData.notes[i].sectionNotes
		}
		/* 
			daNotes = songData.notes;
			daSong = songData.song;
			daSections = songData.sections;
			daBpm = songData.bpm;
			daSectionLengths = songData.sectionLengths; */

		return songData;
	}
}
