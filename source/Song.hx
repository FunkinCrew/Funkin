package;

import haxe.Json;
import lime.utils.Assets;

class Song
{
	public var song:String;
	public var notes:Array<Section>;
	public var bpm:Int;
	public var sections:Int;
	public var sectionLengths:Array<Dynamic> = [];

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

		var songData = Json.parse(Assets.getText('assets/data/' + jsonInput + '/' + jsonInput + '.json'));

		daNotes = songData.notes;
		daSong = songData.song;
		daSections = songData.sections;
		daBpm = songData.bpm;
		daSectionLengths = songData.sectionLengths;

		return new Song(daSong, daNotes, daBpm, daSections);
	}
}
