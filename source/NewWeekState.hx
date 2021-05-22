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
import flixel.addons.ui.FlxUIButton;
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
class NewWeekState extends MusicBeatState
{
	var addCharUi:FlxUI;
	var nameText:FlxUIInputText;
	var mainPngButton:FlxUIButton;
	var mainXmlButton:FlxUIButton;
	var selectSongsButton:FlxButton;
	var dadText:FlxUIInputText;
	var bfText:FlxUIInputText;
	var gfText:FlxUIInputText;
	var likeText:FlxUIInputText;
	var finishButton:FlxButton;
	public static var epicFiles:Dynamic;
	var pngPath:String = "not valid lol";
	var xmlPath:String = "not valid lol";
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	public static var sorted:Bool = false;

	override function create()
	{
		if (!sorted) {
			addCharUi = new FlxUI();
			FlxG.mouse.visible = true;
			epicFiles = {png: "lol", xml: "lol"};
			var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
			add(bg);
			mainPngButton = new FlxUIButton(10, 10, "Week Png", function():Void
			{
				var coolDialog = new FileDialog();
				coolDialog.browse(FileDialogType.OPEN);
				coolDialog.onSelect.add(function(path:String):Void
				{
					epicFiles.png = path;
				});
			});
			mainXmlButton = new FlxUIButton(10, 60, "Week Xml", function():Void
			{
				var coolDialog = new FileDialog();
				coolDialog.browse(FileDialogType.OPEN);
				coolDialog.onSelect.add(function(path:String):Void
				{
					epicFiles.xml = path;
					trace(epicFiles);
				});
			});
			selectSongsButton = new FlxButton(10, 110, "Select Songs", function():Void
			{
				SelectSongsState.selectedSongs = [];
				openSubState(new SelectSongsState());
			});
			nameText = new FlxUIInputText(100, 50, 70, "daddy dearest");
			likeText = new FlxUIInputText(100, 10, 70, "WEEK1 select");
			dadText = new FlxUIInputText(100, 90, 70, "dad");
			bfText = new FlxUIInputText(100, 130, 70, "bf");
			gfText = new FlxUIInputText(100, 170, 70, "gf");
			add(mainPngButton);
			add(mainXmlButton);
			finishButton = new FlxButton(FlxG.width - 170, FlxG.height - 50, "Finish", function():Void
			{
				writeCharacters();
				LoadingState.loadAndSwitchState(new SaveDataState());
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
				LoadingState.loadAndSwitchState(new SaveDataState());
			});
			add(cancelButton);
			super.create();
		}
		
	}


	override function update(elapsed:Float)
	{
		super.update(elapsed);

	}
	function writeCharacters() {
		#if sys
		var parsedWeekJson:StoryMenuState.StorySongsJson = CoolUtil.parseJson(File.getContent("assets/data/storySonglist.json"));
		
		var coolSongArray:Array<String> = [];
		coolSongArray.push(likeText.text);
		// probably crashes if no songs selected weeeeeeeeeeeee
		for (song in SelectSongsState.selectedSongs) {
			coolSongArray.push(song);
		}
		trace("Pog");
		trace(epicFiles.png);
		File.copy(epicFiles.png, 'assets/images/campaign-ui-week/week' + parsedWeekJson.songs.length + '.png');
		trace("ehh");
		File.copy(epicFiles.xml, 'assets/images/campaign-ui-week/week' + parsedWeekJson.songs.length + '.xml');
		trace("parsed");
		if (parsedWeekJson.version == 1 || parsedWeekJson.version == null) {
			parsedWeekJson.songs.push(coolSongArray);
			parsedWeekJson.weekNames.push(nameText.text);
			parsedWeekJson.characters.push([dadText.text, bfText.text, gfText.text]);
		} else if (parsedWeekJson.version == 2) {
			var coolObject:StoryMenuState.WeekInfo = {animation: coolSongArray[0], name: nameText.text, bf: bfText.text, gf: gfText.text, dad: dadText.text, songs: coolSongArray.slice(1)};
			parsedWeekJson.weeks.push(coolObject);

		}
		
		File.saveContent('assets/data/storySonglist.json', CoolUtil.stringifyJson(parsedWeekJson));
		trace("cool stuff");
		#end
	}
}
