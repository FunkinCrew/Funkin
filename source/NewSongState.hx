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
import flixel.addons.ui.FlxUIButton;
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
import Song.SwagSong;
import openfl.net.FileReference;
import openfl.utils.ByteArray;
import lime.ui.FileDialogType;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
using StringTools;
typedef TDifficulty = {
	var offset:Int;
	var anim:String;
	var name:String;
}
typedef TDifficulties = {
	var difficulties:Array<TDifficulty>;
	var defaultDiff:Int;
}
class NewSongState extends MusicBeatState
{
	var addCharUi:FlxUI;
	var nameText:FlxUIInputText;
	var diffButtons:FlxTypedSpriteGroup<FlxUIButton>;
	var instButton:FlxUIButton;
	var voiceButton:FlxUIButton;
	var coolDiffFiles:Array<String> = [];
	var instPath:String;
	var voicePath:String;	
	var p1Text:FlxUIInputText;
	var p2Text:FlxUIInputText;
	var gfText:FlxUIInputText;
	var isSpooky:FlxUICheckBox;
	var stageText:FlxUIInputText;
	var cutsceneText:FlxUIInputText;
	var uiText:FlxUIInputText;
	var isMoody:FlxUICheckBox;
	var isHey:FlxUICheckBox;
	var categoryText:FlxUIInputText;
	var finishButton:FlxButton;
	var cancelButton:FlxUIButton;
	var coolFile:FileReference;
	var coolData:ByteArray;
	var epicFiles:Dynamic;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	override function create()
	{
		addCharUi = new FlxUI();
		FlxG.mouse.visible = true;
		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);
		diffButtons = new FlxTypedSpriteGroup<FlxUIButton>(0,0);
		trace('booga ooga');
		var diffJson:TDifficulties = CoolUtil.parseJson(Assets.getText("assets/images/custom_difficulties/difficulties.json"));
		trace("hmb");
		p1Text = new FlxUIInputText(100, 50, 70,"bf");
		p2Text = new FlxUIInputText(100,90,70,"dad");
		gfText = new FlxUIInputText(100,130,70,"gf");
		stageText = new FlxUIInputText(100,180,70,"stage");
		cutsceneText = new FlxUIInputText(100,220,70,"none");
		trace("fiodjsj");
		uiText = new FlxUIInputText(100,260,70,"normal");
		nameText = new FlxUIInputText(100,10,70,"bopeebo");
		trace("scloomb");
		isMoody = new FlxUICheckBox(100,340,null,null, "Girls Scared");
		isSpooky = new FlxUICheckBox(100,390,null,null,"Background Trail");
		isHey = new FlxUICheckBox(100,440, null, null, "Do HEY! Poses");
		add(isSpooky);
		trace("beemb");
		categoryText = new FlxUIInputText(100,290,70,"Base Game");
		trace("mood");
		for (i in 0...diffJson.difficulties.length) {
			var coolDiffButton = new FlxUIButton(10, 10 + (i * 50), diffJson.difficulties[i].name + " json", function():Void {
				var coolDialog = new FileDialog();
				coolDialog.browse(FileDialogType.OPEN);
				coolDialog.onSelect.add(function (path:String):Void {
					coolDiffFiles[i] = path;
				});
			});
			trace("before add");
			diffButtons.add(coolDiffButton);
		}
		trace("line 107");
		add(nameText);
		add(p1Text);
		add(p2Text);
		add(gfText);
		add(stageText);
		add(cutsceneText);
		add(categoryText);
		add(uiText);
		add(isMoody);
		add(isHey);
		add(diffButtons);
		finishButton = new FlxButton(FlxG.width - 170, FlxG.height - 50, "Finish", function():Void {
			writeCharacters();
			LoadingState.loadAndSwitchState(new SaveDataState());
		});
		instButton = new FlxUIButton(190, 10, "Instruments", function():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				instPath = path;
			});
		});
		voiceButton = new FlxUIButton(190, 60, "Vocals", function():Void {
			var coolDialog = new FileDialog();
			coolDialog.browse(FileDialogType.OPEN);
			coolDialog.onSelect.add(function (path:String):Void {
				voicePath = path;
			});
		});
		cancelButton = new FlxUIButton(FlxG.width - 300, FlxG.height - 50, "Cancel", function():Void {
			// go back
			LoadingState.loadAndSwitchState(new SaveDataState());
		});
		add(instButton);
		add(voiceButton);
		add(finishButton);
		add(cancelButton);
		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

	}
	function writeCharacters() {
		// check to see if directory exists
		#if sys
		if (!FileSystem.exists('assets/data/'+nameText.text.toLowerCase())) {
			FileSystem.createDirectory('assets/data/'+nameText.text.toLowerCase());
		}
		for (i in 0...coolDiffFiles.length) {
			if (coolDiffFiles[i] != null) {
				var coolSong:Dynamic = CoolUtil.parseJson(File.getContent(coolDiffFiles[i]));
				var coolSongSong:Dynamic = coolSong.song;
				coolSongSong.song = nameText.text;
				coolSongSong.player1 = p1Text.text;
				coolSongSong.player2 = p2Text.text;
				coolSongSong.gf = gfText.text;
				coolSongSong.stage = stageText.text;
				coolSongSong.uiType = uiText.text;
				coolSongSong.cutsceneType = cutsceneText.text;
				coolSongSong.isMoody = isMoody.checked;
				coolSongSong.isHey = isHey.checked;
				coolSong.song = coolSongSong;

				File.saveContent('assets/data/'+nameText.text.toLowerCase()+'/'+nameText.text.toLowerCase()+DifficultyIcons.getEndingFP(i)+'.json',CoolUtil.stringifyJson(coolSong));
			}
		}
		// probably breaks on non oggs haha weeeeeeeeeee
		File.copy(instPath,'assets/music/'+nameText.text+'_Inst.ogg');
		if (voicePath != null) {
			File.copy(voicePath,'assets/music/'+nameText.text+'_Voices.ogg');
		}
		var coolSongListFile:Array<Dynamic> = CoolUtil.parseJson(Assets.getText('assets/data/freeplaySongJson.jsonc'));
		var foundSomething:Bool = false;
		for (coolCategory in coolSongListFile) {
			if (coolCategory.name == categoryText.text) {
				foundSomething = true; 
				coolCategory.songs.push({"name": nameText.text, "character": p2Text.text, "week": 0});
				break;
			}
		}
		if (!foundSomething) {
			// must be a new category
			coolSongListFile.push({"name": categoryText.text, "songs": [nameText.text]});
		}
		File.saveContent('assets/data/freeplaySongJson.jsonc',CoolUtil.stringifyJson(coolSongListFile));
		#end
	}
}
