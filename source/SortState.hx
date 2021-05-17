package;

import flixel.util.typeLimit.OneOfTwo;
import FreeplayState.JsonMetadata;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import DifficultyIcons;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import sys.FileSystem;
import flash.media.Sound;
#end
import haxe.Json;
import tjson.TJSON;
import haxe.io.Bytes;
using StringTools;

class SortState extends MusicBeatState
{
	public static var sorting:String = "songs";
	public static var category:String = "Base Game";
	public static var sortedSongs:Array<OneOfTwo<String, JsonMetadata>> = [];
	public static var stuffToSort:Array<OneOfTwo<String, JsonMetadata>> = [];
	var referenceArray:Array<Int> = [];
	var songs:Array<OneOfTwo<String, JsonMetadata>> = [];
	var selector:FlxText;
	var curSelected:Int = 0;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var somethingSelected:Bool = false;
	var diffText:FlxText;
	var deleteStuff:Bool = false;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var checkmarks:Array<FlxSprite>;
	private var curPlaying:Bool = false;

	override function create()
	{
		

		// LOAD MUSIC

		// LOAD CHARACTERS
		songs = stuffToSort;
		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);
		checkmarks = [];
		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var coolName = "";
			if (sorting != "songs") {
				coolName = songs[i]; 
			} else {
				coolName = (songs:Array<JsonMetadata>)[i].name;
			}
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, coolName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			var checkmark = new FlxSprite(0, 0).loadGraphic('assets/images/checkmark.png');
			checkmark.visible = false;
			grpSongs.add(songText);
			songText.add(checkmark);
			referenceArray.push(i);
			checkmarks.push(checkmark);
			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		var scoreBG:FlxSprite = new FlxSprite((FlxG.width *0.62) - 6, 0).makeGraphic(Std.int(FlxG.width * 0.4), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreBG.x, 5, 0, "select", 24);
		diffText.setFormat("assets/fonts/vcr.ttf", 32, FlxColor.WHITE, RIGHT);
		add(diffText);
		changeSelection();

		// FlxG.sound.playMusic('assets/music/title' + TitleState.soundExt, 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;


		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;
		if (controls.RIGHT_P || controls.LEFT_P) {
			changeDiff();
		}
		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.BACK)
		{
			if (somethingSelected) {
				for (checkmark in checkmarks)
				{
					checkmark.visible = false;
				}
				somethingSelected = false;
			} else {
				sortedSongs = [];
				
				switch (sorting) {
					case "songs":
						var coolCategoryJson:Array<SelectSongsState.TCategory> = CoolUtil.parseJson(Assets.getText('assets/data/freeplaySongJson.jsonc'));
						for (i in referenceArray)
						{
							sortedSongs.push(songs[i]);
						}
						for (coolCategory in coolCategoryJson) {
							if (coolCategory.name == category) {
								coolCategory.songs = sortedSongs;
								break;
								// if this isn't found something is very very wrong
							}
						}
						trace(sortedSongs);
						FNFAssets.saveContent('assets/data/freeplaySongJson.jsonc',CoolUtil.stringifyJson(coolCategoryJson));
						FlxG.switchState(new SaveDataState());
					case "categories": 
						var coolCategoryJson:Array<SelectSongsState.TCategory> = CoolUtil.parseJson(Assets.getText('assets/data/freeplaySongJson.jsonc'));
						var coolReplacementJson:Array<SelectSongsState.TCategory> = [];
						for (i in referenceArray) {
							coolReplacementJson.push(coolCategoryJson[i]);
						}
						FNFAssets.saveContent('assets/data/freeplaySongJson.jsonc', CoolUtil.stringifyJson(coolReplacementJson));
						FlxG.switchState(new SaveDataState());
					case "weeks":
						// ha ha weeeeeee
						// this also has to rename files
						// we don't really need to do much to prepare the numbers, reference array handles it
						// lets read the files first
						var coolFiles:Array<{var png:Bytes; var xml:String;}> = [];
						var coolStoryJson:StoryMenuState.StorySongsJson = CoolUtil.parseJson(Assets.getText('assets/data/storySonglist.json'));
						var replacementJson:StoryMenuState.StorySongsJson = {songs: [], weekNames: [], characters: []};
						for (i in referenceArray) {
							// get files
							var coolPng:Bytes = FNFAssets.getBytes('assets/images/campaign-ui-week/week'+i+'.png');
							var coolXml:String = FNFAssets.getText('assets/images/campaign-ui-week/week'+i+'.xml');
							coolFiles.push({png: coolPng, xml:coolXml});
							replacementJson.songs.push(coolStoryJson.songs[i]);
							replacementJson.weekNames.push(coolStoryJson.weekNames[i]);
							replacementJson.characters.push(coolStoryJson.characters[i]);
						}
						// save the files to their new positions
						for (i in 0...coolFiles.length) {
							FNFAssets.saveBytes('assets/images/campaign-ui-week/week'+i+'.png',coolFiles[i].png);
							FNFAssets.saveContent('assets/images/campaign-ui-week/week'+i+'.xml',coolFiles[i].xml);
						}
						FNFAssets.saveContent('assets/data/storySonglist.json', CoolUtil.stringifyJson(replacementJson));
						FlxG.switchState(new SaveDataState());
				}
				FlxG.switchState(new SaveDataState());
			}
		}

		if (accepted)
		{
			// do shit
			if (!deleteStuff) {
				for (checkmark in checkmarks)
				{
					checkmark.visible = false;
				}
				somethingSelected = true;
				checkmarks[referenceArray[curSelected]].visible = true;
			} else {
				var numToRemove:Int = referenceArray[curSelected];
				var spriteToPutDown:Alphabet = grpSongs.members[curSelected];
				grpSongs.remove(spriteToPutDown, true).visible = false;
				songs.remove(songs[numToRemove]);
				referenceArray.remove(numToRemove);
				// hope this works
				var coolArray = [];
				for (i in 0...referenceArray.length) {
					var coolNum:Int = referenceArray[i];
					if (referenceArray[i] > numToRemove) {
						coolNum -= 1;
					}
					coolArray.push(coolNum);
				}
				referenceArray = coolArray;
				trace(grpSongs.members);
				trace(referenceArray);
			}
			
		}
	}

	function changeDiff()
	{
		if (deleteStuff) {
			diffText.text = "select";
			deleteStuff = false;
		} else {
			diffText.text = "delete";
			deleteStuff = true;
		}
		
	}
	function changeSelection(change:Int = 0)
	{

		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);
		var oldSelected = curSelected;
		curSelected += change;
		
		if (curSelected < 0)
			curSelected = referenceArray.length - 1;
		if (curSelected >= referenceArray.length)
			curSelected = 0;
		if (change != 0 && somethingSelected)
		{
			var temp = referenceArray[oldSelected];
			referenceArray[oldSelected] = referenceArray[curSelected];
			referenceArray[curSelected] = temp;
			trace(referenceArray);
		}
		var bullShit:Int = 0;
		// reference array is a fucky way of getting around not being able to manipulate groups
		for (item in referenceArray)
		{
			grpSongs.members[item].targetY = bullShit - curSelected;
			bullShit++;

			grpSongs.members[item].alpha = 0.6;

			if (grpSongs.members[item].targetY == 0)
			{
				grpSongs.members[item].alpha = 1;
			}
		}
	}
}
