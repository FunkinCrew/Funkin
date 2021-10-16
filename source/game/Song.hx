package game;

#if sys
import sys.FileSystem;
import sys.io.File;
import polymod.backends.PolymodAssets;
#end
import utilities.CoolUtil;
import states.PlayState;
import game.Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

using StringTools;

class Event
{
	public var name:String;
	public var position:Float;
	public var value:Float;
	public var type:String;

	public function new(name:String,pos:Float,value:Float,type:String)
	{
		this.name = name;
		this.position = pos;
		this.value = value;
		this.type = type;
	}
}

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gf:String;
	var stage:String;
	var validScore:Bool;

	var modchartPath:String;

	var keyCount:Int;

	// shaggy pog
	var mania:Int;

	var ui_Skin:String;

	var cutscene:String;

	var eventObjects:Array<Event>;
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
	public var gf:String = 'gf';
	
	public var stage:String = 'chromatic-stage';

	public var keyCount:Int = 4;

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var original_Folder = folder;
		
		folder = "song data/" + folder + "/";

		var rawJson:String = "";

		rawJson = Assets.getText(Paths.json(folder.toLowerCase() + jsonInput.toLowerCase())).trim();

		if(rawJson != "")
		{
			while (!rawJson.endsWith("}"))
			{
				rawJson = rawJson.substr(0, rawJson.length - 1);
				// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
			}
	
			return parseJSONshit(rawJson);
		}
		else
		{
			rawJson = Assets.getText(Paths.json("song data/tutorial/tutorial")).trim();

			while (!rawJson.endsWith("}"))
			{
				rawJson = rawJson.substr(0, rawJson.length - 1);
				// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
			}
	
			return parseJSONshit(rawJson, original_Folder);
		}
	}

	public static function parseJSONshit(rawJson:String, ?originalSongName:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;

		if(Std.string(swagShit.keyCount) == "null")
			swagShit.keyCount = 4;
		
		if(Std.string(swagShit.mania) != "null")
		{
			//shaggy support pog
			switch(swagShit.mania)
			{
				case 0:
					swagShit.keyCount = 4;
				case 1:
					swagShit.keyCount = 6;
				case 2:
					swagShit.keyCount = 7;
				case 3:
					swagShit.keyCount = 9;
			}
		}

		if(originalSongName != null)
			swagShit.song = originalSongName;

		if(Std.string(swagShit.ui_Skin) == "null")
			swagShit.ui_Skin = swagShit.song == "Senpai" || swagShit.song == "Roses" || swagShit.song == "Thorns" ? "pixel" : "default";

		return swagShit;
	}
}
