package;

import Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import tjson.TJSON;
#if sys
import sys.io.File;
import lime.system.System;
import haxe.io.Path;
#end
using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Int;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var stage:String;
	var gf:String;
	var isMoody:Null<Bool>;
	var cutsceneType:String;
	var uiType:String;
	var isSpooky:Null<Bool>;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Int;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var stage:String = 'stage';
	public var gf:String = 'gf';
	public var isMoody:Null<Bool> = false;
	public var isSpooky:Null<Bool> = false;
	public var cutsceneType:String = "none";
	public var uiType:String = 'normal';
	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson:String = "";
		if (jsonInput != folder)
		{
			// means this isn't normal difficulty
			// raw json 
			// folder is always just the song name
			rawJson = File.getContent("assets/data/"+folder.toLowerCase()+"/"+folder.toLowerCase()+".json").trim();
		} else {
			#if sys
			rawJson = File.getContent("assets/data/" + folder.toLowerCase() + "/" + jsonInput.toLowerCase() + '.json').trim();
			#else
			rawJson = Assets.getText('assets/data/' + folder.toLowerCase() + '/' + jsonInput.toLowerCase() + '.json').trim();
			#end
		}
		
		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}
		var parsedJson = parseJSONshit(rawJson);
		if (parsedJson.stage == null) {
			if (parsedJson.song.toLowerCase() == 'spookeez'|| parsedJson.song.toLowerCase() == 'monster' || parsedJson.song.toLowerCase() == 'south') {
				parsedJson.stage = 'spooky';
			} else if (parsedJson.song.toLowerCase() == 'pico' || parsedJson.song.toLowerCase() == 'philly' || parsedJson.song.toLowerCase() == 'blammed') {
				parsedJson.stage = 'philly';
			} else if (parsedJson.song.toLowerCase() == 'milf' || parsedJson.song.toLowerCase() == 'high' || parsedJson.song.toLowerCase() == 'satin-panties') {
				parsedJson.stage = 'limo';
			} else if (parsedJson.song.toLowerCase() == 'cocoa' || parsedJson.song.toLowerCase() == 'eggnog') {
				parsedJson.stage = 'mall';
			} else if (parsedJson.song.toLowerCase() == 'winter-horrorland') {
				parsedJson.stage = 'mallEvil';
			} else if (parsedJson.song.toLowerCase() == 'senpai' || parsedJson.song.toLowerCase() == 'roses'){
				parsedJson.stage = 'school';
			} else if (parsedJson.song.toLowerCase() == 'thorns'){
				parsedJson.stage = 'schoolEvil';
			} else {
				parsedJson.stage = 'stage';
			}
		}
		trace(parsedJson.stage);
		if (parsedJson.gf == null) {
			// are you kidding me did i really do song to lowercase
			switch (parsedJson.stage) {
				case 'limo':
					parsedJson.gf = 'gf-car';
				case 'mall':
					parsedJson.gf = 'gf-christmas';
				case 'mallEvil':
					parsedJson.gf = 'gf-christmas';
				case 'school':
					parsedJson.gf = 'gf-pixel';
				case 'schoolEvil':
					parsedJson.gf = 'gf-pixel';
				default:
					parsedJson.gf = 'gf';
			}

		}
		if (parsedJson.isMoody == null) {
			if (parsedJson.song.toLowerCase() == 'roses') {
				parsedJson.isMoody = true;
			} else {
				parsedJson.isMoody = false;
			}
		}
		// is spooky means trails on spirit
		if (parsedJson.isSpooky == null) {
			if (parsedJson.stage.toLowerCase() == 'mallEvil') {
				parsedJson.isSpooky = true;
			} else {
				parsedJson.isSpooky = false;
			}
		}
		if (parsedJson.song.toLowerCase() == 'winter-horrorland') {
			parsedJson.cutsceneType = "monster";
		}
		if (parsedJson.cutsceneType == null) {
			switch (parsedJson.song.toLowerCase()) {
				case 'roses':
					parsedJson.cutsceneType = "angry-senpai";
				case 'senpai':
					parsedJson.cutsceneType = "senpai";
				case 'thorns':
					parsedJson.cutsceneType = 'spirit';
				case 'winter-horrorland':
					parsedJson.cutsceneType = 'monster';
				default:
					parsedJson.cutsceneType = 'none';
			}
		}
		if (parsedJson.uiType == null) {
			if (parsedJson.song.toLowerCase() == 'roses' || parsedJson.song.toLowerCase() == 'senpai' || parsedJson.song.toLowerCase() == 'thorns') {
				parsedJson.uiType = 'pixel';
			} else {
				parsedJson.uiType = 'normal';
			}
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
				daSections = songData.sections;
				daBpm = songData.bpm;
				daSectionLengths = songData.sectionLengths; */
		if (jsonInput != folder)
		{
			// means this isn't normal difficulty
			// lets finally overwrite notes
			var realJson = parseJSONshit(File.getContent("assets/data/" + folder.toLowerCase() + "/" + jsonInput.toLowerCase() + '.json').trim());
			parsedJson.notes = realJson.notes;
			parsedJson.bpm = realJson.bpm;
			parsedJson.sections = realJson.sections;
			parsedJson.sectionLengths = realJson.sectionLengths;
			parsedJson.needsVoices = realJson.needsVoices;
			parsedJson.speed = realJson.speed;
		}
		return parsedJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast CoolUtil.parseJson(rawJson).song;
		return swagShit;
	}
}
