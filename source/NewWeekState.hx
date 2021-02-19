package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import DifficultyIcons;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.ui.FlxButton;
import flixel.ui.FlxSpriteButton;
import flixel.addons.ui.FlxUITabMenu;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import sys.FileSystem;
import flash.media.Sound;

#end
import lime.ui.FileDialog;
import lime.app.Event;
import haxe.Json;
import tjson.TJSON;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import lime.ui.FileDialogType;
import haxe.io.Path;
using StringTools;
typedef TWeekJson = {
	var songs:Array<Array<String>>;
	var weekNames:Array<String>;
	var characters:Array<Array<String>>;
}
class NewWeekState extends MusicBeatState
{
	var addCharUi:FlxUI;
	var nameText:FlxUIInputText;
	var mainPngButton:FlxButton;
	var mainXmlButton:FlxButton;
	var selectSongsButton:FlxButton;
	var dadText:FlxUIInputText;
	var bfText:FlxUIInputText;
	var gfText:FlxUIInputText;
	var likeText:FlxUIInputText;
	var finishButton:FlxButton;
	var coolFile:FileReference;
	var coolData:ByteArray;
	var epicFiles:Array<String>;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	override function create()
	{
		addCharUi = new FlxUI();
		FlxG.mouse.visible = true;
		epicFiles = [];
		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);
		mainPngButton = new FlxButton(10,10,"Week Png",function ():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				epicFiles[0] = path;
			});
		});
		mainXmlButton = new FlxButton(10,60,"Week Xml", function ():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				epicFiles[1] = path;
			});
		});
		selectSongsButton = new FlxButton(10,110,"Select Songs", function ():Void {
			SelectSongsState.selectedSongs = [];
			FlxG.switchState(new SelectSongsState());
		});
		nameText = new FlxUIInputText(100,50,70,"daddy dearest");
		likeText = new FlxUIInputText(100, 10, 70,"WEEK 1");
		dadText = new FlxUIInputText(100, 90, 70, "dad");
		bfText = new FlxUIInputText(100,130, 70, "bf");
		gfText = new FlxUIInputText(100,170, 70, "gf");
		add(mainPngButton);
		add(mainXmlButton);
		finishButton = new FlxButton(FlxG.width - 170, FlxG.height - 50, "Finish", function():Void {
			writeCharacters();
			FlxG.switchState(new SaveDataState());
		});
		add(nameText);
		add(likeText);
		add(selectSongsButton);
		add(dadText);
		add(bfText);
		add(gfText);
		add(finishButton);
		var cancelButton = new FlxButton(FlxG.width - 300, FlxG.height - 50, "Cancel", function():Void
		{
			// go back
			FlxG.switchState(new SaveDataState());
		});
		add(cancelButton);
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

	}
	function writeCharacters() {
		#if sys
		var parsedWeekJson:TWeekJson = CoolUtil.parseJson(File.getContent("assets/data/storySongList.json"));
		File.copy(epicFiles[0], 'assets/data/week'+parsedWeekJson.songs.length+'.png');
		File.copy(epicFiles[1], 'assets/data/week'+parsedWeekJson.songs.length+'.xml');
		trace("parsed");
		var coolSongArray:Array<String> = [];
		coolSongArray.push(likeText.text);
		// probably crashes if no songs selected weeeeeeeeeeeee
		for (song in SelectSongsState.selectedSongs) {
			coolSongArray.push(song);
		}
		parsedWeekJson.songs.push(coolSongArray);
		parsedWeekJson.weekNames.push(nameText.text);
		parsedWeekJson.characters.push([dadText.text,bfText.text,gfText.text]);
		File.saveContent('assets/data/storySonglist.json', CoolUtil.stringifyJson(parsedWeekJson));
		trace("cool stuff");
		#end
	}
}
