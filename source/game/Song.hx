package game;

import utilities.NoteVariables;
import game.Section.SwagSection;
import haxe.Json;
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
	var gf:Null<String>;
	var stage:String;
	var validScore:Bool;

	var modchartPath:String;

	var keyCount:Null<Int>;
	var playerKeyCount:Null<Int>;

	var timescale:Array<Int>;

	var chartOffset:Null<Int>; // in milliseconds

	// shaggy pog
	var mania:Null<Int>;

	var ui_Skin:Null<String>;

	var cutscene:String;
	var endCutscene:String;

	var eventObjects:Array<Event>;

	var events:Null<Array<Array<Dynamic>>>;

	var specialAudioName:Null<String>;

	var gfVersion:Null<String>;
	var player3:Null<String>;
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
	public var gf:Null<String> = 'gf';
	
	public var stage:Null<String> = 'stage';

	public var keyCount:Null<Int> = 4;
	public var playerKeyCount:Null<Int> = 4;

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

		if(Std.string(swagShit.playerKeyCount) == "null")
			swagShit.playerKeyCount = swagShit.keyCount;

		if(originalSongName != null)
			swagShit.song = originalSongName;

		if(Std.string(swagShit.ui_Skin) == "null")
			swagShit.ui_Skin = swagShit.song == "Senpai" || swagShit.song == "Roses" || swagShit.song == "Thorns" ? "pixel" : "default";

		if(swagShit.timescale == null)
			swagShit.timescale = [4,4];

		if(swagShit.chartOffset == null)
			swagShit.chartOffset = 0;

		swagShit.mania = null;

		if(swagShit.keyCount > NoteVariables.Note_Count_Directions.length)
			swagShit.keyCount = NoteVariables.Note_Count_Directions.length; // guarenteed safe value?

		if(swagShit.events == null)
			swagShit.events = [];

		if(swagShit.gfVersion != null && swagShit.gf == null)
			swagShit.gf = swagShit.gfVersion;

		if(swagShit.player3 != null && swagShit.gf == null)
			swagShit.gf = swagShit.player3;

		var new_events:Array<Array<Dynamic>> = [];

		for(event in swagShit.events)
		{
			// aka, if(event == A Psych Engine Event Lmfao)
			if(Std.isOfType(event[0], Float) || Std.isOfType(event[0], Int) && Std.isOfType(event[1], Array))
			{
				var event_datas:Array<Array<Dynamic>> = event[1];

				for(actual_event_data in event_datas)
				{
					var new_event = [Std.string(actual_event_data[0]), event[0], Std.string(actual_event_data[1]), Std.string(actual_event_data[2])];
					new_events.push(new_event);
				}
			}
			else
				new_events.push(event);
		}

		if(swagShit.notes != null)
		{
			for (secNum in 0...swagShit.notes.length)
			{
				var sec:SwagSection = swagShit.notes[secNum];
	
				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
	
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
	
					if(note[1] < 0 && Std.isOfType(note[2], String))
					{
						if(note[3] == null)
							note[3] = "";
						if(note[4] == null)
							note[4] = "";

						new_events.push([note[2], note[0], note[3], note[4]]);
						notes.remove(note);
						len = notes.length;
					}
	
					else i++;
				}
			}
		}

		swagShit.events = new_events;

		return swagShit;
	}
}
