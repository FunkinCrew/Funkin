package;

import haxe.Json;
import lime.utils.Assets;

class Song
{
	public var song:String;
	public var notes:Array<Dynamic>;
	public var bpm:Int;
	public var sections:Int;

	public function new(song, notes, bpm, sections)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
		this.sections = sections;
	}

	public static function loadFromJson(jsonInput:String):Song
	{
		var daNotes:Array<Dynamic> = [];
		var daBpm:Int = 0;
		var daSections:Int = 0;
		var daSong:String = '';

		var songData = Json.parse(Assets.getText('assets/data/' + jsonInput + '/' + jsonInput + '.json'));

		daNotes = songData.notes;
		daSong = songData.song;
		daSections = songData.sections;
		daBpm = songData.bpm;

		return new Song(daSong, daNotes, daBpm, daSections);
	}
}
